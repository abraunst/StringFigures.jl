function release(p::LinearSequence, n::SeqNode)
    @assert isframe(n)
    p2 = LinearSequence(filter(!=(n), p.seq))
    canonical(p2)
end


function simplify(p::LinearSequence)
    p2 = p
    isadjacent(i,j) = mod(length(p) + j - i, length(p)) == 1

    while true
        p2 = canonical(p2)
        D1 = Dict{Int,Int}()
        D2 = Dict{Int,Int}()

        for (i,n) in pairs(p)
            if n.type == :O
                D1[n.idx] = i
            elseif n.type == :U
                D2[n.idx] = i
            end
        end
        rem = Int[]
        for (idx,i) in pairs(D1)
            idx ∈ rem && continue
            # lemma 2a
            if isadjacent(D2[idx], i) == 1
                push!(rem, idx)
            end
            # lemma 2b
            if idx > 1 && 
                isadjacent(i,       D1[idx-1]) &&
                isadjacent(D2[idx], D2[idx-1])
                push!(rem, idx)
                push!(rem, idx-1)
            end        
        end
        isempty(rem) && break
        deleteat!(p2, sort!(rem))
    end
    return p2
end

function overpick(p::LinearSequence, n::SeqNode, under::Bool)


end