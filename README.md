# TableFormatter
This package formats a Matrix into a table according to the Syntax struct specified
By default, it formats the Matrix into a LaTeX table, but it is possible to define a custom Syntax object and format it accordingly.

The package supports strings, Real numbers and numbers with errors. If a cell needs to be empty, it has to be set to missing. 
In particular:
 - Strings elements do not get changed
 - Real numbers, by default get turned into a string with $ delimitating them
 - Numbers with errors are represented by an NTuple, the first component is the central value, and the others are the errors. 

Keywords parameters:
- custom_precision::Union{Nothing, Int64}=nothing, override the precision to which round numbers. It is set to nothing by default.
- error_style::String ="bz", it sets the style for writing the errors. "z" applies zero-padding until the errors within a column have the same number of digits,  "b" writes the error in brackets, "p" writes the error with a \pm 
- F::Syntax=LaTeXsyntax, set the syntax, by default uses a LaTeX syntax

Syntax structure:
This structure defines the syntax for writing the table. Its components are:
  - cs::String ## column separator
  - el::String ## end line
  - ms::String ## math environment separator
  - pm::String ## pm style   
