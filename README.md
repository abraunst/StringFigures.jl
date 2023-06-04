# StringFigures

This code attempts to implement the string figure calculus in Storer's book.

[![Build Status](https://github.com/abraunst/StringFigures.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/abraunst/StringFigures.jl/actions/workflows/CI.yml?query=branch%3Amain)

## Progress:

### Linear sequences
- [x] Structure for Linear Sequences
- [x] Canonical Form

### Visualization
- [x] Elementary visualization (no crossings)
- [ ] Crossings @abraunst
- [ ] Better layout, better string physics?

### Calculus
- [x] basic: `simplify` (lemmas 2a and 2b in Storer's book)
- [ ] advanced: $\phi_3$ moves and heuristics to decide when to apply it
- [x] `pick` (pick from below)
- [ ] pick from above (pick from below plus loop adition)
- [ ] pick non-standard arguments
- [ ] Syntactic sugar for functors

