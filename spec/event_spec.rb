require "spec_helper"

module Sandthorn
  describe Event do
    let(:event_data) do
      JSON.parse(
        '{"aggregate_type":"SandthornProduct",
            "aggregate_version":1,
            "aggregate_id":"62d88e96-c551-4157-a837-1674e3f2698d",
            "sequence_number":114,
            "event_name":"new",
            "timestamp":"2014-08-16 20:02:05 UTC",
            "event_args":{"method_name":"new",
            "method_args":[{"name":"Hahah",
            "price":"50",
            "stock_status":"outofstock"}],
            "attribute_deltas":[{"attribute_name":"name",
            "old_value":null,
        "new_value":"Hahah"},
            {"attribute_name":"price",
            "old_value":null,
        "new_value":50},
            {"attribute_name":"stock_status",
            "old_value":null,
        "new_value":"outofstock"},
            {"attribute_name":"active",
            "old_value":null,
        "new_value":true},
            {"attribute_name":"on_sale",
            "old_value":null,
        "new_value":false},
            {"attribute_name":"aggregate_id",
            "old_value":null,
        "new_value":"62d88e96-c551-4157-a837-1674e3f2698d"}]}}', symbolize_names: true)
    end

    let(:subject) { Event.new(event_data) }
    describe "primitive attributes" do
      attrs = %i(
        aggregate_id
        aggregate_type
        aggregate_version
        timestamp
        event_name
        event_args
        method_args
        trace
      )

      attrs.each do |attr|
        it "has an accessor for #{attr}" do
          expect(subject.send(attr)).to eq(subject[attr])
        end
      end
    end

    describe "#new_values" do
      context "when given the value of an attribute that has changed" do
        it "returns the new value" do
          expect(subject.new_values[:name]).to eq("Hahah")
        end
      end

      context "when given a non-existing attribute name" do
        it "returns nil" do
          expect(subject.new_values[:foo]).to be_nil
        end
      end
    end

    describe "#attributes_deltas" do
      it "returns something enumerable" do
        expect(subject.attribute_deltas).to respond_to(:each)
      end

      describe "a delta" do
        let(:wrapped_delta) { subject.attribute_deltas.first }
        let(:raw_delta) { subject[:event_args][:attribute_deltas].first }
        describe "#attribute_name" do
          it "has the same value as the raw hash" do
            expect(wrapped_delta.attribute_name).to eq(raw_delta[:attribute_name])
          end
        end

        describe "#new_value" do
          it "has the same value as the raw hash" do
            expect(wrapped_delta.new_value).to eq(raw_delta[:new_value])
          end
        end

        describe "#old_value" do
          it "has the same value as the raw hash" do
            expect(wrapped_delta.old_value).to eq(raw_delta[:old_value])
          end
        end
      end
    end
  end
end
