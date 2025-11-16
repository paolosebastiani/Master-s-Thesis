clear all

// Set the path to your working directory
cd "C:\Users\paose\Desktop\Thesis"

// Open a log file to record all commands and output
capture log close
log using "Finished\MicrosimulationModel\log_microsimulation_ecuador.log", replace text

// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"

// ====================================================================================
//
//  ECUADOR REGIME (https://www.sri.gob.ec/impuesto-a-la-renta-de-ingresos-provenientes-de-herencias-legados-y-donaciones#%C2%BFqu%C3%A9-es?)
//
// ====================================================================================

// Ecuador uses US Dollars.
// The average exchange rate in 2022 was:
// https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/eurofxref-graph-usd.en.html

//==============================================================================
// 1. SETUP AND CONSTANTS
//==============================================================================

// --- Define Ecuadorian tax parameters for 2022 ---
scalar usd_to_eur_2022 = 0.9497

// Tax brackets (converted from USD to EUR)
scalar ecu_bracket1 = 72750 * usd_to_eur_2022
scalar ecu_bracket2 = 145501 * usd_to_eur_2022
scalar ecu_bracket3 = 291002 * usd_to_eur_2022
scalar ecu_bracket4 = 436534 * usd_to_eur_2022
scalar ecu_bracket5 = 582055 * usd_to_eur_2022
scalar ecu_bracket6 = 727555 * usd_to_eur_2022
scalar ecu_bracket7 = 873037 * usd_to_eur_2022

// --- Define current Italian tax parameters (parent-to-child) ---
scalar ita_tax_rate = 0.04
scalar ita_threshold_eur = 1000000

//==============================================================================
// 2. BASELINE AND COMMON CALCULATIONS
//==============================================================================

// --- Baseline Wealth Inequality (Pre-Reform) ---
ineqdec0 net_wealth [pweight=universe_wt], by(inheritor)

// --- Calculate tax already paid under current Italian rules ---
gen tax_due_ita = 0
replace tax_due_ita = . if owner_status != 2

replace tax_due_ita = (value_2022 - ita_threshold_eur) * ita_tax_rate ///
    if owner_status == 2 & value_2022 > ita_threshold_eur

replace tax_due_ita = 0 if tax_due_ita < 0
label var tax_due_ita "Tax Paid under Current Italian Regime"

//==============================================================================
// 3. ECUADORIAN TAX SIMULATION
//==============================================================================

// STEP 3.1: Calculate the GROSS tax due with progressive brackets
gen tax_due_ecu_gross = 0
replace tax_due_ecu_gross = . if owner_status != 2

// Calculate tax progressively, bracket by bracket
// Note: The first bracket (up to ecu_bracket1) is 0-rated
replace tax_due_ecu_gross = (value_2022 - ecu_bracket1) * 0.05 if value_2022 > ecu_bracket1 & value_2022 <= ecu_bracket2
replace tax_due_ecu_gross = ((ecu_bracket2 - ecu_bracket1) * 0.05) + ((value_2022 - ecu_bracket2) * 0.10) if value_2022 > ecu_bracket2 & value_2022 <= ecu_bracket3
replace tax_due_ecu_gross = ((ecu_bracket2 - ecu_bracket1) * 0.05) + ((ecu_bracket3 - ecu_bracket2) * 0.10) + ((value_2022 - ecu_bracket3) * 0.15) if value_2022 > ecu_bracket3 & value_2022 <= ecu_bracket4
replace tax_due_ecu_gross = ((ecu_bracket2 - ecu_bracket1) * 0.05) + ((ecu_bracket3 - ecu_bracket2) * 0.10) + ((ecu_bracket4 - ecu_bracket3) * 0.15) + ((value_2022 - ecu_bracket4) * 0.20) if value_2022 > ecu_bracket4 & value_2022 <= ecu_bracket5
replace tax_due_ecu_gross = ((ecu_bracket2 - ecu_bracket1) * 0.05) + ((ecu_bracket3 - ecu_bracket2) * 0.10) + ((ecu_bracket4 - ecu_bracket3) * 0.15) + ((ecu_bracket5 - ecu_bracket4) * 0.20) + ((value_2022 - ecu_bracket5) * 0.25) if value_2022 > ecu_bracket5 & value_2022 <= ecu_bracket6
replace tax_due_ecu_gross = ((ecu_bracket2 - ecu_bracket1) * 0.05) + ((ecu_bracket3 - ecu_bracket2) * 0.10) + ((ecu_bracket4 - ecu_bracket3) * 0.15) + ((ecu_bracket5 - ecu_bracket4) * 0.20) + ((ecu_bracket6 - ecu_bracket5) * 0.25) + ((value_2022 - ecu_bracket6) * 0.30) if value_2022 > ecu_bracket6 & value_2022 <= ecu_bracket7
replace tax_due_ecu_gross = ((ecu_bracket2 - ecu_bracket1) * 0.05) + ((ecu_bracket3 - ecu_bracket2) * 0.10) + ((ecu_bracket4 - ecu_bracket3) * 0.15) + ((ecu_bracket5 - ecu_bracket4) * 0.20) + ((ecu_bracket6 - ecu_bracket5) * 0.25) + ((ecu_bracket7 - ecu_bracket6) * 0.30) + ((value_2022 - ecu_bracket7) * 0.35) if value_2022 > ecu_bracket7

