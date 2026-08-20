using DoseFlow
using Test

@testset "DoseFlow.jl" begin
    @testset "Compounds" begin
        c = Compound(name="Aspirin", mw=180.16, logP=1.19, pKa=3.5, fu=0.5, CL_int=10.0)
        @test c.name == "Aspirin"
        @test c.mw == 180.16
    end

    @testset "Population & ICRP Data" begin
        # Assuming we are running tests from the package root
        pop = load_icrp89(joinpath(@__DIR__, "..", "data", "icrp89_adult_male.json"))
        @test pop.name == "ICRP-89 Adult Male"
        @test pop.body_weight == 73.0
        @test haskey(pop.compartments, "liver")
        @test pop.compartments["liver"].volume == 1.8
    end

    @testset "Simulation Engine" begin
        pop = load_icrp89(joinpath(@__DIR__, "..", "data", "icrp89_adult_male.json"))
        c = Compound(name="TestDrug", mw=200.0, logP=2.0, pKa=7.0, fu=0.8, CL_int=50.0)
        
        dose_mg = 100.0
        tspan = (0.0, 24.0) # 24 horas
        
        sol = run_simulation(pop, c, dose_mg, tspan)
        
        # Testar se o solver chegou ao fim com sucesso / Test if solver succeeded
        @test sol.t[end] == 24.0
        
        # Testar se a concentração final no sangue venoso diminuiu (metabolismo hepático) 
        # Test if final concentration in venous blood decreased (hepatic metabolism)
        u_final = sol.u[end]
        A_ven_final = u_final[1]
        @test A_ven_final < dose_mg
    end
end
