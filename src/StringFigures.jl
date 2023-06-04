module StringFigures

include("linearsequence.jl")
include("embedding.jl")
include("functors.jl")

export LinearSequence, SeqNode, depth, @seq_str, @node_str, plot,
        isframenode, isfarsidenext, isnearsidenext, 
        canonical, release, simplify, pick
end
