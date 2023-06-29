"""
A `StringCalculus` describes an algorithm or procedure that
can be applied to a string. It is represented as list of transformations
(Passages). You can build a `StringCalculus` by using the
special notation `proc\"<seq>\"` where `<seq>` is a list of
Passages separated by `#`. Heart sequences can be:
* Used as functions on a `LinearSequence`, producing a new `LinearSequence`
* Multiplied to other `StringCalculus`s or `Passage`s (concatenating the instructions)
* Elevated to some power (repeating the same statements)
"""
struct StringCalculus 
    seq::Vector{Passage}
end

Base.length(c::StringCalculus) = length(c.seq)

Base.:(*)(s::StringCalculus, t::StringCalculus) = StringCalculus(vcat(s.seq,t.seq))

Base.:(*)(s::StringCalculus, t::Passage) = StringCalculus(vcat(s.seq,[t]))

Base.:(*)(s::Passage, t::StringCalculus) = StringCalculus(vcat([s],t.seq))

Base.:(*)(s::Passage, t::Passage) = StringCalculus([s,t])

Base.:(^)(s::Passage, k::Integer) = StringCalculus(fill(s,k))

Base.:(^)(s::StringCalculus, k::Integer) = StringCalculus(reduce(vcat, (s.seq for i=1:k)))

(s::StringCalculus)(p::LinearSequence) = reduce((x,h)->h(x), s.seq; init = p)

Base.show(io::IO, s::StringCalculus) = print(io, "calc\"", join(string.(s.seq), " # "), "\"")

Base.show(io::IO, ::MIME"text/latex", s::StringCalculus) = print(io, latex(s))

latex(s::StringCalculus) =  "\$" * join(latex.(s.seq), " \\# ") * "\$"

macro calc_str(s)
    StringCalculus(string2passage.(split(s,"#")))
end


struct StringProcedure
    initial::LinearSequence
    calculus::StringCalculus
end

Base.iterate(p::StringProcedure) = length(p.calculus) > 0 ? (p.initial, (1,p.initial)) : nothing  
function Base.iterate(p::StringProcedure, (i,s))
    i >= length(p) && return nothing
    nexts = p.calculus.seq[i](s)
    nexts, (i+1, nexts)
end

Base.length(p::StringProcedure) = length(p.calculus) + 1

function plot(p::StringProcedure)
    for (i,l) in enumerate(p)
        i > 1 && display(p.calculus.seq[i-1])
        display(plot(l))
    end
end