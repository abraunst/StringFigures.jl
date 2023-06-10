abstract type Functor end

struct ExtendFunctor <: Functor end

Base.string(f::ExtendFunctor) = "|"

(f::ExtendFunctor)(p::LinearSequence) = simplify(p)

struct PickFunctor <: Functor
    fun::SeqNode
    arg::SeqNode
    near::Bool
    over::Bool
end

Base.string(f::PickFunctor) = "$(string(f.fun))$(f.over ? "o" : "u")($(string(f.arg))$(f.near ? "n" : "f"))"

(f::PickFunctor)(p::LinearSequence) = pick(p, f.over, f.fun, f.arg, f.near)

struct ReleaseFunctor <: Functor
    arg::SeqNode
end

Base.string(f::ReleaseFunctor) = "□$(string(f.arg))"

(f::ReleaseFunctor)(p::LinearSequence) = release(p, f.arg)

"""
A Heart sequence describes an algorithm or procedure that
can be applied to a string. It is represented as list of transformations
(Functors). You can build a `HeartSequence` by using the
special notation `heart\"<seq>\"` where `<seq>` is a list of
Functors separated by `#`. Heart sequences can be:
* Used as functions on a `LinearSequence`, producing a new `LinearSequence`
* Multiplied to other `HeartSequence`s or `Functor`s (concatenating the instructions)
* Elevated to some power (repeating the same statements)
"""
struct HeartSequence 
    seq::Vector{Functor}
end

Base.:(*)(s::HeartSequence, t::HeartSequence) = HeartSequence(vcat(s.seq,t.seq))

Base.:(*)(s::HeartSequence, t::Functor) = HeartSequence(vcat(s.seq,[t]))

Base.:(*)(s::Functor, t::HeartSequence) = HeartSequence(vcat([s],t.seq))

Base.:(*)(s::Functor, t::Functor) = HeartSequence([s,t])

Base.:(^)(s::Functor, k::Integer) = HeartSequence(fill(s,k))

Base.:(^)(s::HeartSequence, k::Integer) = HeartSequence(reduce(vcat, (s.seq for i=1:k)))

(s::HeartSequence)(p::LinearSequence) = ∘(s.seq...)(p)

Base.show(io::IO, s::HeartSequence) = print(io, "heart\"", join(string.(s.seq), " # "), "\"")



function string2functor(s)
    m = match(r"\|", s)
    !isnothing(m) && return ExtendFunctor()
    m = match(r"□([LR]\d+)", s) 
    !isnothing(m) && return ReleaseFunctor(SeqNode(m[1]))
    m = match(r"([LR]\d+)([ou])\(([LR]\d+)([nf])\)", s) 
    !isnothing(m) && return PickFunctor(SeqNode(m[1]),SeqNode(m[3]), m[4] == "n", m[2] == "o")
    throw(ArgumentError("Could not parse $s"))
end

macro heart_str(s)
    HeartSequence(string2functor.(split(s,"#")))
end