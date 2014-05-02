[![Build Status](https://travis-ci.org/Sandthorn/sandthorn.svg?branch=master)](https://travis-ci.org/Sandthorn/sandthorn)
[![Coverage Status](https://coveralls.io/repos/Sandthorn/sandthorn/badge.png?branch=master)](https://coveralls.io/r/Sandthorn/sandthorn?branch=master)
[![Code Climate](https://codeclimate.com/github/Sandthorn/sandthorn.png)](https://codeclimate.com/github/Sandthorn/sandthorn)
[![Gem Version](https://badge.fury.io/rb/sandthorn.png)](http://badge.fury.io/rb/sandthorn)

# Sandthorn Event Sourcing
A ruby framework for saving an object's state as a series of events, and tracking non state changing events.

## What is Event Sourcing

"Capture all changes to an application state as a sequence of events."
[Event Sourcing](http://martinfowler.com/eaaDev/EventSourcing.html)

## The short story

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

## Installation

Add this line to your application's Gemfile:

    gem 'sandthorn'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sandthorn

## Usage

Any object that should have event-sourcing capability must include the methods provided by `Sandthorn::AggregateRoot`. These makes it possible to `commit` events and `save` changes to an aggregate. Use the `include` directive as follows:

```ruby
require 'sandthorn'

class Board
  include Sandthorn::AggregateRoot
end
```

All objects that include `Sandthorn::AggregateRoot` will get an `aggregate_id` which is a [UUID](http://en.wikipedia.org/wiki/Universally_unique_identifier).

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

If no aggregate with the specifid id is found, a `Sandthorn::Errors::AggregateNotFound` exception is raised.

## Development

Run tests: `rake`

Run benchmark tests: `rake benchmark`

Load a console: `rake console`

## Contributing

We're happily accepting pull requests that makes the code cleaner or more idiomatic, the documentation more understandable, or improves the testsuite. If you don't have time right now, considering opening an issue, that's worth a lot too!

In general, the contribution process works like this.

1. Fork this repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

