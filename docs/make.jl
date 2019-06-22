using Documenter, Rogue

makedocs(;
    modules=[Rogue],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/tkf/Rogue.jl/blob/{commit}{path}#L{line}",
    sitename="Rogue.jl",
    authors="Takafumi Arakaki <aka.tkf@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/tkf/Rogue.jl",
)
