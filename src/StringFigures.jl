module StringFigures

include("node.jl")
include("linearsequence.jl")
include("embedding.jl")
include("functions.jl")
include("passages.jl")
include("calculus.jl")

export LinearSequence, SeqNode, FrameNode, CrossNode, FrameRef,
        @node_str, @seq_str, @storer_str, @pass_str, @calc_str, @proc_str, @fref_str, @open_str,
        plot, latex, isframenode, isfarsidenext, isnearsidenext,
        iscanonical, canonical, release, simplify, pick, twist,
        Passage, ExtendPassage, PickPassage, ReleasePassage, 
        TwistPassage, NavahoPassage, MultiPickPassage,
        StringCalculus, StringProcedure
end
