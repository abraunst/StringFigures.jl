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
    return canonical(p)
end

function pick_sameside(p::LinearSequence, over::Bool, f::SeqNode, arg::SeqNode, near::Bool)
    @assert f.type == arg.type # only on the same side
    isframenode(arg) || throw(ArgumentError("Only frame nodes can identify sectors"))
    isframenode(f) || throw(ArgumentError("Only frame nodes can be functors"))
    nold = numcrossings(p) 
    n = nold + 1
    @assert findfirst(==(f), p) === nothing
    i = findfirst(==(arg), p) 
    !isnothing(i) || throw(ArgumentError("Non existing argument"))
    newcross = [SeqNode[] for _ in eachindex(p)]
    function addpair(x, U, b)
        append!(newcross[mod(x, eachindex(p))], 
            (SeqNode(U, n + b), SeqNode(U, n + !b)))
        #println("adding pair ", newcross[mod(x, eachindex(p))], " at pos $x($(p[x-1])↓$(p[x]))" )
        n += 2
    end
    (U, O) = over ? (:U, :O) : (:O, :U)

    # is the functor below the arg?
    fbelow = f.idx < arg.idx
    # is the arg of the functor on the right of i in the seq?
    argnext = (near == isnearsidenext(p, i))
    # @show argnext
    # eventual crossing in the arg node 
    if fbelow != near
        addpair(i + !argnext, U, !argnext)
    end

    middle = [(n.idx,j) for (j,n) in pairs(p) if 
        p[j].type == f.type && (p[j].idx-f.idx)*(p[j].idx-arg.idx) < 0]
    sort!(middle; rev=(f.idx < arg.idx))

    #@show [p[j] for (_,j) in middle]

    for (_,j) in middle
        # intermediate active frame node
        farnext = isfarsidenext(p, j)  
        # are the first two new crossings on the right of j in the seq?
        cnext = (fbelow == farnext)
        addpair(j + cnext, U, cnext)
        addpair(j + !cnext, U, !cnext)
    end
    #cnext = (fbelow == isfarsidenext(p, i))
    # add spike
    c = Iterators.flatten((
        (SeqNode(O, j) for j in nold+1:2:n-2),
        (f,),
        (SeqNode(O, j) for j in n-1:-2:nold+2)))
    #@show newcross
    append!(newcross[mod(i + argnext, eachindex(p))],
            !argnext ? c : Iterators.reverse(c)) 

    # build new linear sequence inserting all new crossings 
    vnew = SeqNode[]
    for j in eachindex(p)
        append!(vnew, newcross[j])
        push!(vnew, p[j])
    end
    LinearSequence(vnew)
    #canonical(LinearSequence(vnew))
end

function pick(p::LinearSequence, over::Bool, f::SeqNode, arg::SeqNode, near::Bool, above::Bool=false)
    f.type == arg.type && return pick_sameside(p, over, f, arg, near)
    extra = f.idx > arg.idx ? 0 : 6 ## check
    farg, ffun = SeqNode(arg.type, extra), SeqNode(f.type, extra)
    p = pick_sameside(p, over, farg, arg, near)
    p.seq[findfirst(==(farg), p)] = ffun
    #println(p)
    p = pick_sameside(p, over, f, ffun, f.idx < extra)
    p = release(p, ffun) 
    if above
        p = twist(p, f, f.idx < arg.idx)
    end
    p |> simplify
end

function twist(p::LinearSequence, f::SeqNode, away::Bool)
    i = findfirst(==(f), p)
    n = maximum(x->x.idx, Iterators.filter(!isframenode, p); init=0)
    U, O = away == isnearsidenext(p, f) ? (:U, :O) : (:O, :U)
    canonical(@views LinearSequence([
        p.seq[1:i-1]; 
        SeqNode(U, n+1); 
        f; 
        SeqNode(O, n+1); 
        p.seq[i+1:end]]))
end


function Base.:(==)(p::LinearSequence, q::LinearSequence)
    (iscanonical(p) ? p.seq : canonical(p).seq) == (iscanonical(q) ? q.seq : canonical(q).seq)
end
