function release(p::LinearSequence, n::SeqNode)
    @assert isframenode(n)
    p2 = LinearSequence(filter(!=(n), p.seq))
    canonical(p2)
end


function simplify(p::LinearSequence)
    while true
        p = canonical(p)
        isadjacent(i,j) = abs(i-j) == 1 || abs(i-j) == length(p) - 1
        D1 = Dict{Int,Int}()
        D2 = Dict{Int,Int}()

        for (i,n) in pairs(p)
            if n.type == :O
                D1[n.idx] = i
            elseif n.type == :U
                D2[n.idx] = i
            end
        end
        #@show D1 D2
        rem = Int[]
        for (idx,i) in pairs(D1)
            idx ∈ rem && continue
            # lemma 2a
            #@show D2 idx D2[idx] i isadjacent(D2[idx], i)
            if isadjacent(D2[idx], i)
                push!(rem, i)
                push!(rem, D2[idx])
            end
            # lemma 2b
            if idx > 1 && 
                isadjacent(i,       D1[idx-1]) &&
                isadjacent(D2[idx], D2[idx-1])
                push!(rem, i)
                push!(rem, D1[idx-1])
                push!(rem, D2[idx])
                push!(rem, D2[idx-1])
            end        
        end
        isempty(rem) && break
        #@show rem
        deleteat!(p.seq, sort!(rem))
    end
    return p
end

function pick(over::Bool, p::LinearSequence, f::SeqNode, arg::SeqNode, near::Bool)
    @assert f.type == arg.type # only on the same side
    isframenode(arg) || throw(ArgumentError("Only frame nodes can identify sectors"))
    isframenode(f) || throw(ArgumentError("Only frame nodes can be functors"))
    nold = maximum(n.idx for n in p if n.type ∈ (:U, :O); init = 0) 
    n = nold + 1
    @assert findfirst(==(f), p) === nothing
    i = findfirst(==(arg), p) 
    !isnothing(i) || throw(ArgumentError("Non existing argument"))
    newcross = [SeqNode[] for _ in eachindex(p)]
    function addpair(x, U, b)
        append!(newcross[mod(x, eachindex(p))], 
            (SeqNode(U, n + b), SeqNode(U, n + !b)))
        println("adding pair ", newcross[mod(x, eachindex(p))], " at pos $x($(p[x]))" )
        n += 2
    end
    (U, O) = over ? (:U, :O) : (:O, :U)

    fbelow = f.idx < arg.idx

    for j in i+1:i+lastindex(p)
        middle = (p[j].idx - f.idx) * (p[j].idx - arg.idx) < 0
        # intermediate active frame node
        if p[j].type == f.type && middle
            farnext = isfarsidenext(p, j)  
            cnext = (fbelow == farnext)
            addpair(j + cnext, U, cnext)
            addpair(j + !cnext, U, !cnext)
        end
    end

    # eventual crossing in the arg node
    farnext = isfarsidenext(p, i)
    cnext = fbelow == farnext # is the crossing on the next string
    if fbelow != near #extra crossings on arg
        @show "in arg"
        addpair(i + cnext, U, cnext)
    end

    # add spike
    c = Iterators.flatten((
        (SeqNode(O, j) for j in nold+1:2:n-2),
        (f,),
        (SeqNode(O, j) for j in n-1:-2:nold+2)))

    append!(newcross[mod(i + !cnext, eachindex(p))],
            cnext ? c : Iterators.reverse(c)) 

    # build new linear sequence inserting all new crossings 
    vnew = SeqNode[]
    for j in eachindex(p)
        append!(vnew, newcross[j])
        push!(vnew, p[j])
    end
    LinearSequence(vnew)
end