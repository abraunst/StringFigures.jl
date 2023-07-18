using StringFigures
using Test

@testset "StringFigures.jl" begin
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
    
end
