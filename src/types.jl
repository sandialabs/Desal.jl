"""
Design parameters for a reverse-osmosis desalination plant.

The defaults are aligned with typical seawater RO operation ranges reported in the
literature (e.g., specific energy around 2.5-4.5 kWh/m^3 and recovery around 35-50%).
"""
struct DesignStruct{T<:Real}
    name::String
    capacity_m3_per_h::T
    specific_energy_nominal_kwh_per_m3::T
    recovery_ratio_nominal::T
    min_load::T
    max_load::T
    ramp_rate_fraction_per_hour::T
    response_time_hours::T
    feed_salinity_g_per_l::T
    nominal_salinity_g_per_l::T
    feed_temperature_c::T
    nominal_temperature_c::T
    part_load_penalty::T
    recovery_part_load_sensitivity::T
    min_recovery_ratio::T
    max_recovery_ratio::T

    function DesignStruct(
        name::String,
        capacity_m3_per_h::Real,
        specific_energy_nominal_kwh_per_m3::Real,
        recovery_ratio_nominal::Real,
        min_load::Real,
        max_load::Real,
        ramp_rate_fraction_per_hour::Real,
        response_time_hours::Real,
        feed_salinity_g_per_l::Real,
        nominal_salinity_g_per_l::Real,
        feed_temperature_c::Real,
        nominal_temperature_c::Real,
        part_load_penalty::Real,
        recovery_part_load_sensitivity::Real,
        min_recovery_ratio::Real,
        max_recovery_ratio::Real,
    )
        T = promote_type(
            typeof(capacity_m3_per_h),
            typeof(specific_energy_nominal_kwh_per_m3),
            typeof(recovery_ratio_nominal),
            typeof(min_load),
            typeof(max_load),
            typeof(ramp_rate_fraction_per_hour),
            typeof(response_time_hours),
            typeof(feed_salinity_g_per_l),
            typeof(nominal_salinity_g_per_l),
            typeof(feed_temperature_c),
            typeof(nominal_temperature_c),
            typeof(part_load_penalty),
            typeof(recovery_part_load_sensitivity),
            typeof(min_recovery_ratio),
            typeof(max_recovery_ratio),
        )
        cap = convert(T, capacity_m3_per_h)
        sec = convert(T, specific_energy_nominal_kwh_per_m3)
        rec = convert(T, recovery_ratio_nominal)
        minl = convert(T, min_load)
        maxl = convert(T, max_load)
        ramp = convert(T, ramp_rate_fraction_per_hour)
        tau = convert(T, response_time_hours)
        feed_sal = convert(T, feed_salinity_g_per_l)
        nom_sal = convert(T, nominal_salinity_g_per_l)
        feed_temp = convert(T, feed_temperature_c)
        nom_temp = convert(T, nominal_temperature_c)
        pl_pen = convert(T, part_load_penalty)
        rec_sens = convert(T, recovery_part_load_sensitivity)
        min_rec = convert(T, min_recovery_ratio)
        max_rec = convert(T, max_recovery_ratio)

        _validate_design(
            cap,
            sec,
            rec,
            minl,
            maxl,
            ramp,
            tau,
            feed_sal,
            nom_sal,
            feed_temp,
            nom_temp,
            pl_pen,
            rec_sens,
            min_rec,
            max_rec,
        )

        return new{T}(
            name,
            cap,
            sec,
            rec,
            minl,
            maxl,
            ramp,
            tau,
            feed_sal,
            nom_sal,
            feed_temp,
            nom_temp,
            pl_pen,
            rec_sens,
            min_rec,
            max_rec,
        )
    end
end

DesignStruct(
    ;
    name = "SWRO",
    capacity_m3_per_h,
    specific_energy_nominal_kwh_per_m3,
    recovery_ratio_nominal = 0.45,
    min_load = 0.2,
    max_load = 1.0,
    ramp_rate_fraction_per_hour = 1.0,
    response_time_hours = 0.1,
    feed_salinity_g_per_l = 35.0,
    nominal_salinity_g_per_l = 35.0,
    feed_temperature_c = 25.0,
    nominal_temperature_c = 25.0,
    part_load_penalty = 0.2,
    recovery_part_load_sensitivity = 0.15,
    min_recovery_ratio = 0.1,
    max_recovery_ratio = 0.65,
) = DesignStruct(
    String(name),
    capacity_m3_per_h,
    specific_energy_nominal_kwh_per_m3,
    recovery_ratio_nominal,
    min_load,
    max_load,
    ramp_rate_fraction_per_hour,
    response_time_hours,
    feed_salinity_g_per_l,
    nominal_salinity_g_per_l,
    feed_temperature_c,
    nominal_temperature_c,
    part_load_penalty,
    recovery_part_load_sensitivity,
    min_recovery_ratio,
    max_recovery_ratio,
)

"""
Operational inputs for a desalination run.
"""
struct OperationStruct{T,U<:Real,V<:Real}
    static::Bool
    power_input_mw::T
    duration_hours::U
    initial_power_mw::V

    function OperationStruct(
        static::Bool,
        power_input_mw::T,
        duration_hours::Real,
        initial_power_mw::Real,
    ) where {T}
        U = typeof(duration_hours)
        V = typeof(initial_power_mw)
        dur = convert(U, duration_hours)
        p0 = convert(V, initial_power_mw)
        _validate_operation(static, power_input_mw, dur, p0)
        return new{T,U,V}(static, power_input_mw, dur, p0)
    end
