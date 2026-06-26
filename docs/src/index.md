# Desal

`Desal` is a lightweight reverse-osmosis (RO) desalination dynamics package.
It supports static operating-point simulation and dynamic time-series simulation
for power-constrained RO systems.

## What this package models

- Plant load bounds (`min_load`, `max_load`)
- Dynamic tracking with first-order response (`response_time_hours`)
- Ramp-rate constraints (`ramp_rate_fraction_per_hour`)
- Salinity/temperature effects on specific energy (via osmotic-pressure scaling)
- Recovery and part-load effects on performance

## Getting started

```julia
using Desal

design = DesignStruct(
    name = "SWRO",
    capacity_m3_per_h = 100.0,
    specific_energy_nominal_kwh_per_m3 = 3.2,
    recovery_ratio_nominal = 0.45,
)

op_static = OperationStruct(static = true, power_input_mw = 0.25, duration_hours = 1.0)
static_out = Desalinate(design, op_static)
```

For full dynamic usage with plotting, see `Examples`.

## Documentation map

- `Theory`: model equations and assumptions.
- `API`: generated from docstrings via `@autodocs`.
- `Examples`: Literate walkthrough with dynamic profile plots.
- `References`: verified citation metadata used by the docs and README.
