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

See also: [`StringProcedure`](@ref)
"""
struct StringCalculus 
    seq::Vector{Passage}
end


function framenode(f::FrameRef, p::LinearSequence)
    loop = f.loop == :l || f.loop == Symbol("") ? 0 :
        f.loop == :m ? 1 :
        f.loop == :u ? maximum(n->(n.nodetype == f.nodetype && n.index == f.index ? n.loop : -1), p; init=-1) :
        f.loop == :m1 ? 1 :
        f.loop == :m2 ? 2 :
        f.loop == :m3 ? 3 :
        f.loop == :m4 ? 4 :
        f.loop == :m5 ? 5 :
        f.loop == :m6 ? 6 :
        f.loop == :m7 ? 7 :
        f.loop == :m8 ? 8 :
        f.loop == :m9 ? 9 : -1
    @assert loop ≥ 0
    FrameNode(f.nodetype, f.index, loop)
end


@rule passages = (passage & r""p & r"#?"p) > (x,_,_) -> x
@rule calculus = r""p & passages[*]  > (_,x) -> StringCalculus(x)

Base.length(c::StringCalculus) = length(c.seq)

Base.:(*)(s::StringCalculus, t::StringCalculus) = StringCalculus(vcat(s.seq,t.seq))

Base.:(*)(s::StringCalculus, t::Passage) = StringCalculus(vcat(s.seq,[t]))

Base.:(*)(s::Passage, t::StringCalculus) = StringCalculus(vcat([s],t.seq))

Base.:(*)(s::Passage, t::Passage) = StringCalculus([s,t])

Base.:(^)(s::Passage, k::Integer) = StringCalculus(fill(s,k))

Base.:(^)(s::StringCalculus, k::Integer) = StringCalculus(reduce(vcat, (s.seq for i=1:k)))

(s::StringCalculus)(p::LinearSequence) = reduce((x,h)->h(x), s.seq; init = p)

Base.show(io::IO, ::MIME"text/plain", s::StringCalculus) = print(io, "calc\"", join(string.(s.seq), " # "), "\"")

function Base.show(io::IO, s::StringCalculus)
    t = map(eachindex(s.seq)) do i
        o = string(s.seq[i])
        s.seq[i] isa ExtendPassage && return o
        i+1 ∈ eachindex(s.seq) && s.seq[i+1] isa ExtendPassage && return o
        return o * "#"
    end |> join
    print(io, t)
end

function Base.show(io::IO, m::MIME"text/latex", s::StringCalculus) 
    idx = get(io, :passidx, -1)::Int
    inmath = get(io, :inmath, false)::Bool
    if !inmath 
        print(io, "\$")
        io = IOContext(io, :inmath => true)
    end
    for i in eachindex(s.seq)
        print(io, "{")
        print(io, i == idx ? "{\\color{blue}{" : "{{")
        show(io, m, s.seq[i])
        print(io, "}}}")
        if s.seq[i] isa ExtendPassage
            print(io, " ")
        elseif !(i+1 ∈ eachindex(s.seq) && s.seq[i+1] isa ExtendPassage)
            print(io, "\\# ")
        end 
    end
    inmath || print(io, " \$")
end

"""
`calc"xxx"` produces a [`Calculus`](@ref) from "xxx"

```jldoctest
julia> calc"DL1#DR1"
calc"DL1 # DR1"
```
"""
macro calc_str(s)
    parsepeg(calculus, s)
end


"""
A `StringProcedure``consists in an initial `LinearSequence` plus a 
`StringCalculus` to be applied to it. It represents the full "movie" of
the figure construction. It can be
* indexed and iterated to access each intermediate step
* `plot`ed to show all steps

See also [`proc""`](@ref)
"""
struct StringProcedure
    initial::LinearSequence
    calculus::StringCalculus
end

@rule parenseq = "(" & linseq & ")" > (_,s,_)->s 

@rule procedure = ((parenseq,opening) & r"::"p & calculus) > (s,_,c) -> StringProcedure(s,c)

"""
`proc"xxx"` creates a [`StringProcedure`](@ref) from string "xxx"
```jldoctest
julia> p = proc"OA::D1"
proc"OA::D1#"

julia> last(p)
seq"L2:x1(U):R5:L5:x1(0):R2:x2(0):x2(U)"
```
"""
macro proc_str(s)
    parsepeg(procedure, s)
end

(::Colon)(s::LinearSequence, c::StringCalculus) = StringProcedure(s, c)
(::Colon)(s::LinearSequence, c::AbstractString) = StringProcedure(s, parsepeg(calculus, c))


function initialstring(seq::LinearSequence)
    for (name, s) in pairs(Openings)
        if seq == s
            return name
        end
    end
    return "($(seq))"
end

function Base.show(io::IO, m::MIME"text/latex", p::StringProcedure)
    idx = get(io, :passidx, -1)::Int
    print(io, "\$")
    io = IOContext(io, :inmath => true)
    print(io, idx == 0 ? "{\\color{blue}{" : "{{")
    print(io, initialstring(p.initial))
    print(io, "}}~::~")
    show(io, m, p.calculus)
    print(io, "\$")
end

function Base.show(io::IO, ::MIME"text/plain", p::StringProcedure)
    print(io, "proc\"", initialstring(p.initial), "::", p.calculus, "\"")
end


### Indexed procedure, used to plot sequence of figures


struct ProcedurePlot{K}
    p::StringProcedure
    kwd::K
end

struct IndexedProcedure
    p::StringProcedure
    idx::Int
end

function Base.show(io::IO, m::MIME"text/latex", p::IndexedProcedure)
    show(IOContext(io, :passidx => p.idx), m, p.p)
end


Base.iterate(p::StringProcedure) = (p.initial, (1,p.initial)) 
function Base.iterate(p::StringProcedure, (i,s))
    i >= length(p) && return nothing
    nexts = p.calculus.seq[i](s)
    nexts, (i+1, nexts)
end

Base.length(p::StringProcedure) = length(p.calculus) + 1

plot(p::StringProcedure; kwd...) = ProcedurePlot(p, kwd)

function Base.display(plt::ProcedurePlot)
    p, kwd = plt.p, plt.kwd
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