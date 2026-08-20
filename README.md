# DoseFlow (PhysPK Core) 🩸💊

**O teu simulador farmacocinético fisiológico (PBPK) determinístico e open-source.**

O **DoseFlow** (baseado no motor interno **PhysPK**) nasceu de uma convicção simples: *a fisiologia é pública, a matemática é pública, e o conhecimento que salva vidas não pode ficar trancado num simulador de 50.000 dólares.*

Este simulador permite a cientistas, universidades, desenvolvedores de genéricos e farmacêuticas pequenas modelar, prever e auditar como um fármaco viaja pelo corpo humano — sem "caixas negras" ou algoritmos opacos de IA. É tudo EDOs puras, claras e auditáveis.

## 🚀 Funcionalidades (O que o núcleo faz)

- **Determinismo Absoluto**: Escrito em Julia (`DifferentialEquations.jl`), cada número tem uma equação e garante-se o mesmo resultado bit-a-bit para fins regulamentares.
- **Biologia Real (ICRP-89)**: O modelo constrói os órgãos com base nos volumes e fluxos sanguíneos padrão para humanos (fígado, rim, cérebro, músculos, etc.).
- **Escalonamento Pediátrico**: Aplica leis de alometria ($W^{0.75}$) para derivar fisiologias de crianças instantaneamente a partir de um adulto.
- **Absorção Oral e Noyes-Whitney**: Simula não só a entrada intravenosa (IV), mas o perfil completo de dissolução e absorção gastrointestinal dependente da solubilidade.
- **Ionização e Partição (Kp)**: Usa a equação de Henderson-Hasselbalch e $logP$ para prever automaticamente o rácio de concentração tecido-plasma.
- **Metabolismo Hepático e Excreção Renal**: Modela a fração livre no sangue ($f_u$) sujeita a clearance hepático (well-stirred) e a filtração glomerular (GFR).
- **Dashboard Interativo**: Interface web rápida para veres as curvas Cmax/Tmax ganharem vida (Dash.jl).
- **Relatórios Regulamentares**: Gera _templates_ Quarto (.qmd) perfeitamente estruturados para relatórios padrão (EMA/FDA/INFARMED).

## 🛠️ Instalação

Precisas de ter a linguagem [Julia](https://julialang.org/downloads/) instalada no teu sistema. O motor é ultra-leve e corre bem em portáteis de 8GB RAM.

1. Clona o repositório:
```bash
git clone https://github.com/teu-usuario/doseflow.git
cd doseflow
```

2. Instala as dependências:
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## 🧪 Como usar as Simulações (Terminal)

Temos um script básico configurado que lê o humano (ICRP-89) e testa uma dose oral vs intravenosa:

```bash
julia --project=. examples/basic_sim.jl
```
Isto irá correr as EDOs em milissegundos e produzir as saídas no terminal, além de gerar automaticamente um `results_oral.csv` com a tabela de tempos/concentrações na pasta `data/`.

## 🌐 Dashboard Interativo

Para teres uma interface visual onde podes ajustar as doses e ver as curvas a atualizar em tempo real:

```bash
julia --project=. dashboard/app.jl
```
Abre o teu browser no endereço: `http://127.0.0.1:8050`

## 📊 Relatórios Regulamentares (PDF)

A função `generate_pdf_report(pop, compound, sol, dose, route, out_dir)` do nosso módulo `reports.jl` pega no modelo e produz um `report_XXX.qmd` preenchido.
Se tiveres o [Quarto](https://quarto.org/) instalado, basta compilares:

```bash
quarto render data/report_CustomDrug_Oral.qmd
```
*(Garante PDF perfeitamente formatado para dossiers de submissão)*

## 🔬 A Matemática Base

Não há segredos no **DoseFlow**. Eis o que acontece no motor:

*   **Absorção Oral**: $dM/dt = k_{diss} \times \max(C_s - C_{GI}, 0)$ e $dA_{absorvido} = k_a \times A_{Líquido}$
*   **Ionização (Henderson-Hasselbalch)**: Para um ácido: $f_{un} = \frac{1}{1 + 10^{(pH - pKa)}}$
*   **Clearance Hepático**: $CL_H = \frac{Q_L \cdot f_u \cdot CL_{int}}{Q_L + f_u \cdot CL_{int}}$
*   **Clearance Renal (GFR)**: $CL_R = f_u \cdot GFR$
*   **Efeito (Farmacodinâmica)**: Equação de Hill $E = \frac{E_{max} \cdot C^n}{EC50^n + C^n}$

---

*Criado para democratizar a ciência dos fármacos. Livre, aberto, exato.*
