using PEG

####### Nodes in a linear sequence

abstract type SeqNode end

struct CrossNode <: SeqNode
    nodetype::Symbol
    index::Int
    function CrossNode(type, idx)
        idx ≥ 0 || throw(ArgumentError("Wrong index $idx"))
        type ∈ (:U, :O) || throw(ArgumentError("Wrong type $type"))
        #type ∉ (:L, :R) || 1 ≤ idx ≤ 5 || throw(ArgumentError("Wrong index $idx"))
        new(type, idx)
    end
end

struct FrameNode <: SeqNode
    nodetype::Symbol
    index::Int
    loop::Int
    function FrameNode(type, idx, loop = 0)
        idx ≥ 0 || throw(ArgumentError("Wrong index $idx"))
        type ∈ (:L, :R) || throw(ArgumentError("Wrong type $type"))
        new(type, idx, loop)
    end
end

SeqNode(type::Symbol, idx) = (type ∈ (:O, :U) ? CrossNode : FrameNode)(type, idx)

@rule int =  r"\d+"[1] > x -> parse(Int, x)
@rule fnode = r"[LR]" & int & ("." & int)[0:1] > (t,d,l) -> FrameNode(Symbol(t), d, isempty(l) ? 0 : only(l)[2])
@rule xnode = "x" & int & "(" & r"[0U]" & ")" > (_,d,_,t,_) -> CrossNode(t == "U" ? :U : :O, d)
@rule snode = fnode, xnode

idx(n::SeqNode) = n.index
idx(n::FrameNode) = (n.index, n.loop)
loop(n::FrameNode) = n.loop
type(n::SeqNode) = n.nodetype

function Base.string(n::FrameNode)
    i,l = idx(n)
    l == 0 ? "$(type(n))$i" : "$(type(n))$i.$l"
end

Base.string(n::CrossNode) =  "x$(idx(n))($(type(n) == :U ? 'U' : '0'))"

Base.:(<)(s::FrameNode, t::FrameNode) = idx(s) < idx(t)

macro node_str(s)
    try 
        parse_whole(snode, s)
    catch e
        println(e.msg)
    end
end

Base.show(io::IO, p::SeqNode) = print(io, "node\"", string(p), "\"")
