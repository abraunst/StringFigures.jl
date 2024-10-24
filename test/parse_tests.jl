"""
Test parsing linear sequences.

(Storer, p009) on crossings, (Storer, p001) on fingers.
"""


@testset "parse error" begin
    @test_throws StringFigures.PEGParseError StringFigures.parsepeg(StringFigures.snode, "y1(0)")
end

@testset "parse nodes" begin
    # fingers
    expect = [FrameNode(:L, 1), FrameNode(:L, 5), FrameNode(:R, 5), FrameNode(:R, 1)]
    actual = [node"L1", node"L5", node"R5", node"R1"]
    @test actual == expect
    # (Storer p001) no 6th finger is allowed
    # @test_throws node"R6"

    # crossings
    @test CrossNode(:U, 1) == node"x1(U)"
    # not sure if there's a string figure with 99 crossings, but it's allowed
    @test CrossNode(:O, 99) == node"x99(0)"
end

@testset "parse sequence" begin
    # no crossings (Opening 1, Fig. 3, Storer p002)
    o1 = seq"L1:L5:R5:R1"
    o1seq = [FrameNode(:L, 1), FrameNode(:L, 5), FrameNode(:R, 5), FrameNode(:R, 1)]
    @test o1.seq == o1seq

    # with crossings (Opening A, Fig. 13, Storer p014)
    oa = seq"L1:x1(0):R2:x2(0):L5:R5:x2(U):L2:x1(U):R1"
    oaseq = [
        FrameNode(:L, 1),
        CrossNode(:O, 1),
        FrameNode(:R, 2),
        CrossNode(:O, 2),
        FrameNode(:L, 5),
        FrameNode(:R, 5),
        CrossNode(:U, 2),
        FrameNode(:L, 2),
        CrossNode(:U, 1),
        FrameNode(:R, 1),
    ]
    @test oa.seq == oaseq

    # linear sequences are cyclic
    @test o1[end+1] == o1[begin]
    @test oa[end+1] == oa[begin]
end