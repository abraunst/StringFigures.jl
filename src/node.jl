####### Nodes in a linear sequence

abstract type SeqNode end

"""
A `CrossNode` represents a crossing in a knot diagram, and is parametrized by `index::Int` and `nodetype ∈ (:U,:O)` 
"""
struct CrossNode <: SeqNode
    nodetype::Symbol
    index::Int
    function CrossNode(type, idx)
        idx ≥ 0 || throw(ArgumentError("Wrong index $idx"))
        type ∈ (:U, :O) || throw(ArgumentError("Wrong type $type"))
        new(type, idx)
    end
end

abstract type AbstractFrameNode <: SeqNode end

"""
A `FrameNode` represents both:
  * A loop on a finger or other body part that is holding the string.
  * A "puncture" of the plane that the string cannot freely cross.

It is parametrized by `nodetype ∈ (:L, :R)`, `index::Int`, `loop::Int`
"""
struct FrameNode <: AbstractFrameNode
    nodetype::Symbol
    index::Int
    loop::Int
    function FrameNode(type, idx::Int, loop = 0)
        idx ≥ 0 || throw(ArgumentError("Wrong index $idx"))
        #type ∈ (:L, :R, :La, :Lb, :Ra, :Rb) || throw(ArgumentError("Wrong type $type"))
        new(type, idx, loop)
    end
end

FrameNode(type, idx::Tuple{Int, Int}) = FrameNode(type, idx...)

iscrossnode(n::SeqNode) = n isa CrossNode
isframenode(n::SeqNode) = n isa FrameNode

SeqNode(type::Symbol, idx) = (type ∈ (:O, :U) ? CrossNode : FrameNode)(type, idx)

@rule int =  r"\d+" |> x -> parse(Int, x)
@rule fnode = r"[LR]" & int & ("." & int)[0:1] > (t,d,l) -> FrameNode(Symbol(t), d, isempty(l) ? 0 : only(l)[2])
@rule xnode = "x" & int & "(" & r"[0U]" & ")" > (_,d,_,t,_) -> CrossNode(t == "U" ? :U : :O, d)
@rule snode = fnode, xnode

inverse(n::CrossNode) = CrossNode(type(n) == :O ? :U : :O, n.index)
idx(n::CrossNode) = n.index
type(n::SeqNode) = n.nodetype
idx(n::AbstractFrameNode) = (n.index, n.loop)
functor(n::FrameNode) = (n.nodetype, n.index)
loop(n::FrameNode) = n.loop

Base.:(<)(s::FrameNode, t::FrameNode) = idx(s) < idx(t)


"""
node"xxx" generates either a [`FrameNode`](@ref) or a [`CrossNode`](@ref).

```jldoctest
julia> node"L1"
node"L1"

julia> show(node"L1")
L1

julia> node"x100(0)"
node"x100(0)"

julia> show(node"x100(U)")
x100(U)
```
"""
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