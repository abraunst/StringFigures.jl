"""
Test linear sequences in canonical/noncanonical forms.

(Storer, p006)
"""

# canonical form of O1 opening
o1 = seq"L1:L5:R5:R1"
# different starting point
start = seq"R5:R1:L1:L5"
# counterclockwise orientation
orient = seq"L1:R1:R5:L5"
# diff starting point AND ccw orientation
both = seq"L5:L1:R1:R5"
# noncanonical with crossings
noncanonical = seq"L1:x1(U):L2:x3(U):x1(0):R2:x3(0):R1"

@testset "convert to canonical" begin
    # get inner sequence of a LinearSequence
    seq(s::LinearSequence) = s.seq
    # allequal
    # copied from https://github.com/JuliaLang/julia/blob/147bdf428cd14c979202678127d1618e425912d6/base/set.jl#L505-L532
    allequal(v::Vector) = all(v |> first |> isequal, v)

    o1s = [o1, start, orient, both]
    # although only one is canonical, they are considered equal
    @test o1 == start
    @test o1 == orient
    @test o1 == both
    # converting to canonical form maintains equality
    @test allequal(@. o1s |> canonical)
    # in canonical forms, same figures have same sequence of frame nodes
    @test allequal(@. o1s |> canonical |> seq)

    # some linear sequences converted to canonical
    canonicals = @. [o1s; noncanonical] |> canonical
    # canonical forms are indeed, canonical
    @test all(@. canonicals |> iscanonical)

    # converting to canonical is idempotent
    @test (@. canonicals |> seq) == (@. canonicals |> canonical |> seq)
end

@testset "iscanonical" begin
    @test iscanonical(o1)
    @test !iscanonical(start)
    @test !iscanonical(orient)
    @test !iscanonical(both)
    @test !iscanonical(noncanonical)
end
