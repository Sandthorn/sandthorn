require "rspec/expectations"

RSpec::Matchers.define :have_aggregate_type do |expected|
  match do |actual|
    actual[:aggregate_type].to_s == expected.to_s
  end
end
