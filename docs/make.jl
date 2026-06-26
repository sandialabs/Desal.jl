import Pkg
Pkg.activate(@__DIR__)
Pkg.develop(Pkg.PackageSpec(path = joinpath(@__DIR__, "..")))
Pkg.instantiate()

using Documenter
using Desal
using Literate

DocMeta.setdocmeta!(
    Desal,
    :DocTestSetup,
    quote
        using Desal
        using Plots
    end;
    recursive = true,
)

generated_dir = joinpath(@__DIR__, "src", "generated")
mkpath(generated_dir)

Literate.markdown(
    joinpath(@__DIR__, "..", "examples", "desalination.jl"),
    generated_dir;
    name = "desalination_example",
    flavor = Literate.DocumenterFlavor(),
)

makedocs(
    sitename = "Desal",
    modules = [Desal],
    remotes = nothing,
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        edit_link = "main",
        repolink = "https://github.com/EnergyModelsX/Desal.jl",
        assets = String[],
        ansicolor = true,
    ),
    pages = [
        "Home" => "index.md",
        "Quick Start" => "quickstart.md",
        "Theory" => "theory.md",
        "API" => "api.md",
        "Examples" => [
            "Overview" => "examples.md",
            "Dynamic RO Walkthrough" => "generated/desalination_example.md",
        ],
        "References" => "references.md",
    ],
)

if get(ENV, "CI", "false") == "true"
    deploydocs(; repo = "github.com/EnergyModelsX/Desal.jl.git", devbranch = "main")
end
