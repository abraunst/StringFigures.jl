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

function overpick(p::LinearSequence, n::SeqNode, under::Bool)


end