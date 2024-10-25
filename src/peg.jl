struct PEGError
    msg::String
end

Base.showerror(io::IO, e::PEGError) = print(io, e.msg)

function parsepeg(peg, s)
    try 
        parse_whole(peg, s)
    catch e
        if e isa Meta.ParseError
            rethrow(Meta.ParseError(e.msg, PEGError(e.msg)))
        else
            rethrow(e)
        end
    end
end