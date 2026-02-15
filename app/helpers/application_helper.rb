module ApplicationHelper
  def format_currency(amount)
    number_to_currency(amount, unit: "R$ ", separator: ",", delimiter: ".")
  end
end
