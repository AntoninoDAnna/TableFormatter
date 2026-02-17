using Format
magnitude(x::Real) = x==0.0 ? 1 : floor(Int64,log10(abs(0.5*x)))
magnitude10(x::Real) = x==0.0 ? 2 : ceil(Int64,log10(abs(x)));
non_zero(a::AbstractArray) = a[findall(x->x!=0.0,a)]

function nonmissing(x::AbstractArray)
    i = findfirst(y->!ismissing(y), x)
    if isnothing(i)
        return x[1]
    end

    return x[i]
end

istype(x, type...) = any(y-> x isa y, type)

@doc raw"""
     only_String(M::AbstractMatrix)

Convert any element that is an `AbstractString` into a `String`
"""
function only_String(M::AbstractMatrix)
    for c in CartesianIndices(M)
        if !(M[c] isa AbstractString)
            continue;
        end
        M[c] = String(M[c])
    end
end

to_row(A::AbstractVector;F::Syntax=LaTeXsyntax) = join(A,F.cs).*F.el

function rotate(M::AbstractMatrix)
    m = typeof(M)(undef,size(M,2),size(M,1))
    [m[i,j] = M[j,i] for i in axes(m,1), j in axes(m,2)]
    return m
end

function rotate(M::AbstractVector)
    m = Matrix{Any}(undef,1,size(M,1))
    [m[1,j] = M[j] for j in axes(m,2)]
    return m
end

function format_numbers(M::AbstractVector{Union{Missing,T}} where T; F::Syntax=LaTeXsyntax,k...)
    filter = findall(x->!ismissing(x),M)
    if length(filter) ==0
        return M
    end
    output = fill(F.empty,length(M))
    output[filter] = format_numbers([M[filter]...];F=F,k...)
    return output
end

format_numbers(V::AbstractVector{T} where T<:Real; F::Syntax=LaTeXsyntax,k...) = string(F.ms,"[",join(v,", "),"]",F.ms)

format_numbers(V::AbstractVector{<:AbstractVector{T}} where T<:Real;F::Syntax=LaTeXsyntax,k...) =  format_numbers.(V,F=F;k...)

format_numbers(A::AbstractString;k...) = A

format_numbers(M::AbstractVector{<:AbstractString};k...) = M

format_numbers(x::Int64; F::Syntax=LaTeXsyntax,) = string(F.ms,x,F.ms)

function format_numbers(V::AbstractVector{Int64},zpad::Bool=false;k...)
    M = magnitude10(maximum(abs.(V)));
    return format.(V,width=M,precision =M, zeropadding = zpad);
end

function format_numbers(V::T;F::Syntax=LaTeXsyntax,custom_precision::Union{Nothing,Int64}=nothing,zpad::Bool=false,k...) where T <:AbstractFloat
    m = isnothing(custom_precision) ? 8 : custom_precision
    M = magnitude10(abs.(V));
    return string(F.ms,format(V,width=M+m+1,precision = m, zeropadding = zpad),F.ms)
end

function format_numbers(A::AbstractVector{T};custom_precision::Union{Nothing,Int64}=nothing,zpad::Bool=false,F::Syntax=LaTeXsyntax,k...) where T <:AbstractFloat
    M= maximum(abs.(A));
    m= minimum(abs.(A));
    m = isnothing(custom_precision) ? -magnitude(m) : custom_precision;
    if zpad && M>1.0
        w = magnitude10(M)+m+1;
        return [string(F.ms,format(a,precision = m, width=w, zeropadding = true), F.ms) for a in A]
    else
        return [string(F.ms,format(a,precision = m), F.ms) for a in A]
    end

end

function format_numbers(x::NTuple{N,T} where {N,T<:Real};error_style::String="b",custom_precision::Union{Nothing,Int64}=nothing,F::Syntax = LaTeXsyntax,k...)
    val = x[1];
    err = [x[2:end]...];

    merr = isnothing(custom_precision) ? -magnitude(minimum(non_zero(err))) : custom_precision
    mval = isnothing(custom_precision) ? -magnitude(val) : custom_precision
    m = max(merr,mval)
    M = min(merr,mval)
    val = round(val, digits = m)
    err = round.(err,digits = m)

    if m >6
        err .*= 10^M
        val *= 10^M
        val = format(val,precision=m-M)
        res = string(F.ms,val,"(",join(err,")("),")","\\times 10^{-$M}",F.ms)
    else
        if all(err.<1.0)
            err.*= 10^m
            err = format.(err,precision=0)
        else
            err = format.(err, precision =m)
        end
        val = format(val,precision = m)
        res = string(F.ms,val,"(",join(err, ")("),")",F.ms)
    end
    return res
end

format_numbers(M::Missing; k...) = " - "

