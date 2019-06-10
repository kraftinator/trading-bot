module ApplicationHelper
  
  ZERO = 0.0001
  #ZERO = 0.00001
=begin  
  def get_text_color_class(number)
    if number > ZERO
      return 'text-success'
    elsif number < -ZERO
      return 'text-danger'
    end
  end
=end
  
  def get_text_color_class(number)
    if number.round(4) > 0
      return 'text-success'
    elsif number.round(4) < 0
      return 'text-danger'
    end
  end
  
=begin  
  def print_plus_or_minus(number)
    if number > ZERO
      return '+'
    elsif number < -ZERO
      return '-'
    end
  end
=end

  def print_plus_or_minus(number)
    if number.round(4) > 0
      return '+'
    elsif number.round(4) < 0
      return '-'
    end
  end

  
end
