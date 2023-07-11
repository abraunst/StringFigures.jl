"""
Test passages
"""

O1 = seq"L1:L5:R5:R1"
fig9a = seq"L1:L5:x1(0):x1(U):R5:R1"
fig9b = seq"L1:L5:x1(0):x2(0):R5:R1:x2(U):x1(U)"
fig9c = seq"L1:L5:x1(0):x2(0):x3(0):x1(U):R5:R1:x2(U):x3(U)"
fig10 = seq"L1:L5:x1(0):x2(0):x2(U):x3(0):R5:R1:x3(U):x1(U)"
OA = seq"L1:x1(0):R2:x2(0):L5:R5:x2(U):L2:x1(U):R1"
fig155a = seq"L2:x1(0):R3:x2(0):L5:R5:x2(U):L3:x1(U):R2"

@testset "extend" begin
    # O1 opening, nothing to extend-cancel
    # (i.e. extend-cancellation is idempotent)
    @test simplify(O1).seq == O1.seq

    # one-step extention cancellation
    # Fig. 9, Storer p010
    @test simplify(fig9a).seq == O1.seq

    @test simplify(fig9b).seq == O1.seq

    @test simplify(fig9c).seq == O1.seq

    # two-step extention cancellation
    # Fig. 10, Storer p012
    @test simplify(fig10).seq == O1.seq
end

@testset "pick" begin
    fig155apick = seq"x9(U):x10(U):L2:x8(U):x7(U):x1(0):R3:x2(0):x3(0):x5(0):x7(0):x9(0):L1:x10(0):x8(0):x6(0):x4(0):L5:R5:x2(U):x3(U):x4(U):L3:x6(U):x5(U):x1(U):R2"
    pick(fig155a, true, node"L1", node"L5", true) == fig155apick
end

@testset "release" begin
    p = seq"Ll:x1(0):R2:x2(0):L5:R5:x2(U):L2:xl(U):x3(U):Rl:x3(0)"
    release(p, node"L1") == seq"L2:x1(U):R5:L5:x1(0):R2:x2(0):x3(0):R1:x3(U):x2(U)"
end

@testset "twist" begin
    twist(O1, node"R1", true) == seq"L1:L5:R5:x1(U):R1:x1(0)"
end

@testset "calc" begin
    C = calc"R2o(L1f)#L2u(R5n)"
    @test C(O1) == OA
end