end

OperationStruct(; static::Bool, power_input_mw, duration_hours = 1.0, initial_power_mw = 0.0) =
    OperationStruct(static, power_input_mw, duration_hours, initial_power_mw)

"""
Outputs for a static desalination calculation.
"""
struct StaticOutputs{T<:Real}
    power_requested_mw::T
    power_used_mw::T
    water_output_m3_per_h::T
    brine_output_m3_per_h::T
    specific_energy_kwh_per_m3::T
    recovery_ratio::T
    capacity_utilization::T
    osmotic_pressure_bar::T
    power_used_mwh::T
    water_output_m3::T
    brine_output_m3::T
end

"""
Outputs for a dynamic desalination calculation.
"""
struct DynamicOutputs{T<:Real}
    time_hours::Vector{T}
    power_requested_mw::Vector{T}
    power_used_mw::Vector{T}
    water_output_m3_per_h::Vector{T}
    brine_output_m3_per_h::Vector{T}
    specific_energy_kwh_per_m3::Vector{T}
    recovery_ratio::Vector{T}
    capacity_utilization::Vector{T}
    osmotic_pressure_bar::Vector{T}
    total_power_used_mwh::T
    total_water_output_m3::T
    total_brine_output_m3::T
    average_specific_energy_kwh_per_m3::T
    average_recovery_ratio::T
    average_utilization::T
end

function _validate_design(
    capacity_m3_per_h::T,
    specific_energy_nominal_kwh_per_m3::T,
    recovery_ratio_nominal::T,
    min_load::T,
    max_load::T,
    ramp_rate_fraction_per_hour::T,
    response_time_hours::T,
    feed_salinity_g_per_l::T,
    nominal_salinity_g_per_l::T,
    feed_temperature_c::T,
    nominal_temperature_c::T,
    part_load_penalty::T,
    recovery_part_load_sensitivity::T,
    min_recovery_ratio::T,
    max_recovery_ratio::T,
) where {T<:Real}
    capacity_m3_per_h <= zero(T) && throw(ArgumentError("capacity_m3_per_h must be positive"))
    specific_energy_nominal_kwh_per_m3 <= zero(T) &&
        throw(ArgumentError("specific_energy_nominal_kwh_per_m3 must be positive"))
    (recovery_ratio_nominal <= zero(T) || recovery_ratio_nominal >= one(T)) &&
        throw(ArgumentError("recovery_ratio_nominal must be within (0, 1)"))

    min_load < zero(T) && throw(ArgumentError("min_load must be non-negative"))
    max_load < min_load && throw(ArgumentError("max_load must be >= min_load"))
    max_load > one(T) && throw(ArgumentError("max_load must be <= 1"))

    ramp_rate_fraction_per_hour <= zero(T) &&
        throw(ArgumentError("ramp_rate_fraction_per_hour must be positive"))
    response_time_hours < zero(T) && throw(ArgumentError("response_time_hours must be non-negative"))

    feed_salinity_g_per_l < zero(T) && throw(ArgumentError("feed_salinity_g_per_l must be non-negative"))
    nominal_salinity_g_per_l <= zero(T) &&
        throw(ArgumentError("nominal_salinity_g_per_l must be positive"))

    feed_temperature_c <= T(-273.15) &&
        throw(ArgumentError("feed_temperature_c must be greater than absolute zero"))
    nominal_temperature_c <= T(-273.15) &&
        throw(ArgumentError("nominal_temperature_c must be greater than absolute zero"))

    part_load_penalty < zero(T) && throw(ArgumentError("part_load_penalty must be non-negative"))
    recovery_part_load_sensitivity < zero(T) &&
        throw(ArgumentError("recovery_part_load_sensitivity must be non-negative"))

    (min_recovery_ratio <= zero(T) || min_recovery_ratio >= one(T)) &&
        throw(ArgumentError("min_recovery_ratio must be within (0, 1)"))
    (max_recovery_ratio <= zero(T) || max_recovery_ratio >= one(T)) &&
        throw(ArgumentError("max_recovery_ratio must be within (0, 1)"))
    max_recovery_ratio < min_recovery_ratio &&
        throw(ArgumentError("max_recovery_ratio must be >= min_recovery_ratio"))
    recovery_ratio_nominal < min_recovery_ratio &&
        throw(ArgumentError("recovery_ratio_nominal must be >= min_recovery_ratio"))
    recovery_ratio_nominal > max_recovery_ratio &&
        throw(ArgumentError("recovery_ratio_nominal must be <= max_recovery_ratio"))

    return nothing
end

function _validate_operation(
    static::Bool,
    power_input_mw,
    duration_hours::U,
    initial_power_mw::V,
) where {U<:Real,V<:Real}
    duration_hours <= zero(U) && throw(ArgumentError("duration_hours must be positive"))
    initial_power_mw < zero(V) && throw(ArgumentError("initial_power_mw must be non-negative"))
    if static
        power_input_mw isa Real || throw(ArgumentError("static OperationStruct expects power_input_mw::Real"))
    else
        power_input_mw isa AbstractVector{<:Real} ||
            throw(ArgumentError("dynamic OperationStruct expects power_input_mw to be a vector"))
    end
    return nothing
end
