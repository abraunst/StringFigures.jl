# StringFigures

This code attempts to implement the string figure calculus in Storer's article:

Storer, Thomas F. String-figures. Math Department, University of Michigan, 1999

[![Build Status](https://github.com/abraunst/StringFigures.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/abraunst/StringFigures.jl/actions/workflows/CI.yml?query=branch%3Amain)

## Progress

### Linear sequences

- [x] Structure for Linear Sequences
- [x] Canonical Form

### Visualization

- [x] Elementary visualization (no crossings)
- [x] Crossings visualization
- [x] only plot active frame nodes
- [ ] multi-loop framenodes
- [ ] Better layout, better string physics?

### Calculus

- [x] `release` move
- [x] basic: `simplify` (lemmas 2a and 2b in Storer's book)
- [x] `pick` (from below)
- [X] `pick` (from above)
- [ ] advanced: $\phi_3$ moves and heuristics to decide when to apply it
- [ ] pick non-standard arguments
- [ ] multiple loops in a single Ln or Rn, on-finger framenodes, pick from non-empty framenode
- [x] Syntactic sugar for functors
- [x] Elementary Heart sequences
- [x] LaTeX output of Heart sequences
