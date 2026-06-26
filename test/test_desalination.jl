using Test
using Desal
using ForwardDiff
using FiniteDiff

@testset "Static desalination outputs" begin
    design = DesignStruct(
        name = "SWRO",
        capacity_m3_per_h = 100.0,
        specific_energy_nominal_kwh_per_m3 = 3.5,
        recovery_ratio_nominal = 0.45,
        min_load = 0.2,
        max_load = 1.0,
        ramp_rate_fraction_per_hour = 10.0,
        response_time_hours = 0.0,
        feed_salinity_g_per_l = 35.0,
        nominal_salinity_g_per_l = 35.0,
        feed_temperature_c = 25.0,
        nominal_temperature_c = 25.0,
        part_load_penalty = 0.2,
        recovery_part_load_sensitivity = 0.1,
        min_recovery_ratio = 0.2,
        max_recovery_ratio = 0.65,
    )

    op = OperationStruct(static = true, power_input_mw = 0.175, duration_hours = 2.0)
    out = Desalinate(design, op)

    @test isapprox(out.power_requested_mw, 0.175)
    @test isapprox(out.power_used_mw, 0.175)
    @test isapprox(out.capacity_utilization, 0.5)
    @test isapprox(out.recovery_ratio, 0.4275; atol = 1e-6)
    @test isapprox(out.specific_energy_kwh_per_m3, 3.6986899563318785; atol = 1e-9)
    @test isapprox(out.water_output_m3_per_h, 47.314049586776854; atol = 1e-9)
    @test isapprox(out.brine_output_m3_per_h, 63.362089797496495; atol = 1e-9)
    @test isapprox(out.power_used_mwh, 0.35)
    @test isapprox(out.water_output_m3, 94.62809917355371; atol = 1e-9)
    @test isapprox(out.brine_output_m3, 126.72417959499299; atol = 1e-9)
    @test out.osmotic_pressure_bar > 0

    op_low = OperationStruct(static = true, power_input_mw = 0.01, duration_hours = 1.0)
    out_low = Desalinate(design, op_low)
    @test out_low.power_used_mw == 0.0
    @test out_low.water_output_m3_per_h == 0.0
    @test out_low.brine_output_m3_per_h == 0.0
end

@testset "Dynamic desalination outputs" begin
    design = DesignStruct(
        name = "SWRO",
        capacity_m3_per_h = 100.0,
        specific_energy_nominal_kwh_per_m3 = 3.0,
        recovery_ratio_nominal = 0.45,
        min_load = 0.0,
        max_load = 1.0,
        ramp_rate_fraction_per_hour = 0.5,
        response_time_hours = 0.0,
        feed_salinity_g_per_l = 35.0,
        nominal_salinity_g_per_l = 35.0,
        feed_temperature_c = 25.0,
        nominal_temperature_c = 25.0,
        part_load_penalty = 0.0,
        recovery_part_load_sensitivity = 0.0,
        min_recovery_ratio = 0.2,
        max_recovery_ratio = 0.65,
    )

    time_hours = [1.0, 1.0, 1.0]
    op = OperationStruct(
        static = false,
        power_input_mw = [0.3, 0.3, 0.0],
        initial_power_mw = 0.0,
    )
    out = Desalinate(time_hours, design, op)

    @test all(isapprox.(out.power_used_mw, [0.15, 0.3, 0.15]))
    @test all(isapprox.(out.capacity_utilization, [0.5, 1.0, 0.5]))
    @test all(isapprox.(out.water_output_m3_per_h, [50.0, 100.0, 50.0]))
    @test all(isapprox.(out.recovery_ratio, [0.45, 0.45, 0.45]))
    @test out.total_power_used_mwh == 0.6
    @test isapprox(out.total_water_output_m3, 200.0)
    @test isapprox(out.total_brine_output_m3, 244.44444444444446)
    @test isapprox(out.average_specific_energy_kwh_per_m3, 3.0)
    @test isapprox(out.average_recovery_ratio, 0.45)
    @test isapprox(out.average_utilization, 2 / 3)
