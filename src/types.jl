@doc raw"""
    @kwdef struct Syntax

Define the syntax rules that are used during the table formatting. 
LaTeXsyntax is already defined and used by deafult. 

## Fields
  - cs::String: column separator
  - el::String: end line 
  - ms::String: math envirorment separator
  - pm::String: `\pm` symbol 
  - bs::String: block separator, i.e \hline in LaTeX

See also: [`LaTeXsyntax`](@ref)
"""
@kwdef struct Syntax
    cs::String ## column separator
    el::String ## end line
    ms::String ## math envirorment separator
    pm::String ## pm style
    bs::String ## block separator
    empty::String
end

@doc raw"""
    LaTeXsyntax::Syntax =  Syntax(cs = " & ",el ="\\\\",ms=" \$ ",pm=" \\pm ",bs = "\\hline",empty=""))

Predefined syntax stucture for Latex syntax
See also: [`Syntax`](@ref)
"""
LaTeXsyntax = Syntax(cs = " & ",el ="\\\\",ms=" \$ ",pm=" \\pm ",bs = "\\hline",empty="\$ - \$")
