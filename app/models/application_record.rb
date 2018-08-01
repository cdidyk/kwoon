class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # available options are :except, :include, :methods, and :only
  def to_dto options=nil
    serializable_hash options
  end

  # REVIEW: this is probably too simplistic for handling nested attributes. It also
  # assumes dto is a Hash.
  def self.from_dto dto
    attrs = new.attributes
    assignable_attrs = dto.select do |k,v|
      attrs.include?(k.to_s) && !["created_at", "updated_at"].include?(k.to_s)
    end
    new assignable_attrs
  end
end
