[![Build Status](https://travis-ci.org/Sandthorn/sandthorn.svg?branch=master)](https://travis-ci.org/Sandthorn/sandthorn)
[![Coverage Status](https://coveralls.io/repos/Sandthorn/sandthorn/badge.png?branch=master)](https://coveralls.io/r/Sandthorn/sandthorn?branch=master)
[![Code Climate](https://codeclimate.com/github/Sandthorn/sandthorn.png)](https://codeclimate.com/github/Sandthorn/sandthorn)
[![Gem Version](https://badge.fury.io/rb/sandthorn.png)](http://badge.fury.io/rb/sandthorn)

# Sandthorn Event Sourcing
A ruby library for saving an object's state as a series of events.

## What is Event Sourcing?

"Capture all changes to an application state as a sequence of events."
[Event Sourcing](http://martinfowler.com/eaaDev/EventSourcing.html)

## When do I need event sourcing?

If the history of how an object came to be is important a well known technique is to generate a separate history log. The log is generated in parallel with the object and all actions to the object needs to be stored to the log by a separate method call. With event sourcing the history log is now integrated with the object and generated based on the actions that are made on the object, the log is now the fact that the object is built upon.


## Why Sandthorn?

If you have been following [Uncle Bob](http://blog.8thlight.com/uncle-bob/2014/05/11/FrameworkBound.html) you know what he thinks of the "Rails way" and how we get bound to the Rails framework. We have created Sandthorn to decouple our models from Active Record and restore them to what they should be, i.e., Plain Old Ruby Objects (PORO) with a twist of Sandthorn magic.

Check out examples of Sandthorn:

* [Examples](https://github.com/Sandthorn/sandthorn_examples) including a product shop and TicTacToe game.
* Live [demo](http://demo.sandthorn.org) comparing Active Record and Sandthorn.

## How do I use Sandthorn?



Think of it as an object database where you store not only what the new value of an attribute is, but also when and why it changed.
_Example:_

```ruby

# Setup the Aggregate

# The one available right now
require 'sandthorn'
require 'sandthorn_driver_sequel'

class Ship
  include Sandthorn::AggregateRoot
  attr_reader :name

  def initialize name: nil, shipping_company: nil
    @name = name
  end

  # State-changing command
  def rename! new_name: ""
    unless new_name.empty? or new_name == name
      @name = new_name
      ship_was_renamed
    end
  end

  private

  # Commit the event and state-change is automatically recorded.
  def ship_was_renamed
    commit
  end
end

# Setup the framework with the sequel driver for persistance
url = "sqlite://spec/db/sequel_driver.sqlite3"
catch_all_config = [ { driver: SandthornDriverSequel.driver_from_url(url: url) } ]
Sandthorn.configuration = catch_all_config

# Migrate db schema for the sequel driver
migrator = SandthornDriverSequel::Migration.new url: url
SandthornDriverSequel.migrate_db url: url

# Usage
ship = Ship.new name: "Titanic"
ship.rename! new_name: "Vasa"

ship.save

new_ship = Ship.find ship.id
puts new_ship.name
```

# Installation

Add this line to your application's Gemfile:

    gem 'sandthorn'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sandthorn

# Configuring Sandthorn

Sandthorn relies on a driver is specific to the data storage that you are using. This means Sandthorn can be used with any data storage given that a driver exists.

To setup a driver you need to add it to your project's Gemfile and configure it in your application code.

    gem 'sandthorn_driver_sequel'

The driver is configured when your application launches. Here's an example of how to do it using the Sequel driver and a sqlite3 database.

```ruby
url = "sqlite://spec/db/sequel_driver.sqlite3"
driver = SandthornDriverSequel.driver_from_url(url: url)
catch_all_config = [ { driver: driver } ]
Sandthorn.configuration = catch_all_config
```

First we specify the path to the sqlite3 database in the `url` variable. Secondly, the specific driver is instantiated with the `url`. Hence, the driver could be instantiated using a different configuration, for example, an address to a Postgres database. Finally, `Sandthorn.configure` accepts a keyword list with options. The only option which is required is `driver`.

The first time you use the Sequel driver it is necessary to install the database schema.

```ruby
url = "sqlite://spec/db/sequel_driver.sqlite3"
SandthornDriverSequel::Migration.new url: url
SandthornDriverSequel.migrate_db url: url
```

Optionally, when using Sandthorn in your tests you can configure it in a `spec_helper.rb` which is then required by your test suites [example](https://github.com/Sandthorn/sandthorn_examples/blob/master/sandthorn_tictactoe/spec/spec_helper.rb#L20-L30). Note that the Sequel driver accepts a special parameter to empty the database between each test.

The Sequel driver is the only production-ready driver to date.

# Usage

Any object that should have event sourcing capability must include the methods provided by `Sandthorn::AggregateRoot`. These make it possible to `commit` events and `save` changes to an aggregate. Use the `include` directive as follows:

```ruby
require 'sandthorn'

class Board
  include Sandthorn::AggregateRoot
end
```

All objects that include `Sandthorn::AggregateRoot` is provided with an `aggregate_id` which is a [UUID](http://en.wikipedia.org/wiki/Universally_unique_identifier).

### `Sandthorn::AggregateRoot.commit`

It is required that an event is commited to the aggregate to be stored as an event. `commit` extracts the object's delta and locally caches the state changes that has been applied to the aggregate. Commonly, commit is called when an event is applied. In [CQRS](http://martinfowler.com/bliki/CQRS.html), events are named using past tense.

```ruby
def mark player, pos_x, pos_y
  # change some state
  marked
end

def marked
  commit
end
```

`commit` determines the state changes by monitoring the object's readable fields.

### `Sandthorn::AggregateRoot.save`

Once one or more commits have been applied to an aggregate it should be saved. This means all commited events will be persisted by the specific Sandthorn driver. `save` is called by the owning object.

```ruby
board = Board.new
board.mark :o, 0, 1
board.save
```

### `Sandthorn::AggregateRoot.all`

It is possible to retrieve an array with all instances of a specific aggregate.

```ruby
Board.all
```

Since it return's an `Array` you can, for example, filter on an aggregate's fields

```ruby
Board.all.select { |board| board.active == true }
```

### `Sandthorn::AggregateRoot.find`

Using `find` it is possible to retrieve a specific aggregate using it's id.

```ruby
uuid = '550e8400-e29b-41d4-a716-446655440000'
board = Board.find(uuid)
board.aggregate_id == uuid
```

### `Sandthorn::AggregateRoot.aggregate_trace`
 
Using `aggragete_trace` it is possible to add extra data to an event that is not aggregate specific.
 
```ruby
uuid = '550e8400-e29b-41d4-a716-446655440000'
board = Board.find(uuid)
board.aggregate_trace "trace data" do |aggregate|
   aggreagte.mark :o, 0, 1
   aggregate.save
end
```

It is also possible to do a `aggregate_trace` on a class, all event in
the block will have the trace attached to when.

````ruby
Board.aggregate_trace "trace data" do
  board = Board.new
  board.mark :o , 0, 1
  board.save
end
```

If no aggregate with the specifid id is found, a `Sandthorn::Errors::AggregateNotFound` exception is raised.

# Development

Run tests: `rake`

Run benchmark tests: `rake benchmark`

Load a console: `rake console`

# Contributing

We're happy to accept pull requests that makes the code cleaner or more idiomatic, the documentation more understandable, or improves the testsuite. Even considering opening an issue for what's troubling you or writing a blog post about how you used Sandthorn is  worth a lot too!

In general, the contribution process for code works like this.

1. Fork this repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
