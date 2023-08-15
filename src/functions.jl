release(p::LinearSequence, f::FrameNode) = delete(==(f), p)

function delete(g::Function, p::LinearSequence)
    filter(!g, p.seq) |> LinearSequence |> canonical
end

function navaho(p::LinearSequence, f::FrameNode)
    N = maximum(idx(n) for n in p if n isa CrossNode)
    s = SeqNode[]
    for n in p
        if n == FrameNode(type(f), idx(f)[1], idx(f)[2]+1)
            append!(s, isnearsidenext(p, n) ?
                [CrossNode(:O,N+3), CrossNode(:U,N+2), f, CrossNode(:U,N+1), CrossNode(:O,N+4)] :
                [CrossNode(:O,N+4), CrossNode(:U,N+1), f, CrossNode(:U,N+2), CrossNode(:O,N+3)]
            )
        elseif n == f
            append!(s, isnearsidenext(p, n) ?
                [CrossNode(:U,N+4), CrossNode(:U,N+3), CrossNode(:O,N+2), CrossNode(:O,N+1)] :
                [CrossNode(:O,N+1), CrossNode(:O,N+2), CrossNode(:U,N+3), CrossNode(:U,N+4)]
            )
        else
            push!(s, n)
        end
    end
    return LinearSequence(s) |> canonical
end

"ϕ₁ and ϕ₂ simplifications (lemmas 2a and 2b)"
function simplify12(p::LinearSequence)
    while true
        p = canonical(p)
        isadjacent(i,j) = abs(i - j) ∈ (1, length(p) - 1)
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
        deleteat!(p.seq, sort!(rem))
    end
    return canonical(p)
end

function pick_sameside(p::LinearSequence, over::Bool, f::FrameNode, arg::FrameNode, near::Bool)
    @assert type(f) == type(arg) # only on the same side
    k = 1 + maximum(loop(n) for n in p if type(n) == type(f) && idx(n)[1] == idx(f)[1]; init=-1)
    f = FrameNode(type(f), idx(f)[1], k)

    i = findframenode(arg, p) 
    isnothing(i) && throw(ArgumentError("Non existing argument"))
    path = Tuple{Int, Bool, Symbol}[]
    U = over ? :U : :O

    # is the functor below the arg?
    fbelow = idx(f) < idx(arg)
    # is the arg of the functor on the right of i in the seq?
    argnext = (near == isnearsidenext(p, i))

    # eventual crossing in the arg node 
    if fbelow != near
        push!(path, (mod(i + !argnext, p), !argnext, U))
    end

    middle = [(idx(n),j) for (j,n) in pairs(p) if n != f && n != arg && 
        type(n) == type(f) && (idx(n) < idx(f)) != (idx(n) < idx(arg))]
    sort!(middle; rev=fbelow)

    for (_,j) in middle
        # intermediate active frame node
        farnext = isfarsidenext(p, j)  
        # are the first two new crossings on the right of j in the seq?
        cnext = (fbelow == farnext)
        push!(path, (mod(j + cnext, p), cnext, U))
        push!(path, (mod(j + !cnext, p), !cnext, U))
    end
    pick_path(p, f, path, i, argnext)
end

function pick_path(p, f, path, i, argnext)
    newcross = [SeqNode[] for _ in p]
    nold = numcrossings(p) 
    nnew = nold + 1

    for (x, b, u) in path
        push!(newcross[x], CrossNode(u, nnew +  b))
        push!(newcross[x], CrossNode(u, nnew + !b))
        nnew += 2
    end
    # add spike
    c = Iterators.flatten((
        (CrossNode(path[j][3] == :U ? :O : :U, 2j - 1 + nold) for j in eachindex(path)),
        (f,),
        (CrossNode(path[j][3] == :U ? :O : :U, 2j + nold) for j in reverse(eachindex(path)))))
    append!(newcross[mod(i + argnext, eachindex(p))],
            !argnext ? c : Iterators.reverse(c)) 

    # build new linear sequence inserting all new crossings 
    vnew = SeqNode[]
    for j in eachindex(p)
        append!(vnew, newcross[j])
        push!(vnew, p[j])
    end
    #LinearSequence(vnew)
    canonical(LinearSequence(vnew))
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

"ϕ₃ simplifications (lemma 2c), based on string total length/tension" 
function simplify3(q::LinearSequence)
    p = copy(q)
    ten = tension(p)
    for i in eachindex(p)
        if p[i] isa CrossNode && p[i+1] isa CrossNode && 
            type(p[i]) == type(p[i+1]) && idx(p[i]) != idx(p[i+1])
            j1 = findfirst(==(inverse(p[i])),p)
            j2 = findfirst(==(inverse(p[i+1])),p)
            for (k1,k2) in Iterators.product((j1+1,j1-1),(j2+1,j2-1))
                if p[k1] isa CrossNode && p[k2] isa CrossNode && 
                        p[k1] == inverse(p[k2])
                    p1 = copy(p)
                    p1[i],p1[i+1] = p1[i+1],p1[i]
                    p1[j1],p1[k1] = p1[k1],p1[j1]
                    p1[j2],p1[k2] = p1[k2],p1[j2] 
                    p1 = simplify12(p1)
                    tension(p1) < ten  && return p1
                end
            end
        end
    end
    return p
end

"Extension-cancellation simplifications"
function simplify(p::LinearSequence)
    q = simplify12(p)
    while true
        q = simplify3(q)
        q == p && return q
        p = q
    end
end