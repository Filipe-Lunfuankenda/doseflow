# src/reports.jl

"""
    export_to_csv(sol, filepath::String)

Exports the PBPK simulation time-series results to a CSV file.
Designed to be lightweight (no heavy DataFrames.jl dependency).
"""
function export_to_csv(sol, filepath::String)
    open(filepath, "w") do io
        # Write CSV Header
        write(io, "Time_h,Venous_Blood_mg,Arterial_Blood_mg,Liver_mg,Kidney_mg,Muscle_mg,GI_Solid_mg,GI_Liquid_mg\n")
        
        # Write Data rows
        for i in 1:length(sol.t)
            t = sol.t[i]
            u = sol.u[i]
            line = "$(t),$(u[1]),$(u[2]),$(u[3]),$(u[4]),$(u[5]),$(u[6]),$(u[7])\n"
            write(io, line)
        end
    end
    println("Results successfully exported to: ", filepath)
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
