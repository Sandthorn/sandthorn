[![Build Status](https://travis-ci.org/Sandthorn/sandthorn.svg?branch=master)](https://travis-ci.org/Sandthorn/sandthorn)
[![Coverage Status](https://coveralls.io/repos/Sandthorn/sandthorn/badge.svg?branch=master)](https://coveralls.io/r/Sandthorn/sandthorn?branch=master)
[![Code Climate](https://codeclimate.com/github/Sandthorn/sandthorn.svg)](https://codeclimate.com/github/Sandthorn/sandthorn)
[![Gem Version](https://badge.fury.io/rb/sandthorn.svg)](http://badge.fury.io/rb/sandthorn)

# Sandthorn Event Sourcing
A ruby library for saving an object's state as a series of events.

## What is Event Sourcing?

"Capture all changes to an application state as a sequence of events."
[Event Sourcing](http://martinfowler.com/eaaDev/EventSourcing.html)

## When do I need event sourcing?

When state changes made to an object is important a common technique is to store the changes in a separate history log where the log is generated in parallel with the object internal state. With event sourcing the history log is now integrated within the object and generated based on the actions made to the object. The entries in log is the facts the object is built upon.

## Why Sandthorn?

If you have been following [Uncle Bob](http://blog.8thlight.com/uncle-bob/2014/05/11/FrameworkBound.html) you know what he thinks of the "Rails way" and how we get bound to the Rails framework. We have created Sandthorn to decouple our models from Active Record and restore them to what they should be, i.e., Plain Old Ruby Objects (PORO) with a twist of Sandthorn magic.

Check out examples of Sandthorn:

* [Examples](https://github.com/Sandthorn/sandthorn_examples) including a product shop and TicTacToe game.
* Live [demo](http://infinite-mesa-8629.herokuapp.com/) comparing Active Record and Sandthorn.

# Installation

Add this line to your application's Gemfile:

    gem 'sandthorn'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sandthorn

# Configuring Sandthorn

## Driver
Sandthorn can be setup with one or more drivers. A driver is bound to a specific data store where events are saved and loaded from. The current implemented drivers are [sandthorn_driver_sequel](https://github.com/Sandthorn/sandthorn_driver_sequel) for SQL via [Sequel](https://github.com/jeremyevans/sequel) and [sandthorn_driver_event_store](https://github.com/Sandthorn/sandthorn_driver_event_store) that uses [Get Event Store](https://geteventstore.com).

This means Sandthorn can be used with any data store given that a driver exists.

Here's an example of setting up Sandthorn with the Sequel driver and a sqlite3 database.

```ruby
url = "sqlite://sql.sqlite3"
driver = SandthornDriverSequel.driver_from_url(url: url)
Sandthorn.configure do |conf|
  conf.event_stores = { default: driver }
end
```

## Map aggregate types to event stores

Its possible to save events from different classes into different stores. Below the events from class FooAggregate are stored into the sql_foo.sqlite3 database and events from class BarAggregate are stored in sql_bar.sqlite3.

```ruby
driver_foo = SandthornDriverSequel.driver_from_url(url: "sqlite://sql_foo.sqlite3")
driver_bar = SandthornDriverSequel.driver_from_url(url: "sqlite://sql_bar.sqlite3")

class FooAggregate
  Include Sandthorn::AggregateRoot
end

class BarAggregate
  Include Sandthorn::AggregateRoot
end

Sandthorn.configure do |conf|
  conf.event_stores = { foo: driver_foo, bar: driver_bar }
  conf.map_types = { foo: [FooAggregate], bar: [BarAggregate] }
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

In this exampel the `events` method will generate a method called `marked`, this method take an block that will be executed before the event is commited and is used to groups the state changes to the event. The block is optional and the state changes could have been made outside the `marked` method.

```ruby
class Board
  include Sandthorn::AggregateRoot

  events :marked

  def mark player, pos_x, pos_y
    # change some state
    marked() do
      @pos_x = pos_x
      @pos_y = pos_y
    end
  end
end
```

### `Sandthorn::AggregateRoot::constructor_events`

With `constructor_events` its possible to be more specific on how an aggregate came to be. The first event will now have the name `board_created` instead of the default `new`.

```ruby
class Board
  include Sandthorn::AggregateRoot

  # creates a private class method `board_created`
  constructor_events :board_created

  def self.create name

    board_created(name) do
      @name = name
    end
  end
end
```

### `Sandthorn::AggregateRoot::stateless_events`

Calling `stateless_events` creates public class methods. The first argument is an `aggregate_id` and the second argument is optional but has to be a hash and is stored in the event_data of the event.

When creating a stateless event, the corresponding aggregate is never loaded and the event is saved without calling the save method.

```ruby
class Board
  include Sandthorn::AggregateRoot

  stateless_events :player_went_to_toilet

end

Board.player_went_to_toilet "board_aggregate_id", {player_id: "1", time: "10:12"}
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

To generate an event the commit method has to be called within the aggregate. `commit` extracts the object's delta and locally caches the state changes that has been applied to the aggregate.

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

The concept `events` have been introduced to abstract away the usage of `commit`. Commit still works as before but we think that the `events` abstraction makes the aggregate more readable.

### `Sandthorn::AggregateRoot.save`

The save method store generated events, this means all commited events will be persisted via a Sandthorn driver.

```ruby
board = Board.new
board.mark :o, 0, 1
board.save
```

### `Sandthorn::AggregateRoot.all`

Retrieve an array with all instances of a specific aggregate type.

```ruby
Board.all
```

Since it return's an `Array` you can, for example, filter on an aggregate's fields

```ruby
Board.all.select { |board| board.active == true }
```

### `Sandthorn::AggregateRoot.find`

Loads a specific aggregate using it's uuid.

```ruby
uuid = '550e8400-e29b-41d4-a716-446655440000'
board = Board.find(uuid)
```

If no aggregate with the specifid uuid is found, a `Sandthorn::Errors::AggregateNotFound` exception is raised.

### `Sandthorn::AggregateRoot.aggregate_trace`

Using `aggregate_trace` one can store meta data on events. The data is not aggregate specific and it can for example store who executed a specific command on the aggregate.

```ruby
board.aggregate_trace {player: "Fred"} do |aggregate|
   aggregate.mark :o, 0, 1
   aggregate.save
end
```

`aggregate_trace` can also be specified on a class.

```ruby
Board.aggregate_trace {ip: :127.0.0.1} do
  board = Board.new
  board.mark :o , 0, 1
  board.save
end
```

In this case, the resulting events from the commands `new` and `mark` will have the trace `{ip: :127.0.0.1}` attached to them.

### `Sandthorn::AggregateRoot.unsaved_events?`

Check if there are unsaved events attached to the aggregate.

```ruby
board = Board.new
board.mark :o, 0, 1
board.unsaved_events?
=> true
```

## Snapshot

If there is a lot of events saved to an aggregate it can take some time to reload the current state of the aggregate via the `.find` method. This is because all events belonging to the aggregate has to be fetched and iterated one by one to build its current state. The snapshot functionality makes it possible to store the current aggregate state and re-use it when loading the aggregate. The snapshot is used as a cache where only the events that has occurred after the snapshot has to be fetched and used to build the current state of the aggregate.

There is one global snapshot store where all snapshots are stored independent on aggregate_type. To enable snapshot on a aggregate_type the Class has to be added to the `snapshot_types` Array when configuring Sandthorn. The aggregate will now be stored to the snapshot_store on every `.save` and when using `.find` it will look for a snapshot of the requested aggregate.

```ruby

class Board
  include Sandthorn::AggregateRoot
end

Sandthorn.configure do |c|
  c.snapshot_types = [Board]
end
```

Its possible to take manual snapshots without enabling snapshots on the aggregate_type.

```ruby
board = Board.new
board.save

# Save snapshot of the board aggregate
Sandthorn.save_snapshot board

# Get snapshot
snapshot = Sandthorn.find_snapshot board.aggregate_id
```

### External snapshot store

There is one external snapshot store available [sandthorn_snapshot_memcached](https://github.com/Sandthorn/sandthorn_snapshot_memcached) and it can be configured via `Sandthorn.configure`

```ruby
require 'sandthorn_snapshot_memcached'

snapshot_store = SandthornSnapshotMemcached.from_url "memcached_url"

Sandthorn.configure do |conf|
  conf.snapshot_store = snapshot_store
end
```

**If no external snapshot store is configured snapshots will be stored in the application memory (be careful not draining your application memory space).**

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
