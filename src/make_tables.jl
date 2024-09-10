using Format
magnitude(x::Real) = floor(Int64,log10(0.5*x))
magnitude10(x::Real) = ceil(Int64,log10(x));

to_row(A::AbstractVector;F::Syntax=LaTeXsyntax) = join(A,F.cs).*F.el

function to_string(A::AbstractVector{Any};k...)
  non_missing = findall(x->!ismissing(x),A)
  if length(non_missing) ==0
    return to_string.(A);
  end
  missing_val = findall(x-> ismissing(x),A)
  T = typeof.(A[non_missing])
  if !all(T.===T[1]) && !any(T.<:Real)
    error("TableFormatter Error: table is not well formatted:")
  end
  if T[1] <: AbstractString
    A[missing_val] .=" ";
    return to_string(String.(A))
  end
  V = Vector{T[1]}(undef, length(A[non_missing]))
  for i in eachindex(A[non_missing]) 
    V[i] = A[non_missing[i]]
  end
  output = [" " for _ in A];
  output[non_missing]= to_string(V;k...)
  return to_string(output)
end

function to_string(A::AbstractVector{<:AbstractString};k...) 
  m = maximum(length.(A))
  return [a*' '^(m-length(a)) for a in A]
end 
to_string(A::Missing;k...) = " ";
to_string(A::AbstractString; k...) = A

function to_string(A::AbstractVector{T} where T<: Real;F::Syntax=LaTeXsyntax, custom_precision::Union{Int64,Nothing}=nothing, zpad::Bool=false, k...)
  M= maximum(A);
  m= minimum(A)
  m = isnothing(custom_precision) ? -magnitude(m) : custom_precision;

  if zpad && M>1.0
    w = magnitude10(M)+m+1;
    format.(A,precision = m, width=w, zeropadding = true)
  else
    format.(A,precision = m)
  end
  return [string(F.ms,a, F.ms) for a in A];
end

function to_string(A::AbstractVector{NTuple{N,T}} where {N,T<:Real}; F::Syntax=LaTeXsyntax, error_style::String="bz",zpad::Bool=false,custom_precision::Union{Int64,Nothing}=nothing)
  error_style = [error_style...]
  N = length(A[1]);
  v = [a[1] for a in A]
  e = [a[i] for i in 2:N, a in A]
  if 'p' in error_style
    return [string(F.ms,join([v[i],e[:,i]...],F.pm),F.ms) for i in eachindex(v)]
  end
  m = isnothing(custom_precision) ? -magnitude(minimum(e)) : custom_precision
  if 'z' in error_style
    M = magnitude10(maximum(e));
    if all(e.<1.0)
      e *= 10^m 
      e = format.(e,width=M+m,precision=0, zeropadding=true)
    else
      e = format.(e,width=M+m+1,precision = m, zeropadding = true);
    end
  end
  M = magnitude10(maximum(v));
  v = format.(v,width=M+m+1,precision = m, zeropadding = zpad);
  if 'b' in error_style
    return [string(F.ms,v[i],"(",join(e[:,i],")("),")",F.ms) for i in eachindex(v)]
  end
end

function to_string(V::AbstractVector{<:AbstractVector{T}} where T<:Real;F::Syntax=LaTeXsyntax,kwargs...)
  A = [string(F.ms,"[",join(v,", "),"]",F.ms) for v in V]
  return to_string(A,F=F;kwargs...) 
end

function format_numbers(M::AbstractVector{Union{Missing,T}} where T; k...) 
  filter = findall(x->!ismissing(x),M)
  output = Vector{Any}(missing,length(M))
  if length(filter) ==0
    return M
  end
  output[filter] = format_numbers([M[filter]...];k...)
  return output
end

format_numbers(M::AbstractVector{<:AbstractString};k...) = M

function format_numbers(V::AbstractVector{Int64},zpad::Bool=false;k...)
  M = magnitude10(maximum(V));
  return format.(V,width=M,precision =M, zeropadding = zpad);
end

function format_numbers(V::AbstractVector{T};custom_precision::Union{Nothing,Int64}=nothing,zpad::Bool=false,k...) where T <:AbstractFloat
  m = isnothing(custom_precision) ? 8 : custom_precision
  M = magnitude10(maximum(V));
  return format.(V,width=M+m+1,precision = m, zeropadding = zpad);
end

function format_numbers(M::AbstractVector{NTuple{N,T}} where {N,T<:Real};custom_precision::Union{Nothing,Int64}=nothing,k...)
  N = length(M[1])
  err = [getfield(M[i],j) for i in eachindex(M), j in 2:N];
  val = getfield.(M,1);
  m = isnothing(custom_precision) ?  -minimum(magnitude.(err)) : custom_precision;
  err = round.(err,digits=m)
  val = round.(val,digits=m)
  return [(val[i],err[i,:]...) for i in eachindex(val)]
end

format_numbers(V::AbstractVector{<:AbstractVector{T}} where T<:Real; k...) = V 



