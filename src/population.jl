# src/population.jl
using JSON

"""
    Population

Represents a virtual population or individual based on physiological parameters.
"""
@with_kw struct Population
    name::String
    body_weight::Float64
    cardiac_output::Float64
    blood_volume::Float64
    compartments::Dict{String, Compartment}
end

"""
    load_icrp89(filepath::String) -> Population

Loads the ICRP-89 physiological data from a JSON file.
"""
function load_icrp89(filepath::String)
    data = JSON.parsefile(filepath)
    comps = Dict{String, Compartment}()
    
    for (k, v) in data["compartments"]
        comps[k] = Compartment(
            name=k,
            volume=v["volume_L"],
            flow=v["blood_flow_L_h"],
            is_eliminating=v["is_eliminating"],
            pH=get(v, "pH", 7.4)
        )
    end
    
    return Population(
        name=data["reference_population"],
        body_weight=data["body_weight_kg"],
        cardiac_output=data["cardiac_output_L_h"],
        blood_volume=data["blood_volume_L"],
        compartments=comps
    )
end

"""
    scale_pediatric(adult::Population, child_weight_kg::Float64) -> Population

Applies allometric scaling to generate a pediatric virtual population from an adult reference.
Volumes scale linearly (exponent 1.0), flows scale with exponent 0.75.
"""
function scale_pediatric(adult::Population, child_weight_kg::Float64)
    ratio_W = child_weight_kg / adult.body_weight
    ratio_allometric = ratio_W^0.75
    
    child_comps = Dict{String, Compartment}()
    for (k, c) in adult.compartments
        child_comps[k] = Compartment(
            name=c.name,
            volume=c.volume * ratio_W,
            flow=c.flow * ratio_allometric,
            pH=c.pH,
            Kp=c.Kp,
            fu_tissue=c.fu_tissue,
            is_eliminating=c.is_eliminating
        )
    end
    
    return Population(
        name="Scaled Pediatric (W = $(child_weight_kg) kg)",
        body_weight=child_weight_kg,
        cardiac_output=adult.cardiac_output * ratio_allometric,
        blood_volume=adult.blood_volume * ratio_W,
        compartments=child_comps
    )
end
