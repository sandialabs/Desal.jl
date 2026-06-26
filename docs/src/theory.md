# Theory

This page documents the simplified RO dynamics implemented in `Desal`.

## 1. Rated power and load bounds

Let:

- `Q_nom` be nominal product-water capacity (`capacity_m3_per_h`)
- `SEC_nom` be nominal specific energy (`specific_energy_nominal_kwh_per_m3`)

Then rated electric power is:

`P_rated = Q_nom * SEC_nom / 1000`

Requested power is clipped by load limits and minimum stable operation:

- `P_max = P_rated * max_load`
- `P_min = P_rated * min_load`
- if `0 < P < P_min`, operation is set to zero.

## 2. Dynamic power tracking

For dynamic runs, requested setpoints are converted to bounded targets and then passed through:

- first-order lag (time constant `response_time_hours`)
- explicit ramp-rate limit (`ramp_rate_fraction_per_hour` of rated power)

The implementation uses an exponential first-order discrete update and then clamps
step changes with a symmetric ramp bound.

## 3. Salinity and temperature effect

The model uses a van't Hoff osmotic-pressure approximation for NaCl-equivalent salinity:

`π = i * C * R * T`

with `i = 2`, `C` from salinity, and `R = 0.08314 bar·L/(mol·K)`.
A salinity-temperature correction factor is defined as `π_feed / π_nominal`.

## 4. Recovery and part-load adjustments

Recovery is reduced at part load with a linear sensitivity:

`recovery = clamp(recovery_nominal * (1 - s * (1 - load_norm)), min_recovery, max_recovery)`

where `s` is `recovery_part_load_sensitivity`.

Specific energy scales with:

- salinity-temperature factor
- part-load penalty
- recovery deviation from nominal

This gives a compact dynamic model for scenario analysis and control-oriented studies.

## 5. Output relationships

For each time step:

- `Q_water = P_used * 1000 / SEC`
- `Q_brine = Q_water * (1 - recovery) / recovery`

Time-integrated totals are computed as duration-weighted sums.

## 6. Intended use

The model is intentionally low-order and suitable for:

- variable renewable coupling studies
- operational sensitivity analyses
- preliminary control prototyping

It is not a membrane-physics replacement for high-fidelity design tools.

For citation metadata used by these assumptions, see `References`.
