# DoseFlow

**Open-source, deterministic physiologically-based pharmacokinetics (PBPK) simulation.**

DoseFlow models the human body as a network of physiologically realistic compartments and solves the ordinary differential equations (ODEs) that govern a drug's journey — absorption, distribution, metabolism and excretion (ADME). Every equation is explicit, auditable and reproducible. No AI. No black boxes.

> ⚠️ **Research & educational tool.** DoseFlow is **not** a medical device and does **not** provide medical advice. Outputs must be reviewed by a qualified professional and are not for clinical decision-making.

## Why DoseFlow exists

Commercial PBPK platforms cost tens of thousands of dollars per year, locking out small pharma, independent researchers and universities in low- and middle-income countries. DoseFlow puts a rigorous, transparent PBPK engine in everyone's hands — free, forever.

## Principles

- **Deterministic** — same input → same output, always.
- **Auditable** — every number traces to a published equation and reference.
- **Accessible** — runs offline on a laptop; no license server, no cloud.
- **Interoperable** — reads/writes SBML and PEtab.
- **Free** — MIT-licensed core, free forever.

## Features

- Whole-body multi-compartment PBPK (liver, kidney, lung, brain, muscle, fat, skin, gut, …)
- Physiological priors from ICRP 89 (tissue volumes, blood flows)
- Absorption: first-order kinetics + Noyes–Whitney dissolution
- Distribution: tissue/plasma partitioning (Rodgers–Rowland), protein binding (Scatchard)
- Metabolism: Michaelis–Menten (CYP450), hepatic clearance (well-stirred / parallel-tube)
- Excretion: glomerular filtration (GFR)
- Pharmacodynamics: E<sub>max</sub> / Hill equation
- Special populations: pediatric allometric scaling, hepatic/renal impairment
- Reproducible population simulation (seeded quasi-random sampling)
- SBML / PEtab import & export

## The auditable core

| Process | Model |
|---|---|
| Compartment mass balance | dCᵢ/dt = Qᵢ/V·(C_art − C/K_p,i) − CLᵢ/V·Cᵢ |
| GI absorption | dA_GI/dt = −k_a·A_GI |
| Dissolution | dC/dt = (D·A/(h·V))·(C_s − C) |
| Metabolism | v = V_max·C/(K_m + C) |
| PD effect | E = E_max·Cⁿ/(EC₅₀ⁿ + Cⁿ) |
| Protein binding | f_u = 1/(1 + K_a·P) |
| Pediatric scaling | CL_child = CL_adult·(W_child/W_adult)^0.75 |

## Quick start

Requires **Julia ≥ 1.10**.

```julia
using Pkg; Pkg.add("DoseFlow")
```

```julia
using DoseFlow, Plots

# Default adult whole-body model + oral 400 mg dose
model   = pbpk_model(population = :adult)
regimen = dose(amount = 400.0, route = :oral, interval = 8.0)

sol = simulate(model, regimen, tspan = (0.0, 24.0))
plot_concentration(sol, tissue = :plasma)
```

*(API is the current development target; see `docs/` for the evolving reference.)*

## Project structure

```
src/            # core engine (compartments, ODEs, solvers)
  physiology/   # ICRP priors, populations, scaling
  adme/         # absorption, distribution, metabolism, excretion
  pd/           # pharmacodynamics
  io/           # SBML / PEtab import-export
docs/           # documentation & tutorials
test/           # unit & regression tests
```

## Roadmap

- [ ] Core whole-body PBPK + oral/IV routes
- [ ] Special populations (pediatric, hepatic, renal)
- [ ] SBML/PEtab interoperability
- [ ] Reproducible population simulation
- [ ] Web dashboard (Makie/Dash)
- [ ] Regulatory-style report generation (Quarto)

## Contributing

Issues and pull requests are welcome. Please read `CONTRIBUTING.md` and keep every model change accompanied by a test and a literature reference — auditability is the project's core promise.

## License

MIT © DoseFlow contributors. See [`LICENSE`](LICENSE).

## Citation

If you use DoseFlow in research, please cite:

```bibtex
@software{doseflow,
  title  = {DoseFlow: an open-source, deterministic PBPK simulator},
  author = {Lunfuankenda, Filipe},
  year   = {2026},
  url    = {https://github.com/<your-username>/doseflow},
  license = {MIT}
}
```

---

*DoseFlow is part of a broader effort to make quantitative pharmacology open and equitable.*
