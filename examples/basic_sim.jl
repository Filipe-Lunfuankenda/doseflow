using DoseFlow

pop = load_icrp89(joinpath(@__DIR__, "..", "data", "icrp89_adult_male.json"))
c = Compound(
    name="DoseFlow-X", 
    mw=250.0, logP=2.5, pKa=6.5, fu=0.7, 
    CL_int=30.0, k_a=1.2, solubility=500.0
)

dose_mg = 500.0
tspan = (0.0, 24.0)

println("--- IV Bolus Simulation ---")
sol_iv = run_simulation(pop, c, dose_mg, tspan, route=:IV)
println("IV max venous amount: ", maximum([u[1] for u in sol_iv.u]), " mg")

println("\n--- Oral Simulation ---")
sol_oral = run_simulation(pop, c, dose_mg, tspan, route=:Oral)
max_oral_venous = maximum([u[1] for u in sol_oral.u])
t_max_idx = argmax([u[1] for u in sol_oral.u])
t_max = sol_oral.t[t_max_idx]

println("Oral Cmax (venous amount): ", round(max_oral_venous, digits=2), " mg")
println("Oral Tmax: ", round(t_max, digits=2), " h")
println("\nSuccess! Oral absorption with Noyes-Whitney added.")

# Export the oral simulation to CSV
csv_path = joinpath(@__DIR__, "..", "data", "results_oral.csv")
export_to_csv(sol_oral, csv_path)
