module Sandthorn
  module Refinements
    refine String do
      def to_id
        self
      end
    end
  end
end