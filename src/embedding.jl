using LinearAlgebra, Graphs, GraphPlot, Colors, Compose, StaticArrays


laplacian(A) = Diagonal(vec(sum(A; dims=2))) - A

function tutte_embedding(g; vfixed=1:0, locs_fixed=fill(0.0, 0, 2))
    A = adjacency_matrix(g)
    @assert issymmetric(A)
    K = laplacian(A)
    K[vfixed,:] .= 0
    K[vfixed,vfixed] = I(length(vfixed))
    c = fill(0.0, size(A, 1), 2)
    c[vfixed,:] = locs_fixed
    v = K \ c
    v[:,1], v[:,2]
end


function node_labels_and_fixed_positions(p::LinearSequence; crossings=true)
    D = Dict{SeqNode, Int}()
    function pos(n)
        id,l = idx(n)
        θ = [-π/4; 0.0:π/12:π/4]
        ε = 0.4
        v = 1.0
        L = 0
        w = 0.7
        R = 0.99
        if type(n) == :L
            SVector(-v*cos(θ[id]+l*π/36), -sin(w*(θ[id]+l*π/36)))
        elseif type(n) == :La
            R*SVector(-v*cos(θ[id]+(l-ε)*π/36), -sin(w*(θ[id]+(l-ε)*π/36)))
        elseif type(n) == :Lb
            R*SVector(-v*cos(θ[id]+(l+ε)*π/36), -sin(w*(θ[id]+(l+ε)*π/36)))
        elseif type(n) == :R
            SVector(v*cos(θ[id]+l*π/36), -sin(w*(θ[id]+l*π/36))) + SVector(L,0)
        elseif type(n) == :Ra
            R*SVector(v*cos(θ[id]+(l-ε)*π/36), -sin(w*(θ[id]+(l-ε)*π/36))) + SVector(L,0)
        elseif type(n) == :Rb
            R*SVector(v*cos(θ[id]+(l+ε)*π/36), -sin(w*(θ[id]+(l+ε)*π/36))) + SVector(L,0)
        end
    end

    i = 0
    vfixed = Int[]
    pfixed = fill(SVector(0.,0.), 0)
    vlabels = String[]

    maxloop = Dict{Pair{Symbol,Int},Int}()
    for n in p
        if isframenode(n)
            key = n.nodetype => n.index
            if !haskey(maxloop, key) || maxloop[key] < n.loop 
                maxloop[key] = n.loop
            end
        end
    end

    function label(n)
        type(n) ∈ (:L,:R) || return ""
        pre = if n.loop == 0 && maxloop[n.nodetype => n.index] > 0
            "ℓ"
        elseif n.loop == 0
            ""
        elseif n.loop == maxloop[n.nodetype => n.index]
            "u"
        elseif maxloop[n.nodetype => n.index] == 2
            "m"
        else
            "m" * ('₁':'₉')[n.loop]
        end
        "$(pre)$(type(n))$(n.index)"
    end

    for n in p
        if isframenode(n)
            if !haskey(D, n)
                i +=1; D[n] = i
                push!(vfixed, i)
                push!(pfixed, pos(n))
                push!(vlabels, label(n))
            end
        else
            n1 = CrossNode(type(n) == :U ? :O : :U, idx(n))
            if !haskey(D, n1)
                i += 1; D[n] = i
                push!(vlabels, crossings ? "x$(idx(n))" : "")
            else
                D[n] = D[n1]
            end
        end
    end
    i, vlabels, vfixed, pfixed, D
end