function format_numbers(M::AbstractVector{NTuple{N,T}} where {N,T<:Real};F::Syntax=LaTeXsyntax,error_style::String="bz",zpad::Bool=false,custom_precision::Union{Nothing,Int64}=nothing,k...)
    N = length(M[1])
    err = [getfield(M[i],j) for i in eachindex(M), j in 2:N];
    val = getfield.(M,1);
    merr = isnothing(custom_precision) ? -magnitude(minimum(non_zero(err))) : custom_precision
    mval = isnothing(custom_precision) ? -magnitude(minimum(val)) : custom_precision
    m = max(merr,mval)
    err = round.(err,digits=m)
    val = round.(val,digits=m)

    if 'p' in error_style
        return [string(F.ms,join([val[i],err[:,i]...],F.pm),F.ms) for i in eachindex(val)]
    end
    if 'z' in error_style
        M = magnitude10(maximum(err));
        if all(err.<1.0)
            err *= 10^float(m)
            err = format.(err,width=M+m,precision=0, zeropadding=true)
        else
            err = format.(err,width=M+m+1,precision = m, zeropadding = true);
        end
    end
    M = magnitude10(maximum(abs.(val)));
    val = format.(val,width=M+m+1,precision = m, zeropadding = zpad);
    if 'b' in error_style
        return [string(F.ms,val[i],"(",join(err[i,:],")("),")",F.ms) for i in eachindex(val)]
    end
    error("TableFormatter: non valid error style.")
end

function no_ze(M,custom_precision::Vector,F::Syntax,error_style,zpad)
    m = [format_numbers(M[i,j],custom_precision=custom_precision[j],error_style=error_style) for i in axes(M,1), j in axes(M,2)]
    m = [to_row([r...]) for r in eachrow(m)]
    m[end]*=" $(F.bs)"
    return m
end

function space_padding!(M::AbstractMatrix{<:AbstractString})
    for j in axes(M,2)
        lmax = maximum(length.(M[:,j]))

        for i in axes(M,1)
            l = length(M[i,j])
            n = div(lmax-l,2)
            off = lmax-l-2n;
            M[i,j] = string(" "^n, M[i,j], " "^(n+off))
        end
    end
end

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
                    zpad::Bool = false,
                    do_spadding::Bool = true,
                    endline = nothing)::Vector{String}


    cs::Vector{Any} = [nothing for _ in 1:max(size(M)...)];
    if custom_precision isa Vector
        [cs[c] = precision for (c,precision) in custom_precision]
    else
        [cs[c] = custom_precision for c in eachindex(cs)]
    end

    only_String(M);
    _M = similar(M,String);
    if !('z' in error_style)
        return no_ze(M,cs,F,error_style,zpad)
    end

    ## check for headers
    type = if all(x-> istype(x,AbstractString,Missing), M[1,:]) && all(x-> all(y-> istype(y,typeof(nonmissing(x)),Missing), x[2:end]),eachcol(M[2:end,:]))
        _M[1,:] .=M[1,:]
         'r'
    elseif all(x-> istype(x,AbstractString,Missing), M[:,1]) && all(x-> all(y-> istype(y,typeof(nonmissing(x)),Missing), x[2:end]),eachrow(M[:,2:end]))
        _M[:,1] .= M[1,:]
        'c'
    elseif all(x-> all(y-> istype(y,typeof(nonmissing(x)),Missing), x[2:end]),eachcol(M))
        'v'
    elseif all(x-> all(y-> istype(y,typeof(nonmissing(x)),Missing), x[2:end]),eachrow(M))
        'h'
    else
        @warn raw"""
    Multiple types in row and column, ignoring zero padding in errors.
    To suppress this warning either remove 'z' from error style,
    or reorganize your table in such a way that each row or each column (header excluded)
    contains entry of only one type.
      """
        return no_ze(M,cs,F,filter(c->!(c != 'z'), error_style),zpad)
    end

    if type =='r'
        _M[2:end,:] .= reduce(hcat,[format_numbers([M[2:end,c]...],custom_precision=cs[c]) for c in axes(M,2)])
    elseif type =='c'
        _M[:,2:end] .= reduce(vcat,rotate.([format_numbers([M[c,2:end]...],custom_precision=cs[c]) for c in axes(M,1)]))
    elseif type =='v'
        _M .= reduce(hcat,[format_numbers([M[:,c]...], custom_precision=cs[c]) for c in axes(M,2)])
    else
        _M .=  reduce(vcat,rotate.(format_numbers([M[c,:]...], custom_precision=cs[c]) for c in axes(M,1)))
    end

    do_spadding && space_padding!(_M)

    output = [to_row(_M[c,:]) for c in axes(_M,1)]
    if isnothing(endline)
        output[end]*=F.bs
    else
        for (idx,l) in endline
            output[idx]*=l
        end
    end
    return output
end

#=
"""
make_table(data::AbstractVector...;k...)::Vector{String}

It takes a set of AbstractVector and generate a table. Each vector correspond to a column colum of
the table and all data vector must have the same number of data. Remember to use `missing` for empty
table entries.

## Example
v1 = [1,2,3]
v2 = ["test", missing, "test"]
v3 = [(12.0,0.2,0.3),(2.12,0.3,0.02),(2.22,0.03,0.51)]

# "1 & test &  \$ 12.00(20)(30) \$ \\\\"
# "2 &      &  \$  2.12(30)(02) \$ \\\\"
# "3 & test &  \$  2.22(03)(51) \$ \\\\"
"""
function make_table(data::AbstractVector ...; k...)::Vector{String}
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
end =#


function make_table(data::Vector{Matrix{Any}};k...)
    return vcat(make_table.(data;k...)...)
end
