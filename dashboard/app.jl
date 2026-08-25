using Dash, PlotlyJS, Base64, CSV, DataFrames
using DoseFlow

# App Initialization
app = dash(external_stylesheets=["https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&display=swap"])

# Load Population
const pop = load_icrp89(joinpath(@__DIR__, "..", "data", "icrp89_adult_male.json"))

app.layout = html_div(style=Dict("fontFamily" => "Inter, sans-serif", "backgroundColor" => "#F7FAFA", "minHeight" => "100vh", "padding" => "2rem")) do
    html_div(style=Dict("maxWidth" => "1200px", "margin" => "0 auto")) do
        html_div(style=Dict("textAlign" => "center", "marginBottom" => "3rem")) do
            html_h1("DoseFlow", style=Dict("color" => "#0E2A3A", "fontWeight" => "600", "fontSize" => "3rem", "marginBottom" => "0.5rem")),
            html_p("Deterministic PBPK Engine & Result Viewer", style=Dict("color" => "#0FA3B1", "fontSize" => "1.2rem", "fontWeight" => "300"))
        end,
        
        dcc_tabs(id="tabs", value="tab-1", style=Dict("marginBottom" => "2rem"), children=[
            dcc_tab(label="Live Simulator", value="tab-1", selected_style=Dict("backgroundColor" => "#0FA3B1", "color" => "white", "fontWeight" => "600"), style=Dict("padding" => "1rem", "fontWeight" => "600")),
            dcc_tab(label="Result Viewer", value="tab-2", selected_style=Dict("backgroundColor" => "#0FA3B1", "color" => "white", "fontWeight" => "600"), style=Dict("padding" => "1rem", "fontWeight" => "600"))
        ]),
        
        html_div(id="tabs-content")
    end
end

