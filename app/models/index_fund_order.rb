class IndexFundOrder < ApplicationRecord
  
  belongs_to :index_fund_coin
  
  scope :non_canceled, -> { where( "open is true or filled_at is not null" ) }
  
end
