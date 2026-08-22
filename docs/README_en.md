# DoseFlow (PhysPK Core)

**Your deterministic, open-source Physiologically Based Pharmacokinetic (PBPK) simulator.**

[Português](../README.md) | **English**

DoseFlow (powered by the internal **PhysPK** engine) was born from a simple conviction: physiology is public, mathematics is public, and knowledge that saves lives should not be locked behind a 50,000-dollar simulator.

This simulator empowers scientists, universities, generic drug developers, and small pharmaceutical companies to model, predict, and audit how a drug travels through the human body — without "black boxes" or opaque AI algorithms. It is built purely on clear, auditable Ordinary Differential Equations (ODEs).

## Features

- **Absolute Determinism**: Written in Julia (`DifferentialEquations.jl`), every number has an equation, guaranteeing bit-by-bit identical results for regulatory purposes.
- **Real Biology (ICRP-89)**: The model constructs organs based on standard human volume and blood flow data (liver, kidney, brain, muscle, etc.).
- **Pediatric Scaling**: Applies allometric scaling ($W^{0.75}$) to derive child physiology instantly from an adult reference.
- **Oral Absorption & Noyes-Whitney**: Simulates not just intravenous (IV) input, but the complete solubility-dependent gastrointestinal dissolution and absorption profile.
- **Ionization and Partitioning (Kp)**: Uses the Henderson-Hasselbalch equation and $logP$ to automatically predict the tissue-to-plasma concentration ratio.
- **Hepatic Metabolism & Renal Excretion**: Models the unbound fraction ($f_u$) subject to hepatic clearance (well-stirred model) and glomerular filtration (GFR).
- **Interactive Dashboard**: A fast web interface to visualize Cmax/Tmax curves dynamically (Dash.jl).
- **Regulatory Reports**: Generates perfectly structured Quarto (.qmd) templates for standard submission reports (EMA/FDA).

## Installation

You must have [Julia](https://julialang.org/downloads/) installed on your system. The engine is extremely lightweight and runs smoothly on 8GB RAM machines.

1. Clone the repository:
```bash
git clone https://github.com/your-username/doseflow.git
cd doseflow
```

2. Install dependencies:
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## How to Run Simulations (Terminal)

We provide a basic script that loads the human data (ICRP-89) and tests an oral vs intravenous dose:

```bash
julia --project=. examples/basic_sim.jl
```
This runs the ODEs in milliseconds and produces terminal outputs, while also generating a `results_oral.csv` time/concentration table in the `data/` folder.

## Interactive Dashboard

To access a visual interface where you can adjust doses and see curves update in real-time:

```bash
julia --project=. dashboard/app.jl
```
Open your browser at: `http://127.0.0.1:8050`

## Regulatory Reports (PDF)

The function `generate_pdf_report(pop, compound, sol, dose, route, out_dir)` from our `reports.jl` module takes the model and produces a populated `report_XXX.qmd`.
If you have [Quarto](https://quarto.org/) installed, simply compile it:

```bash
quarto render data/report_CustomDrug_Oral.qmd
```
*(Produces a perfectly formatted PDF for submission dossiers)*

## Core Mathematics

There are no secrets in DoseFlow. Here is what happens in the engine:

*   **Oral Absorption**: $dM/dt = k_{diss} \times \max(C_s - C_{GI}, 0)$ and $dA_{absorbed} = k_a \times A_{Liquid}$
*   **Ionization (Henderson-Hasselbalch)**: For an acid: $f_{un} = \frac{1}{1 + 10^{(pH - pKa)}}$
*   **Hepatic Clearance**: $CL_H = \frac{Q_L \cdot f_u \cdot CL_{int}}{Q_L + f_u \cdot CL_{int}}$
*   **Renal Clearance (GFR)**: $CL_R = f_u \cdot GFR$
*   **Effect (Pharmacodynamics)**: Hill Equation $E = \frac{E_{max} \cdot C^n}{EC50^n + C^n}$

---
*Built to democratize drug science. Free, open, exact.*
