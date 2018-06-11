require 'spec_helper'

module Sandthorn
  module Snapshot
    class KlassOne
      include Sandthorn::AggregateRoot
      snapshot true
    end

    class KlassTwo
      include Sandthorn::AggregateRoot
    end

    class KlassThree
      include Sandthorn::AggregateRoot
    end

    describe "::snapshot" do
      before do
        Sandthorn.configure do |c|
          c.snapshot_types = [KlassTwo]
        end
      end
      it "snapshot is true on KlassOne and KlassTwo but not KlassThree" do
        expect(KlassOne.snapshot).to be_truthy
        expect(KlassTwo.snapshot).to be_truthy
        expect(KlassThree.snapshot).not_to be_truthy
      end
    end

  end
end

