require 'active_model/serialization'

module Domain
  module Entities
    class Base
      include ActiveModel::Serialization
      include Comparable

      attr_accessor :id

      def self.from_dto dto
        new dto
      end

      def initialize attrs={}
        attrs.each do |k,v|
          next unless respond_to? k
          instance_variable_set("@#{k}", v)
        end
      rescue => e
        raise ArgumentError, "bad attrs value for #{self.class}.new. Is it a Hash with string keys?"
      end

      def <=> obj
        id <=> obj.id
      end

      def to_dto options=nil
        serializable_hash options
      end

      # NOTE all Entities need to have attr_accessors for each attributes key
      # for serializable_hash to work

      def attributes
        { 'id' => id }
      end
    end
  end
end