end

@testset "Salinity sensitivity" begin
    base_design = DesignStruct(
        name = "SWRO",
        capacity_m3_per_h = 100.0,
        specific_energy_nominal_kwh_per_m3 = 3.0,
        recovery_ratio_nominal = 0.45,
        min_load = 0.0,
        max_load = 1.0,
        ramp_rate_fraction_per_hour = 1.0,
        response_time_hours = 0.0,
        feed_salinity_g_per_l = 35.0,
        nominal_salinity_g_per_l = 35.0,
        feed_temperature_c = 25.0,
        nominal_temperature_c = 25.0,
        part_load_penalty = 0.0,
        recovery_part_load_sensitivity = 0.0,
        min_recovery_ratio = 0.2,
        max_recovery_ratio = 0.65,
    )

    high_sal_design = DesignStruct(
        name = "HighSalinity",
        capacity_m3_per_h = 100.0,
        specific_energy_nominal_kwh_per_m3 = 3.0,
        recovery_ratio_nominal = 0.45,
        min_load = 0.0,
        max_load = 1.0,
        ramp_rate_fraction_per_hour = 1.0,
        response_time_hours = 0.0,
        feed_salinity_g_per_l = 70.0,
        nominal_salinity_g_per_l = 35.0,
        feed_temperature_c = 25.0,
        nominal_temperature_c = 25.0,
        part_load_penalty = 0.0,
        recovery_part_load_sensitivity = 0.0,
        min_recovery_ratio = 0.2,
        max_recovery_ratio = 0.65,
    )

    op = OperationStruct(static = true, power_input_mw = 0.3, duration_hours = 1.0)
    base = Desalinate(base_design, op)
    high = Desalinate(high_sal_design, op)

    @test high.specific_energy_kwh_per_m3 > base.specific_energy_kwh_per_m3
    @test high.water_output_m3_per_h < base.water_output_m3_per_h
end


@testset "Static desalination AD vs FD" begin
    design = DesignStruct(
        name = "SWRO",
        capacity_m3_per_h = 100.0,
        specific_energy_nominal_kwh_per_m3 = 3.5,
        recovery_ratio_nominal = 0.45,
        min_load = 0.2,
        max_load = 1.0,
        ramp_rate_fraction_per_hour = 10.0,
        response_time_hours = 0.0,
        feed_salinity_g_per_l = 35.0,
        nominal_salinity_g_per_l = 35.0,
        feed_temperature_c = 25.0,
        nominal_temperature_c = 25.0,
        part_load_penalty = 0.2,
        recovery_part_load_sensitivity = 0.1,
        min_recovery_ratio = 0.2,
        max_recovery_ratio = 0.65,
    )

    water_output(power_input_mw) = Desalinate(design, OperationStruct(static = true, power_input_mw = power_input_mw, duration_hours = 1.0)).water_output_m3_per_h

    d_ad = ForwardDiff.derivative(water_output, 0.175)
    d_fd = FiniteDiff.finite_difference_derivative(water_output, 0.175, Val(:central))
    @test isfinite(d_ad)
    @test isfinite(d_fd)
    @test isapprox(d_ad, d_fd; rtol = 1e-7, atol = 1e-9)
end

@testset "Argument validation" begin
    @test_throws ArgumentError DesignStruct(
        name = "invalid",
        capacity_m3_per_h = -1.0,
        specific_energy_nominal_kwh_per_m3 = 3.0,
    )

    design = DesignStruct(
        name = "SWRO",
        capacity_m3_per_h = 100.0,
        specific_energy_nominal_kwh_per_m3 = 3.0,
    )

    op_static = OperationStruct(static = true, power_input_mw = 0.2, duration_hours = 1.0)
    @test_throws ArgumentError Desalinate([1.0, 1.0], design, op_static)

    op_dynamic = OperationStruct(static = false, power_input_mw = [0.2, 0.2])
    @test_throws ArgumentError Desalinate([1.0], design, op_dynamic)

    @test_throws ArgumentError OperationStruct(static = false, power_input_mw = 0.2)
end
