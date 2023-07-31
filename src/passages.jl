using PEG


"""
The `Passage` type represents one passage or move in a string figure construction
"""
abstract type Passage end

@rule passage = extend_p, twist_p, release_p, navaho_p, pick_p, b_pick_p, b_release_p, b_navaho_p, b_twist_p

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

@rule release_p = "D" & fnode > (_,f) -> ReleasePassage(f)

Base.string(f::ReleasePassage) = "D$(string(f.arg))"
latex(f::ReleasePassage) = "\\square $(string(f.arg))"

function (f::ReleasePassage)(p::LinearSequence)
    for n in p
        if type(n) == type(f.arg) && idx(n)[1] == idx(f.arg)[1] && n >= f.arg
            p = release(p, f.arg)
        end
    end
    return p
end

"""
A `NavahoPassage` represents the release of the lower loop in a two-loop finger. 
It is denoted by the "N" symbol in Storer. 
"""
struct NavahoPassage <: Passage
    arg::FrameNode
end

@rule navaho_p = "N" & fnode > (_,f) -> NavahoPassage(f)

Base.string(f::NavahoPassage) = "N$(string(f.arg))"
latex(f::NavahoPassage) = "N$(string(f.arg))"

function (f::NavahoPassage)(p::LinearSequence)
    navaho(p, f.arg)
end



"""
A `TwistPassage` represents the invertion of one loop
"""
struct TwistPassage <: Passage
    arg::FrameNode
    away::Bool
end

@rule twist_p = r"[<>]" & fnode > (t,f) -> TwistPassage(f, t == ">")

Base.string(f::TwistPassage) =  "$(f.away ? '>' : '<')$(string(f.arg))"

latex(f::TwistPassage) = string(f)

(f::TwistPassage)(p::LinearSequence) = twist(p, f.arg, f.away)


#### Bilateral Passages

struct BilateralPickPassage <: Passage
    fun::Tuple{Int,Int}
    arg::Tuple{Int,Int}
    near::Bool
    over::Bool
    above::Bool
end

@rule b_fnode = int & ("." & int)[0:1] > (d,l) -> (d, (isempty(l) ? 0 : only(l)[2]))
@rule b_pick_p = b_fnode & r"[ou]"p & r"a?"p & r"\("p & b_fnode & r"[fn]"p & ")" > (f,ou,a,_,g,fn,_) -> BilateralPickPassage(f,g,fn=="n",ou=="o",a=="a")

_b_string(f) = !iszero(f[2]) ? join(f,".") : string(f[1])
Base.string(f::BilateralPickPassage) = "$(_b_string(f.fun))$(f.over ? "o" : "u")$(f.above ? "a" : "")($(_b_string(f.arg))$(f.near ? "n" : "f"))"
function latex(f::BilateralPickPassage)
    arrow = "\\long$(f.fun <= f.arg ? "right" : "left")arrow"
    "\\$(f.over ? "over" : "under")set{$arrow}{$(_b_string(f.fun))}\\left($(f.above ? "\\over" : "\\under")line{$(_b_string(f.arg))$(f.near ? "n" : "f")}\\right)"
end
function (f::BilateralPickPassage)(p::LinearSequence)
    p = pick(p, f.over, FrameNode(:L,f.fun), FrameNode(:L,f.arg), f.near, f.above)
    p = pick(p, f.over, FrameNode(:R,f.fun), FrameNode(:R,f.arg), f.near, f.above)
end



struct BilateralReleasePassage <: Passage
    arg::Tuple{Int,Int}
end

@rule b_release_p = r"[D]" & b_fnode > (_,f) -> BilateralReleasePassage(f)

Base.string(f::BilateralReleasePassage) = "D$(_b_string(f.arg))"
latex(f::BilateralReleasePassage) = "\\square $(_b_string(f.arg))"

function (f::BilateralReleasePassage)(p::LinearSequence)
    p = release(p, FrameNode(:L, f.arg))
    p = release(p, FrameNode(:R, f.arg)) 
end

struct BilateralNavahoPassage <: Passage
    arg::Tuple{Int,Int}
end

@rule b_navaho_p = r"[N]" & b_fnode > (_,f) -> BilateralNavahoPassage(f)

Base.string(f::BilateralNavahoPassage) = "D$(_b_string(f.arg))"
latex(f::BilateralNavahoPassage) = "\\square $(_b_string(f.arg))"

function (f::BilateralNavahoPassage)(p::LinearSequence)
    p = navaho(p, FrameNode(:L, f.arg))
    p = navaho(p, FrameNode(:R, f.arg)) 
end



struct BilateralTwistPassage <: Passage
    arg::Tuple{Int,Int}
    away::Bool
end

@rule b_twist_p = r"[<>]" & b_fnode > (t,f) -> BilateralTwistPassage(f, t == ">")

Base.string(f::BilateralTwistPassage) = f.away ? ">$(_b_string(f.arg))" : "<$(_b_string(f.arg))"

latex(f::BilateralTwistPassage) = _b_string(f)

function (f::BilateralTwistPassage)(p::LinearSequence)
    p = twist(p, FrameNode(:L, f.arg), f.away)
    p = twist(p, FrameNode(:R, f.arg), f.away)
end

