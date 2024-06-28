
magnitude(x::Real) = floor(Int,log10(0.5*x))

to_row(A::AbstractVector;F::Syntax=LaTeXsyntax) = join(A,F.cs).*F.el
to_string(A::String;k...) =  A 
to_string(A::Real;F::Syntax=LaTeXsyntax,k...) =  string(F.ms,A,F.ms)
to_string(A::Missing;k...) = " ";

function to_string(A::NTuple{N,Real} where N; F::Syntax=LaTeXsyntax, error_style::String="bs",k...)
  error_style = [c for c in error_style]
  v = string(A[1])
  e = string.([A[2:end]...])
  if 's' in error_style
    l= maximum(length.(e))
    for i in eachindex(e)
      e[i] = "0"^(l-length(e[i]))*e[i]
    end
  end
  if 'b' in error_style
    return string(F.ms,v,"(",join(e,")("),")",F.ms)
  else
    return string(F.ms,join([v,e...],F.pm),F.ms)
  end
 end

function format_numbers(M::AbstractVector{Union{Missing,T}} where T; k...) 
  filter = findall(x->!ismissing(x),M)
  output = Vector{Any}(missing,length(M))
  output[filter] = format_numbers([M[filter]...];k...)
  return output
end

format_numbers(M::AbstractVector{String};k...) = M

function format_numbers(V::AbstractVector{T};real_precision::Union{Nothing,Int64}=nothing,k...) where T <:Real
  if isnothing(real_precision)
    return V
  end
  return round.(V,digits=real_precision)
end

function format_numbers(M::AbstractVector{NTuple{N,T}} where {N,T<:Real};extra_precision::Int64=0,k...)
  N = length(M[1])
  err = [getfield(M[i],j) for i in eachindex(M), j in 2:N];
  val = getfield.(M,1);
  m = -minimum(magnitude.(err))+extra_precision;
  err = round.(err,digits=m)
  if !any(err.>=1.0)
    err =round.(Int,err.*10.0^(m))
  end
  val = round.(val,digits=m)
  return [(val[i],err[i,:]...) for i in eachindex(val)]
end

function make_table(M::AbstractMatrix;F::Syntax=LaTeXsyntax,real_precision::Union{Nothing,Int64} = nothing,extra_precision::Int64=0,error_style::String="bs")
  output = Vector{String}(undef,size(M,1))

  m = reduce(hcat,[format_numbers([r...],extra_precision=extra_precision,real_precision=real_precision) for r in eachcol(M)])
  for i in axes(M,1)
    aux = to_string.(m[i,:],F=F,error_style=error_style)
    output[i] = to_row(aux,F=F)
  end
  return output
end