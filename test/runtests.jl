using StringFigures
using Test

@testset "StringFigures.jl" begin
    @testset "canonical" begin
        include("canonical_tests.jl")
    end

    @testset "parse" begin
        include("parse_tests.jl")
    end

    @testset "functor" begin
        include("functor_tests.jl")
    end
end
