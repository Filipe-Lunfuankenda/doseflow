# src/reports.jl
using DataFrames, CSV

"""
    export_to_csv(sol, filepath::String)

Exports the PBPK simulation time-series results to a CSV file.
"""
function export_to_csv(sol, filepath::String)
    df = DataFrame(
        Time_h = sol.t,
        Venous_Blood_mg = [u[1] for u in sol.u],
        Arterial_Blood_mg = [u[2] for u in sol.u],
        Liver_mg = [u[3] for u in sol.u],
        Kidney_mg = [u[4] for u in sol.u],
        Brain_mg = [u[5] for u in sol.u],
        Muscle_mg = [u[6] for u in sol.u],
        Adipose_mg = [u[7] for u in sol.u],
        Heart_mg = [u[8] for u in sol.u],
        Lungs_mg = [u[9] for u in sol.u],
        Skin_mg = [u[10] for u in sol.u],
        Gut_mg = [u[11] for u in sol.u],
        GI_Solid_mg = [u[12] for u in sol.u],
        GI_Liquid_mg = [u[13] for u in sol.u]
    )
    CSV.write(filepath, df)
    println("Results successfully exported to: ", filepath)
end

"""
    export_to_sbml(sol, pop, compound, filepath)

Exports a simplified structural SBML representation of the model parameters.
"""
function export_to_sbml(sol, pop::Population, compound::Compound, filepath::String)
    xml = """<?xml version="1.0" encoding="UTF-8"?>
<sbml xmlns="http://www.sbml.org/sbml/level3/version2/core" level="3" version="2">
  <model id="DoseFlow_PBPK_$(compound.name)" name="DoseFlow PBPK Model">
    <listOfCompartments>"""
    
    for (k, c) in pop.compartments
        xml *= "\n      <compartment id=\"$(k)\" name=\"$(c.name)\" size=\"$(c.volume)\" constant=\"true\"/>"
    end
    xml *= "\n      <compartment id=\"VenousBlood\" size=\"$(pop.blood_volume * 0.7)\" constant=\"true\"/>"
    xml *= "\n      <compartment id=\"ArterialBlood\" size=\"$(pop.blood_volume * 0.3)\" constant=\"true\"/>"
    
    xml *= """
    
    </listOfCompartments>
    <listOfParameters>
      <parameter id="CL_int" value="$(compound.CL_int)" constant="true"/>
      <parameter id="fu" value="$(compound.fu)" constant="true"/>
      <parameter id="k_a" value="$(compound.k_a)" constant="true"/>
      <parameter id="solubility" value="$(compound.solubility)" constant="true"/>
    </listOfParameters>
  </model>
</sbml>"""
    
    write(filepath, xml)
    println("SBML structure successfully exported to: ", filepath)
end

"""
    generate_pdf_report(pop, compound, sol, dose, route, out_dir)

Replaces placeholders in the Quarto template and prepares the `.qmd` file for PDF rendering.
Note: Requires Quarto CLI installed on the system to compile the PDF.
"""
function generate_pdf_report(pop::Population, compound::Compound, sol, dose::Float64, route::Symbol, out_dir::String)
    template_path = joinpath(@__DIR__, "..", "templates", "regulatory_report.qmd")
    out_qmd = joinpath(out_dir, "report_$(compound.name)_$(route).qmd")
    
    # Calculate PK Metrics
    C_venous = [u[1] / (pop.blood_volume * 0.7) for u in sol.u]
    Cmax = maximum(C_venous)
    Tmax = sol.t[argmax(C_venous)]
    
    # Simple Trapezoidal AUC
    AUC = 0.0
    for i in 1:(length(sol.t)-1)
        dt = sol.t[i+1] - sol.t[i]
        AUC += 0.5 * (C_venous[i] + C_venous[i+1]) * dt
    end
    
    content = read(template_path, String)
    content = replace(content, "{{DRUG_NAME}}" => compound.name)
    content = replace(content, "{{MW}}" => string(compound.mw))
    content = replace(content, "{{LOGP}}" => string(compound.logP))
    content = replace(content, "{{PKA}}" => string(compound.pKa))
    content = replace(content, "{{TYPE}}" => string(compound.type))
    content = replace(content, "{{FU}}" => string(compound.fu))
    content = replace(content, "{{CL_INT}}" => string(compound.CL_int))
    
    content = replace(content, "{{POP_NAME}}" => pop.name)
    content = replace(content, "{{WEIGHT}}" => string(pop.body_weight))
    content = replace(content, "{{CARDIAC_OUT}}" => string(pop.cardiac_output))
    
    content = replace(content, "{{DOSE}}" => string(dose))
    content = replace(content, "{{ROUTE}}" => string(route))
    content = replace(content, "{{TSPAN}}" => string(sol.t[end]))
    
    content = replace(content, "{{CMAX}}" => string(round(Cmax, digits=4)))
    content = replace(content, "{{TMAX}}" => string(round(Tmax, digits=4)))
    content = replace(content, "{{AUC}}" => string(round(AUC, digits=4)))
    content = replace(content, "{{HASH}}" => string(hash(content))) # Deterministic signature
    
    write(out_qmd, content)
    println("Quarto report template generated at: ", out_qmd)
    println("To render PDF, run: quarto render \"$(out_qmd)\"")
end
