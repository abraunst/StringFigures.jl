abstract type Functor end

struct ExtendFunctor <: Functor end

(f::ExtendFunctor)(p::LinearSequence) = simplify(p)

struct PickFunctor <: Functor
    fun::SeqNode
    arg::SeqNode
    near::Bool
    over::Bool
end

(f::PickFunctor)(p::LinearSequence) = pick(p, f.over, f.fun, f.arg, f.near)

struct ReleaseFunctor <: Functor
    arg::SeqNode
end

(f::ReleaseFunctor)(p::LinearSequence) = release(p, f.arg)


macro f_str(s)
    m = match(r"\|", s)
    !isnothing(m) && return ExtendFunctor()
    m = match(r"□([LR]\d+)", s) 
    !isnothing(m) && return ReleaseFunctor(SeqNode(m[1]))
    m = match(r"([LR]\d+)([ou])\(([LR]\d+)([nf])\)", s) 
    !isnothing(m) && return PickFunctor(SeqNode(m[1]),SeqNode(m[3]), m[4] == "n", m[2] == "o")
    throw(ArgumentError("Could not parse $s"))
end
