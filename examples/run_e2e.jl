using DoseFlow

function main()
    println("--- DoseFlow E2E Test ---")
    println("Loading population data...")
    pop = load_icrp89(joinpath(@__DIR__, "..", "data", "icrp89_adult_male.json"))
    
    println("Creating compound (Aspirin)...")
    c = Compound(name="Aspirin_E2E", mw=180.16, logP=1.19, pKa=3.5, fu=0.5, CL_int=10.0, type=:acid)
    
    dose_mg = 100.0
    tspan = (0.0, 24.0)
    
    println("Running simulation for 24 hours...")
    sol = run_simulation(pop, c, dose_mg, tspan)
    
    out_file = "e2e_results.csv"
    println("Exporting results to ", out_file, "...")
    export_to_csv(sol, out_file)
    println("E2E Test completed successfully!")
end

main()
