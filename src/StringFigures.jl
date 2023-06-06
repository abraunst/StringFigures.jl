module StringFigures

include("linearsequence.jl")
include("embedding.jl")
include("functions.jl")
include("functors.jl")

export LinearSequence, SeqNode, depth, @seq_str, @node_str, @f_str, plot,
        isframenode, isfarsidenext, isnearsidenext, iscanonical,
        canonical, release, simplify, pick
end
