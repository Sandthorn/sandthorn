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
* Live [demo](http://infinite-mesa-8629.herokuapp.com/) comparing Active Record and Sandthorn.

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

# Configure one driver
url = "sqlite://spec/db/sequel_driver.sqlite3"
sql_event_store = SandthornDriverSequel.driver_from_url(url: url)
Sandthorn.configure do |c|
  c.event_store = sql_event_store
end

# Or configure many drivers
url = "sqlite://spec/db/sequel_driver.sqlite3"
sql_event_store = SandthornDriverSequel.driver_from_url(url: url)
url_two = "sqlite://spec/db/sequel_driver_two.sqlite3"
other_store = SandthornDriverSequel.driver_from_url(url: url_two)

Sandthorn.configure do |c|
  c.event_stores = {
    default: sql_event_store,
    other_event_store: other_store
  }
end

# Assign your aggregates to a named event store

class Boat
  include Sandthorn::AggregateRoot
  event_store :other_event_store
end

# Aggregates with no explicit event store will use the default event store

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

## Driver

Sandthorn relies on a driver that is specific to the data storage that you are using. This means Sandthorn can be used with any data storage given that a driver exists.

To setup a driver you need to add it to your project's Gemfile and configure it in your application code.

    gem 'sandthorn_driver_sequel'


The driver is configured when your application launches. Here's an example of how to do it using the Sequel driver and a sqlite3 database.

```ruby
url = "sqlite://spec/db/sequel_driver.sqlite3"
driver = SandthornDriverSequel.driver_from_url(url: url)
Sandthorn.configure do |conf|
  conf.event_stores = { default: driver }
end
```

First we specify the path to the sqlite3 database in the `url` variable. Secondly, the specific driver is instantiated with the `url`. Hence, the driver could be instantiated using a different configuration, for example, an address to a Postgres database. Finally, `Sandthorn.configure` accepts a keyword list with options. It´s here the driver is bound to Sandthorn via a context.

The first time you use the Sequel driver it is necessary to install the database schema.

```ruby
url = "sqlite://spec/db/sequel_driver.sqlite3"
SandthornDriverSequel::Migration.new url: url
SandthornDriverSequel.migrate_db url: url
```

Optionally, when using Sandthorn in your tests you can configure it in a `spec_helper.rb` which is then required by your test suites [example](https://github.com/Sandthorn/sandthorn_examples/blob/master/sandthorn_tictactoe/spec/spec_helper.rb#L20-L30). Note that the Sequel driver accepts a special parameter to empty the database between each test.

The Sequel driver is the only production-ready driver to date.


## Map aggregate types to event stores

Its possible to map aggregate_types to events stores from the configuration setup. This makes it possible to work with data from different stores that are using the same context, and will override any event_store setting within an aggregate.

```ruby
url_foo = "sqlite://spec/db/sequel_driver_foo.sqlite3"
driver_foo = SandthornDriverSequel.driver_from_url(url: url_foo)

url_bar = "sqlite://spec/db/sequel_driver_bar.sqlite3"
driver_bar = SandthornDriverSequel.driver_from_url(url: url_bar)

class AnAggregate
  Include Sandthorn::AggregateRoot
end

class AnOtherAggregate
  Include Sandthorn::AggregateRoot
end

Sandthorn.configure do |conf|
  conf.event_stores = { foo: driver_foo, bar: driver_bar }
  conf.map_types = { foo: [AnAggregate], bar: [AnOtherAggregate] }
end
```

## Data serialization / deserialization

Its possible to configure how events and snapshots are serialized / deserialized. The default are YAML but can be overloaded in the configure block.

```ruby
Sandthorn.configure do |conf|
  conf.serializer = Proc.new { |data| Oj::dump(data) }
  conf.deserializer = Proc.new { |data| Oj::load(data) }
  conf.snapshot_serializer = Proc.new { |data| Oj::dump(data) }
  conf.snapshot_deserializer = Proc.new { |data| Oj::load(data) }
end
```


# Usage

## Aggregate Root

Any object that should have event sourcing capability must include the methods provided by `Sandthorn::AggregateRoot`. These make it possible to `commit` events and `save` changes to an aggregate. Use the `include` directive as follows:

```ruby
require 'sandthorn'

class Board
  include Sandthorn::AggregateRoot
end
```

All objects that include `Sandthorn::AggregateRoot` is provided with an `aggregate_id` which is a [UUID](http://en.wikipedia.org/wiki/Universally_unique_identifier).

### `Sandthorn::AggregateRoot::events`

An abstraction over `commit` that creates events methods that can be used from within a command method.

In this exampel the `events` method will generate a method called `marked`, this method take *args as input that will result in the method argument on the event. It also take a block that will be executed before the event is commited and is used to groups the state changes to the event (but is only optional right now).

```ruby
class Board
  include Sandthorn::AggregateRoot
  
  events :marked
  
  def mark player, pos_x, pos_y
    # change some state
    marked(player) do
      @pos_x = pos_x
      @pos_y = pos_y
    end
  end
end
```

### `Sandthorn::AggregateRoot::default_attributes`

Its possible to add a default_attributes method on an aggregate and set default values to new and already created aggregates.

The `default_attributes` method will be run before initialize on Class.new and before the events when an aggregate is rebuilt. This will make is possible to add default attributes to an aggregate during its hole life cycle.

```ruby
def default_attributes
  @new_array = []
end
```

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

Since version 0.10.0 of Sandthorn the concept `events` have been introduced to abstract away the usage of `commit`. Commit still works as before but we think that the `events` abstraction makes the aggregate more readable. 

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


### `Sandthorn::AggregateRoot.aggregate_trace`

Using `aggregate_trace` one can store meta data with events. The data is not aggregate specific, for example, one can store who executed a specific command on the aggregate.

```ruby
board.aggregate_trace {player: "Fred"} do |aggregate|
   aggregate.mark :o, 0, 1
   aggregate.save
end
```

`aggregate_trace` can also be specified on a class.

````ruby
Board.aggregate_trace {ip: :127.0.0.1} do
  board = Board.new
  board.mark :o , 0, 1
  board.save
end
```

In this case, the resulting events from the commands `new` and `mark` will have the trace `{ip: :127.0.0.1}` attached to them.

## Bounded Context

A bounded context is a system divider that split large systems into smaller parts. [Bounded Context by Martin Fowler](http://martinfowler.com/bliki/BoundedContext.html) 

A module can include `Sandthorn::BoundedContext` and all aggregates within the module can be retreived via the ::aggregate_types method on the module. A use case is to use it when Sandthorn is configured and setup all aggregates in a bounded context to a driver.

```ruby
require 'sandthorn/bounded_context'

module TicTacToe
  include Sandthorn::BoundedContext

  class Board
    include Sandthorn::AggregateRoot
  end
end

Sandthorn.configure do |conf|
  conf.event_stores = { foo: driver_foo}
  conf.map_types = { foo: TicTacToe.aggregate_types }
end

TicTacToe.aggregate_types -> [TicTacToy::Board]
```

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
