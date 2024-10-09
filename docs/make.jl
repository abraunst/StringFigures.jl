using Documenter
using StringFigures

DocMeta.setdocmeta!(StringFigures, :DocTestSetup, :(using StringFigures); recursive=true)

makedocs(
    sitename = "StringFigures",
    format = Documenter.HTML(),
    modules = [StringFigures]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/abraunst/StringFigures.jl.git",
)

