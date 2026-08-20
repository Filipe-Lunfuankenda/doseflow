# src/compounds.jl

"""
    Compound

Represents a chemical compound (drug) and its physicochemical properties.

Fields:
- `name::String`: Name of the drug.
- `mw::Float64`: Molecular weight in g/mol.
- `logP::Float64`: Partition coefficient octanol/water.
- `pKa::Float64`: Acid dissociation constant.
- `type::Symbol`: `:Acid`, `:Base`, or `:Neutral`.
- `fu::Float64`: Fraction unbound in plasma.
- `CL_int::Float64`: Intrinsic hepatic clearance in L/h.
- `k_a::Float64`: First-order absorption rate constant in 1/h.
- `solubility::Float64`: Drug solubility in mg/L.
- `Emax::Float64`: Maximum pharmacological effect.
- `EC50::Float64`: Concentration for 50% of maximal effect.
- `Hill_n::Float64`: Hill coefficient (n).
- `Ea::Float64`: Activation energy for thermal degradation (J/mol).
"""
@with_kw struct Compound
    name::String
    mw::Float64
    logP::Float64
    pKa::Float64
    type::Symbol = :Neutral
    fu::Float64
    CL_int::Float64 = 0.0
    k_a::Float64 = 1.0
    solubility::Float64 = 1000.0
    Emax::Float64 = 100.0
    EC50::Float64 = 1.0
    Hill_n::Float64 = 1.0
    Ea::Float64 = 0.0 # Default 0 = no thermal degradation
end

"""
    fraction_unionized(c::Compound, pH::Float64) -> Float64
Calculates the fraction of unionized drug at a specific pH (Henderson-Hasselbalch).
"""
function fraction_unionized(c::Compound, pH::Float64)
    if c.type == :Acid
        return 1.0 / (1.0 + 10.0^(pH - c.pKa))
    elseif c.type == :Base
        return 1.0 / (1.0 + 10.0^(c.pKa - pH))
    else
        return 1.0
    end
end

"""
    hill_effect(c::Compound, C::Float64) -> Float64
Calculates the pharmacological effect E using the Hill equation.
E = (Emax * C^n) / (EC50^n + C^n)
"""
function hill_effect(c::Compound, C::Float64)
    if C <= 0.0 return 0.0 end
    return (c.Emax * C^c.Hill_n) / (c.EC50^c.Hill_n + C^c.Hill_n)
end

"""
    arrhenius_degradation(c::Compound, T_kelvin::Float64; A::Float64=1e10) -> Float64
Calculates thermal degradation rate k using Arrhenius: k = A * exp(-Ea / RT).
R = 8.314 J/(mol K). T = Temperatura em Kelvin (ex: 310.15 para 37°C).
"""
function arrhenius_degradation(c::Compound, T_kelvin::Float64; A::Float64=1e10)
    if c.Ea == 0.0 return 0.0 end
    R = 8.314
    return A * exp(-c.Ea / (R * T_kelvin))
end

"""
    predict_Kp(c::Compound, tissue_pH::Float64; plasma_pH::Float64=7.4) -> Float64
Simplified prediction of tissue-to-plasma partition coefficient Kp (LogP / pKa / Henderson-Hasselbalch).
Kp = (f_un_plasma / f_un_tissue) * P_octanol
"""
function predict_Kp(c::Compound, tissue_pH::Float64; plasma_pH::Float64=7.4)
    f_un_plasma = fraction_unionized(c, plasma_pH)
    f_un_tissue = fraction_unionized(c, tissue_pH)
    P_octanol = 10.0^c.logP
    
    # Highly simplified tissue partitioning model based on unionized lipophilic fraction
    Kp_unionized = (f_un_plasma / max(f_un_tissue, 1e-6)) * P_octanol * 0.05 # 5% lipid volume approx
    Kp_aqueous = (1.0 - f_un_plasma) / max(1.0 - f_un_tissue, 1e-6) * 0.7 # 70% water
    
    return max(Kp_unionized + Kp_aqueous, 0.1) # Kp >= 0.1 safety limit
end
