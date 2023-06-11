using StringFigures
using Test

@testset "StringFigures.jl" begin
    # Example in Fig. 10, pag 12

    @test SeqNode(:L,2) == node"L2"
    @test SeqNode(:R,1) == node"R1"
    fig10 = seq"L1:L5:x1(0):x2(0):x2(U):x3(0):R5:R1:x3(U):x1(U)"
    @test fig10[end+1] == fig10[begin] # cyclic property, firstindex, lastindex
    @test simplify(fig10) == seq"L1:L5:R5:R1" # simplify
    noncanonical = seq"L1:x1(U):L2:x3(U):x1(O):R2:x3(O):R1"
    @test iscanonical(noncanonical) == false # iscanonical
    @test noncanonical == canonical(noncanonical)
    @test iscanonical(canonical(noncanonical)) # canonical
    twist = LinearSequence(vcat(node"L2", node"L3",
        [[SeqNode(:U,i); SeqNode(:O,i)] for i=1:100]...,
        SeqNode(:R,3),
        SeqNode(:R,2),
        [[SeqNode(:O,i); SeqNode(:U,i)] for i=100:-1:1]...))
    @test simplify(twist) == seq"L2:L3:R3:R2"
end
