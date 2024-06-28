# TableFormatter
This package formats a Matrix into a table according to the Syntax struct specified
By default, it formats the Matrix into a LaTeX table, but it is possible to define a custom Syntax object and format it accordingly.

The package supports strings, Real numbers and numbers with errors. If a cell needs to be empty, it has to be set to missing. 
In particular:
 - Strings elements do not get changed
 - Real numbers, by default get turned into a string with $ delimitating them
 - Numbers with errors are represented by an NTuple, the first component is the central value, and the others are the errors. 

Keywords parameters:
- real_precision::Union{Nothing,Int64}=nothing, set the precision to which round real numbers. By default, it is set to nothing, so no rounding is applied. When set, it round the number as round(x,digits=real_precision)
- extra_precision::Int64=0 when rounding Numbers with errors, it increases the precision
- error_style::String ="bs", it sets the style for writing the errors. "s" forces the errors in a column to have the same number of digits by adding zeros before the shorter one. "b" writes the error in brackets
- F::Syntax=LaTeXsyntax, set the syntax


Syntax structure:
This structure defines the syntax for writing the table. Its components are:
  - cs::String ## column separator
  - rs::String ## row separator
  - el::String ## end line
  - ms::String ## math environment separator
  - pm::String ## pm style
