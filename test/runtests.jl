using Test, Documenter, StringFigures

@testset "canonical" begin
    include("canonical_tests.jl")
end

@testset "parse" begin
    include("parse_tests.jl")
end

@testset "passage" begin
    include("passage_tests.jl")
end

@testset "calculus" begin
    include("calculus_tests.jl")
end

@testset "plot" begin
    @test_nowarn plot(open"O0")
    @test_nowarn plot(proc"OA::D1#D2")
    @test_throws Exception plot(seq"x1(0):x1(U)")
end

@testset "doctests" begin
    DocMeta.setdocmeta!(StringFigures, :DocTestSetup, :(using StringFigures); recursive=true)
    doctest(StringFigures; manual = false)
end

