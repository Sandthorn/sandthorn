require 'spec_helper'

describe Sandthorn::Configuration do
  let(:config) { Sandthorn::Configuration.new }

  shared_examples "block receiver" do |method, default_method|
    context "when not given a block" do
      context "and no block has ever been given" do
        it "returns the default block" do
          expect(config.send(method)).to eq(config.send(default_method))
        end
      end

      context "when a block has been given" do
        it "returns the given block" do
          block = -> {}
          config.send(method, &block)
          expect(config.send(method)).to eq(block)
        end
      end
    end
  end

  describe "#serializer" do
    it_behaves_like "block receiver", :serializer, :default_serializer
  end

  describe "#deserializer" do
    it_behaves_like "block receiver", :deserializer, :default_deserializer
  end
end