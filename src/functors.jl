abstract type Functor end

struct ExtendFunctor <: Functor end

Base.string(f::ExtendFunctor) = "|"
latex(f::ExtendFunctor) = "|"

(f::ExtendFunctor)(p::LinearSequence) = simplify(p)

struct PickFunctor <: Functor
    fun::SeqNode
    arg::SeqNode
    near::Bool
    over::Bool
    above::Bool
end

Base.string(f::PickFunctor) = "$(string(f.fun))$(f.over ? "o" : "u")$(f.above ? "a" : "")($(string(f.arg))$(f.near ? "n" : "f"))"
function latex(f::PickFunctor)
    arrow = "\\$(f.fun.type == f.arg.type ? "l" : "L")ong$(f.fun.idx <= f.arg.idx ? "right" : "left")arrow"
    "\\$(f.over ? "over" : "under")set{$arrow}{$(string(f.fun))}$(f.above ? "\\downarrow" : "")\\left($(string(f.arg))$(f.near ? "n" : "f")\\right)"
end
(f::PickFunctor)(p::LinearSequence) = pick(p, f.over, f.fun, f.arg, f.near, f.above)

struct ReleaseFunctor <: Functor
    arg::SeqNode
end

Base.string(f::ReleaseFunctor) = "D$(string(f.arg))"
latex(f::ReleaseFunctor) = "\\square $(string(f.arg))"

(f::ReleaseFunctor)(p::LinearSequence) = release(p, f.arg)

struct TwistFunctor <: Functor
    arg::SeqNode
    away::Bool
end

Base.string(f::TwistFunctor) = f.away ? ">$(string(f.arg))" : "<$(string(f.arg))"
latex(f::TwistFunctor) = string(f)

(f::TwistFunctor)(p::LinearSequence) = twist(p, f.arg, f.away)

Base.show(io::IO, ::MIME"text/latex", f::Functor) = print(io, "\$", latex(f), "\$")

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

(s::HeartSequence)(p::LinearSequence) = reduce((x,h)->h(x), s.seq; init = p)

Base.show(io::IO, s::HeartSequence) = print(io, "heart\"", join(string.(s.seq), " # "), "\"")

Base.show(io::IO, ::MIME"text/latex", s::HeartSequence) = print(io, "\$", join(latex.(s.seq), " \\# "), "\$")


function string2functor(s)
    m = match(r"\|", s)
    !isnothing(m) && return ExtendFunctor()
    m = match(r"([\<\>])([LR]\d+)",s)
    !isnothing(m) && return TwistFunctor(SeqNode(m[2]), m[1] == ">")
    m = match(r"D([LR]\d+)", s) 
    !isnothing(m) && return ReleaseFunctor(SeqNode(m[1]))
#    m = match(r"([LR]\d+)([ou])\(([LR]\d+)([nf])\)", s) 
#    !isnothing(m) && return PickFunctor(SeqNode(m[1]),SeqNode(m[3]), m[4] == "n", m[2] == "o")
    m = match(r"([LR]\d+)([ou])(a?)\(([LR]\d+)([nf])\)", s) 
    !isnothing(m) && return PickFunctor(SeqNode(m[1]),SeqNode(m[4]), m[5] == "n", m[2] == "o", m[3] == "a")
    throw(ArgumentError("Could not parse $s"))
end

macro heart_str(s)
    HeartSequence(string2functor.(split(s,"#")))
end


