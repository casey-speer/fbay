# A simple mixin for setting state on MongoMapper models
module Fbay
  module Utils
    module SetState
      def self.included(klass)
        raise "Isn't a MongoMapper model" unless klass.method_defined?(:save)
      end

      def set_state( state_token )
        self.state = state_token
        save
      end
    end
  end
end
