module StringFigures

include("linearsequence.jl")
include("embedding.jl")
include("functions.jl")
include("passages.jl")
include("calculus.jl")

export LinearSequence, SeqNode,
        @seq_str, @node_str, @calc_str, @pass_str, plot, latex,
        isframenode, isfarsidenext, isnearsidenext, iscanonical,
        canonical, release, simplify, pick, twist,
        Passage, ExtendPassage, PickPassage, ReleasePassage, TwistPassage, 
        StringCalculus, StringProcedure
end
