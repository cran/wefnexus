## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(wefnexus)
# Silence informational messages from all wefnexus functions
options(wefnexus.verbose = FALSE)
has_gg <- requireNamespace("ggplot2", quietly = TRUE)

## ----data---------------------------------------------------------------------
data(arid_pulse_nexus)
d <- arid_pulse_nexus
str(d)

## ----water--------------------------------------------------------------------
# Water Use Efficiency
wue <- water_use_efficiency(d$grain_yield, d$total_water)

# Crop Water Productivity
cwp <- crop_water_productivity(d$grain_yield, d$crop_et)

# Water Footprint (green + blue)
wf <- water_footprint(
  green_water = d$effective_rainfall,
  blue_water = d$irrigation_applied,
  yield = d$grain_yield
)
wf

## ----energy-------------------------------------------------------------------
# Total energy output
e_out <- d$energy_output_grain + d$energy_output_straw

# Energy Use Efficiency
eue <- energy_use_efficiency(e_out, d$energy_input)

# Energy Return on Investment (EROI)
eroi_values <- eroi(e_out, d$energy_input)

# Net Energy Balance
ne <- net_energy(e_out, d$energy_input)

# Compare treatments
data.frame(Treatment = d$treatment, EUE = eue, EROI = eroi_values,
           Net_Energy = ne)

## ----energy-budget------------------------------------------------------------
head(energy_coefficients[, c("input", "unit", "mj_per_unit", "form",
                             "source")])

inputs <- data.frame(
  treatment = c("CT+Flood", "ZT+Drip"),
  human_labour_man = c(320, 240),
  diesel = c(65, 38),
  electricity = c(180, 75),
  nitrogen = c(20, 20),
  phosphorus = c(40, 40),
  seed = c(20, 20),
  herbicide = c(0, 0.75),
  grain = c(980, 1280),
  straw = c(1450, 1850)
)
eb <- energy_budget(inputs)
eb$summary[, c("treatment", "total_input_MJ", "direct_pct",
               "renewable_pct", "EUE", "energy_intensity_MJ_kg")]

## ----energy-plot, fig.width = 7.5, fig.height = 3.4, eval = has_gg------------
plot(eb)
plot(eb, type = "source", percent = TRUE)

## ----food---------------------------------------------------------------------
# Harvest Index
bio_yield <- d$grain_yield + d$straw_yield
hi <- harvest_index(d$grain_yield, bio_yield)

# Protein Yield (assuming 22% protein in pulses)
py <- protein_yield(d$grain_yield, protein_content = 22)

data.frame(Treatment = d$treatment, HI = hi, Protein_kg_ha = py)

## ----nutrient-----------------------------------------------------------------
# Partial Factor Productivity of N
pfp <- partial_factor_productivity(d$grain_yield, d$n_applied)

# Nutrient Harvest Index for N
nhi <- nutrient_harvest_index(d$grain_n_uptake, d$n_uptake)

data.frame(Treatment = d$treatment, PFP_N = pfp, NHI_N = nhi)

## ----carbon-------------------------------------------------------------------
# Carbon Footprint (IPCC AR6 GWP: CH4=27, N2O=273)
cf <- carbon_footprint(
  diesel_use = d$diesel_use[1],
  electricity_use = d$electricity_kwh[1],
  n_fertilizer = d$n_applied[1],
  p_fertilizer = d$p_applied[1],
  yield = d$grain_yield[1],
  ef_n2o = 0.005
)
cf$breakdown

# Soil Carbon Stock
soc <- soil_carbon_stock(d$soc_pct, d$bulk_density, depth = 30)

# Global Warming Potential (example)
gwp100 <- global_warming_potential(co2 = 500, ch4 = 10, n2o = 2)
gwp20 <- global_warming_potential(co2 = 500, ch4 = 10, n2o = 2,
                                   time_horizon = "20yr")

## ----nexus--------------------------------------------------------------------
# Full Nexus Summary
ns <- nexus_summary(
  yield = d$grain_yield,
  water_consumed = d$total_water,
  energy_input = d$energy_input,
  energy_output = e_out,
  n_applied = d$n_applied,
  n_uptake = d$n_uptake,
  carbon_emission = d$ghg_emission,
  treatment_names = d$treatment,
  nutrient_metric = "iue",
  carbon_basis = "intensity"
)
ns[, c("treatment", "EROI", "nexus_index")]

## ----radar, fig.width=7, fig.height=6-----------------------------------------
scores <- as.matrix(ns[, c("W_score", "E_score", "F_score",
                             "N_score", "C_score")])
nexus_radar(scores, treatment_names = d$treatment)

## ----sustainability-----------------------------------------------------------
nss <- nexus_sustainability_score(
  water_score = ns$W_score,
  energy_score = ns$E_score,
  food_score = ns$F_score,
  nutrient_score = ns$N_score,
  carbon_score = ns$C_score
)
nss[, c("nexus_score", "category")]

## ----weights------------------------------------------------------------------
ind <- data.frame(
  WUE = ns$WUE_kg_mm,
  EUE = ns$EUE_ratio,
  Yield = ns$yield_kg_ha,
  IUE = ns$IUE_kg_kgN,
  CI = ns$carbon_intensity
)
benefit <- c(TRUE, TRUE, TRUE, TRUE, FALSE)  # lower carbon intensity is better

rbind(
  entropy = nexus_weights(ind, "entropy", benefit),
  critic  = nexus_weights(ind, "critic", benefit),
  pca     = nexus_weights(ind, "pca", benefit)
)

nexus_topsis(ind, weights = "entropy", benefit = benefit,
             treatment_names = d$treatment)

## ----robustness---------------------------------------------------------------
rc <- nexus_rank_compare(ind, benefit = benefit,
                         treatment_names = d$treatment)
rc

## ----robustness-plot, fig.width = 8, fig.height = 4.2, eval = has_gg----------
plot(rc)

## ----tradeoff, fig.width = 6, fig.height = 4.8, eval = has_gg-----------------
plot_tradeoff(nexus_tradeoff(ind), benefit = benefit)

## ----workflow-----------------------------------------------------------------
data(arid_pulse_trial)
res <- nexus_analysis(
  arid_pulse_trial,
  treatment = "treatment", block = "replication",
  yield = "grain_yield", water = "total_water",
  energy_in = "energy_input", energy_out = "energy_output",
  emission = "ghg_emission", n_uptake = "n_uptake",
  weights = "entropy", carbon_basis = "intensity"
)
res

## ----anova--------------------------------------------------------------------
res$anova

## ----fig-anova, fig.width = 8, fig.height = 5.6, eval = has_gg----------------
plot(res$anova, response = c("grain_yield", "WUE", "EUE", "CI"),
     labels = c(grain_yield = "Grain yield (kg/ha)",
                WUE = "WUE (kg/ha/mm)",
                EUE = "Energy use efficiency",
                CI = "Carbon intensity (kg CO2-eq/kg)"),
     ncol = 2)

## ----fig-radar, fig.width = 8, fig.height = 5.4, eval = has_gg----------------
plot(res)                    # one radar per treatment

## ----fig-topsis, fig.width = 7, fig.height = 3.4, eval = has_gg---------------
plot(res, which = "topsis")

