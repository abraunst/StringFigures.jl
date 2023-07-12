module StringFigures

include("linearsequence.jl")
include("embedding.jl")
include("functions.jl")
include("passages.jl")
include("calculus.jl")

export LinearSequence, SeqNode, FrameNode, CrossNode,
        @node_str, @seq_str, @storer_str, @pass_str, @calc_str, @proc_str, plot, latex,
        isframenode, isfarsidenext, isnearsidenext, iscanonical,
        canonical, release, simplify, pick, twist,
        Passage, ExtendPassage, PickPassage, ReleasePassage, TwistPassage, 
        StringCalculus, StringProcedure
end
