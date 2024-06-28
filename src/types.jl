@kwdef struct Syntax
  cs::String ## column separator
  rs::String ## row separator
  el::String ## end line
  ms::String ## math envirorment separator
  pm::String ## pm style 
end

LaTeXsyntax = Syntax(cs = " & ",rs=" \\hline",el ="\\",ms=" \$ ",pm=" \\pm ")