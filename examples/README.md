# Running examples

`examples/desalination.jl` is the main dynamic RO walkthrough and the Literate source
used to generate docs. `examples/small_scale_desalination.jl` demonstrates strict ON/OFF
small-scale behavior using model settings (`min_load = max_load = 1.0`).

Run it from a Julia REPL with:

```julia
using Pkg
using Desal

exdir = joinpath(pkgdir(Desal), "examples")
Pkg.activate(exdir)
Pkg.develop(Pkg.PackageSpec(path = dirname(exdir)))
Pkg.instantiate()
using Plots
include(joinpath(exdir, "desalination.jl"))
include(joinpath(exdir, "small_scale_desalination.jl"))
```

- `desalination.jl` writes `docs/src/generated/desalination_dynamic_profile.svg`.
- `small_scale_desalination.jl` writes `small_scale_on_off_profile.svg`.