# The content of the tabs will be updated via a callback to keep layout clean
callback!(
    app,
    Output("tabs-content", "children"),
    Input("tabs", "value")
) do tab
    if tab == "tab-1"
        return html_div(style=Dict("display" => "grid", "gridTemplateColumns" => "1fr 2fr", "gap" => "2rem")) do
            # Left Control Panel
            html_div(style=Dict("backgroundColor" => "white", "padding" => "2rem", "borderRadius" => "16px", "boxShadow" => "0 10px 25px rgba(14, 42, 58, 0.05)")) do
                html_h3("Parameters", style=Dict("color" => "#0E2A3A", "marginBottom" => "1.5rem", "borderBottom" => "2px solid #F7FAFA", "paddingBottom" => "0.5rem")),
                
                html_div(style=Dict("marginBottom" => "1.2rem")) do
                    html_label("Dose (mg)", style=Dict("display" => "block", "color" => "#0B7285", "fontWeight" => "600", "marginBottom" => "0.5rem")),
                    dcc_input(id="dose", value=500.0, type="number", style=Dict("width" => "100%", "padding" => "0.5rem", "borderRadius" => "8px", "border" => "1px solid #ddd"))
                end,
                
                html_div(style=Dict("marginBottom" => "1.2rem")) do
                    html_label("Clearance Intrínseco (L/h)", style=Dict("display" => "block", "color" => "#0B7285", "fontWeight" => "600", "marginBottom" => "0.5rem")),
                    dcc_input(id="cl_int", value=30.0, type="number", style=Dict("width" => "100%", "padding" => "0.5rem", "borderRadius" => "8px", "border" => "1px solid #ddd"))
                end,
                
                html_div(style=Dict("marginBottom" => "1.2rem")) do
                    html_label("Fração Livre (fu)", style=Dict("display" => "block", "color" => "#0B7285", "fontWeight" => "600", "marginBottom" => "0.5rem")),
                    dcc_input(id="fu", value=0.7, type="number", step=0.1, style=Dict("width" => "100%", "padding" => "0.5rem", "borderRadius" => "8px", "border" => "1px solid #ddd"))
                end,
                
                html_div(style=Dict("marginBottom" => "1.2rem")) do
                    html_label("Taxa de Absorção (ka)", style=Dict("display" => "block", "color" => "#0B7285", "fontWeight" => "600", "marginBottom" => "0.5rem")),
                    dcc_input(id="ka", value=1.2, type="number", style=Dict("width" => "100%", "padding" => "0.5rem", "borderRadius" => "8px", "border" => "1px solid #ddd"))
                end,
                
                html_div(style=Dict("marginBottom" => "1.2rem")) do
                    html_label("Via de Administração", style=Dict("display" => "block", "color" => "#0B7285", "fontWeight" => "600", "marginBottom" => "0.5rem")),
                    dcc_dropdown(
                        id="route",
                        options=[
                            Dict("label" => "Oral", "value" => "Oral"),
                            Dict("label" => "Intravenoso (IV Bolus)", "value" => "IV")
                        ],
                        value="Oral",
                        style=Dict("borderRadius" => "8px")
                    )
                end
            end,
            
            # Right Graph Panel
            html_div(style=Dict("backgroundColor" => "white", "padding" => "2rem", "borderRadius" => "16px", "boxShadow" => "0 10px 25px rgba(14, 42, 58, 0.05)")) do
                dcc_graph(id="pk-plot", style=Dict("height" => "500px"))
            end
        end
    elseif tab == "tab-2"
        return html_div(style=Dict("backgroundColor" => "white", "padding" => "2rem", "borderRadius" => "16px", "boxShadow" => "0 10px 25px rgba(14, 42, 58, 0.05)", "textAlign" => "center")) do
            html_h3("Upload E2E Results", style=Dict("color" => "#0E2A3A", "marginBottom" => "1rem")),
            html_p("Arraste e largue o ficheiro e2e_results.csv exportado pelo motor para visualizar os gráficos.", style=Dict("color" => "#777", "marginBottom" => "2rem")),
            dcc_upload(
                id="upload-data",
                children=html_div([
                    "Drag and Drop or ",
                    html_a("Select Files", style=Dict("color" => "#0FA3B1", "textDecoration" => "underline", "cursor" => "pointer"))
                ]),
                style=Dict(
                    "width" => "100%",
                    "height" => "60px",
                    "lineHeight" => "60px",
                    "borderWidth" => "2px",
                    "borderStyle" => "dashed",
                    "borderColor" => "#0FA3B1",
                    "borderRadius" => "10px",
                    "textAlign" => "center",
                    "marginBottom" => "2rem",
                    "backgroundColor" => "#F7FAFA"
                ),
                multiple=false
            ),
            dcc_graph(id="upload-plot", style=Dict("height" => "500px"))
        end
    end
end

# Live Simulation Callback
callback!(
    app,
    Output("pk-plot", "figure"),
    Input("dose", "value"),
    Input("cl_int", "value"),
    Input("fu", "value"),
    Input("ka", "value"),
    Input("route", "value"),
    prevent_initial_call=false
) do dose, cl_int, fu, ka, route
    
    if dose === nothing || cl_int === nothing || fu === nothing || ka === nothing || route === nothing
        return Plot()
    end
    
    c = Compound(
        name="CustomDrug", mw=250.0, logP=2.5, pKa=6.5, type=:Neutral,
        fu=fu, CL_int=cl_int, k_a=ka, solubility=1000.0
    )
    
    r = Symbol(route)
    sol = run_simulation(pop, c, dose, (0.0, 24.0), route=r)
    
    V_venous = pop.blood_volume * 0.7
    C_venous = [u[1] / V_venous for u in sol.u]
    C_liver = [u[3] / pop.compartments["liver"].volume for u in sol.u]
    C_brain = [u[5] / pop.compartments["brain"].volume for u in sol.u]
    C_lungs = [u[9] / pop.compartments["lungs"].volume for u in sol.u]
    
    trace1 = scatter(x=sol.t, y=C_venous, mode="lines", name="Plasma (Venoso)", line=attr(color="#0FA3B1", width=3))
    trace2 = scatter(x=sol.t, y=C_liver, mode="lines", name="Fígado", line=attr(color="#FFB020", width=2, dash="dash"))
    trace3 = scatter(x=sol.t, y=C_brain, mode="lines", name="Cérebro", line=attr(color="#0E2A3A", width=2, dash="dot"))
    trace4 = scatter(x=sol.t, y=C_lungs, mode="lines", name="Pulmões", line=attr(color="#34C78A", width=2, dash="dashdot"))
    
    layout = Layout(
        title=attr(text="Live Pharmacokinetic Profile", font=attr(family="Inter", color="#0E2A3A", size=24)),
        xaxis=attr(title="Tempo (h)", gridcolor="#f0f0f0"),
        yaxis=attr(title="Concentração (mg/L)", gridcolor="#f0f0f0"),
        plot_bgcolor="white",
        paper_bgcolor="white",
        margin=attr(l=60, r=40, t=60, b=60),
        legend=attr(x=0.75, y=0.95, bgcolor="rgba(255,255,255,0.8)"),
        hovermode="x unified"
    )
    
    return Plot([trace1, trace2, trace3, trace4], layout)
