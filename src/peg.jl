struct PEGParseError <: Exception
    msg::String
end

Base.showerror(io::IO, e::PEGParseError) = print(io, e.msg)

function parsepeg(peg, s)
    try 
        parse_whole(peg, s)
    catch e
        if e isa Meta.ParseError
            rethrow(PEGParseError(e.msg))
        else
            rethrow(e)
        end
    end
end