"""
Test calculus
"""

O1 = seq"L1:L5:R5:R1"
OA = seq"L1:x1(0):R2:x2(0):L5:R5:x2(U):L2:x1(U):R1"


@testset "calc" begin
    C = calc"R2o(L1f)#L2u(R1f)#"
    @test C(O1) == OA
    O1b = pass"R2o(L1f)"(O1)
    @test O1b == seq"L1:x1(0):R2:x2(0):L5:R5:x2(U):x1(U):R1"
    @test pass"L2ut(R5n)"(O1b) == seq"L1:x1(0):R2:x2(0):L5:R5:x2(U):L2:x1(U):R1"
end

@testset "procedure" begin
    @test O1 == proc"O1::" |> only
    @test OA == proc"OA::" |> only
    @test pass"R2o(L1f)"(O1) == proc"O1::R2o(L1f)" |> last
    @test proc"O1::>L1#D1|" |> last == proc"O1::D1|" |> last
    @test proc"O1::1o(5f)#NL1#DL1|" |> last == proc"O1::1o(5f)#DL1|" |> last
end