@doc raw"""
    make_table(M::AbstractMatrix; kwargs...)::Vector{String}

make a table from a matrix `M`. Each entries of `M` will be converted into one entry of the final table. 
Each component of the output vector is a row of the matrix.

## Supported type
The matrix `M` is an `AbstractMatrix{Any}`, therefore its entry can be of any type. The following are supported 
by the `make_table` function
  - `T<:Real`: any real number is supported and treated as a pure number without error. 
     By default, if `Float`,they are printed with 8 digits after the comar. 
  - `String`: they remain untouch, apart of appending whitespaces for alignment reasons
  - `NTuple{N,T} where {N,T<:Real}`: this represent a number with error. The first component is the central value, 
     the remaning components are treated as separate errors
  - `Vector{T} T<:Real`: Vector are printed as $ [...] $, a comar separate each value. 
  - `Missing`: Missing values are use to indicate an empty entry

The functions operate on eachcolumn to determine the precision, hence the element of a column need to  be of the same type.
If a column has multiple types elements, an error is thrown.

## Arguments
  - `F::Syntax` = LaTeXsyntax : Specify the syntax
  - `error_style::String` = "bz" : Specify the error style:
    - "b": the error is written in brakets: 3.1415(23)
    - "p": the error is written with a `\pm` sign: 3.1415 ± 0.0023
    - "z": if given, the errors within the same columns are forced to have the same number of digits using zeropadding
  - `custom_precision::Union{Int64,Nothing,Vector{Tuple{Int64,Int64}}}=nothing`: override the detected precision. 
    - if `Int64` the precision of all the entries is overridden
    - if `Vector{Tuple{Int64,Int64}}`: the tuple is interepret as `(c, p)`, such that the precision in column `c` is set to `p`. This allows to set diffenents precision for each column. 
  - `zpad::Bool=false`: it forces the zero padding. while `error_style="z"` force zeropadding only with the errors,`zpad` forces it also for central value
  
## Example
```  
    using TableFormatter

    M = ["test" (10.984,0.023) 5.00;
          missing  (10.984,0.003) 0.60;
          "test"  (122.34,0.490) 12.23]

    make_table(M); 
    # "test &  \$ 10.984 \\pm 0.023 \$  &  5.00000000\\\\"
    # "     &  \$ 10.984 \\pm 0.003 \$  &  0.60000000\\\\"
    # "test &  \$ 122.34 \\pm 0.49 \$   & 12.23000000\\\\"
  

    make_table(M,zpad=true)
    # "test &  \$ 010.984(023) \$  &  \$ 05.00000000 \$ \\\\"
    # "     &  \$ 010.984(003) \$  &  \$ 00.60000000 \$ \\\\"
    # "test &  \$ 122.340(490) \$  &  \$ 12.23000000 \$ \\\\"

    M[:,1] = [[1,2],[2,3],[4,5]]

    make_table(M,custom_precision=3)
    # " \$ [1, 2] \$  &  \$  10.984(023) \$  &  5.000\\\\"
    # " \$ [2, 3] \$  &  \$  10.984(003) \$  &  0.600\\\\"
    # " \$ [4, 5] \$  &  \$ 122.340(490) \$  & 12.230\\\\"
```        
"""
function make_table(M::AbstractMatrix;
  F::Syntax=LaTeXsyntax,
  error_style::String="bz", 
  custom_precision::Union{Int64,Nothing,Vector{Tuple{Int64,Int64}}}=nothing,
  zpad::Bool = false) ::Vector{String}
  output = Vector{String}(undef,size(M,1))
  if custom_precision isa Vector
    cs::Vector{Any} = [nothing for _ in axes(M,2)];
    for (c,precision) in custom_precision
      cs[c] = precision
    end
    m = reduce(hcat,[format_numbers([M[:,c]...],custom_precision=cs[c]) for c in axes(M,2)])
  else
    m = reduce(hcat,[format_numbers([c...],custom_precision=custom_precision) for c in eachcol(M)])
  end

  for i in axes(m,2)
    m[:,i] = to_string(m[:,i],F=F,error_style=error_style,custom_precision=custom_precision,zpad=zpad)
  end
    output = [to_row([r...]) for r in eachrow(m)]
  return output
end


"""
    make_table(data::AbstractVector...;k...)::Vector{String}

It takes a set of AbstractVector and generate a table. Each vector correspond to a column colum of 
the table and all data vector must have the same number of data. Remember to use `missing` for empty
table entries. 

## Example
    v1 = [1,2,3]
    v2 = ["test", missing, "test"]
    v3 = [(12.0,0.2,0.3),(2.12,0.3,0.02),(2.22,0.03,0.51)]

    make_table(v1,v2,v3)
    # "1 & test &  \$ 12.00(20)(30) \$ \\\\"  
    # "2 &      &  \$  2.12(30)(02) \$ \\\\"
    # "3 & test &  \$  2.22(03)(51) \$ \\\\"    
"""
function make_table(data::AbstractVector...; k...)::Vector{String}
  l = length(data);
  n = length(data[1]);
  if any(length.(data).!=n)
    error("ERROR: The data vectors have diffenents size. Consider using 'missing' for empty table entries")
  end
  M = Matrix{Any}(undef,n,l)
  for i in eachindex(data)
    M[:,i] = data[i]
  end
  return make_table(M;k...)
end

