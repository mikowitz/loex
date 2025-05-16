defprotocol Loex.Statement do
  def to_string(expr)

  def interpret(statement)
end
