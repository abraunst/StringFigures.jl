using PEG

######## Linear Sequence

struct LinearSequence
    seq::Vector{SeqNode}
end

@rule snodec = snode & ":" > (x,_) -> x
@rule opening = "O" & r"[0-9A-Z]*"p > (_, o) -> Openings[o] 
@rule linseq = (snodec[*] & snode) > (x,y) -> LinearSequence(push!(copy(x),y))

macro seq_str(s)
    parsepeg(linseq, s)
end

macro open_str(s)
    parsepeg(opening, s)
end

macro storer_str(s)
    # allow some fuzziness to be able to easily copy-paste 
    # from Storer's OCR'd book :)
    parsepeg(linseq, replace(s, "\n"=>"", " " => "", "{" => "(",
        "l" => "1", ";" => ":", "O" => "0", "S" => "5", "X" => "x",
        "B" => "8", "G" => "6", "?" => "7"))
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


"""
Determine if n1 is closer to the executer than n2 (wrt. n)
"""
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

    @assert mod(l-i, length(p)) != 0 && mod(r-i, length(p)) != 0  "only 3 or more frame nodes!"

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

const Openings = Dict(
    "1" => seq"L1:L5:R5:R1",
    "A" => seq"L1:x1(0):R2:x2(0):L5:R5:x2(U):L2:x1(U):R1"
)