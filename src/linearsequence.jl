using PEG

######## Linear Sequence

struct LinearSequence
    seq::Vector{SeqNode}
end

@rule snodec = snode & ":" > (x,_) -> x
@rule linseq = (snodec[*] & snode) > (x,y) -> LinearSequence(push!(copy(x),y))

macro seq_str(s)
    parsepeg(linseq, s)
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

function Base.show(io::IO, p::LinearSequence)
    print(io, "seq\"", join(string.(p.seq),":"), "\"")
end

### equivalent to canonical(p).seq == p.seq but faster and non-allocating
function iscanonical(p::LinearSequence)
    type(p[begin]) == :L || return false
    L = idx(p[begin])
    isnearsidenext(p, p[begin]) && return false
    last = 0
    for j in 2:lastindex(p)
        if type(p[j]) ∈ (:O, :U)
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
        if isframenode(n)
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

isadjacent(p::LinearSequence, i, j) = abs(i-j) == 1 || abs(i-j) == length(p) - 1

isframenode(n::SeqNode) = n isa FrameNode

findframenode(f::FrameNode,p) = findfirst(==(f), p)

numcrossings(p::LinearSequence) = maximum(idx(n) for n in p if !isframenode(n); init = 0)

function isfarsidenext(p::LinearSequence, i::Int)
    l, r = i, i
    lset, rset = Set{Int}(), Set{Int}()
    for k in 1:length(p)-1
        n = p[i+k]
        if isframenode(n) && type(n) != type(p[i])
            r = i+k
            break
        elseif !isframenode(n)
            push!(rset, idx(n)) 
        end
    end
    for k in 1:length(p)-1
        n = p[i-k]
        if isframenode(n) && type(n) != type(p[i])
            l = i-k
            break
        elseif !isframenode(n)
            push!(lset, idx(n))
        end
    end


    @assert mod(l-i, length(p)) != 0 && mod(r-i, length(p)) != 0  "only 3 or more frame nodes!"

    crossings = lset ∩ rset
    #@show crossings
    (idx(p[l]) < idx(p[r])) != isodd(length(crossings))
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
