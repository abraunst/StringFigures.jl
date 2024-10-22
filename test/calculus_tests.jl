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

@testset "bilateral" begin
    @test proc"OA::>>>>1"[end] == proc"OA::>>>>L1#>>>>R1"[end]
    @test proc"OA::1ua(2f)"[end] == proc"OA::L1ua(L2f)#R1ua(R2f)"[end]
    @test proc"OA::N1"[end] == proc"OA::NL1#NR1"[end]
end

@testset "latex" begin
    io = IOBuffer()
    show(io, MIME"text/latex"(), proc"OA::D1#[L2o(L5n)]^2#>1")
    String(take!(io)) == "\${{OA}}~::~{{{\\square 1}}}\\# {{{\\left[{{{\\overset{\\longrightarrow}{L2}\\left(\\underline{L5n}\\right)}}}\\# \\right]^{2}}}}\\# {{{>1}}}\\# \$"
end