using Dash, PlotlyJS
using DoseFlow

# App Initialization
app = dash()

# Load Population
const pop = load_icrp89(joinpath(@__DIR__, "..", "data", "icrp89_adult_male.json"))

app.layout = html_div() do
    html_h1("PhysPK / DoseFlow - Interactive Dashboard", style=Dict("textAlign" => "center", "color" => "#0FA3B1")),
    html_p("Simulador PBPK determinístico (Open-Source)", style=Dict("textAlign" => "center")),
    
    html_div(style=Dict("display" => "flex", "justifyContent" => "space-around", "margin" => "20px")) do
        html_div() do
            html_h3("Fármaco (Compound)"),
            html_label("Dose (mg): "),
            dcc_input(id="dose", value=500.0, type="number"), html_br(),
            html_label("Clearance Intrínseco Hepático (L/h): "),
            dcc_input(id="cl_int", value=30.0, type="number"), html_br(),
            html_label("Fração Livre (fu): "),
            dcc_input(id="fu", value=0.7, type="number", step=0.1), html_br(),
            html_label("Taxa de Absorção (ka): "),
            dcc_input(id="ka", value=1.2, type="number"), html_br(),
            html_label("Via de Administração: "),
            dcc_dropdown(
                id="route",
                options=[
                    Dict("label" => "Oral", "value" => "Oral"),
                    Dict("label" => "Intravenoso (IV Bolus)", "value" => "IV")
                ],
                value="Oral"
            )
        end,
        html_div() do
            html_h3("População (Population)"),
            html_p("Model: ICRP-89 Adult Male"),
            html_p("Weight: 73.0 kg"),
            html_p("Cardiac Output: 390.0 L/h")
        end
    end,
    
    dcc_graph(id="pk-plot")
end

callback!(
    app,
    Output("pk-plot", "figure"),
    Input("dose", "value"),
    Input("cl_int", "value"),
    Input("fu", "value"),
    Input("ka", "value"),
    Input("route", "value")
) do dose, cl_int, fu, ka, route
    
    # Check nulls from UI
    if dose === nothing || cl_int === nothing || fu === nothing || ka === nothing
        return Plot()
    end
    
    c = Compound(
        name="CustomDrug", mw=250.0, logP=2.5, pKa=6.5, type=:Neutral,
        fu=fu, CL_int=cl_int, k_a=ka, solubility=1000.0
    )
    
    r = Symbol(route)
    sol = run_simulation(pop, c, dose, (0.0, 24.0), route=r)
    
    # Blood Volume for concentration
    V_venous = pop.blood_volume * 0.7
    C_venous = [u[1] / V_venous for u in sol.u]
    C_liver = [u[3] / pop.compartments["liver"].volume for u in sol.u]
    
    trace1 = scatter(x=sol.t, y=C_venous, mode="lines", name="Concentração Venosa (Sistémica)", line_color="#0FA3B1")
    trace2 = scatter(x=sol.t, y=C_liver, mode="lines", name="Concentração Fígado", line_color="#FFB020", line_dash="dash")
    
    layout = Layout(
        title="Curva Concentração-Tempo (PK)",
        xaxis_title="Tempo (h)",
        yaxis_title="Concentração (mg/L)",
        template="plotly_white"
    )
    
    return Plot([trace1, trace2], layout)
end

println("Starting DoseFlow Dashboard on http://127.0.0.1:8050")
run_server(app, "127.0.0.1", 8050)
