defprotocol Loex.Expr do
  def to_string(expr)

  def evaluate(expr)
end
