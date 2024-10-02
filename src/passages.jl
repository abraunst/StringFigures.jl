using PEG


"""
The `Passage` type represents one passage or move in a string figure construction
"""
abstract type Passage end


struct FrameRef
    nodetype::Symbol
    index::Int
    loop::Symbol
end

type(f::FrameRef) = f.nodetype



const refindices = Dict{Symbol, Int}(:l => 0, :m => 1, :u => 1000, :m1 => 1, :m2 => 2, :m3 => 3, 
:m4 => 4, :m5 => 5, :m6 => 6, :m7 => 7, :m8 => 8, :m9 => 9, Symbol("") => 0)

idx(f::FrameRef) = (f.index,refindices[f.loop])


function Base.show(io::IO, n::FrameRef)
    print(io, "$(string(n.loop))$(n.nodetype)$(n.index)")
end

function Base.show(io::IO, ::MIME"text/plain", n::FrameRef)
    print(io, "fref\"")
    show(io, n)
    print(io,"\"")
end

const reflabels = Dict{Symbol, String}(:l => "ℓ", :m => "m", :u => "u", :m1 => "m₁", :m2 => "m₂", :m3 => "m₃", 
    :m4 => "m₄", :m5 => "m₅", :m6 => "m₆", :m7 => "m₇", :m8 => "m₈", :m9 => "m₉", Symbol("") => "")

function latex(io::IO, n::FrameRef)
    print(io, "$(reflabels[n.loop])$(n.nodetype)$(n.index)")
end

@rule fref = r"l|u|m1|m2|m3|m4|m5|m6|m7|m8|m9|m|" & r"[RL]?" & r"[0-9]"p > (l,t,i) -> FrameRef(Symbol(t), parse(Int, i), Symbol(l))

@rule ffun = r"[LR]?" & int > (t,d) -> FrameNode(Symbol(t), d)

macro fref_str(s)
    parsepeg(fref, s)
end

#@rule passage = extend_p, twist_p, release_p, navaho_p, multi_pick_p, pick_p, b_multi_pick_p, b_pick_p, b_release_p, b_navaho_p, b_twist_p
@rule passage = extend_p, twist_p, release_p, navaho_p, multi_pick_p, pick_p

macro pass_str(s)
    parsepeg(passage, s)
end

function Base.show(io::IO, ::MIME"text/latex", f::Passage)
    inmath = get(io, :inmath, false)
    inmath || print(io, "\$")
    latex(io, f)
    inmath || print(io, "\$")
end

function Base.show(io::IO, ::MIME"text/plain", f::Passage)
    print(io, "pass\"")
    show(io, f)
    print(io, "\"")
end

"""
An `ExtendPassage` represents the extension of the string in order to make it taut. 
It has no arguments. Represented in Storer with the symbol "|".
"""
struct ExtendPassage <: Passage 
    k::Int
end

@rule extend_p = "|" & r"!*"p > (_, x) -> ExtendPassage(length(x))

Base.show(io::IO, f::ExtendPassage) = print(io, "|"*"!"^f.k)
latex(io::IO, f::ExtendPassage) = show(io, f)

(f::ExtendPassage)(p::LinearSequence) = simplify(p; k=1/(f.k+2))

"""
A `PickPassage` represents the action of picking a string with a given functor. 
Its arguments are:
- `fun::FrameRef`  : the functor (i.e. the picking finger)
- `away::Bool`    : on an "other hand" pick, if the first movement is away the executer (default) 
- `arg::FrameRef`  : the argument (i.e. the finger holding the section of string being picked)
- `near::Bool`    : is it the *near* portion of the string? 
- `over::Bool`    : does the finger travels above all other string in order to reach it?
- `above::Bool`   : does it pick the string from above?

In Storer, it is represented by `F(A)` in which `F`` is the functor, decorated with an 
arrow on top if the finger travels over other strings (the `over` flag) and a downward
pointing arrow "↓" if it picks the argument from above (the `above` flag). The argument
`A` represents a framenode, appended with the letter `n` or `f` if the string picked is
one `near` the executer or not. 
"""
struct PickPassage <: Passage
    fun::FrameNode
    away::Bool
    arg::FrameRef
    near::Bool
    over::Bool
    above::Bool
    function PickPassage(fun,away,arg,near,over,above)
        if type(fun) == type(arg) 
            away = (idx(fun) < idx(arg))
        end
        new(fun,away,arg,near,over,above)
    end
end


@rule pick_p = ffun & r"[ou]"p & r"a?"p & r"t?"p & r"\("p & fref & r"[fn]"p & ")" > (f,ou,a,t,_,g,fn,_) -> PickPassage(f,t == "",g,fn=="n",ou=="o",a=="a")

function Base.show(io::IO, f::PickPassage)
    show(io, f.fun)
    print(io, f.over ? "o" : "u", f.above ? "a" : "", "(")
    show(io, f.arg)
    print(io, f.near ? "n" : "f", ")")
end

function latex(io::IO, f::PickPassage)
    arrow = "\\$(type(f.fun) == type(f.arg) ? "l" : "L")ong$(f.away ? "right" : "left")arrow"
    print(io,"\\$(f.over ? "over" : "under")set{$arrow}{")
    print(io, f.fun)
    print(io, "}\\left($(f.above ? "\\over" : "\\under")line{")
    latex(io, f.arg)
    print(io, f.near ? "n" : "f", "}\\right)")
end

