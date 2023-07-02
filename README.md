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
- [x] Canonical Form, as per Convention Seq. 1 and Seq. 2 (Storer, p006)

### Visualization

- [x] Elementary visualization (no crossings)
- [x] Crossings visualization
- [x] only plot active frame nodes
- [ ] multi-loop framenodes
- [ ] Better layout, better string physics?

### Calculus

- [x] `release` passage
- [x] basic: `simplify` (lemmas 2a and 2b in Storer's book)
- [x] `pick` (from below)
- [X] `pick` (from above)
- [ ] advanced: $\phi_3$ passages and heuristics to decide when to apply it
- [ ] pick non-standard arguments
- [ ] multiple loops in a single Ln or Rn, non-finger functors, pick from non-empty framenode
- [x] Syntactic sugar for passages
- [x] Elementary `StringCalculus`s
- [x] LaTeX output of `StringCalculus`
- [x] `StringProcedures`
