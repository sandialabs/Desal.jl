# Desal

[![Tests](https://github.com/sandialabs/Desal.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/sandialabs/Desal.jl/actions/workflows/ci.yml)
[![Docs](https://github.com/sandialabs/Desal.jl/actions/workflows/documentation.yml/badge.svg?branch=master)](https://sandialabs.github.io/Desal.jl/dev/)
[![Coverage](https://codecov.io/gh/sandialabs/Desal.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/sandialabs/Desal.jl)

Documentation is hosted at [sandialabs.github.io/Desal.jl/dev/](https://sandialabs.github.io/Desal.jl/dev/).

`Desal` is a lightweight reverse-osmosis (RO) desalination simulation package with static and dynamic modes.
It is designed for fast studies of variable-power operation without optimization dependencies.

## Installation

`Desal` is distributed as an unregistered Julia package:

```julia
using Pkg
Pkg.add(url = "https://github.com/sandialabs/Desal.jl")
```

For local development from a checkout:

```julia
using Pkg
Pkg.develop(path = "/path/to/Desal.jl")
```

## Model scope

The package models:

- Power-limited RO production (`MW` input, `m^3/h` water output)
- Part-load operation with minimum load and maximum load bounds
- Dynamic response using first-order lag + ramp-rate limits
- Specific-energy scaling with salinity/temperature (via osmotic-pressure ratio), recovery, and part-load penalty

Core relationships:

- Rated electrical power: `P_rated = Q_nom * SEC_nom / 1000`
- Dynamic power tracking: first-order response (`response_time_hours`) with ramp limit (`ramp_rate_fraction_per_hour`)
- Water production: `Q = P_used * 1000 / SEC`

## Quick start

```julia
using Desal

design = DesignStruct(
    name = "SWRO",
    capacity_m3_per_h = 100.0,
    specific_energy_nominal_kwh_per_m3 = 3.2,
    recovery_ratio_nominal = 0.45,
    min_load = 0.2,
    max_load = 1.0,
    ramp_rate_fraction_per_hour = 0.8,
    response_time_hours = 0.1,
    feed_salinity_g_per_l = 35.0,
    nominal_salinity_g_per_l = 35.0,
    feed_temperature_c = 25.0,
    nominal_temperature_c = 25.0,
)

# Static operation
op_static = OperationStruct(static = true, power_input_mw = 0.25, duration_hours = 1.0)
static_out = Desalinate(design, op_static)

# Dynamic operation
time_hours = [1.0, 1.0, 1.0, 1.0]
op_dynamic = OperationStruct(static = false, power_input_mw = [0.1, 0.25, 0.3, 0.15])
dynamic_out = Desalinate(time_hours, design, op_dynamic)
```

## Literature basis

The parameterization and assumptions are aligned with peer-reviewed RO desalination literature:

- Voutchkov, N. (2018). *Energy use for membrane seawater desalination - current status and trends*. **Desalination, 431, 2-14**. https://doi.org/10.1016/j.desal.2017.10.033
- Mito, M. T., Ma, X., Albuflasa, H., & Davies, P. A. (2019). *Reverse osmosis (RO) membrane desalination driven by wind and solar photovoltaic (PV) energy: State of the art and challenges for large-scale implementation*. **Renewable and Sustainable Energy Reviews, 112, 669-685**. https://doi.org/10.1016/j.rser.2019.06.008
- Mito, M. T., Ma, X., Albuflasa, H., & Davies, P. A. (2022). *Variable operation of a renewable energy-driven reverse osmosis system using model predictive control and variable recovery: Towards large-scale implementation*. **Desalination, 532, 115715**. https://doi.org/10.1016/j.desal.2022.115715
- Ghaffour, N., Missimer, T. M., & Amy, G. L. (2013). *Technical review and evaluation of the economics of water desalination: Current and future challenges for better water supply sustainability*. **Desalination, 309, 197-207**. https://doi.org/10.1016/j.desal.2012.10.015
