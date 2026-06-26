using Desal
ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")
using Plots

# Small-scale unit configured for strict ON/OFF operation with the current model:
# - min_load = max_load = 1.0 enforces either 0 MW or full rated MW.
# - response_time_hours = 0.0 removes first-order lag.
# - high ramp rate allows near-instant transitions between steps.
design = DesignStruct(
    name = "Small Scale ON/OFF",
    capacity_m3_per_h = 5.0,
    specific_energy_nominal_kwh_per_m3 = 4.0,
    recovery_ratio_nominal = 0.35,
    min_load = 1.0,
    max_load = 1.0,
    ramp_rate_fraction_per_hour = 100.0,
    response_time_hours = 0.0,
    feed_salinity_g_per_l = 2.0,
    nominal_salinity_g_per_l = 2.0,
    feed_temperature_c = 25.0,
    nominal_temperature_c = 25.0,
    part_load_penalty = 0.0,
    recovery_part_load_sensitivity = 0.0,
    min_recovery_ratio = 0.2,
    max_recovery_ratio = 0.65,
)

rated_power_mw = design.capacity_m3_per_h * design.specific_energy_nominal_kwh_per_m3 / 1000.0
println("Rated power (MW): ", rated_power_mw)

# Any request below rated power becomes OFF (0 MW).
# Any request at/above rated power becomes ON (rated MW).
time_hours = fill(0.25, 16)
power_profile_mw = [
    0.0,
    0.01,
    rated_power_mw,
    0.5 * rated_power_mw,
    1.2 * rated_power_mw,
    0.0,
    rated_power_mw,
    rated_power_mw,
    0.0,
    0.0,
    1.5 * rated_power_mw,
    rated_power_mw,
    0.2 * rated_power_mw,
    rated_power_mw,
    0.0,
    rated_power_mw,
]

op = OperationStruct(
    static = false,
    power_input_mw = power_profile_mw,
    initial_power_mw = 0.0,
)
out = Desalinate(time_hours, design, op)

println("\nRequested power (MW):")
println(out.power_requested_mw)
println("Used power (MW):")
println(out.power_used_mw)
println("Water output (m^3/h):")
println(out.water_output_m3_per_h)

t = cumsum(time_hours)

p1 = plot(
    t,
    out.power_requested_mw;
    seriestype = :steppost,
    lw = 2.5,
    label = "Requested power",
    xlabel = "Time (h)",
    ylabel = "MW",
    title = "ON/OFF power behavior",
)
plot!(p1, t, out.power_used_mw; seriestype = :steppost, lw = 2.5, label = "Used power")
hline!(p1, [rated_power_mw]; ls = :dash, color = :black, label = "Rated power")

p2 = plot(
    t,
    out.water_output_m3_per_h;
    seriestype = :steppost,
    lw = 2.5,
    label = "Water output",
    xlabel = "Time (h)",
    ylabel = "m^3/h",
    title = "ON/OFF production behavior",
)

p = plot(p1, p2; layout = (2, 1), size = (1000, 750))
savefig(p, "small_scale_on_off_profile.svg")
println("Saved plot to: " * abspath("small_scale_on_off_profile.svg"))
