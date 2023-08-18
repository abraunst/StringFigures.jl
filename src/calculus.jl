using PEG

"""
A `StringCalculus` describes an algorithm or procedure that
can be applied to a string. It is represented as list of transformations
(Passages). You can build a `StringCalculus` by using the
special notation `calc\"<seq>\"` where `<seq>` is a list of
Passages, possibly separated by `#`. A `StringCalculus` can be:
* Used as functions on a `LinearSequence`, producing a new `LinearSequence`
* Multiplied to other `StringCalculus`s or `Passage`s (concatenating the instructions)
* Elevated to some power (repeating the same statements)
"""
struct StringCalculus 
    seq::Vector{Passage}
end

@rule passages = (passage & r"#?"p) > (x,_) -> x
@rule calculus = r""p & passages[*]  > (_,x) -> StringCalculus(x)

Base.length(c::StringCalculus) = length(c.seq)

Base.:(*)(s::StringCalculus, t::StringCalculus) = StringCalculus(vcat(s.seq,t.seq))

Base.:(*)(s::StringCalculus, t::Passage) = StringCalculus(vcat(s.seq,[t]))

Base.:(*)(s::Passage, t::StringCalculus) = StringCalculus(vcat([s],t.seq))

Base.:(*)(s::Passage, t::Passage) = StringCalculus([s,t])

Base.:(^)(s::Passage, k::Integer) = StringCalculus(fill(s,k))

Base.:(^)(s::StringCalculus, k::Integer) = StringCalculus(reduce(vcat, (s.seq for i=1:k)))

(s::StringCalculus)(p::LinearSequence) = reduce((x,h)->h(x), s.seq; init = p)

Base.show(io::IO, s::StringCalculus) = print(io, "calc\"", join(string.(s.seq), " # "), "\"")

Base.show(io::IO, ::MIME"text/latex", s::StringCalculus) = print(io, "\$", latex(s), "\$")

function Base.string(s::StringCalculus)
    map(eachindex(s.seq)) do i
        o = string(s.seq[i])
        s.seq[i] isa ExtendPassage && return o
        i+1 ∈ eachindex(s.seq) && s.seq[i+1] isa ExtendPassage && return o
        return o * "#"
    end |> join
end

function latex(s::StringCalculus; idx = 0)
    l = map(eachindex(s.seq)) do i
        o = (i == idx ? "\\blue{" : "{")*latex(s.seq[i])*"}"
        s.seq[i] isa ExtendPassage && return o * " "
        i+1 ∈ eachindex(s.seq) && s.seq[i+1] isa ExtendPassage && return o
        o * "\\# "
    end
    "$(join(l))"
end

macro calc_str(s)
    parsepeg(calculus, s)
end


"""
A `StringProcedure``consists n an initial `LinearSequence` plus a 
`StringCalculus` to be applied to it. It represents the full "movie" of
the figure construction. It can be
* indexed and iterated`to access each intermediate step
* `plot`ed to show all steps
"""
struct StringProcedure
    initial::LinearSequence
    calculus::StringCalculus
end
_O1 = seq"L1:L5:R5:R1"
_OA = seq"L1:x1(0):R2:x2(0):L5:R5:x2(U):L2:x1(U):R1"
@rule O1 = r"O1"p[1] > _ -> _O1
@rule OA = r"OA"p[1] > _ -> _OA
@rule procedure = ((linseq,O1,OA) & r"::"p & calculus) > (s,_,c) -> StringProcedure(s,c)

macro proc_str(s)
    parsepeg(procedure, s)
end

function latex(p::StringProcedure; idx=-1)
    ini =  p.initial == _O1 ? "O1" :
            p.initial == _OA ? "OA" :
            string(p.initial)
    "{$(idx == 0 ? "\\blue{" : "{ ")$ini}}~::~$(latex(p.calculus; idx))"
end

struct IndexedProcedure
    p::StringProcedure
    idx::Int
end

function Base.show(io::IO, ::MIME"text/latex", p::IndexedProcedure)
    print(io, "\$", latex(p.p; idx=p.idx), "\$")
end

function Base.show(io::IO, ::MIME"text/latex", p::StringProcedure)
    print(io, "\$", latex(p), "\$")
end

Base.iterate(p::StringProcedure) = (p.initial, (1,p.initial)) 
function Base.iterate(p::StringProcedure, (i,s))
    i >= length(p) && return nothing
    nexts = p.calculus.seq[i](s)
    nexts, (i+1, nexts)
end

Base.length(p::StringProcedure) = length(p.calculus) + 1

function plot(p::StringProcedure; kwd...)
    for (i,l) in enumerate(p)
        display(IndexedProcedure(p, i-1))
        display(plot(l; kwd...))
    end
end

Base.getindex(p::StringProcedure, i) = StringCalculus(p.calculus.seq[1:i-1])(p.initial)

Base.last(p::StringProcedure) = p.calculus(p.initial)

Base.lastindex(p::StringProcedure) = length(p)

Base.firstindex(p::StringProcedure) = 1

Base.keys(p::StringProcedure) = firstindex(p):lastindex(p)