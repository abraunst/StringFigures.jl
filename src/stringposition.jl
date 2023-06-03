struct SeqNode
    type::Symbol
    idx::Int
    function SeqNode(type, idx)
        type ∈ (:L, :R, :U, :O) || throw(ArgumentError("Wrong type"))
        type ∉ (:L, :R) || 1 ≤ idx ≤ 5 || throw(ArgumentError("Wrong idx"))
        new(type, idx)
    end
end

struct StringPosition
    seq::Vector{SeqNode}
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
    #@assert false "bad node $s" 
end


function StringPosition(s::String)
    labels = split(replace(s, " " => "", "{" => "(", "l" => "1", ";" => ":"), ":")
    StringPosition(SeqNode.(labels))
end

Base.length(p) = length(p.seq)
depth(p) = maximum((n.idx for n in p.seq if n.type ∈ (:U,:O)); init=0) + 10 

function gaussish_code(p::StringPosition)
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

Base.show(io::IO, p::SeqNode) = print(io, string(p))

function Base.show(io::IO, p::StringPosition)
    print(io, "|⟹", join(p.seq,":"), "■")
end


function canonical(p::StringPosition)
    # find first active left finger
    L, Lpos = 11, 0
    for (i,n) in pairs(p.seq)
        if n.type == :L && n.idx < L
            L, Lpos = n.idx, i
        end
    end

    # if the near side is next in the sequence, we need to revert
    rev = isnearsidenext(p, p.seq[Lpos])

    D = Dict{Int,Int}()
    idx = 1

    #rebuild the sequence in canonical order
    map(eachindex(p.seq)) do i
        n = p.seq[mod(rev ? Lpos - i + 1 : Lpos + i - 1, eachindex(p.seq))]
        if n.type ∈ (:L, :R)
            n
        else
            if !haskey(D, n.idx)
                D[n.idx] = idx
                idx += 1
            end
            SeqNode(n.type, D[n.idx])
        end
    end |> StringPosition
end

isframe(n::SeqNode) = n.type ∈ (:L, :R)

function isfarsidenext(p::StringPosition, n::SeqNode)
    i = findfirst(==(n), p.seq)
    l, r = i, i
    for k in eachindex(p.seq)
        pos = mod(i+k, eachindex(p.seq))
        if isframe(p.seq[pos])
            r = pos
            break
        end
    end
    for k in eachindex(p.seq)
        pos = mod(i-k, eachindex(p.seq))
        if isframe(p.seq[pos])
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

isnearsidenext(p::StringPosition, n::SeqNode) = !isfarsidenext(p, n)

Base.:(==)(p1::StringPosition, p2::StringPosition) = p1.seq == p2.seq

macro f_str(s)
    StringPosition(s)
end

macro n_str(s)
    SeqNode(s)
end

function release(p::StringPosition, n::SeqNode)
    @assert isframe(n)
    p2 = StringPosition(filter(!=(n), p.seq))
    canonical(p2)
end