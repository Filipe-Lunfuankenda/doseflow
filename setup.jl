using Pkg
Pkg.add([
    "DifferentialEquations",
    "ModelingToolkit",
    "Parameters",
    "JSON",
    "Catalyst",
    "DataFrames",
    "CSV",
    "Dash",
    "PlotlyJS"
])
Pkg.instantiate()
Pkg.test()
