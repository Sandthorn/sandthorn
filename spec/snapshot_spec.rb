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
      it "snapshot should be enabled on KlassOne and KlassTwo but not KlassThree" do
        expect(KlassOne.snapshot).to be_truthy
        expect(KlassTwo.snapshot).to be_truthy
        expect(KlassThree.snapshot).not_to be_truthy
      end
    end

    describe "find snapshot on snapshot enabled aggregate" do
      let(:klass) { KlassOne.new.save }

      it "should find on snapshot enabled Class" do
        copy = KlassOne.find klass.aggregate_id
        expect(copy.aggregate_version).to eql(klass.aggregate_version)
      end

      it "should get saved snapshot" do
        copy = Sandthorn.find_snapshot klass.aggregate_id
        expect(copy.aggregate_version).to eql(klass.aggregate_version)
      end

    end

    describe "save and find snapshot on snapshot disabled aggregate" do
      let(:klass) { KlassThree.new.save }

      it "should not find snapshot" do
        snapshot = Sandthorn.find_snapshot klass.aggregate_id
        expect(snapshot).to be_nil
      end

      it "should save and get saved snapshot" do
        Sandthorn.save_snapshot klass
        snapshot = Sandthorn.find_snapshot klass.aggregate_id
        expect(snapshot).not_to be_nil

        #Check by key on the snapshot_store hash
        expect(Sandthorn.snapshot_store.store.has_key?(klass.aggregate_id)).to be_truthy
        
      end

    end

  end
end

