module ApplicationHelper
  
  def get_text_color_class(number)
    if number > 0
      return 'text-success'
    elsif number < 0
      return 'text-danger'
    end
  end
  
  def print_plus_or_minus(number)
    if number > 0
      return '+'
    elsif number < 0
      return '-'
    end
  end
  
end