// STEP 3.2: Apply the 50% tax reduction for children
gen tax_due_ecu = tax_due_ecu_gross * 0.50
label var tax_due_ecu "Final Tax Due under Ecuadorian Regime"

// STEP 3.3: Calculate the ADDITIONAL tax due under the reform
gen additional_tax_ecu = max(0, tax_due_ecu - tax_due_ita)
label var additional_tax_ecu "Additional Tax Due under Ecuadorian Regime Simulation"

//==============================================================================
// 4. REVENUE COLLECTION AND INTERMEDIATE GINI
//==============================================================================

// STEP 4.1: Compute the total ADDITIONAL revenue
svy: total additional_tax_ecu
scalar total_revenue = e(b)[1,1]

// STEP 4.2: Create the post-reform wealth variable
gen net_wealth_posttax = net_wealth - additional_tax_ecu

// STEP 4.3: Intermediate Gini ("Tax effect")
ineqdec0 net_wealth_posttax [pweight=universe_wt]


//==============================================================================
// 5. REDISTRIBUTION SCENARIO 1
//==============================================================================

// Define recipients and calculate the lump-sum transfer
gen is_recipient_scen1 = (wealth_dec == 1)
svy: total is_recipient_scen1
scalar num_recipients_scen1 = e(b)[1,1]
scalar transfer_amount_scen1 = total_revenue / num_recipients_scen1
display "Transfer per Household (Scenario 1): " %12.2f transfer_amount_scen1

// Distribute
gen net_wealth_scen1 = net_wealth_posttax
replace net_wealth_scen1 = net_wealth_scen1 + transfer_amount_scen1 if is_recipient_scen1 == 1

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen1 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/ecuador1.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop is_recipient_scen1 net_wealth_scen1
matrix drop G


//==============================================================================
// 5. REDISTRIBUTION SCENARIO 2
//==============================================================================

// --- Define recipients and their total number of components ---
gen is_recipient_scen2 = (wealth_dec == 1)
gen recipient_components_scen2 = is_recipient_scen2 * n_comp

svy: total recipient_components_scen2
scalar total_components_scen2 = e(b)[1,1]

// --- Calculate transfer amount PER COMPONENT ---
scalar transfer_per_comp_scen2 = total_revenue / total_components_scen2
display "Transfer per Household Component (Scenario 2): " %12.2f transfer_per_comp_scen2

// --- Create wealth variable and distribute transfers ---
gen net_wealth_scen2 = net_wealth_posttax
gen transfer_amount_scen2 = transfer_per_comp_scen2 * n_comp
replace net_wealth_scen2 = net_wealth_scen2 + transfer_amount_scen2 if is_recipient_scen2 == 1

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen2 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/ecuador2.tex", replace label booktabs


// --- Clean up scenario-specific variables ---
drop is_recipient_scen2 recipient_components_scen2 transfer_amount_scen2 net_wealth_scen2
matrix drop G



//==============================================================================
// 5. REDISTRIBUTION SCENARIO 3
//==============================================================================
// --- Calculate number of total households and transfer amount ---
gen all_hh = 1
svy: total all_hh
scalar num_total_hh = e(b)[1,1]
scalar transfer_amount_scen3 = total_revenue / num_total_hh
display "Transfer per Household (Scenario 3): " %12.2f transfer_amount_scen3

// --- Create wealth variable and distribute transfers ---
gen net_wealth_scen3 = net_wealth_posttax + transfer_amount_scen3

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen3 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/ecuador3.tex", replace label booktabs


// --- Clean up scenario-specific variables ---
drop all_hh net_wealth_scen3
matrix drop G


//==============================================================================
// 5. REDISTRIBUTION SCENARIO 4
//==============================================================================
// --- Calculate total number of components in the whole population ---
svy: total n_comp
scalar total_components_scen4 = e(b)[1,1]

// --- Calculate transfer amount PER COMPONENT ---
scalar transfer_per_comp_scen4 = total_revenue / total_components_scen4

// --- Create wealth variable and distribute transfers ---
gen transfer_amount_scen4 = transfer_per_comp_scen4 * n_comp
gen net_wealth_scen4 = net_wealth_posttax + transfer_amount_scen4

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen4 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/ecuador4.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop transfer_amount_scen4 net_wealth_scen4
matrix drop G


// Close the log 
log close
