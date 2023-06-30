abstract type Passage end

struct ExtendPassage <: Passage end

Base.string(f::ExtendPassage) = "|"
latex(f::ExtendPassage) = "|"

(f::ExtendPassage)(p::LinearSequence) = simplify(p)

struct PickPassage <: Passage
    fun::SeqNode
    arg::SeqNode
    near::Bool
    over::Bool
    above::Bool
end

Base.string(f::PickPassage) = "$(string(f.fun))$(f.over ? "o" : "u")$(f.above ? "a" : "")($(string(f.arg))$(f.near ? "n" : "f"))"
function latex(f::PickPassage)
    arrow = "\\$(f.fun.type == f.arg.type ? "l" : "L")ong$(f.fun.idx <= f.arg.idx ? "right" : "left")arrow"
    "\\$(f.over ? "over" : "under")set{$arrow}{$(string(f.fun))}$(f.above ? "\\downarrow" : "")\\left($(string(f.arg))$(f.near ? "n" : "f")\\right)"
end
(f::PickPassage)(p::LinearSequence) = pick(p, f.over, f.fun, f.arg, f.near, f.above)

struct ReleasePassage <: Passage
    arg::SeqNode
end

Base.string(f::ReleasePassage) = "D$(string(f.arg))"
latex(f::ReleasePassage) = "\\square $(string(f.arg))"

(f::ReleasePassage)(p::LinearSequence) = release(p, f.arg)

struct TwistPassage <: Passage
    arg::SeqNode
    away::Bool
end

Base.string(f::TwistPassage) = f.away ? ">$(string(f.arg))" : "<$(string(f.arg))"
latex(f::TwistPassage) = string(f)

(f::TwistPassage)(p::LinearSequence) = twist(p, f.arg, f.away)

Base.show(io::IO, ::MIME"text/latex", f::Passage) = print(io, "\$", latex(f), "\$")

function string2passage(s)
    m = match(r"\|", s)
    !isnothing(m) && return ExtendPassage()
    m = match(r"([\<\>])([LR]\d+)",s)
    !isnothing(m) && return TwistPassage(SeqNode(m[2]), m[1] == ">")
    m = match(r"D([LR]\d+)", s) 
    !isnothing(m) && return ReleasePassage(SeqNode(m[1]))
#    m = match(r"([LR]\d+)([ou])\(([LR]\d+)([nf])\)", s) 
#    !isnothing(m) && return PickPassage(SeqNode(m[1]),SeqNode(m[3]), m[4] == "n", m[2] == "o")
    m = match(r"([LR]\d+)([ou])(a?)\(([LR]\d+)([nf])\)", s) 
    !isnothing(m) && return PickPassage(SeqNode(m[1]),SeqNode(m[4]), m[5] == "n", m[2] == "o", m[3] == "a")
    throw(ArgumentError("Could not parse $s"))
end

