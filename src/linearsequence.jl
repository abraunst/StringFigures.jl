######## Linear Sequence

"""
A `LinearSequence` represents a knot in punctured space with a notation similar to Gauss codes. 
A linear sequence is a sequence (separated by ":") of either `FrameNode`s (loosely, fingers) and `Crossing`s. 

See also: [`seq""`](@ref), [`plot`](@ref)
"""
struct LinearSequence
    seq::Vector{SeqNode}
end

@rule snodec = snode & ":" > (x,_) -> x
@rule linseq = (snodec[*] & snode) > (x,y) -> LinearSequence(push!(copy(x),y))

"""
`seq"xxx"` returns the [`LinearSequence`](@ref) `"xxx"`.
    
See also: [`open""`](@ref), [`storer""`](@ref)

# Examples
```jldoctest
julia> seq"L1:R1:R2"
seq"L1:R1:R2"
```
"""
macro seq_str(s)
    parsepeg(linseq, s)
end

const Openings = Dict(
    "O1" => seq"L1:L5:R5:R1",
    "OA" => seq"L1:x1(0):R2:x2(0):L5:R5:x2(U):L2:x1(U):R1",
    "O0" => seq"L2:R2"
)

@rule opening = r"[0-9A-Za-z]*"p[1] > o -> haskey(Openings, o) ? Openings[o] : throw(ArgumentError("Opening \"$o\" not found")) 


"""
`open"xxx"` returns the opening xxx. 

# Examples
```jldoctest
julia> open"O0"
seq"L2:R2"

julia> open"O1"
seq"L1:L5:R5:R1"

julia> open"OA"
seq"L1:x1(0):R2:x2(0):L5:R5:x2(U):L2:x1(U):R1"
```
"""
macro open_str(s)
    parsepeg(opening, s)
end

"""
`storer"xxx"` is equivalent to `seq"xxx"` but allows some fuzziness to be able to easily copy-paste 
from Storer's OCR'd book :)

# Examples
```jldoctest
julia> osage3diamondsfig41 = storer"Ll: x1(0): x2(U): x3(0): x4(0): x5(U): x6(0): x7(0): x8(UJ: x9(U):
       x10(0): x11(0): x12(U): x13(UJ: x14(0): x15(U): x16(U): R2: x16(0):
       x17(U): x18{0): x19(U): x20(0): x5(0): x4(U): x21(0): L2: x2l(U):
       x3(U): x2(0): xl(U): x22(U): x23(0): x6(U): x20(U): x19(0): x9(0):
       xlO (U): x18 (U): xl7(0): x15 (0): x14 (U): x13 (0): Rl: x12'(0): xll (U):
       x8(0): x7(UJ: x23(U): x22(0) "
seq"L1:x1(0):x2(U):x3(0):x4(0):x5(U):x6(0):x7(0):x8(U):x9(U):x10(0):x11(0):x12(U):x13(U):x14(0):x15(U):x16(U):R2:x16(0):x17(U):x18(0):x19(U):x20(0):x5(0):x4(U):x21(0):L2:x21(U):x3(U):x2(0):x1(U):x22(U):x23(0):x6(U):x20(U):x19(0):x9(0):x10(U):x18(U):x17(0):x15(0):x14(U):x13(0):R1:x12(0):x11(U):x8(0):x7(U):x23(U):x22(0)"
```
"""
macro storer_str(s)
    parsepeg(linseq, replace(s, "\n"=>"", " " => "", "{" => "(",
        "l" => "1", ";" => ":", "O" => "0", "S" => "5", "X" => "x",
        "B" => "8", "G" => "6", "?" => "7", "J" => ")", "'" => ""))
end

Base.length(p::LinearSequence) = length(p.seq)

function gaussish_code(p::LinearSequence)
    map(p.seq) do n
        if n.type == :U 
            -idx(n)
        else
            idx(n)
        end
    end
end



### equivalent to canonical(p).seq == p.seq but faster and non-allocating
function iscanonical(p::LinearSequence)
    type(p[begin]) == :L || return false
    L = idx(p[begin])
    isnearsidenext(p, p[begin]) && return false
    last = 0
    for j in 2:lastindex(p)
        if p[j] isa CrossNode
            if idx(p[j]) > last + 1 
                return false
            elseif idx(p[j]) > last
                last += 1
            end
        elseif type(p[j]) == :L
            idx(p[j]) < L && return false
        end
    end
    return true
end

