module StringFigures

include("stringposition.jl")
include("embedding.jl")

export StringPosition, SeqNOde, release, isfarsidenext, isnearsidenext, 
        canonical, plot, @f_str, @n_str

end
