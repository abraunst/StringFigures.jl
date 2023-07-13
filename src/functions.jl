function release(p::LinearSequence, n::FrameNode)
    dn, ln = idx(n)
    map(filter(!=(n), p.seq)) do m
        dm,lm = idx(m)
        type(m) == type(n) && dm == dn && lm > ln ? FrameNode(type(n), dn, lm - 1) : m
    end |> LinearSequence |> canonical
end


function simplify(p::LinearSequence)
    while true
        p = canonical(p)
        isadjacent(i,j) = abs(i-j) == 1 || abs(i-j) == length(p) - 1
        D1 = Dict{Int,Int}()
        D2 = Dict{Int,Int}()

        for (i,n) in pairs(p)
            #@show n type(n) idx(n)
            if type(n) == :O
                D1[idx(n)] = i
            elseif type(n) == :U
                D2[idx(n)] = i
            end
        end
        #@show D1 D2
        rem = Int[]
        for (j,i) in pairs(D1)
            j ∈ rem && continue
            # lemma 2a
            #@show D2 j D2[j] i isadjacent(D2[j], i)
            if isadjacent(D2[j], i)
                push!(rem, i)
                push!(rem, D2[j])
            end
            # lemma 2b
            if j > 1 && 
                isadjacent(i,       D1[j-1]) &&
                isadjacent(D2[j], D2[j-1])
                push!(rem, i)
                push!(rem, D1[j-1])
                push!(rem, D2[j])
                push!(rem, D2[j-1])
            end        
        end
        isempty(rem) && break
        #@show rem
        deleteat!(p.seq, sort!(rem))
    end
    return canonical(p)
end


function pick_sameside(p::LinearSequence, over::Bool, f::FrameNode, arg::FrameNode, near::Bool)
    @assert type(f) == type(arg) # only on the same side
    nold = numcrossings(p) 
    n = nold + 1
    k = 1 + maximum(loop(n) for n in p if type(n) == type(f) && idx(n)[1] == idx(f)[1]; init=-1)
    f = FrameNode(type(f), idx(f)[1], k)

    i = findframenode(arg, p) 
    !isnothing(i) || throw(ArgumentError("Non existing argument"))
    newcross = [SeqNode[] for _ in eachindex(p)]
    function addpair(x, U, b)
        append!(newcross[mod(x, eachindex(p))], 
            (CrossNode(U, n + b), CrossNode(U, n + !b)))
        #println("adding pair ", newcross[mod(x, eachindex(p))], " at pos $x($(p[x-1])↓$(p[x]))" )
        n += 2
    end
    (U, O) = over ? (:U, :O) : (:O, :U)

    # is the functor below the arg?
    fbelow = idx(f) < idx(arg)
    # is the arg of the functor on the right of i in the seq?
    argnext = (near == isnearsidenext(p, i))
    # @show argnext
    # eventual crossing in the arg node 
    if fbelow != near
        addpair(i + !argnext, U, !argnext)
    end

    middle = [(idx(n),j) for (j,n) in pairs(p) if p[j] != f && p[j] != arg && 
        type(p[j]) == type(f) && (idx(p[j]) < idx(f)) != (idx(p[j]) < idx(arg))]
    sort!(middle; rev=fbelow)

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
        (CrossNode(O, j) for j in nold+1:2:n-2),
        (f,),
        (CrossNode(O, j) for j in n-1:-2:nold+2)))
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

function pick(p::LinearSequence, over::Bool, f::FrameNode, arg::FrameNode, near::Bool, above::Bool=false)
    type(f) == type(arg) && return pick_sameside(p, over, f, arg, near)
    extra = idx(f) > idx(arg) ? (0,0) : (6,0) ## check
    farg, ffun = FrameNode(type(arg), extra...), FrameNode(type(f), extra...)
    p = pick_sameside(p, over, farg, arg, near)
    p.seq[findframenode(farg, p)] = ffun
    #println(p)
    p = pick_sameside(p, over, f, ffun, idx(f) < extra)
    p = release(p, ffun) 
    if above
        p = twist(p, f, idx(f) < idx(arg))
    end
    p |> simplify
end

function twist(p::LinearSequence, f::FrameNode, away::Bool)
    i = findframenode(f, p)
    n = maximum(idx, Iterators.filter(!isframenode, p); init=0)
    U, O = away == isnearsidenext(p, f) ? (:U, :O) : (:O, :U)
    canonical(@views LinearSequence([
        p.seq[1:i-1]; 
        CrossNode(U, n+1); 
        f; 
        CrossNode(O, n+1); 
        p.seq[i+1:end]]))
end


function Base.:(==)(p::LinearSequence, q::LinearSequence)
    (iscanonical(p) ? p.seq : canonical(p).seq) == (iscanonical(q) ? q.seq : canonical(q).seq)
end
