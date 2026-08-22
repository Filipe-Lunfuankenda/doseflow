module DoseFlow

using DifferentialEquations
using ModelingToolkit
using Parameters
using JSON

# Includes
include("compounds.jl")
include("compartments.jl")
include("population.jl")
include("models.jl")
include("reports.jl")

# Exports
export Compound, Compartment, Population
export run_simulation, load_icrp89
export fraction_unionized, hill_effect, arrhenius_degradation, predict_Kp
export scale_pediatric, export_to_csv, generate_pdf_report, export_to_sbml

end # module DoseFlow
