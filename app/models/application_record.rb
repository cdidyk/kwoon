class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # available options are :except, :include, :methods, and :only
  def to_dto options=nil
    serializable_hash options
  end

  # REVIEW: this is probably too simplistic for handling nested attributes. It also
  # assumes dto is a Hash.
  def from_dto dto
    self.attributes = dto
  end
end
