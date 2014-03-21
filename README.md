# Sandthorn Event Sourcing
A ruby framework for saving an object's state as a series of events, and tracking non state changing events.

## What is Event Sourcing

"Capture all changes to an application state as a sequence of events."
[Event Sourcing](http://martinfowler.com/eaaDev/EventSourcing.html)

## The short story

Think of it as an object database where you not only what the new value of the attribute is but when and why it changed.
_Example:_

```ruby

# Setup the Aggregate

# The one available right now
require 'sandthorn'
require 'sandthorn_driver_sequel'
require 'sandthorn/aggregate_root_dirty_hashy'

class Ship
  include Sandthorn::AggregateRoot::DirtyHashy
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
url = "path to sql" #Example sqlite://path/sequel_driver.sqlite3
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
puts ship.name

# For more info look at the specs.

```

## Installation

Add this line to your application's Gemfile:

    gem 'sandthorn'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sandthorn

## Usage

TODO: Write usage instructions here

## Development

run:
   `rake console`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
