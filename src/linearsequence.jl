using PEG

struct SeqNode
    type::Symbol
    idx::Int
    function SeqNode(type, idx)
        idx ≥ 0 || throw(ArgumentError("Wrong index $idx"))
        type ∈ (:L, :R, :U, :O) || throw(ArgumentError("Wrong type $type"))
        #type ∉ (:L, :R) || 1 ≤ idx ≤ 5 || throw(ArgumentError("Wrong index $idx"))
        new(type, idx)
    end
end

@rule fnode = r"[LR]" & r"\d+" > (t,d) -> SeqNode(Symbol(t), parse(Int, d))
@rule xnode = "x" & r"\d+" & "(" & r"[0U]" & ")" > (_,d,_,t,_) -> SeqNode(t == "U" ? :U : :O, parse(Int, d))
@rule snode = fnode, xnode
@rule snodec = snode & ":" > (x,_) -> x
@rule linseq = snodec[*] & snode > (x,y) -> LinearSequence(push!(copy(x),y))

Base.:(<)(s::SeqNode, t::SeqNode) = s.idx < t.idx

struct LinearSequence
    seq::Vector{SeqNode}
end

Base.length(p::LinearSequence) = length(p.seq)

function gaussish_code(p::LinearSequence)
    map(p.seq) do n
        if n.type == :U 
            -n.idx
        else
            n.idx
        end
    end
end

function Base.string(n::SeqNode)
    if n.type ∈ (:L,:R)
        "$(n.type)$(n.idx)" 
    elseif n.type == :U
        "x$(n.idx)(U)"
    else
        "x$(n.idx)(0)"
    end
end

Base.show(io::IO, p::SeqNode) = print(io, "node\"", string(p), "\"")

function Base.show(io::IO, p::LinearSequence)
    print(io, "seq\"", join(string.(p.seq),":"), "\"")
end

function iscanonical(p::LinearSequence)
    # find first active left finger
    L, Lpos = 11, 0
    for (i,n) in pairs(p)
        if n.type == :L && n.idx < L
            L, Lpos = n.idx, i
        end
    end
    isnearsidenext(p, p[Lpos]) && return false
    last = 0
    for j in (eachindex(p) .+ (Lpos - 1))
        if p[j].type ∈ (:O, :U)
            if p[j].idx > last + 1 
                return false
            elseif p[j].idx > last
                last += 1
            end
        end
    end
    return true
end



function canonical(p::LinearSequence)
    # find first active left finger
    L, Lpos = 11, 0
    for (i,n) in pairs(p)
        if n.type == :L && n.idx < L
            L, Lpos = n.idx, i
        end
    end

    # if the near side is next in the sequence, we need to revert
    rev = isnearsidenext(p, p[Lpos])
    #@show L, Lpos, rev

    D = Dict{Int,Int}()
    idx = 1

    #rebuild the sequence in canonical order
    map(eachindex(p)) do i
        n = p[rev ? Lpos - i + 1 : Lpos + i - 1]
        if n.type ∈ (:L, :R)
            n
        else
            if !haskey(D, n.idx)
                D[n.idx] = idx
                idx += 1
            end
            SeqNode(n.type, D[n.idx])
        end
    end |> LinearSequence
end

isframenode(n::SeqNode) = n.type ∈ (:L, :R)

findframenode(f,p) = findfirst(==(f), p)

numcrossings(p::LinearSequence) = maximum(n.idx for n in p if n.type ∈ (:U, :O); init = 0)

function isfarsidenext(p::LinearSequence, i::Int)
    l, r = i, i
    lset, rset = Set{Int}(), Set{Int}()
    for k in 1:length(p)-1
        n = p[i+k]
        if isframenode(n)
            r = i+k
            break
        else
            push!(rset, n.idx) 
        end
    end
    for k in 1:length(p)-1
        n = p[i-k]
        if isframenode(n)
            l = i-k
            break
        else
            push!(lset, n.idx)
        end
    end


    @assert mod(l-i, length(p)) != 0 && mod(r-i, length(p)) != 0  "only 3 or more frame nodes!"

    crossings = lset ∩ rset
    #@show crossings
    (p[l].idx < p[r].idx) != isodd(length(crossings))
end

isfarsidenext(p::LinearSequence, n::SeqNode) = isfarsidenext(p, findframenode(n, p))

isnearsidenext(p::LinearSequence, n::Union{Int, SeqNode}) = !isfarsidenext(p, n)

macro seq_str(s)
    # allow some fuzziness to be able to easily copy-paste 
    # from Storer's OCR'd book :)
    s = replace(s, "\n"=>"", " " => "", "{" => "(", "l" => "1", ";" => ":", 
        "O" => "0", "S" => "5", "X" => "x", "B" => "8", "G" => "6", "?" => "7")
    parse_whole(linseq, s)
end

macro node_str(s)
    parse_whole(snode, s)
end

Base.iterate(p::LinearSequence) = iterate(p.seq)
Base.iterate(p::LinearSequence, s) = iterate(p.seq, s)
Base.getindex(p::LinearSequence, i) = @inbounds p.seq[mod(i,eachindex(p))]
Base.getindex(p::LinearSequence, i::AbstractVector) = @inbounds p.seq[mod.(i,eachindex(p))]
Base.eachindex(p::LinearSequence) = eachindex(p.seq)
Base.pairs(p::LinearSequence) = pairs(p.seq)
Base.lastindex(p::LinearSequence) = lastindex(p.seq)
Base.firstindex(p::LinearSequence) = firstindex(p.seq)