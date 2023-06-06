using LinearAlgebra, Graphs, GraphPlot, Colors, Compose


function tutte_embedding(g; vfixed=1:0, px=Float64[], py=Float64[])
    nfixed = length(vfixed)
    A = adjacency_matrix(g)
    @assert issymmetric(A)
    n = size(A, 1)
    A = Float64.(A)
    K = Diagonal(vec(sum(A; dims=2))) - A
    K[vfixed,:] .= 0
    K[vfixed,vfixed] = I(nfixed)
    c = fill(0.0, n, 2)
    c[vfixed,1] = px
    c[vfixed,2] = py
    v = K \ c
    v[:,1], v[:,2]
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

function graph(p::LinearSequence)
    n = depth(p)
    N = length(p)
    elist = [
        [Edge(index(p[i]), n + i) for i=1:N];
        [Edge(n + i, index(p[i + 1])) for i in 1:N]
    ]
    function idx2label(i)
        if i <= 5
            "L$i"
        elseif i <= 10
            "R$(i-5)"
        elseif i <= n
            "x$(i-10)"
        else
            ""
        end
    end
    vlabels = idx2label.(1:N+n)
    g = SimpleGraphFromIterator(elist)
    g, vlabels
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

"""
`plot(p::LinearSequence; rfact, k, randomize, labels, shadowc, kwd...)`

Plots `p` using Tutte embedding. Parallel edges are then separated by slightly translating them perpendicularly to the segment joining the two vertices.

* `k::Float64`:        Set `k>0` to relayout using a very small repulsive force (`0.0`).
* `rfact::Float64`:    Distance between parallel edges (`0.02`)
* `randomize::Bool`:   Slightly randomize positions (`false`) 
* `labels::Bool`:      Add labels to the plot (`true`)
* `shadowc::colorant`: Color of the string shadow (`colorant"black"`)
* `kwd...`:            Additional options for gplot (`(;)`)
"""
function plot(p::LinearSequence; rfact=0.02, k=0.0, randomize=false, 
            labels=true, shadowc = colorant"black", kwd...)
    g, vlabels = graph(p)
    N = depth(p)
    θ = [-π/2; 0.0:π/6:π/2]
    add_vertices!.((g,), N-nv(g))
    # fix position of frame nodes
    vfixed = 1:10
    px = [-0.5 .* cos.(θ); 0.5 .* cos.(θ) .+ 3]
    py = [       -sin.(θ);       -sin.(θ)     ]
    # find Tutte embeding
    locs_x, locs_y = tutte_embedding(g; vfixed, px, py);
    # move internal nodes a little bit
    if randomize
        locs_x[1:end] .+= randn.() * rfact
        locs_y[1:end] .+= randn.() * rfact
    end
    for i in eachindex(p)
        #(isframenode(p[i]) || isframenode(p[i+1])) && continue
        P1 = [locs_x[index(p[i+1])], locs_y[index(p[i+1])]]
        P2 = [locs_x[index(p[i+2])], locs_y[index(p[i+2])]]
        P3 = [locs_x[index(p[i  ])], locs_y[index(p[i  ])]]
        P4 = [locs_x[index(p[i-1])], locs_y[index(p[i-1])]]
        Q = (P1 + P3)/2
        locs_x[N + i] = Q[1]
        locs_y[N + i] = Q[2]
        P12 = (P1-P2)/norm(P1-P2)
        P34 = (P3-P4)/norm(P3-P4)
        P13 = (P1-P3)/norm(P1-P3)
        D = P12 + P34 - ((P12 + P34) ⋅ P13) * P13
        locs_x[N + i] += isnan(D[1]) ? 0.0 : D[1] * rfact 
        locs_y[N + i] += isnan(D[2]) ? 0.0 : D[2] * rfact
    end
    if k > 0
        # find spring embedding with small repulsive forces
        locs_x, locs_y = spring_layout_fixed(g; vfixed, locs_x, locs_y, k)
    end
    pl0 = gplot(g, locs_x, locs_y;
        NODELABELSIZE=0.0, NODESIZE=0.0, EDGELINEWIDTH=0.8, edgestrokec=shadowc)
    underlist = [
        [Edge(index(p[i]), N + i) for i in eachindex(p) if p[i].type == :U];
        [Edge(N + i, index(p[i + 1])) for i in eachindex(p) if p[i+1].type == :U]
    ] 
    gunder = SimpleGraphFromIterator(underlist)
    pl1 = gplot(gunder, locs_x, locs_y; NODESIZE=0.0, EDGELINEWIDTH=0.2)
    
    overlist = [
        [Edge(index(p[i]), N + i) for i in eachindex(p) if p[i].type ∈ (:O,:L,:R)];
        [Edge(N + i, index(p[i + 1])) for i in eachindex(p) if p[i+1].type ∈ (:O,:L,:R)]
    ]
    
    gover = SimpleGraphFromIterator(overlist)
    add_vertices!(gover, nv(g)-nv(gover))
    pl2 = gplot(gover, locs_x, locs_y;
        NODELABELSIZE=0.0, NODESIZE=0.01, nodesize=[i < N ? 1.0 : 0.0 for i=1:nv(g)], 
        nodefillc=shadowc, EDGELINEWIDTH=1.0, edgestrokec=shadowc)

    pl3 = gplot(gover, locs_x, locs_y;
        EDGELINEWIDTH=0.2, edgestrokec=colorant"white",
        NODESIZE=0.005, nodesize=[i ≤ N ? 1.0 : 0.0 for i in 1:nv(g)],
        nodefillc=[i ∈ vfixed ? colorant"red" : colorant"white" for i in 1:nv(g)],
        NODELABELSIZE=2.0, nodelabel=labels ? vlabels : nothing, nodelabeldist=9, 
        nodelabelc=colorant"white", kwd...
        )

    compose(pl3,pl2,pl1,pl0)
end
