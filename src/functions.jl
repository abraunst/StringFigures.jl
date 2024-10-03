release(p::LinearSequence, f::FrameNode) = delete(==(f), p)

function delete(g::Function, p::LinearSequence)
    filter(!g, p.seq) |> LinearSequence |> canonical
end

function navaho(p::LinearSequence, f::FrameNode)
    N = maximum(idx(n) for n in p if n isa CrossNode)
    s = SeqNode[]
    for n in p
        if isframenode(f) && n == FrameNode(functor(f)..., loop(f) + 1)
            append!(s, isnearsidenext(p, n) ?
                       [CrossNode(:O, N + 3), CrossNode(:U, N + 2), f, CrossNode(:U, N + 1), CrossNode(:O, N + 4)] :
                       [CrossNode(:O, N + 4), CrossNode(:U, N + 1), f, CrossNode(:U, N + 2), CrossNode(:O, N + 3)]
            )
        elseif n == f
            append!(s, isnearsidenext(p, n) ?
                       [CrossNode(:U, N + 4), CrossNode(:U, N + 3), CrossNode(:O, N + 2), CrossNode(:O, N + 1)] :
                       [CrossNode(:O, N + 1), CrossNode(:O, N + 2), CrossNode(:U, N + 3), CrossNode(:U, N + 4)]
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
        isadjacent(i, j) = abs(i - j) ∈ (1, length(p) - 1)
        D1 = Dict{Int,Int}()
        D2 = Dict{Int,Int}()

        for (i, n) in pairs(p)
            #@show n type(n) idx(n)
            if type(n) == :O
                D1[idx(n)] = i
            elseif type(n) == :U
                D2[idx(n)] = i
            end
        end
        #@show D1 D2
        rem = Int[]
        for (j, i) in pairs(D1)
            j ∈ rem && continue
            # lemma 2a
            #@show D2 j D2[j] i isadjacent(D2[j], i)
            if isadjacent(D2[j], i)
                push!(rem, i)
                push!(rem, D2[j])
            end
            # lemma 2b
            if j > 1 &&
               isadjacent(i, D1[j-1]) &&
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
    pick_sameside(p, f, [(arg, near, over)])
end

function pick_sameside(p::LinearSequence, f::FrameNode, args::Vector{Tuple{FrameNode,Bool,Bool}})
    arg, near, _ = args[end]
    @assert type(f) == type(arg) # only on the same side
    k = 1 + maximum(loop(n) for n in p if isframenode(n) && functor(n) == functor(f); init=-1)
    f = FrameNode(functor(f)..., k)
    path = build_path(p, f, args)
    i = findframenode(arg, p)
    argnext = (near == isnearsidenext(p, i))
    pick_path(p, f, i, argnext, path)
end

"""
Builds path from `f` to `args[end]` close to the fingers, with under/over switching at 
intermediate steps.
"""
function build_path(p::LinearSequence, f::FrameNode, args::Vector{Tuple{FrameNode,Bool,Bool}})
    a, (arg, near, over) = (length(args) - 1, args[end])
    function update(n, b)
        if a > 0 && n == args[a][1] && b == args[a][2]
            arg, near, over
            arg, near, over = args[a]
            a -= 1
        end
    end

    i = findframenode(arg, p)
    path = Tuple{Int,Bool,Bool}[]

    # is the functor below the arg?
    fbelow = idx(f) < idx(arg)
    # is the arg of the functor on the right of i in the seq?
    argnext = (near == isnearsidenext(p, i))

    # eventual crossing in the arg node 
    if fbelow != near
        push!(path, (i, !argnext, over))
        update(p[i], fbelow)
    end

    middle = [(idx(n), j) for (j, n) in pairs(p) if n != f && n != arg &&
              type(n) == type(f) && (idx(n) < idx(f)) != (idx(n) < idx(arg))]
    sort!(middle; rev=fbelow)

    for (_, j) in middle
        # intermediate active frame node
        farnext = isfarsidenext(p, j)
        # are the first two new crossings on the right of j in the seq?
        cnext = (fbelow == farnext)
        push!(path, (j, cnext, over))
        update(p[j], !fbelow)
        push!(path, (j, !cnext, over))
        update(p[j], fbelow)
    end
    return path
end

"""
Makes a complex pick by functor `f`` of segment `(i,bi)` through
all segments in `path`, each one identified by `(j,bj,o)` where `o` determines 
if the pick passes over the corresponding segment. Here segment `(j,bj)` is the 
segment going from `p[j]` to `p[j+bj]`.
"""
function pick_path(p, f, i, bi, path)
    before, after = [SeqNode[] for _ in p], [SeqNode[] for _ in p]
    nx = numcrossings(p)
    insert(j, bj, x) = bj ? append!(after[j], x) : append!(before[j], Iterators.reverse(x))

    # add two new crossings for each crossing segment
    for (x, (j, bj, oj)) in pairs(path)
        insert(j, bj, (CrossNode(oj ? :U : :O, nx + 2x), CrossNode(oj ? :U : :O, nx + 2x - 1)))
    end

    # add spike
    insert(i, bi, Iterators.flatten((
        (CrossNode(oj ? :O : :U, nx + 2x) for (x, (_, _, oj)) in pairs(path)),
        (f,),
        (CrossNode(oj ? :O : :U, nx + 2x - 1) for (x, (_, _, oj)) in Iterators.reverse(pairs(path))))))

    # build new linear sequence inserting all new crossings 
    vnew = SeqNode[]
    for (b, n, a) in zip(before, p, after)
        append!(vnew, b)
        push!(vnew, n)
        append!(vnew, a)
    end
    #LinearSequence(vnew)
    canonical(LinearSequence(vnew))
end


function pick(p::LinearSequence, over::Bool, away::Bool, f::FrameNode, arg::FrameNode, near::Bool, above::Bool=false)
    pick(p, f, away, [(arg, near, over)], above)
end


function pick_otherside(p::LinearSequence, f::FrameNode, away::Bool, args)
    arg, _, over = args[end]
    extra = away ? (0, 0) : (6, 0) ## check
    farg, ffun = FrameNode(type(arg), extra...), FrameNode(type(f), extra...)
    p = pick_sameside(p, farg, args)
    p.seq[findframenode(farg, p)] = ffun
    p = pick_sameside(p, over, f, ffun, idx(f) < extra)
    p = release(p, ffun)
end

function pick(p::LinearSequence, f::FrameNode, away::Bool, args::Vector{Tuple{FrameNode,Bool,Bool}}, above::Bool=false)
    p = type(f) == type(args[end][1]) ?
        pick_sameside(p, f, args) :
        pick_otherside(p, f, away, args)
    if above
        p = twist(p, f, away)
    end
    simplify(p)
end

function pick(p::LinearSequence, f::FrameNode, args::Vector{Tuple{FrameNode,Bool,Bool}}, above::Bool=false)
    pick(p::LinearSequence, f::FrameNode, idx(f) < idx(args[end][1]), args, above)
end

function twist(p::LinearSequence, f::FrameNode, away::Bool)
    i = findframenode(f, p)
    n = maximum(idx, Iterators.filter(!isframenode, p); init=0)
    U, O = away == isnearsidenext(p, f) ? (:U, :O) : (:O, :U)
    canonical(@views LinearSequence([
        p.seq[1:i-1];
        CrossNode(U, n + 1);
        f;
        CrossNode(O, n + 1);
        p.seq[i+1:end]]))
end

function lemma2c(p::LinearSequence, i1, i2, j1, j2, k1, k2)
    @assert (k1, k2) ∈ ((j1 + 1, j2 + 1), (j1 + 1, j2 - 1), (j1 - 1, j2 + 1), (j1 - 1, j2 - 1))
    p1 = copy(p)
    p1[i1], p1[i2] = p1[i2], p1[i1]
    p1[j1], p1[k1] = p1[k1], p1[j1]
    p1[j2], p1[k2] = p1[k2], p1[j2]
    p1
end

function findpair(x, p)
    l = filter(i->(p[i] isa CrossNode && idx(p[i]) == x), eachindex(p))
    @assert length(l) == 2
    l[1], l[2]
end

function lemma2c(p::LinearSequence, i1::Int, i2::Int, i3::Int)
    N1, N2, N3 = findpair(i1, p), findpair(i2, p), findpair(i3, p)
    for ((a1,a2),(b1,b2),(c1,c2)) in Iterators.product(N1,N2,N3)
        if type(p[a1]) == O && type(p[a2]) == O && 
                mod(a1 - a2, length(p)) ∈ (1,length(p)-1) && 
                mod(b1 - b2, length(p)) ∈ (1,length(p)-1) &&
                mod(c1 - c2, length(p)) ∈ (1,length(p)-1) &&
                p[a1] == inverse(p[b1]) && 
                p[a2] == inverse(p[c1]) && 
                p[b2] == inverse(p[c2])
                return lemma2c(p, a1,a2,b1,b2,c1,c2)
        end
    end
end

"ϕ₃ simplifications (lemma 2c), based on string total length/tension"
function simplify3(q::LinearSequence; k=0.5, mult=10^4)
    ten = tension(q; k) + mult*length(q)
    p = simplify12(q)
    p1 = p
    for i in eachindex(p)
        if p[i] isa CrossNode && p[i+1] isa CrossNode &&
           type(p[i]) == type(p[i+1]) && idx(p[i]) != idx(p[i+1])
            j1 = findfirst(==(inverse(p[i])), p)
            j2 = findfirst(==(inverse(p[i+1])), p)
            for (k1, k2) in ((j1 + 1, j2 + 1), (j1 + 1, j2 - 1), (j1 - 1, j2 + 1), (j1 - 1, j2 - 1))
                if p[k1] isa CrossNode && p[k2] isa CrossNode && p[k1] == inverse(p[k2])
                    p1 = lemma2c(p, i, i+1, j1, j2, k1, k2)
                    p1 = simplify12(p1)
                    ten1 = tension(p1; k) + mult*length(p1)
                    if ten1 < ten
                        p = p1
                        ten = ten1
                    end
                end
            end
        end
    end
    return p1
end

"Extension-cancellation simplifications"
function simplify(p::LinearSequence; k=0.5)
    q = simplify12(p)
    while true
        q = simplify3(q; k)
        q == p && return q
        p = q
    end
end