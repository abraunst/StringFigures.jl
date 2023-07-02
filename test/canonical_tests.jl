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
noncanonical = seq"L1:x1(U):L2:x3(U):x1(O):R2:x3(O):R1"

@testset "convert to canonical" begin
    # get inner sequence of a LinearSequence
    seq(s::LinearSequence) = s.seq

    o1s = [o1, start, orient, both]
    # although only one is canonical, they are considered equal
    @test allequal(o1s)
    # converting to canonical form maintains equality
    @test allequal(@. o1s |> canonical)
    # in canonical form, same figures have same sequence of frame nodes
    @test allequal(@. o1s |> canonical |> seq)

    openings = [o1s; noncanonical]
    @test all(@. openings |> canonical |> iscanonical)
end

@testset "iscanonical" begin
    @test iscanonical(o1)
    @test !iscanonical(start)
    @test !iscanonical(orient)
    @test !iscanonical(both)
    @test !iscanonical(noncanonical)
end