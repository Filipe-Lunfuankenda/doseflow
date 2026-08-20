# src/models.jl
using DifferentialEquations

"""
    run_simulation(pop::Population, compound::Compound, dose::Float64, tspan::Tuple{Float64, Float64}; route=:IV)

Runs a standard PBPK simulation.
Executa uma simulação PBPK padrão.
Routes supported: `:IV` (Intravenous Bolus), `:Oral` (Oral Administration with dissolution).
"""
function run_simulation(pop::Population, compound::Compound, dose::Float64, tspan::Tuple{Float64, Float64}; route=:IV)
    # Extrair compartimentos / Extract compartments
    liver = pop.compartments["liver"]
    kidney = pop.compartments["kidney"]
    muscle = pop.compartments["muscle"]
    
    V_venous = pop.blood_volume * 0.7
    V_arterial = pop.blood_volume * 0.3
    V_GI_fluid = 0.25 # L (Standard GI fluid volume for dissolution)
    
    # [Q_liver, Q_kidney, Q_muscle, V_liver, V_kidney, V_muscle, V_ven, V_art, CL_int, fu, k_a, solubility, V_GI_fluid]
    p = [
        liver.flow, kidney.flow, muscle.flow,
        liver.volume, kidney.volume, muscle.volume,
        V_venous, V_arterial,
        compound.CL_int, compound.fu,
        compound.k_a, compound.solubility, V_GI_fluid
    ]
    
    function pbpk_odes!(du, u, p, t)
        Q_L, Q_K, Q_M, V_L, V_K, V_M, V_ven, V_art, CL_int, fu, k_a, Cs, V_GI = p
        
        # Estados / States
        A_ven = u[1]; A_art = u[2]; A_L = u[3]; A_K = u[4]; A_M = u[5]
        A_GI_solid = u[6]; A_GI_liquid = u[7]
        
        # Concentrações / Concentrations
        C_ven = A_ven / V_ven
        C_art = A_art / V_art
        C_L = A_L / V_L
        C_K = A_K / V_K
        C_M = A_M / V_M
        C_GI = A_GI_liquid / V_GI
        
        # 1. Absorção Oral (Noyes-Whitney Dissolution + First-order absorption)
        # dC/dt = D*A/(h*V) * (Cs - C). Representamos a constante D*A/h como k_diss
        k_diss = 0.5 # 1/h (Simplificação para MVP)
        
        # Dissolução para apenas se C_GI atingir a solubilidade (Cs) ou se não houver sólido
        dissolution_rate = A_GI_solid > 0 ? k_diss * max(Cs - C_GI, 0.0) * V_GI : 0.0
        # Garantir que a taxa não retira mais do que o existente
        if dissolution_rate > A_GI_solid * 100 # Prevenir instabilidade numérica
            dissolution_rate = A_GI_solid * 100 
        end
        
        absorption_rate = k_a * A_GI_liquid # Passa do GI liquid para o Fígado (Portal Vein)
        
        du[6] = -dissolution_rate
        du[7] = dissolution_rate - absorption_rate
        
        # 2. Balanço Sistémico / Systemic Balance
        # O GI drena para a veia porta do fígado / GI drains to Liver portal vein
        du[1] = Q_L * C_L + Q_K * C_K + Q_M * C_M - (Q_L + Q_K + Q_M) * C_ven
        
        du[2] = (Q_L + Q_K + Q_M) * C_ven - (Q_L + Q_K + Q_M) * C_art
        
        # Fígado (recebe sangue arterial + sangue venoso do GI)
        # O metabolismo (CL_int) atua geralmente sobre a porção livre e não-ionizada (ou apenas livre) no tecido hepático.
        # Aqui simplificamos assumindo que CL_int foi medido com base no fármaco livre no sangue.
        f_unionized = fraction_unionized(compound, liver.pH) # Se precisarmos usar
        
        # Well-stirred model para clearance hepática / Well-stirred hepatic clearance
        CL_H = (Q_L * fu * CL_int) / (Q_L + fu * CL_int)
        
        du[3] = Q_L * (C_art - C_L) + absorption_rate - CL_H * C_L
        
        # Rim (Adicionada filtração glomerular) / Kidney (Glomerular Filtration)
        # GFR standard adulto ~ 120 mL/min = 7.2 L/h
        GFR = 7.2
        CL_renal = fu * GFR # Filtração da fração livre
        du[4] = Q_K * (C_art - C_K) - CL_renal * C_K
        
        # Músculo
        du[5] = Q_M * (C_art - C_M)
    end
    
    # Condições Iniciais / Initial Conditions
    u0 = zeros(7)
    if route == :IV
        u0[1] = dose # Dose no sangue venoso
    elseif route == :Oral
        u0[6] = dose # Dose no estômago (sólido)
    else
        error("Route not supported. Use :IV or :Oral")
    end
    
    prob = ODEProblem(pbpk_odes!, u0, tspan, p)
    sol = solve(prob, Tsit5(), reltol=1e-6, abstol=1e-8)
    
    return sol
end
