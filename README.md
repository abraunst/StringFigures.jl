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


## Progress

### Linear sequences

- [x] Structure for Linear Sequences (Storer, p006)
- [x] Canonical Form
  - as per Convention Seq. 1 and Seq. 2 (Storer, p006)
  - Calculus described in (Storer, p357-359)

### Visualization

- [x] Elementary visualization (no crossings)
- [x] Crossings visualization
- [x] only plot active frame nodes
- [ ] multi-loop framenodes
- [ ] Better layout, better string physics?

### Calculus

- [x] `release`
  - introduced as the $\square$ functor (Storer, p023)
  - calculus is described in p362
- [x] `simplify` <!-- extend (hands to absorb slack), see p003 -->
  - introduced as the $\mid$ functor (Storer, p003)
  - calculus is described as Lemma 2 A. and B. (Storer, p011)
- [x] `pick` same hand (Storer, p015), opposite hand (Storer, p020)
  - from below, e.g. $\overset{\longleftarrow}{L3}\left(\underline{L5n}\right)$
    - i.e. pass $L3$ (away) **over** all intermediate strings and pick up $L5n$ from below
    - this is encoded as `"L3o(L5n)"`
- [X] `pick` (from above)
- [ ] advanced: $\phi_3$ passages and heuristics to decide when to apply it
- [ ] pick non-standard arguments
- [ ] multiple loops in a single Ln or Rn, non-finger functors, pick from non-empty framenode
- [x] Syntactic sugar for passages
- [x] Elementary `StringCalculus`s
- [x] LaTeX output of `StringCalculus`
- [x] `StringProcedures`
