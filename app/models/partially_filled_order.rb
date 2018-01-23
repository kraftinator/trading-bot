class PartiallyFilledOrder < ApplicationRecord
  
  belongs_to  :limit_order
  
  delegate :open, :to => :limit_order
  delegate :trader, :to => :limit_order
  
end