function tension(p::LinearSequence; k=0.5)
    n, _, vfixed, pfixed, Didx = node_labels_and_fixed_positions(p)
    locs_fixed = reduce(vcat, p' for p in pfixed)
    g = SimpleGraphFromIterator(Iterators.Flatten(
        ((Edge(Didx[p[i]], n + i),(Edge(n + i, Didx[p[i + 1]])))  for i in eachindex(p))))
    x, y = tutte_embedding(g; vfixed, locs_fixed);
    nrg = 0.0
    for i in vertices(g)
        for j in neighbors(g, i)
            nrg += ((x[i]-x[j])^2 + (y[i]-y[j])^2)^k
        end
    end
    return nrg
end

"""
`plot(p::LinearSequence; rfact, k, randomize, labels, shadowc, kwd...)`

Plots `p` using Tutte embedding. Parallel edges are then separated by slightly translating them perpendicularly to the segment joining the two vertices.

* `fact::Float64`:     Multiplicative factor for edge width
* `rfact::Float64`:    Distance between parallel edges (`0.02`)
* `randomize::Bool`:   Slightly randomize positions (`false`) 
* `labels::Bool`:      Add labels to the plot (`true`)
* `crossings::Bool`:   Should crossings be plotted
* `shadowc::colorant`: Color of the string shadow (`colorant"black"`)
* `stringc::colorant`: Color of the string (`colorant"white"`)
* `kwd...`:            Additional options for gplot (`(;)`). See e.g. `background_color`.

Example1: plot(proc"OA::DL1|")
Example2: plot(proc"OA::DL1|"; shadowc="white", stringc="black", nodelabelc="black", background_color="white")
"""
function plot(p::LinearSequence; rfact=0.02, randomize=false, crossings=false,
            labels=true, shadowc = HSLA(colorant"black", 1.0), stringc=colorant"white", fact=1.0, 
            nodelabelc=colorant"white", kwd...)
    
    q = SeqNode[];
    for (i,n) in pairs(p)
        if isframenode(n)
            ab = FrameNode(Symbol(string(n.nodetype)*"a"), n.index, n.loop), 
                FrameNode(Symbol(string(n.nodetype)*"b"), n.index, n.loop)
            if !isnearsidenext(p,i)
                append!(q, (ab[1],  n))
            else
                append!(q, (n,  ab[1]))
            end
        else
            push!(q, n)
        end
    end
    p = LinearSequence(q)
    n, vlabels, vfixed, pfixed, Didx = node_labels_and_fixed_positions(p; crossings)

    index(x) = Didx[x]
 
    locs_fixed = reduce(vcat, p' for p in pfixed)
    underlist = [
        [Edge(index(p[i]), n + i) for i in eachindex(p) if type(p[i]) == :U];
        [Edge(n + i, index(p[i + 1])) for i in eachindex(p) if type(p[i+1]) == :U]
    ] 
    gunder = SimpleGraphFromIterator(underlist)

    overlist = [
        [Edge(index(p[i]), n + i) for i in eachindex(p) if type(p[i]) != :U];
        [Edge(n + i, index(p[i + 1])) for i in eachindex(p) if type(p[i+1]) != :U]
    ]
    gover = SimpleGraphFromIterator(overlist)

    g = SimpleGraphFromIterator(Iterators.flatten((underlist, overlist)))


    append!(vlabels, fill("", nv(g)-n))

    locs_x, locs_y = tutte_embedding(g; vfixed, locs_fixed);

    if randomize
        locs_x[1:end] .+= randn.() * rfact
        locs_y[1:end] .+= randn.() * rfact
    end
    
    for i in eachindex(p)
        P1 = SVector(locs_x[index(p[i+1])], locs_y[index(p[i+1])])
        P2 = SVector(locs_x[index(p[i+2])], locs_y[index(p[i+2])])
        P3 = SVector(locs_x[index(p[i  ])], locs_y[index(p[i  ])])
        P4 = SVector(locs_x[index(p[i-1])], locs_y[index(p[i-1])])
        locs_x[n + i], locs_y[n + i] = (P1 + P3)/2
        P12 = iszero(P1-P2) ? SVector(0.0,0.0) : (P1-P2)/norm(P1-P2)
        P34 = iszero(P3-P4) ? SVector(0.0,0.0) : (P3-P4)/norm(P3-P4)
        P13 = iszero(P1-P3) ? SVector(0.0,0.0) : (P1-P3)/norm(P1-P3)
        D = P12 + P34 - ((P12 + P34) ⋅ P13) * P13
        locs_x[n + i] += D[1] * (isframenode(p[i]) ? rfact/5 : rfact) 
        locs_y[n + i] += D[2] * (isframenode(p[i]) ? rfact/5 : rfact)
    end 

    extr =  (-(extrema(locs_x)...)*(-7cm) + 3mm, -(extrema(locs_y)...)*(-7cm) + 3mm)

    pl0 = gplot(g, locs_x, locs_y;
        NODELABELSIZE=0.0, NODESIZE=0.0, EDGELINEWIDTH=1.0 * fact, edgestrokec=shadowc, kwd...)

    pl1 = gplot(gunder, locs_x, locs_y;
        NODESIZE=0.0, EDGELINEWIDTH=0.2*fact, edgestrokec=stringc)
        
    pl2 = gplot(gover, locs_x, locs_y;
        NODELABELSIZE=0.0, NODESIZE=0.0, nodefillc=shadowc, EDGELINEWIDTH=1.0*fact, edgestrokec=shadowc)

    pl3 = gplot(gover, locs_x, locs_y;
        EDGELINEWIDTH=0.2*fact, edgestrokec=stringc,
        NODESIZE=[i ∈ vfixed ? 0.00 : (crossings ? 0.002 : 0.0) for i in 1:nv(g)],
        nodefillc=[i ∈ vfixed ? colorant"red" : stringc for i in 1:nv(g)],
        NODELABELSIZE=0.0, nodelabel=nothing, nodelabeldist=9, 
        nodelabelc
        )
    
    oldl = length(locs_x)
    for i=1:2:lastindex(vfixed)
        push!(locs_x, (locs_x[vfixed[i]]+locs_x[vfixed[i+1]])/2)
        push!(locs_y, (locs_y[vfixed[i]]+locs_y[vfixed[i+1]])/2)
        push!(vlabels, vlabels[vfixed[i]]*vlabels[vfixed[i+1]])
        add_vertex!(g)
    end

    pl4 = gplot(g, locs_x, locs_y; 
        NODESIZE=[(i ≤ oldl ? 0.0 : 0.008) for i=1:length(locs_x)], 
        nodelabel=labels ? [(i ≤ oldl ? "" : vlabels[i]) for i=1:nv(g)] : nothing,
        EDGELINEWIDTH=0,
        nodefillc=colorant"red",
        nodelabeldist=9,
        nodelabelc,
        NODELABELSIZE=2.0)
    
    set_default_graphic_size(extr...)

    compose(pl4,pl3,pl2,pl1,pl0)
    #compose(pl2)
end