function (f::PickPassage)(p::LinearSequence)
    if isbilateral(f.fun)
        p = pick(p, f.over, f.away, FrameNode(:L, f.fun.index, f.fun.loop), framenode(FrameRef(:L, f.arg.index, f.arg.loop), p), f.near, f.above)
        p = pick(p, f.over, f.away, FrameNode(:R, f.fun.index, f.fun.loop), framenode(FrameRef(:R, f.arg.index, f.arg.loop), p), f.near, f.above)
    else
        p = pick(p, f.over, f.away, f.fun, framenode(f.arg, p), f.near, f.above)
    end    
end

"""
A `MultiPickPassage` represents the action of picking a string with a given functor. 
Its arguments are:
- `pass::Vector{PickPassage}` : the argument (i.e. the finger holding the section of string being picked)
"""
struct MultiPickPassage <: Passage
    seq::Vector{PickPassage}
end

@rule pick_pp = pick_p & r":"p > (f,_) -> f 
@rule multi_pick_p = pick_pp[1:end] & pick_p > (v,x)->MultiPickPassage(push!(v, x))


left(f::FrameNode) = FrameNode(:L, f.index, f.loop)
right(f::FrameNode) = FrameNode(:R, f.index, f.loop)
left(f::FrameRef) = FrameRef(:L, f.index, f.loop)
right(f::FrameRef) = FrameRef(:R, f.index, f.loop)

isbilateral(f) = type(f) == Symbol("")


function (f::MultiPickPassage)(p::LinearSequence)
    fun = f.seq[1].fun
    @assert all(==(fun), (x.fun for x in f.seq))
    if isbilateral(fun)
        p = pick(p, left(fun), [(framenode(left(x.arg), p), x.near, x.over) for x in f.seq], f.seq[end].above)
        pick(p, right(fun), [(framenode(right(x.arg), p), x.near, x.over) for x in f.seq], f.seq[end].above)
    else
        pick(p, fun, [(framenode(x.arg, p), x.near, x.over) for x in f.seq], f.seq[end].above)
    end
end


function latex(io::IO, ff::MultiPickPassage)
    for f in ff.seq[1:end-1] 
        fun, arg = f.fun, f.arg
        arrow = "\\$(type(f.fun) == type(f.arg) ? "l" : "L")ong$(fun.index <= arg.index ? "right" : "left")arrow"
        print(io,"\\$(f.over ? "over" : "under")set{$arrow}{", fun, "}")
        print(io, "\\left(")
        latex(io, f.arg)
        print(io, f.near ? "n" : "f", "\\right):")
    end 
    latex(io, ff.seq[end])
end

function Base.show(io::IO, ff::MultiPickPassage)
    for f in ff.seq[1:end-1] 
        show(io, f)
        print(io, ":")
    end
    show(io, ff.seq[end])
end

"""
A `ReleasePassage` represents the release of one loop. It is denoted by the "□" symbol in 
Storer, which we represent in ASCII with "D" (for delete) 
"""
struct ReleasePassage <: Passage
    arg::FrameRef
end

@rule release_p = "D" & fref > (_,f) -> ReleasePassage(f)

function Base.show(io::IO, f::ReleasePassage)
    print(io, "D")
    show(io, f.arg)
end

function latex(io::IO, f::ReleasePassage)
    print(io,"\\square ")
    latex(io, f.arg)
end


function release(arg, p)
    delete(p) do n
        type(arg) == type(n) && n.index == arg.index && n.loop >= arg.loop
    end
end

function (f::ReleasePassage)(p::LinearSequence)
    if isbilateral(f.arg)
        p = release(framenode(left(f.arg), p), p)
        release(framenode(right(f.arg), p), p)
    else
        release(framenode(f.arg, p), p)
    end
end

"""
A `NavahoPassage` represents the release of the lower loop in a two-loop finger. 
It is denoted by the "N" symbol in Storer. 
"""
struct NavahoPassage <: Passage
    arg::FrameNode
end

@rule navaho_p = "N" & ffun > (_,f) -> NavahoPassage(f)

Base.show(io::IO, f::NavahoPassage) = print(io, "N", f.arg)
latex(io::IO, f::NavahoPassage) = print(io, "N", f.arg)

function (f::NavahoPassage)(p::LinearSequence)
    if isbilateral(f.arg)
        p = navaho(p, left(f.arg))
        navaho(p, right(f.arg))
    else
        navaho(p, f.arg)
    end
end



"""
A `TwistPassage` represents the invertion of one loop
"""
struct TwistPassage <: Passage
    arg::FrameRef
    away::Bool
    times::Int
end

@rule twist_p = r"(>+)|(<+)"p & fref > (t,f) -> TwistPassage(f, t[1] == '>', length(t))

function Base.show(io::IO, f::TwistPassage)
    print(io, (f.away ? '>' : '<')^f.times)
    show(io, f.arg)
end

latex(io::IO, f::TwistPassage) = show(io, f)

function twist_helper(p::LinearSequence, arg, times, away)
    for _ in 1:times
        p = twist(p, framenode(arg, p), away) 
    end
    return p
end

function (f::TwistPassage)(p::LinearSequence)
    if isbilateral(f.arg)
        p = twist_helper(p, left(f.arg), f.times, f.away)
        p = twist_helper(p, right(f.arg), f.times, f.away)
    else
        p = twist_helper(p, f.arg, f.times, f.away)
    end
    return p
end