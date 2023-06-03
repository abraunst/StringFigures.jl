using LinearAlgebra, Graphs, GraphPlot, Colors


function tutte_embedding(g; vfixed=1:10,
        px = [-0.5 .* cos.([-π/2; 0.0:π/6:π/2]); 0.5 .* cos.([-π/2; 0.0:π/6:π/2]) .+ 3],
        py = -[sin.([-π/2; 0.0:π/6:π/2]); sin.([-π/2; 0.0:π/6:π/2])])
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

function lin2gauss(linseq)
    function idx(s)
        m = match(r"L(\d+)",s)
        !isnothing(m) && return parse(Int, m[1])
        m = match(r"R(\d+)",s)
        !isnothing(m) && return 11-parse(Int, m[1])
        m = match(r"x(\d+)\(([0U])[\)J]",s)
        !isnothing(m) && return (10+parse(Int, m[1])) * (m[2] == "U" ? 1 : -1)
    end
    labels = split(replace(linseq, " " => "", "{" => "(", "l" => "1", ";" => ":"), ":")
    idx.(labels)
end

function graph(p::LinearSequence)
    n = depth(p)
    N = length(p)
    elist = [
        [Edge(index(p.seq[i]), n + i) for i=1:N];
        [Edge(n + i, index(p.seq[mod1(i + 1, N)])) for i in 1:N]
    ]
    #elist = [(abs(gauss[i]), abs(gauss[mod1(i + 1, N)])) for i in 1:N]
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

function gauss_to_graph(gauss)
    n = maximum(abs, gauss)
    N = length(gauss)
    elist = [
        [Edge(abs(gauss[i]), n + i) for i in 1:N]; 
        [Edge(n + i, abs(gauss[mod1(i + 1, N)])) for i in 1:N]
    ]
    #elist = [(abs(gauss[i]), abs(gauss[mod1(i + 1, N)])) for i in 1:N]
    function idx2label(i)
        if i <= 5
            "L$i"
        elseif i <= 10
            "R$(11-i)"
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

function spring_layout(g::AbstractGraph;
        locs_x = 2 .* rand(nv(g)) .- 1.0,
        locs_y = 2 .* rand(nv(g)) .- 1.0,
        fixed = 1:0,
        C = 2.0,
        k = C * sqrt(4.0 / nvg),
        MAXITER = 100,
        INITTEMP = 2.0)

    nvg = nv(g)
    adj_matrix = adjacency_matrix(g)

    # The optimal distance bewteen vertices
    k² = k^2

    # Store forces and apply at end of iteration all at once
    force_x = zeros(nvg)
    force_y = zeros(nvg)

    # Iterate MAXITER times
    for iter = 1:MAXITER
    # Calculate forces
        for i = 1:nvg
            force_vec_x = 0.0
            force_vec_y = 0.0
            for j = 1:nvg
                i == j && continue
                d_x = locs_x[j] - locs_x[i]
                d_y = locs_y[j] - locs_y[i]
                dist²  = d_x^2 + d_y^2
                dist = sqrt(dist²)

                if !( iszero(adj_matrix[i,j]) && iszero(adj_matrix[j,i]) )
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
        for i = 1:nvg
            i ∈ fixed && continue
            fx = force_x[i]
            fy = force_y[i]
            force_mag  = sqrt((fx * fx) + (fy * fy))
            scale      = min(force_mag, temp) / force_mag
            locs_x[i] += force_x[i] * scale
            locs_y[i] += force_y[i] * scale
        end
    end

    # Scale to unit square
    min_x, max_x = minimum(locs_x), maximum(locs_x)
    min_y, max_y = minimum(locs_y), maximum(locs_y)
    function scaler(z, a, b)
        2.0*((z - a)/(b - a)) - 1.0
    end
    map!(z -> scaler(z, min_x, max_x), locs_x, locs_x)
    map!(z -> scaler(z, min_y, max_y), locs_y, locs_y)

    return locs_x, locs_y
end


function plot_linear_seq(lin)
    vfixed = 1:10
    gauss = lin2gauss(lin)
    g, vlabels = gauss_to_graph(gauss)
    N = maximum(abs, gauss)
    add_vertices!.((g,), N-nv(g))
    px, py = tutte_embedding(g);
    px .+= rand.().*0.03
    py .+= rand.().*0.03
    px, py = spring_layout(g; fixed=1:10, locs_x = px, locs_y = py, k = 0.05)
    gplot(g, px, py, NODELABELSIZE=2.0, NODESIZE=0.005, nodelabel=vlabels, nodesize=[i ≤ N ? 1.0 : 0.0 for i in 1:nv(g)],
        nodefillc=[i ∈ vfixed ? colorant"red" : colorant"white" for i in 1:nv(g)],
        EDGELINEWIDTH=0.2, nodelabeldist=9, nodelabelc=colorant"white")
end


function plot(p::LinearSequence)
    vfixed = 1:10
    g, vlabels = graph(p)
    N = depth(p)
    add_vertices!.((g,), N-nv(g))
    px, py = tutte_embedding(g);
    px .+= randn.().*0.03
    py .+= randn.().*0.03
    px, py = spring_layout(g; fixed=1:10, locs_x = px, locs_y = py, k = 0.05)
    gplot(g, px, py, NODELABELSIZE=2.0, NODESIZE=0.005, nodelabel=vlabels, nodesize=[i ≤ N ? 1.0 : 0.0 for i in 1:nv(g)],
        nodefillc=[i ∈ vfixed ? colorant"red" : colorant"white" for i in 1:nv(g)],
        EDGELINEWIDTH=0.2, nodelabeldist=9, nodelabelc=colorant"white")
end
