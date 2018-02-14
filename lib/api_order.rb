class ApiOrder
  
  ## Order attributes
  attr_accessor :uid
  attr_accessor :side
  attr_accessor :status
  attr_accessor :executed_qty
  attr_accessor :original_qty
  attr_accessor :price
  
  ## Error attributes
  attr_accessor :error_code
  attr_accessor :error_msg
  
  def initialize( opts )
    @uid = opts[:uid]
    @side = opts[:side]
    @status = opts[:status]
    @executed_qty = opts[:executed_qty]
    @original_qty = opts[:original_qty]
    @price = opts[:price]
    @error_code = opts[:error_code]
    @error_msg = opts[:error_msg]
  end
  
  def success?
    error_code.nil?
  end
  
  def failed?
    !success?
  end
  
  def show
    output = []
    if success?
      output << "----------------------------"
      output << "Uid:          #{uid}"
      output << "Side:         #{side}"
      output << "Status:       #{status}"
      output << "Executed Qty: #{executed_qty}"
      output << "Original Qty: #{original_qty}"
      output << "Price:        #{price}"
      output << "----------------------------"
    else
      output << "----------------------------"
      output << "Error Code: #{error_code}"
      output << "Error Msg:  #{error_msg}"
      output << "----------------------------"
    end
    puts output
  end
  
end