function canonical(p::LinearSequence)
    # find first active left finger
    L, Lpos = (99,0), 0
    for (i,n) in pairs(p)
        if type(n) == :L && idx(n) < L
            L, Lpos = idx(n), i
        end
    end

    # if the near side is next in the sequence, we need to revert
    rev = isnearsidenext(p, p[Lpos])
    #@show L, Lpos, rev

    D = Dict{Int,Int}()
    j = 1

    #rebuild the sequence in canonical order
    map(eachindex(p)) do i
        n = p[rev ? Lpos - i + 1 : Lpos + i - 1]
        if n isa FrameNode
            n
        else
            if !haskey(D, idx(n))
                D[idx(n)] = j
                j += 1
            end
            CrossNode(type(n), D[idx(n)])
        end
    end |> LinearSequence
end

isadjacent(p::LinearSequence, i, j) = abs(i-j) ∈ (1,length(p) - 1)

function findframenode(f::FrameNode, p)
    i,u = 0,0
    for (j,n) in pairs(p)
        if type(f) == type(n) && idx(f)[1] == idx(n)[1]
            if idx(f)[2] == typemax(Int) && idx(n)[2] > u
                u = idx(n)[2]
                i = j
            elseif idx(n)[2] == idx(f)[2]
                i = j
            end
        end
    end
    isnothing(i) && throw(ArgumentError("Non existing argument"))
    return i
end

numcrossings(p::LinearSequence) = maximum(idx(n) for n in p if n isa CrossNode; init = 0)


#"""
#Determine if n1 is closer to the executer than n2 (wrt. n)
#"""
function isnearer(n1::FrameNode, n2::FrameNode, n::FrameNode)
    if type(n1) != type(n) && type(n2) != type(n)
        idx(n1) < idx(n2)
    elseif type(n1) == type(n) == type(n2)
        if (idx(n1) < idx(n)) == (idx(n2) < idx(n))
            idx(n1) > idx(n2)
        else
            idx(n1) < idx(n2)
        end 
    elseif type(n1) == type(n)
        idx(n1) < idx(n)
    else # type(n2) == type(n)
        idx(n2) > idx(n)
    end
end


function isfarsidenext(p::LinearSequence, i::Int)
    l, r = i, i
    lset, rset = Set{Int}(), Set{Int}()
    for k in 1:length(p) - 1
        n = p[i + k]
        if n isa CrossNode
            idx(n) ∈ rset ? delete!(rset, idx(n)) : push!(rset, idx(n))
        else
            r = i + k
            break
        end
    end
    for k in 1:length(p) - 1
        n = p[i - k]
        if n isa CrossNode
            idx(n) ∈ lset ? delete!(lset, idx(n)) : push!(lset, idx(n))
        else
            l = i - k
            break
        end
    end

    if mod(l-r, length(p)) == 0   # < 3 frame nodes"
        return type(p[i]) == :L
    end

    crossings = lset ∩ rset
    #@show lset rset l r p[l] p[r] getindex.((p,), lset) getindex.((p,), rset) crossings
    isnearer(p[l],p[r],p[i]) == iseven(length(crossings))
end

isfarsidenext(p::LinearSequence, n::FrameNode) = isfarsidenext(p, findframenode(n, p))

isnearsidenext(p::LinearSequence, n::Union{Int, FrameNode}) = !isfarsidenext(p, n)


Base.iterate(p::LinearSequence) = iterate(p.seq)
Base.iterate(p::LinearSequence, s) = iterate(p.seq, s)
Base.getindex(p::LinearSequence, i) = @inbounds p.seq[mod(i,eachindex(p))]
Base.setindex!(p::LinearSequence, v, i) = @inbounds p.seq[mod(i,eachindex(p))] = v
Base.getindex(p::LinearSequence, i::AbstractVector) = @inbounds p.seq[mod.(i,(eachindex(p),))]
Base.eachindex(p::LinearSequence) = eachindex(p.seq)
Base.pairs(p::LinearSequence) = pairs(p.seq)
Base.lastindex(p::LinearSequence) = lastindex(p.seq)
Base.firstindex(p::LinearSequence) = firstindex(p.seq)
Base.copy(p::LinearSequence) = LinearSequence(copy(p.seq))
Base.mod(i, p::LinearSequence) = mod(i, eachindex(p))

function Base.:(==)(p::LinearSequence, q::LinearSequence)
    (iscanonical(p) ? p.seq : canonical(p).seq) == (iscanonical(q) ? q.seq : canonical(q).seq)
end


function Base.show(io::IO, ::MIME"text/plain", p::LinearSequence)
    io = IOContext(io, :linseq => p)
    print(io, "seq\"")
    show(io, p)
    print(io,"\"")
end

function Base.show(io::IO, p::LinearSequence)
    io = IOContext(io, :linseq => p)
    for n in p[1:end-1]
        show(io, n)
        print(io,":")
    end
    show(io, p[end])
end
