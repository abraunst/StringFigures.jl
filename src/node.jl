using PEG

####### Nodes in a linear sequence

_UPPER = typemax(Int)

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
    function FrameNode(type, idx::Int, loop = 0)
        idx ≥ 0 || throw(ArgumentError("Wrong index $idx"))
        type ∈ (:L, :R) || throw(ArgumentError("Wrong type $type"))
        new(type, idx, loop)
    end
end

FrameNode(type, idx::Tuple{Int, Int}) = FrameNode(type, idx...)

SeqNode(type::Symbol, idx) = (type ∈ (:O, :U) ? CrossNode : FrameNode)(type, idx)

@rule int =  r"\d+"[1] > x -> parse(Int, x)
@rule fnode = r"[LR]" & int & ("." & int)[0:1] > (t,d,l) -> FrameNode(Symbol(t), d, isempty(l) ? 0 : only(l)[2])
@rule xnode = "x" & int & "(" & r"[0U]" & ")" > (_,d,_,t,_) -> CrossNode(t == "U" ? :U : :O, d)
@rule snode = fnode, xnode


inverse(n::CrossNode) = CrossNode(type(n) == :O ? :U : :O, n.index)
idx(n::SeqNode) = n.index
type(n::SeqNode) = n.nodetype
idx(n::FrameNode) = (n.index, n.loop)
functor(n::FrameNode) = (n.nodetype, n.index)
functor(n::CrossNode) = nothing
loop(n::FrameNode) = n.loop

Base.:(<)(s::FrameNode, t::FrameNode) = idx(s) < idx(t)

function parsepeg(peg, s)
    try 
        parse_whole(peg, s)
    catch e
        if e isa Meta.ParseError
            println(e.msg)
        else
            rethrow(e)
        end
    end
end

macro node_str(s)
    parsepeg(snode, s)
end

function Base.show(io::IO, n::CrossNode)
    print(io, "x$(idx(n))($(type(n) == :U ? 'U' : '0'))")
end

function Base.show(io::IO, ::MIME"text/plain", p::CrossNode)
    print(io, "node\"")
    show(io, p)
    print(io, "\"")
end

function Base.show(io::IO, n::FrameNode)
    (i,d),t = idx(n), type(n)
    print(io, d == 0 ? "$t$i" : "$t$i.$d")
end

function Base.show(io::IO, ::MIME"text/plain", n::FrameNode)
    print(io, "node\"")
    show(io, n)
    print(io,"\"")
end