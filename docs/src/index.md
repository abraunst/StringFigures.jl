# StringFigures.jl

Documentation for StringFigures.jl

## Linear Sequences and knot diagrams

```@docs
FrameNode
CrossNode
LinearSequence
@node_str
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
FrameRef
BiFrameRef
@pass_str
@fref_str
```

## Calculus

```@docs
StringCalculus
StringProcedure
@proc_str
@calc_str
```

## Grammar

Input of Nodes, Linear sequences, Calculus, and full Procedures is specified by a PEG using the `PEG.jl` library. The full grammar is shown below.

* [`FrameNode`](@ref), [`CrossNode`](@ref)

  ```julia
  @rule int =  r"\d+"
  @rule fnode = r"[LR]" & int & ("." & int)[0:1]
  @rule xnode = "x" & int & "(" & r"[0U]" & ")"
  @rule snode = fnode, xnode
  ```

* [`LinearSequence`](@ref)

  ```julia
  @rule snodec = snode & ":"
  @rule linseq = (snodec[*] & snode)
  @rule opening = r"[0-9A-Za-z]*"p
  ```

* [`FrameRef`](@ref) and [`BiFrameRef`](@ref) and Functor

  ```julia
  @rule fref = r"l|u|m[1-9]?|" & r"[RL]?" & r"[0-9]"
  @rule ffun = r"[LR]?" & int
  ```

* [`Passage`](@ref)

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

* [`Calculus`](@ref)

  ```julia
  @rule passages = (passage & r"#?"p)
  @rule calculus = r""p & passages[*]
  ```
  
* [`StringProcedure`](@ref)

  ```julia
  @rule parenseq = "(" & linseq & ")"
  @rule procedure = ((parenseq,opening) & r"::"p & calculus)
  ```
