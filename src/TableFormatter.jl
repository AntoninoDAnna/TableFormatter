module TableFormatter
  using Printf
  
  include("types.jl")
  include("make_tables.jl")

  export Syntax,LaTeXsyntax
  export make_table

end # module TableFormatter
