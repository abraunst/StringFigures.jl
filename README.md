# StringFigures

This code attempts to implement the string figure calculus in Storer's article:

Storer, Thomas F. String-figures. Math Department, University of Michigan, 1999

[![Build Status](https://github.com/abraunst/StringFigures.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/abraunst/StringFigures.jl/actions/workflows/CI.yml?query=branch%3Amain)

## Quick Start

First, install Julia (e.g. from [juliaup](https://github.com/JuliaLang/juliaup)) and clone this repository.

Inside the repo, open the Julia REPL with `julia`, then press `]` to enter pkg mode.

In pkg mode, set the primary environment to this project:

```
activate .
```

Then, precompile the project (after installing dependencies):

```
precompile
```

To run tests in [test/runtests.jl](./test/runtests.jl):

```
test StringFigures
```

## Grammar

Input of Nodes, Linear sequences, Calculus, and full Procedures is specified by a PEG using the `PEG.jl` library. The full grammar is shown below.

* `SeqNode`s (`node.jl`). Use it with `node"xxx"`
  ```julia
  @rule int =  r"\d+"[1]
  @rule fnode = r"[LR]" & int & ("." & int)[0:1]
  @rule xnode = "x" & int & "(" & r"[0U]" & ")"
  @rule snode = fnode, xnode
  ```
* `LinearSequence` (`linearsequence.jl`). Use it with `seq"xxx"`.
  ```julia
  @rule snodec = snode & ":"
  @rule linseq = (snodec[*] & snode)
  ```
* `Passage`s (`passage.jl`). Use it with `pass"xxx"`
  ```julia
  @rule passage = extend_p, twist_p, release_p, navaho_p, pick_p, b_pick_p, b_release_p, b_twist_p, b_navaho_p
  @rule extend_p = "|"
  @rule pick_p = fnode & r"[ou]"p & r"a?"p & r"\("p & fnode & r"[fn]"p & ")"
  @rule release_p = "D" & fnode
  @rule navaho_p = "N" & fnode
  @rule twist_p = r"[<>]" & fnode
  @rule b_fnode = int & ("." & int)[0:1]
  @rule b_pick_p = b_fnode & r"[ou]"p & r"a?"p & r"\("p & b_fnode & r"[fn]"p & ")"
  @rule b_release_p = r"[DN]" & b_fnode
  @rule b_twist_p = r"[<>]" & b_fnode
  @rule b_navaho_p = "N" & b_fnode

  ```
* `Calculus`s (`calculus.jl`). Use it with `calc"xxx"`
  ```julia
  @rule passages = (passage & r"#?"p)
  @rule calculus = r""p & passages[*]
  @rule O1 = r"O1"p[1]
  @rule OA = r"OA"p[1]
  ```
* `StringProcedure` (`calculus.jl`). Use it with `proc"xxx"`
  ```julia
  @rule procedure = ((linseq,O1,OA) & r"::"p & calculus)
  ```


## Progress

### Linear sequences

- [x] Structure for linear sequences (Storer, p006)
- [x] Canonical form
  - Conventions seq. 1 and seq. 2 (Storer, p006)
  - Convert to canonical form (Storer, p357-359)

### Visualization

- [x] Elementary visualization (no crossings)
- [x] Crossings visualization
- [x] Only plot active frame nodes
- [x] Multi-loop framenodes
- [ ] Better layout, better string physics?

### Calculus

- [x] Release, i.e. the $\square$ operation (Storer, p023)
  - Calculus (Storer, p362)
- [x] Extend, i.e. the $\mid$ operation (Storer, p003)
  - Lemma 2 A. and B. (Storer, p011) on extension cancellation
- [x] Pick string on the same hand (Storer, p015) or opposite hand (Storer, p020) from below
  - e.g. $\overset{\longleftarrow}{L3}\left(\underline{L5n}\right)$
  - i.e. pass $L3$ (away) **over** all intermediate strings and pick up $L5n$ from below
  - this is encoded as `L3o(L5n)`
- [X] Pick from above
- [ ] $\phi_3$ passages and heuristics to decide when to apply it
- [ ] Pick with non-standard arguments
- [x] Multiple loops in a single Ln or Rn
- [ ] Non-finger functors
- [x] Pick from non-empty framenode
- [x] Syntactic sugar for passages
- [x] Elementary `StringCalculus`s
- [x] LaTeX output of `StringCalculus`
- [x] `StringProcedures`
