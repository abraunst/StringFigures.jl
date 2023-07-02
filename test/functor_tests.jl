"""
Test functors
"""

@testset "extend" begin
    # O1 opening, nothing to extend-cancel
    # (i.e. extend-cancellation is idempotent)
    o1 = [
        SeqNode(:L, 1), SeqNode(:L, 5), SeqNode(:R, 5), SeqNode(:R, 1)
    ] |> LinearSequence
    @test simplify(o1).seq == o1.seq

    # one-step extention cancellation
    # Fig. 9, Storer p010
    fig9a = [
        SeqNode(:L, 1), SeqNode(:L, 5),
        SeqNode(:O, 1), SeqNode(:U, 1),
        SeqNode(:R, 5), SeqNode(:R, 1),
    ] |> LinearSequence
    @test simplify(fig9a).seq == o1.seq

    fig9b = [
        SeqNode(:L, 1), SeqNode(:L, 5),
        SeqNode(:O, 1), SeqNode(:O, 2),
        SeqNode(:R, 5), SeqNode(:R, 1),
        SeqNode(:U, 2), SeqNode(:U, 1),
    ] |> LinearSequence
    @test simplify(fig9b).seq == o1.seq

    fig9c = [
        SeqNode(:L, 1), SeqNode(:L, 5),
        SeqNode(:O, 1), SeqNode(:O, 2),
        SeqNode(:O, 3), SeqNode(:U, 1),
        SeqNode(:R, 5), SeqNode(:R, 1),
        SeqNode(:U, 2), SeqNode(:U, 3),
    ] |> LinearSequence
    @test simplify(fig9c).seq == o1.seq

    # two-step extention cancellation
    # Fig. 10, Storer p012
    fig10 = [
        SeqNode(:L, 1), SeqNode(:L, 5),
        SeqNode(:O, 1), SeqNode(:O, 2), SeqNode(:U, 2), SeqNode(:O, 3),
        SeqNode(:R, 5), SeqNode(:R, 1),
        SeqNode(:U, 3), SeqNode(:U, 1),
    ] |> LinearSequence
    @test simplify(fig10).seq == o1.seq
end