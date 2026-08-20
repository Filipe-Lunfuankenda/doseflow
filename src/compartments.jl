# src/compartments.jl

"""
    Compartment

Represents a physiological compartment (organ or tissue) in the PBPK model.

Fields:
- `name::String`: Name of the compartment (Nome do compartimento).
- `volume::Float64`: Volume of the compartment in Liters (Volume em Litros).
- `flow::Float64`: Blood flow to the compartment in L/h (Fluxo sanguíneo em L/h).
- `pH::Float64`: Intracellular pH of the tissue (pH intracelular).
- `Kp::Float64`: Tissue-to-plasma partition coefficient (Coeficiente de partição tecido-plasma).
- `fu_tissue::Float64`: Fraction unbound in the tissue (Fração livre no tecido).
- `is_eliminating::Bool`: Does this compartment eliminate the drug? (Excreta ou metaboliza?)
"""
@with_kw struct Compartment
    name::String
    volume::Float64
    flow::Float64
    pH::Float64 = 7.4
    Kp::Float64 = 1.0 
    fu_tissue::Float64 = 1.0
    is_eliminating::Bool = false
end
