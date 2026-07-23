alias Loex.{AstPrinter, Scanner, Token}
alias Loex.Expr.{Binary, Grouping, Literal, Unary}

expr = Binary.new(
  Unary.new(
    Token.new(:MINUS, "-", nil, 1),
    Literal.new(123)
  ),
  Token.new(:STAR, "*", nil, 1),
  Grouping.new(
    Literal.new(45.67)
  )
)
