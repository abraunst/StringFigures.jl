using PEG

####### Nodes in a linear sequence

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

macro node_str(s)
    try 
        parse_whole(snode, s)
    catch e
        println(e.msg)
    end
end


######## Linear Sequence

struct LinearSequence
    seq::Vector{SeqNode}
end

@rule snodec = snode & ":" > (x,_) -> x
@rule O1 = r"O1"p > (_...,)->LinearSequence([node"L1",node"L5",node"R5",node"R1"])
@rule OA = r"OA"p > (_...,)->LinearSequence([node"L1",node"x1(0)",node"R2",node"x2(0)",node"L5",node"R5",node"x2(U)",node"L2",node"x1(U)",node"R1"])
@rule linseq = O1,OA,(snodec[*] & snode > (x,y) -> LinearSequence(push!(copy(x),y)))

macro seq_str(s)
    # allow some fuzziness to be able to easily copy-paste 
    # from Storer's OCR'd book :)
    s = replace(s, "\n"=>"", " " => "", "{" => "(", "l" => "1", ";" => ":", 
        "O" => "0", "S" => "5", "X" => "x", "B" => "8", "G" => "6", "?" => "7")
    try 
        parse_whole(linseq, s)
    catch e
        println(e.msg)
    end
end

Base.:(<)(s::SeqNode, t::SeqNode) = s.idx < t.idx


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
    p[begin].type == :L || return false
    L = p[begin].idx
    isnearsidenext(p, p[begin]) && return false
    last = 0
    for j in 2:lastindex(p)
        if p[j].type ∈ (:O, :U)
            if p[j].idx > last + 1 
                return false
            elseif p[j].idx > last
                last += 1
            end
        elseif p[j].type == :L
            p[j].idx < L && return false
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


Base.iterate(p::LinearSequence) = iterate(p.seq)
Base.iterate(p::LinearSequence, s) = iterate(p.seq, s)
Base.getindex(p::LinearSequence, i) = @inbounds p.seq[mod(i,eachindex(p))]
Base.getindex(p::LinearSequence, i::AbstractVector) = @inbounds p.seq[mod.(i,eachindex(p))]
Base.eachindex(p::LinearSequence) = eachindex(p.seq)
Base.pairs(p::LinearSequence) = pairs(p.seq)
Base.lastindex(p::LinearSequence) = lastindex(p.seq)
Base.firstindex(p::LinearSequence) = firstindex(p.seq)