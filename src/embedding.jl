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


# Copied and modified from GraphLayout.jl
function spring_layout_fixed(g::AbstractGraph;
        locs_x = 2 .* rand(nv(g)) .- 1.0,
        locs_y = 2 .* rand(nv(g)) .- 1.0,
        vfixed = 1:0,
        C = 2.0,
        k = C * sqrt(4.0 / nv(g)),
        MAXITER = 100,
        INITTEMP = 2.0)

    adj_matrix = adjacency_matrix(g)

    # The optimal distance bewteen vertices
    k² = k^2

    # Store forces and apply at end of iteration all at once
    force_x = zeros(nv(g))
    force_y = zeros(nv(g))

    # Iterate MAXITER times
    for iter = 1:MAXITER
    # Calculate forces
        for i = 1:nv(g)
            force_vec_x = 0.0
            force_vec_y = 0.0
            for j = 1:nv(g)
                i == j && continue
                d_x = locs_x[j] - locs_x[i]
                d_y = locs_y[j] - locs_y[i]
                dist²  = d_x^2 + d_y^2
                dist = sqrt(dist²)

                if !(iszero(adj_matrix[i,j]) && iszero(adj_matrix[j,i]))
                    # Attractive + repulsive force
                    # F_d = dist² / k - k² / dist # original FR algorithm
                    F_d = dist / k - k² / dist²
                else
                    # Just repulsive
                    # F_d = -k² / dist  # original FR algorithm
                    F_d = -k² / dist²
                end
                force_vec_x += F_d*d_x
                force_vec_y += F_d*d_y
            end
            force_x[i] = force_vec_x
            force_y[i] = force_vec_y
        end
        # Cool down
        temp = INITTEMP / iter
        # Now apply them, but limit to temperature
        for i in 1:nv(g)
            i ∈ vfixed && continue
            force_mag  = sqrt(force_x[i]^2 + force_y[i]^2)
            scale      = min(force_mag, temp) / force_mag
            locs_x[i] += force_x[i] * scale
            locs_y[i] += force_y[i] * scale
        end
    end
    return locs_x, locs_y
end


function node_labels_and_fixed_positions(p::LinearSequence; crossings=true)
    D = Dict{SeqNode, Int}()
    function pos(n)
        id,l = idx(n)
        θ = [-π/4; 0.0:π/12:π/4]
        if type(n) == :L
            SVector(-0.5*cos(θ[id]+l*π/36), -sin(θ[id]+l*π/36))
        else
            SVector(0.5*cos(θ[id]+l*π/36) + 3, -sin(θ[id]+l*π/36))
        end
    end

    i = 0
    vfixed = Int[]
    pfixed = fill(SVector(0.,0.), 0)
    vlabels = String[]
    #io = IOBuffer()
    #ioc = IOContext(io, :linseq => p)

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

* `k::Float64`:        Set `k>0` to relayout using a very small repulsive force (`0.0`).
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
function plot(p::LinearSequence; rfact=0.02, k=0.0, randomize=false, crossings=false,
            labels=true, shadowc = HSLA(colorant"black", 1.0), stringc=colorant"white", fact=1.0, 
            nodelabelc=colorant"white", kwd...)
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
        locs_x[n + i] += D[1] * rfact 
        locs_y[n + i] += D[2] * rfact
    end 

    if k > 0
        # find spring embedding with small repulsive forces
        locs_x, locs_y = spring_layout_fixed(g; vfixed, locs_x, locs_y, k)
    end
    
    pl0 = gplot(g, locs_x, locs_y;
        NODELABELSIZE=0.0, NODESIZE=0.0, EDGELINEWIDTH=1.0 * fact, edgestrokec=shadowc, kwd...)

    pl1 = gplot(gunder, locs_x, locs_y;
        NODESIZE=0.0, EDGELINEWIDTH=0.2*fact, edgestrokec=stringc)
        
    pl2 = gplot(gover, locs_x, locs_y;
        NODELABELSIZE=0.0, NODESIZE=0.0, nodefillc=shadowc, EDGELINEWIDTH=1.0*fact, edgestrokec=shadowc)

    pl3 = gplot(gover, locs_x, locs_y;
        EDGELINEWIDTH=0.2*fact, edgestrokec=stringc,
        NODESIZE=[i ∈ vfixed ? 0.008 : (crossings ? 0.002 : 0.0) for i in 1:nv(g)],
        nodefillc=[i ∈ vfixed ? colorant"red" : stringc for i in 1:nv(g)],
        NODELABELSIZE=2.0, nodelabel=labels ? @view(vlabels[1:nv(gover)]) : nothing, nodelabeldist=9, 
        nodelabelc
        )

    compose(pl3,pl2,pl1,pl0)
    #compose(pl2)
end
