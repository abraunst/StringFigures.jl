using PEG


"""
The `Passage` type represents one passage or move in a string figure construction` 
"""
abstract type Passage end

@rule passage = extend_p, twist_p, release_p, pick_p

Base.show(io::IO, ::MIME"text/latex", f::Passage) = print(io, "\$", latex(f), "\$")

macro pass_str(s)
    parsepeg(passage, s)
end

"""
An `ExtendPassage` represents the extension of the string in order to make it taut. 
It has no arguments. Represented in Storer with the symbol "|".
"""
struct ExtendPassage <: Passage end

@rule extend_p = "|" > _ -> ExtendPassage()

Base.string(f::ExtendPassage) = "|"

latex(f::ExtendPassage) = "|"

(f::ExtendPassage)(p::LinearSequence) = simplify(p)

"""
A `PickPassage` represents the action of picking a string with a given functor. 
Its arguments are:
- `fun::SeqNode`  : the functor (i.e. the picking finger)
- `arg::SeqNode`  : the argument (i.e. the finger holding the section of string being picked)
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
    arg::FrameNode
    near::Bool
    over::Bool
    above::Bool
end

@rule pick_p = fnode & r"[ou]"p & r"a?"p & r"\("p & fnode & r"[fn]"p & ")" > (f,ou,a,_,g,fn,_) -> PickPassage(f,g,fn=="n",ou=="o",a=="a")

Base.string(f::PickPassage) = "$(string(f.fun))$(f.over ? "o" : "u")$(f.above ? "a" : "")($(string(f.arg))$(f.near ? "n" : "f"))"

function latex(f::PickPassage)
    arrow = "\\$(type(f.fun) == type(f.arg) ? "l" : "L")ong$(idx(f.fun) <= idx(f.arg) ? "right" : "left")arrow"
    "\\$(f.over ? "over" : "under")set{$arrow}{$(string(f.fun))}\\left($(f.above ? "\\over" : "\\under")line{$(string(f.arg))$(f.near ? "n" : "f")}\\right)"
end

(f::PickPassage)(p::LinearSequence) = pick(p, f.over, f.fun, f.arg, f.near, f.above)


"""
A `ReleasePassage` represents the release of one loop. It is denoted by the "□" symbol in 
Storer, which we represent in ASCII with "D" (for delete) 
"""
struct ReleasePassage <: Passage
    arg::FrameNode
end

@rule release_p = r"[DN]" & fnode > (_,f) -> ReleasePassage(f)

Base.string(f::ReleasePassage) = "D$(string(f.arg))"
latex(f::ReleasePassage) = "\\square $(string(f.arg))"

(f::ReleasePassage)(p::LinearSequence) = release(p, f.arg)


"""
A `TwistPassage` represents the invertion of one loop
"""
struct TwistPassage <: Passage
    arg::FrameNode
    away::Bool
end

@rule twist_p = r"[<>]" & fnode > (t,f) -> TwistPassage(f, t == ">")

Base.string(f::TwistPassage) = f.away ? ">$(string(f.arg))" : "<$(string(f.arg))"

latex(f::TwistPassage) = string(f)

(f::TwistPassage)(p::LinearSequence) = twist(p, f.arg, f.away)
