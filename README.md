# Sandthorn Event Sourcing
A ruby framwork for saving an object's state as a series of events, and tracking non state changing events.

## What is Event Sourcing

"Capture all changes to an application state as a sequence of events."
[Event Sourcing](http://martinfowler.com/eaaDev/EventSourcing.html)

## The short story

Think of it as an object database where you not only what the new value of the attribute is but when and why it changed.
_Example:_

```ruby
class Ship < Sandthorn::EventAggregate
	attr_reader :shipping_company
	attr_reader :name

	def initialize name: nil, shipping_company: nil
		@name = name
		@shipping_company = shipping_company
	end

	# state-changing command
	def rename! new_name: ""
		unless new_name.empty? or new_name == name
			@name = new_name
			ship_was_renamed
		end
	end
	private
	# record the event and state-change is automatically recorded.
	def ship_was_renamed
		record_event
	end
end

class Port < Sandthorn::EventAggregate
	attr_reader :name

	def initialize name: nil, owner: nil
		@name = name
		@owner = owner
	end

	# non_state_changing events
	def ship_arrived_to_port ship: nil
		record_event { ship_id: ship.id }
	end
	def ship_departed_port ship: nil
		record_event { ship_id: ship.id }
	end
end
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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
