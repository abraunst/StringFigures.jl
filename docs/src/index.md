# StringFigures.jl

Documentation for StringFigures.jl

## Linear Sequences and knot diagrams

```@docs
LinearSequence
@seq_str
@open_str
@storer_str
simplify
plot
```

## Passages

```@docs
Passage
ReleasePassage
TwistPassage
ExtendPassage
PickPassage
MultiPickPassage
NavahoPassage
PowerPassage
@pass_str
```

## Calculus

```@docs
StringCalculus
StringProcedure
@proc_str
```

## Grammar

Input of Nodes, Linear sequences, Calculus, and full Procedures is specified by a PEG using the `PEG.jl` library. The full grammar is shown below.

* `SeqNode`: A sequence node is either a `FrameNode` (i.e. a finger, or a loop in a finger), or a `CrossNode`, i.e. a crossing in the 2D representation of the 3D string figure. Example: `node"L1"`, representing the left thumb.

  ```julia
  @rule int =  r"\d+"
  @rule fnode = r"[LR]" & int & ("." & int)[0:1]
  @rule xnode = "x" & int & "(" & r"[0U]" & ")"
  @rule snode = fnode, xnode
  ```

* `LinearSequence`: A linear sequence is a 2D layout of a string figure. It is a sequence of `SeqNode`s, so that following the string you encounter, sequentially, each node in the `LinearSequence`. `CrossNode`s appear in pairs, e.g. `x10(0)` and `x10(U)`, meaning respectively that one goes on the upper string and the lower string in the crossing. Example: `seq"L1:x1(0):R2:x2(0):L5:R5:x2(U):L2:x1(U):R1"` which is Opening A, i.e. OA. You can also graphically display a linear sequence with the function `plot`.

  ```julia
  @rule snodec = snode & ":"
  @rule linseq = (snodec[*] & snode)
  ```

* Some standard openings have been already defined, and can be retrieved with `open"O0", open"O1", open"OA"`.

  ```julia
  @rule opening = r"[0-9A-Za-z]*"p
  ```

* A functor is the finger executing an action. A functor may be lateral or bilateral, the latter meaning that symmetric fingers in both hands will be executing the same action.

  ```julia
  @rule ffun = r"[LR]?" & int
  ```

* A `FrameRef` is a reference to one string attached to a `FrameNode`. `l`,`m`,`u` denote respectively the lowest, middle or top string on it. If there are more than 3 strings, then the second, third, etc are refered to as `m1`, `m2`, ...

  ```julia
  @rule fref = r"l|u|m[1-9]?|" & r"[RL]?" & r"[0-9]"
  ```

* `Passage`s (`passage.jl`). A passage is one coordinated movement of the finger(s), which modifies the figure in some way. E.g. `pass"DL1"`, releasing all strings on the left thumb.

  ```julia
  @rule passage = extend_p, twist_p, release_p, navaho_p, multi_pick_p, pick_p
  @rule extend_p = "|" & r"!*"p
  @rule pick_p = ffun & r"[ou]"p & r"a?"p & r"t?"p & r"\("p & fref & r"[fn]"p & ")"
  @rule pick_pp = pick_p & r":"p
  @rule multi_pick_p = pick_pp[1:end] & pick_p
  @rule release_p = "D" & fref
  @rule navaho_p = "N" & ffun
  @rule twist_p = r"(>+)|(<+)"p & fref
  ```

* `Calculus`s (`calculus.jl`). A `Calculus` is a sequence of `Passage`s, specifying a multi-step transformation of a `LinearSequence`. E.g. `calc"DL1#DL2"`, releasing all strings on both thumbs.

  ```julia
  @rule passages = (passage & r"#?"p)
  @rule calculus = r""p & passages[*]
  ```
  
* `StringProcedure` (`calculus.jl`). A `StringProcedure` is a starting position plus a `Calculus`. Example: `OA::DL2#DR2#|` which goes back to Opening 1 from Opening A. You can plot a `StringProcedure` with the function plot, which plots all intermediate positions.

  ```julia
  @rule parenseq = "(" & linseq & ")"
  @rule procedure = ((parenseq,opening) & r"::"p & calculus)
  ```
