"""
    Desalinate(design::DesignStruct, operation::OperationStruct)

Run a static reverse-osmosis desalination calculation. The operation must have `static=true`.
"""
function Desalinate(design::DesignStruct, operation::OperationStruct)
    operation.static || throw(ArgumentError("static Desalinate expects operation.static = true"))

    T = promote_type(typeof(design.capacity_m3_per_h), typeof(operation.power_input_mw), typeof(operation.duration_hours))
    power_requested = convert(T, operation.power_input_mw)
    power_used = _target_power(design, power_requested)

    water, brine, sec, recovery, utilization, osmotic = _compute_step_outputs(design, power_used)

    power_used_mwh = power_used * operation.duration_hours
    water_output_m3 = water * operation.duration_hours
    brine_output_m3 = brine * operation.duration_hours

    return StaticOutputs(
        power_requested,
        power_used,
        water,
        brine,
        sec,
        recovery,
        utilization,
        osmotic,
        power_used_mwh,
        water_output_m3,
        brine_output_m3,
    )
end

"""
    Desalinate(time_hours, design::DesignStruct, operation::OperationStruct)

Run a dynamic reverse-osmosis desalination calculation. The operation must have `static=false`.
`time_hours` is a vector of durations for each step.
"""
function Desalinate(
    time_hours::AbstractVector{<:Real},
    design::DesignStruct,
    operation::OperationStruct,
)
    operation.static && throw(ArgumentError("dynamic Desalinate expects operation.static = false"))
    power_req = operation.power_input_mw
    power_req isa AbstractVector{<:Real} ||
        throw(ArgumentError("dynamic Desalinate expects power_input_mw to be a vector"))
    length(time_hours) == length(power_req) ||
        throw(ArgumentError("time_hours and power_input_mw must have the same length"))

    T = promote_type(typeof(design.capacity_m3_per_h), eltype(time_hours), eltype(power_req), typeof(operation.initial_power_mw))
    time = collect(T.(time_hours))
    any(t -> t <= zero(T), time) && throw(ArgumentError("time_hours must be positive"))

    power_requested = collect(T.(power_req))
    n = length(power_requested)

    power_used = Vector{T}(undef, n)
    water_output = Vector{T}(undef, n)
    brine_output = Vector{T}(undef, n)
    sec = Vector{T}(undef, n)
    recovery = Vector{T}(undef, n)
    util = Vector{T}(undef, n)
    osmotic = Vector{T}(undef, n)

    prev_power_used = _target_power(design, convert(T, operation.initial_power_mw))

    for i in 1:n
        requested = power_requested[i]
        target = _target_power(design, requested)
        used = _advance_power(design, prev_power_used, target, time[i])

        power_used[i] = used
        water_output[i], brine_output[i], sec[i], recovery[i], util[i], osmotic[i] =
            _compute_step_outputs(design, used)

        prev_power_used = used
    end

    total_power_used = _time_weighted_sum(power_used, time)
    total_water_output = _time_weighted_sum(water_output, time)
    total_brine_output = _time_weighted_sum(brine_output, time)
    average_sec = total_water_output > zero(T) ? (total_power_used * T(1000.0)) / total_water_output : zero(T)
    average_recovery =
        (total_water_output + total_brine_output) > zero(T) ?
        total_water_output / (total_water_output + total_brine_output) : zero(T)
    average_util = _time_weighted_average(util, time)

    return DynamicOutputs(
        time,
        power_requested,
        power_used,
        water_output,
        brine_output,
        sec,
        recovery,
        util,
        osmotic,
        total_power_used,
        total_water_output,
        total_brine_output,
        average_sec,
        average_recovery,
        average_util,
    )
end

function _rated_power_mw(design::DesignStruct)
    return (design.capacity_m3_per_h * design.specific_energy_nominal_kwh_per_m3) / typeof(design.capacity_m3_per_h)(1000.0)
end

function _apply_load_bounds(design::DesignStruct, power_mw::T) where {T<:Real}
    rated = _rated_power_mw(design)
    cap_max = rated * design.max_load
    cap_min = rated * design.min_load

    bounded = clamp(power_mw, zero(T), cap_max)
    bounded < cap_min && return zero(T)
    return bounded
end

function _target_power(design::DesignStruct, power_requested::T) where {T<:Real}
    return _apply_load_bounds(design, power_requested)
end

