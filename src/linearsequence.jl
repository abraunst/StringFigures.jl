struct SeqNode
    type::Symbol
    idx::Int
    function SeqNode(type, idx)
        idx ≥ 0 || throw(ArgumentError("Wrong index $idx"))
        type ∈ (:L, :R, :U, :O) || throw(ArgumentError("Wrong type $type"))
        type ∉ (:L, :R) || 1 ≤ idx ≤ 5 || throw(ArgumentError("Wrong index $idx"))
        new(type, idx)
    end
end

function SeqNode(s)
    m = match(r"L(\d+)",s)
    !isnothing(m) && return SeqNode(:L, parse(Int, m[1]))
    m = match(r"R(\d+)",s)
    !isnothing(m) && return SeqNode(:R, parse(Int, m[1]))
    m = match(r"x(\d+)\(([0U])[\)J]",s)
    !isnothing(m) && return SeqNode(m[2] == "U" ? :U : :O, parse(Int, m[1]))
    @assert false "Impossible to parse $s"
end

function index(s::SeqNode)
    if s.type == :L
        s.idx
    elseif s.type == :R 
        s.idx + 5
    elseif s.type ∈ (:U,:O)
        s.idx + 10
    end
end

struct LinearSequence
    seq::Vector{SeqNode}
end

function LinearSequence(s::String)
    # allow some fuzziness to be able to easily copy-paste 
    # from Storer's OCR'd book :)
    s = replace(s, " " => "", "{" => "(", "l" => "1", ";" => ":", 
        "O" => "0", "S" => "5", "X" => "x")
    LinearSequence(SeqNode.(split(s, ":")))
end

Base.length(p) = length(p.seq)
depth(p) = maximum((n.idx for n in p.seq if n.type ∈ (:U,:O)); init=0) + 10 

function gaussish_code(p::LinearSequence)
    map(p.seq) do n
        if n.type == :U 
            -n.idx
        else
            n.idx
        end
    end
end

function Base.string(n::SeqNode)
    if n.type ∈ (:L,:R)
        "$(n.type)$(n.idx)" 
    elseif n.type == :U
        "x$(n.idx)(U)"
    else
        "x$(n.idx)(0)"
    end
end

Base.show(io::IO, p::SeqNode) = print(io, "node\"", string(p), "\"")

function Base.show(io::IO, p::LinearSequence)
    print(io, "seq\"", join(string.(p.seq),":"), "\"")
end


function canonical(p::LinearSequence)
    # find first active left finger
    L, Lpos = 11, 0
    for (i,n) in pairs(p)
        if n.type == :L && n.idx < L
            L, Lpos = n.idx, i
        end
    end

    # if the near side is next in the sequence, we need to revert
    rev = isnearsidenext(p, p[Lpos])

    D = Dict{Int,Int}()
    idx = 1

    #rebuild the sequence in canonical order
    map(eachindex(p)) do i
        n = p.seq[mod(rev ? Lpos - i + 1 : Lpos + i - 1, eachindex(p))]
        if n.type ∈ (:L, :R)
            n
        else
            if !haskey(D, n.idx)
                D[n.idx] = idx
                idx += 1
            end
            SeqNode(n.type, D[n.idx])
        end
    end |> LinearSequence
end

isframe(n::SeqNode) = n.type ∈ (:L, :R)

function isfarsidenext(p::LinearSequence, n::SeqNode)
    i = findfirst(==(n), p)
    l, r = i, i
    for k in eachindex(p)
        pos = mod(i+k, eachindex(p))
        if isframe(p[pos])
            r = pos
            break
        end
    end
    for k in eachindex(p)
        pos = mod(i-k, eachindex(p))
        if isframe(p[pos])
            l = pos
            break
        end
    end

    #only 3 or more frame nodes! 
    @assert l != i && r != i 

    #@show "left", p.seq[l] 
    #@show "right", p.seq[r] 
    @views Xl = Set(filter(!isframe, l < i ?  p.seq[l:i] : p.seq[i:l]))
    @views Xr = Set(filter(!isframe, i < r ?  p.seq[i:r] : p.seq[r:i]))
    xor(p.seq[l].idx < p.seq[r].idx, isodd(length(Xl ∩ Xr)))
end

isnearsidenext(p::LinearSequence, n::SeqNode) = !isfarsidenext(p, n)

Base.:(==)(p1::LinearSequence, p2::LinearSequence) = p1.seq == p2.seq

macro seq_str(s)
    LinearSequence(s)
end

macro node_str(s)
    SeqNode(s)
end

Base.iterate(p::LinearSequence) = iterate(p.seq)
Base.iterate(p::LinearSequence, s) = iterate(p.seq, s)
Base.getindex(p::LinearSequence, i) = p.seq[i]
Base.eachindex(p::LinearSequence) = eachindex(p.seq)
Base.pairs(p::LinearSequence) = pairs(p.seq)