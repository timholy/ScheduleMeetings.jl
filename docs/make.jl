using ScheduleMeetings
using Documenter

DocMeta.setdocmeta!(ScheduleMeetings, :DocTestSetup, :(using ScheduleMeetings); recursive=true)

makedocs(;
    modules=[ScheduleMeetings],
    authors="Tim Holy <tim.holy@gmail.com> and contributors",
    repo="https://github.com/timholy/ScheduleMeetings.jl/blob/{commit}{path}#{line}",
    sitename="ScheduleMeetings.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://timholy.github.io/ScheduleMeetings.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/timholy/ScheduleMeetings.jl",
    devbranch="main",
)