end

# Upload Viewer Callback
callback!(
    app,
    Output("upload-plot", "figure"),
    Input("upload-data", "contents"),
    prevent_initial_call=false
) do contents
    if contents === nothing
        # Empty plot before upload
        return Plot(Layout(
            title=attr(text="No data uploaded", font=attr(family="Inter", color="#777", size=20)),
            plot_bgcolor="white",
            paper_bgcolor="white",
            xaxis=attr(visible=false),
            yaxis=attr(visible=false)
        ))
    end
    
    # contents is "data:text/csv;base64,....."
    try
        content_type, content_string = split(contents, ",")
        decoded = base64decode(content_string)
        
        # Read as CSV
        df = CSV.read(decoded, DataFrame)
        
        # Check if expected columns are present
        if !("Time_h" in names(df)) || !("Venous_Blood_mg" in names(df))
            return Plot(Layout(title=attr(text="Invalid CSV Format", font=attr(color="red"))))
        end
        
        V_venous = pop.blood_volume * 0.7
        V_liver = pop.compartments["liver"].volume
        V_brain = pop.compartments["brain"].volume
        V_lungs = pop.compartments["lungs"].volume
        
        C_venous = df.Venous_Blood_mg ./ V_venous
        C_liver = df.Liver_mg ./ V_liver
        C_brain = df.Brain_mg ./ V_brain
        C_lungs = df.Lungs_mg ./ V_lungs
        
        trace1 = scatter(x=df.Time_h, y=C_venous, mode="lines", name="Plasma (Venoso)", line=attr(color="#0FA3B1", width=3))
        trace2 = scatter(x=df.Time_h, y=C_liver, mode="lines", name="Fígado", line=attr(color="#FFB020", width=2, dash="dash"))
        trace3 = scatter(x=df.Time_h, y=C_brain, mode="lines", name="Cérebro", line=attr(color="#0E2A3A", width=2, dash="dot"))
        trace4 = scatter(x=df.Time_h, y=C_lungs, mode="lines", name="Pulmões", line=attr(color="#34C78A", width=2, dash="dashdot"))
        
        layout = Layout(
            title=attr(text="Uploaded Results (Concentration Profile)", font=attr(family="Inter", color="#0E2A3A", size=24)),
            xaxis=attr(title="Tempo (h)", gridcolor="#f0f0f0"),
            yaxis=attr(title="Concentração (mg/L)", gridcolor="#f0f0f0"),
            plot_bgcolor="white",
            paper_bgcolor="white",
            margin=attr(l=60, r=40, t=60, b=60),
            legend=attr(x=0.75, y=0.95, bgcolor="rgba(255,255,255,0.8)"),
            hovermode="x unified"
        )
        
        return Plot([trace1, trace2, trace3, trace4], layout)
    catch e
        return Plot(Layout(title=attr(text="Error parsing file: $e", font=attr(color="red"))))
    end
end

println("Starting DoseFlow Dashboard on http://127.0.0.1:8050")
run_server(app, "127.0.0.1", 8050)