function _advance_power(
    design::DesignStruct,
    previous_power_used::T,
    target_power::T,
    dt_hours::T,
) where {T<:Real}
    lagged_target = if design.response_time_hours > zero(design.response_time_hours)
        alpha = one(T) - exp(-dt_hours / design.response_time_hours)
        previous_power_used + alpha * (target_power - previous_power_used)
    else
        target_power
    end

    max_delta = _rated_power_mw(design) * design.ramp_rate_fraction_per_hour * dt_hours
    lower = max(previous_power_used - max_delta, zero(T))
    upper = previous_power_used + max_delta
    ramp_limited = clamp(lagged_target, lower, upper)

    return _apply_load_bounds(design, ramp_limited)
end

# Van't Hoff approximation (NaCl-equivalent): π = i * C * R * T.
function _osmotic_pressure_bar(salinity_g_per_l::T, temperature_c::T) where {T<:Real}
    molar_mass_nacl = T(58.44)
    vant_hoff_i = T(2.0)
    r_bar_l_per_mol_k = T(0.08314)
    temperature_k = temperature_c + T(273.15)
    molarity = salinity_g_per_l / molar_mass_nacl
    return vant_hoff_i * molarity * r_bar_l_per_mol_k * temperature_k
end

function _salinity_temperature_factor(design::DesignStruct)
    pi_feed = _osmotic_pressure_bar(design.feed_salinity_g_per_l, design.feed_temperature_c)
    pi_nominal = _osmotic_pressure_bar(design.nominal_salinity_g_per_l, design.nominal_temperature_c)

    pi_nominal <= zero(pi_nominal) && return (one(pi_nominal), pi_feed)
    return (pi_feed / pi_nominal, pi_feed)
end

function _recovery_ratio(design::DesignStruct, utilization::Real)
    T = promote_type(typeof(utilization), typeof(design.max_load))
    normalized_load = design.max_load > zero(design.max_load) ? clamp(utilization / design.max_load, zero(T), one(T)) : zero(T)
    reduction = design.recovery_part_load_sensitivity * (one(T) - normalized_load)
    raw = design.recovery_ratio_nominal * (one(T) - reduction)
    return clamp(raw, convert(T, design.min_recovery_ratio), convert(T, design.max_recovery_ratio))
end

function _specific_energy(
    design::DesignStruct,
    utilization::Real,
    recovery::Real,
    salinity_temperature_factor::Real,
)
    T = promote_type(typeof(utilization), typeof(recovery), typeof(salinity_temperature_factor), typeof(design.max_load))
    normalized_load = design.max_load > zero(design.max_load) ? clamp(utilization / design.max_load, zero(T), one(T)) : zero(T)
    part_load_factor = one(T) + design.part_load_penalty * (one(T) - normalized_load)

    denominator = max(one(T) - recovery, eps(T))
    nominal_denominator = max(one(T) - convert(T, design.recovery_ratio_nominal), eps(T))
    recovery_factor = nominal_denominator / denominator

    sec =
        convert(T, design.specific_energy_nominal_kwh_per_m3) *
        salinity_temperature_factor *
        part_load_factor *
        recovery_factor

    return max(sec, eps(T))
end

function _compute_step_outputs(design::DesignStruct, power_used_mw::T) where {T<:Real}
    salinity_temperature_factor, osmotic = _salinity_temperature_factor(design)
    osmotic_t = convert(T, osmotic)

    rated = _rated_power_mw(design)
    if power_used_mw <= zero(T) || rated <= zero(rated)
        return zero(T), zero(T), zero(T), zero(T), zero(T), osmotic_t
    end

    utilization = power_used_mw / rated
    recovery = _recovery_ratio(design, utilization)
    sec = _specific_energy(design, utilization, recovery, salinity_temperature_factor)

    water_output = (power_used_mw * T(1000.0)) / sec
    water_cap = design.capacity_m3_per_h * design.max_load
    if water_output > water_cap
        water_output = water_cap
        sec = (power_used_mw * T(1000.0)) / max(water_output, eps(T))
    end

    brine_output = recovery > zero(T) ? water_output * (one(T) - recovery) / recovery : zero(T)

    return water_output, brine_output, sec, recovery, utilization, osmotic_t
end

function _time_weighted_sum(
    values::AbstractVector{<:Real},
    weights::AbstractVector{<:Real},
)
    T = promote_type(eltype(values), eltype(weights))
    total = zero(T)
    for i in eachindex(values, weights)
        total += values[i] * weights[i]
    end
    return total
end

function _time_weighted_average(
    values::AbstractVector{<:Real},
    weights::AbstractVector{<:Real},
)
    T = promote_type(eltype(values), eltype(weights))
    total_w = zero(T)
    for w in weights
        total_w += w
    end
    total_w <= zero(T) && return zero(T)
    return _time_weighted_sum(values, weights) / total_w
end
