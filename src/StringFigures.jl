module StringFigures

include("linearsequence.jl")
include("embedding.jl")
include("functions.jl")
include("functors.jl")

export LinearSequence, SeqNode, depth, 
        @seq_str, @node_str, @heart_str, plot,
        isframenode, isfarsidenext, isnearsidenext, iscanonical,
        canonical, release, simplify, pick,
        Functor, SeqNode, HeartSequence
end
