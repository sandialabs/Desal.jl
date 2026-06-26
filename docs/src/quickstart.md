# Quick Start

`Desal` models reverse-osmosis desalination as a power-constrained production
subsystem. It supports static operating points and dynamic time histories.

```julia
using Desal

design = DesignStruct(
    name = "SWRO",
    capacity_m3_per_h = 100.0,
    specific_energy_nominal_kwh_per_m3 = 3.2,
    recovery_ratio_nominal = 0.45,
)

op = OperationStruct(static = true, power_input_mw = 0.25, duration_hours = 1.0)
out = Desalinate(design, op)

out.water_produced_m3
out.power_used_mw
```

For dynamic studies, pass `static = false`, a power vector, and a matching time
vector. SIRENOpt uses this boundary as the potable-water load/storage interface:
input power, elapsed time, produced water, curtailed/requested power, and plant
state are the quantities that should remain stable as fidelity increases.
