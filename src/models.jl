# src/models.jl
using DifferentialEquations

"""
    run_simulation(pop::Population, compound::Compound, dose::Float64, tspan::Tuple{Float64, Float64}; route=:IV)

Runs a standard PBPK simulation.
Executa uma simulação PBPK padrão.
Routes supported: `:IV` (Intravenous Bolus), `:Oral` (Oral Administration with dissolution).
"""
function run_simulation(pop::Population, compound::Compound, dose::Float64, tspan::Tuple{Float64, Float64}; route=:IV)
    
    # Flow Definitions
    Q_total = pop.cardiac_output
    Q_liver_art = pop.compartments["liver"].flow
    Q_gut = pop.compartments["gut"].flow
    Q_kidney = pop.compartments["kidney"].flow
    Q_brain = pop.compartments["brain"].flow
    Q_muscle = pop.compartments["muscle"].flow
    Q_adipose = pop.compartments["adipose"].flow
    Q_heart = pop.compartments["heart"].flow
    Q_skin = pop.compartments["skin"].flow
    
    # Volumes
    V_venous = pop.blood_volume * 0.7
    V_arterial = pop.blood_volume * 0.3
    V_GI_fluid = 0.25 # L (Standard GI fluid volume for dissolution)
    
    # Ensure mass balance of flows
    sum_Q = Q_liver_art + Q_gut + Q_kidney + Q_brain + Q_muscle + Q_adipose + Q_heart + Q_skin
    Q_other = Q_total - sum_Q
    if Q_other < 0
        error("Sum of compartment flows exceeds total cardiac output!")
    end
    
    p = (pop, compound, V_venous, V_arterial, V_GI_fluid, Q_total, sum_Q, Q_other,
         Q_liver_art, Q_gut, Q_kidney, Q_brain, Q_muscle, Q_adipose, Q_heart, Q_skin)
    
    function pbpk_odes!(du, u, p, t)
        (pop, compound, V_ven, V_art, V_GI, Q_total, sum_Q, Q_other,
         Q_liver_art, Q_gut, Q_kidney, Q_brain, Q_muscle, Q_adipose, Q_heart, Q_skin) = p
        
        # States: 
        # 1:Venous, 2:Arterial, 3:Liver, 4:Kidney, 5:Brain, 6:Muscle, 7:Adipose, 
        # 8:Heart, 9:Lungs, 10:Skin, 11:Gut, 12:GI_Solid, 13:GI_Liquid
        A_ven, A_art, A_liver, A_kidney, A_brain, A_muscle, A_adipose, A_heart, A_lungs, A_skin, A_gut, A_GI_solid, A_GI_liquid = u
        
        # Concentrations
        C_ven = A_ven / V_ven
        C_art = A_art / V_art
        C_liver = A_liver / pop.compartments["liver"].volume
        C_kidney = A_kidney / pop.compartments["kidney"].volume
        C_brain = A_brain / pop.compartments["brain"].volume
        C_muscle = A_muscle / pop.compartments["muscle"].volume
        C_adipose = A_adipose / pop.compartments["adipose"].volume
        C_heart = A_heart / pop.compartments["heart"].volume
        C_lungs = A_lungs / pop.compartments["lungs"].volume
        C_skin = A_skin / pop.compartments["skin"].volume
        C_gut = A_gut / pop.compartments["gut"].volume
        C_GI = A_GI_liquid / V_GI
        
        # 1. Oral Absorption (Noyes-Whitney Dissolution + First-order absorption)
        k_diss = 0.5 # 1/h (Simplificação para MVP)
        dissolution_rate = A_GI_solid > 0 ? k_diss * max(compound.solubility - C_GI, 0.0) * V_GI : 0.0
        if dissolution_rate > A_GI_solid * 100 # Prevent numerical instability
            dissolution_rate = A_GI_solid * 100 
        end
        absorption_rate = compound.k_a * A_GI_liquid
        
        du[12] = -dissolution_rate
        du[13] = dissolution_rate - absorption_rate
        
        # 2. Hepatic & Renal Clearance
        fu = compound.fu
        CL_int = compound.CL_int
        Q_liver_total = Q_liver_art + Q_gut
        
        # Well-stirred model for liver
        CL_H = (Q_liver_total * fu * CL_int) / (Q_liver_total + fu * CL_int)
        
        # Renal Clearance (GFR ~ 7.2 L/h)
        CL_R = fu * 7.2
        
        # 3. Mass Balance ODEs
        
        # Lungs (receives venous return, pumps to arterial)
        du[9] = Q_total * C_ven - Q_total * C_lungs
        
        # Arterial Blood
        du[2] = Q_total * C_lungs - Q_total * C_art
        
        # Gut
        du[11] = Q_gut * (C_art - C_gut)
        
        # Liver (receives hepatic artery + gut venous return)
        du[3] = Q_liver_art * C_art + Q_gut * C_gut + absorption_rate - Q_liver_total * C_liver - CL_H * C_liver
        
        # Other Organs
        du[4] = Q_kidney * (C_art - C_kidney) - CL_R * C_kidney
        du[5] = Q_brain * (C_art - C_brain)
        du[6] = Q_muscle * (C_art - C_muscle)
        du[7] = Q_adipose * (C_art - C_adipose)
        du[8] = Q_heart * (C_art - C_heart)
        du[10] = Q_skin * (C_art - C_skin)
        
        # Venous Blood (collects from all organs)
        Venous_return = (Q_liver_total * C_liver) + (Q_kidney * C_kidney) + (Q_brain * C_brain) + 
                        (Q_muscle * C_muscle) + (Q_adipose * C_adipose) + (Q_heart * C_heart) + 
                        (Q_skin * C_skin) + (Q_other * C_art)
                        
        du[1] = Venous_return - Q_total * C_ven
    end
    
    # Initial Conditions
    u0 = zeros(13)
    if route == :IV
        u0[1] = dose # Venous blood
    elseif route == :Oral
        u0[12] = dose # GI solid
    else
        error("Route not supported. Use :IV or :Oral")
    end
    
    prob = ODEProblem(pbpk_odes!, u0, tspan, p)
    sol = solve(prob, Tsit5(), reltol=1e-6, abstol=1e-8)
    
    return sol
end
