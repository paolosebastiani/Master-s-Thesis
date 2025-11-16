clear all

// Set the path to your working directory
cd "C:\Users\paose\Desktop\Thesis"

// Open a log file to record all commands and output
capture log close
log using "Finished\MicrosimulationModel\log_microsimulation_southkorea.log", replace text

// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"

// ====================================================================================
//
//  SOUTH KOREA REGIME (https://citiesinsider.com/country/south-korea/CountryWide/inheritance-and-gift-tax/en)
//
// ====================================================================================

//==============================================================================
// 1. SETUP AND CONSTANTS
//==============================================================================

// The average exchange rate in 2022 was:
// https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/eurofxref-graph-krw.en.html
// --- Define South Korean tax parameters ---
scalar krw_to_eur = 0.0007363

// --- Scenario A Deduction (Standard) ---
scalar kor_deduction_a_krw = 500000000
scalar kor_deduction_a_eur = kor_deduction_a_krw * krw_to_eur

// --- Scenario B Deduction (Standard + Main Residence) ---
scalar kor_deduction_b_krw = 1100000000
scalar kor_deduction_b_eur = kor_deduction_b_krw * krw_to_eur

// Tax brackets (converted from KRW to EUR)
scalar kor_bracket1 = 100000000 * krw_to_eur
scalar kor_bracket2 = 500000000 * krw_to_eur
scalar kor_bracket3 = 1000000000 * krw_to_eur
scalar kor_bracket4 = 3000000000 * krw_to_eur

// --- Define current Italian tax parameters (parent-to-child) ---
scalar ita_tax_rate = 0.04
scalar ita_threshold_eur = 1000000

// Display constants for verification
di "S. Korean Deduction (Scenario A, EUR): " %12.0fc kor_deduction_a_eur
di "S. Korean Deduction (Scenario B, EUR): " %12.0fc kor_deduction_b_eur

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
// 3. SOUTH KOREAN TAX SIMULATION - SCENARIO A
//==============================================================================

// STEP 3.1 A: Calculate the taxable base
gen taxable_amount_kor_a = value_2022 - kor_deduction_a_eur if owner_status == 2
replace taxable_amount_kor_a = 0 if taxable_amount_kor_a < 0

// STEP 3.2 A: Compute the hypothetical tax due
gen tax_due_kor_a = 0
replace tax_due_kor_a = . if owner_status != 2

replace tax_due_kor_a = taxable_amount_kor_a * 0.10 if taxable_amount_kor_a > 0 & taxable_amount_kor_a <= kor_bracket1
replace tax_due_kor_a = (kor_bracket1 * 0.10) + (taxable_amount_kor_a - kor_bracket1) * 0.20 if taxable_amount_kor_a > kor_bracket1 & taxable_amount_kor_a <= kor_bracket2
replace tax_due_kor_a = (kor_bracket1 * 0.10) + (kor_bracket2 - kor_bracket1) * 0.20 + (taxable_amount_kor_a - kor_bracket2) * 0.30 if taxable_amount_kor_a > kor_bracket2 & taxable_amount_kor_a <= kor_bracket3
replace tax_due_kor_a = (kor_bracket1 * 0.10) + (kor_bracket2 - kor_bracket1) * 0.20 + (kor_bracket3 - kor_bracket2) * 0.30 + (taxable_amount_kor_a - kor_bracket3) * 0.40 if taxable_amount_kor_a > kor_bracket3 & taxable_amount_kor_a <= kor_bracket4
replace tax_due_kor_a = (kor_bracket1 * 0.10) + (kor_bracket2 - kor_bracket1) * 0.20 + (kor_bracket3 - kor_bracket2) * 0.30 + (kor_bracket4 - kor_bracket3) * 0.40 + (taxable_amount_kor_a - kor_bracket4) * 0.50 if taxable_amount_kor_a > kor_bracket4

label var tax_due_kor_a "Tax Due under South Korean Regime A"

// STEP 3.3 A: Calculate the ADDITIONAL tax due
gen additional_tax_kor_a = max(0, tax_due_kor_a - tax_due_ita)
label var additional_tax_kor_a "Additional Tax Due under South Korean Regime A Simulation"

//==============================================================================
// 4. REVENUE COLLECTION AND INTERMEDIATE GINI - SCENARIO A
//==============================================================================

// STEP 4.1 A: Compute the total ADDITIONAL revenue
svy: total additional_tax_kor_a
scalar total_revenue_a = e(b)[1,1]

// STEP 4.2 A: Create the post-reform wealth variable
gen net_wealth_posttax_a = net_wealth - additional_tax_kor_a

// STEP 4.3 A: Intermediate Gini ("Tax effect")
ineqdec0 net_wealth_posttax_a [pweight=universe_wt]

//==============================================================================
// 5. REDISTRIBUTION SCENARIO A1
//==============================================================================

// Define recipients and calculate the lump-sum transfer
gen is_recipient_scen_a1 = (wealth_dec == 1)
svy: total is_recipient_scen_a1
scalar num_recipients_scen_a1 = e(b)[1,1]
scalar transfer_amount_scen_a1 = total_revenue_a / num_recipients_scen_a1
display "Transfer per Household (Scenario A1): " %12.2f transfer_amount_scen_a1

// Distribute
gen net_wealth_scen_a1 = net_wealth_posttax_a
replace net_wealth_scen_a1 = net_wealth_scen_a1 + transfer_amount_scen_a1 if is_recipient_scen_a1 == 1

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen_a1 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/southkoreaA1.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop is_recipient_scen_a1 net_wealth_scen_a1
matrix drop G

//==============================================================================
// 6. REDISTRIBUTION SCENARIO A2
//==============================================================================

// --- Define recipients and their total number of components ---
gen is_recipient_scen_a2 = (wealth_dec == 1)
gen recipient_components_scen_a2 = is_recipient_scen_a2 * n_comp

svy: total recipient_components_scen_a2
scalar total_components_scen_a2 = e(b)[1,1]

// --- Calculate transfer amount PER COMPONENT ---
scalar transfer_per_comp_scen_a2 = total_revenue_a / total_components_scen_a2
display "Transfer per Household Component (Scenario A2): " %12.2f transfer_per_comp_scen_a2

// --- Create wealth variable and distribute transfers ---
gen net_wealth_scen_a2 = net_wealth_posttax_a
gen transfer_amount_scen_a2 = transfer_per_comp_scen_a2 * n_comp
replace net_wealth_scen_a2 = net_wealth_scen_a2 + transfer_amount_scen_a2 if is_recipient_scen_a2 == 1

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen_a2 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/southkoreaA2.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop is_recipient_scen_a2 recipient_components_scen_a2 transfer_amount_scen_a2 net_wealth_scen_a2
matrix drop G

//==============================================================================
// 7. REDISTRIBUTION SCENARIO A3
//==============================================================================

// --- Calculate number of total households and transfer amount ---
gen all_hh = 1
svy: total all_hh
scalar num_total_hh = e(b)[1,1]
scalar transfer_amount_scen_a3 = total_revenue_a / num_total_hh
display "Transfer per Household (Scenario A3): " %12.2f transfer_amount_scen_a3

// --- Create wealth variable and distribute transfers ---
gen net_wealth_scen_a3 = net_wealth_posttax_a + transfer_amount_scen_a3

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen_a3 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/southkoreaA3.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop all_hh net_wealth_scen_a3
matrix drop G

//==============================================================================
// 8. REDISTRIBUTION SCENARIO A4
//==============================================================================

// --- Calculate total number of components in the whole population ---
svy: total n_comp
scalar total_components_scen_a4 = e(b)[1,1]

// --- Calculate transfer amount PER COMPONENT ---
scalar transfer_per_comp_scen_a4 = total_revenue_a / total_components_scen_a4

// --- Create wealth variable and distribute transfers ---
gen transfer_amount_scen_a4 = transfer_per_comp_scen_a4 * n_comp
gen net_wealth_scen_a4 = net_wealth_posttax_a + transfer_amount_scen_a4

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen_a4 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/southkoreaA4.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop transfer_amount_scen_a4 net_wealth_scen_a4
matrix drop G

//==============================================================================
// 9. SOUTH KOREAN TAX SIMULATION - SCENARIO B
//==============================================================================

// STEP 9.1 B: Calculate the taxable base
gen taxable_amount_kor_b = value_2022 - kor_deduction_b_eur if owner_status == 2
replace taxable_amount_kor_b = 0 if taxable_amount_kor_b < 0

// STEP 9.2 B: Compute the hypothetical tax due
gen tax_due_kor_b = 0
replace tax_due_kor_b = . if owner_status != 2

replace tax_due_kor_b = taxable_amount_kor_b * 0.10 if taxable_amount_kor_b > 0 & taxable_amount_kor_b <= kor_bracket1
replace tax_due_kor_b = (kor_bracket1 * 0.10) + (taxable_amount_kor_b - kor_bracket1) * 0.20 if taxable_amount_kor_b > kor_bracket1 & taxable_amount_kor_b <= kor_bracket2
replace tax_due_kor_b = (kor_bracket1 * 0.10) + (kor_bracket2 - kor_bracket1) * 0.20 + (taxable_amount_kor_b - kor_bracket2) * 0.30 if taxable_amount_kor_b > kor_bracket2 & taxable_amount_kor_b <= kor_bracket3
replace tax_due_kor_b = (kor_bracket1 * 0.10) + (kor_bracket2 - kor_bracket1) * 0.20 + (kor_bracket3 - kor_bracket2) * 0.30 + (taxable_amount_kor_b - kor_bracket3) * 0.40 if taxable_amount_kor_b > kor_bracket3 & taxable_amount_kor_b <= kor_bracket4
replace tax_due_kor_b = (kor_bracket1 * 0.10) + (kor_bracket2 - kor_bracket1) * 0.20 + (kor_bracket3 - kor_bracket2) * 0.30 + (kor_bracket4 - kor_bracket3) * 0.40 + (taxable_amount_kor_b - kor_bracket4) * 0.50 if taxable_amount_kor_b > kor_bracket4

label var tax_due_kor_b "Tax Due under South Korean Regime B"

// STEP 9.3 B: Calculate the ADDITIONAL tax due
gen additional_tax_kor_b = max(0, tax_due_kor_b - tax_due_ita)
label var additional_tax_kor_b "Additional Tax Due under South Korean Regime B Simulation"

//==============================================================================
// 10. REVENUE COLLECTION AND INTERMEDIATE GINI - SCENARIO B
//==============================================================================

// STEP 10.1 B: Compute the total ADDITIONAL revenue
svy: total additional_tax_kor_b
scalar total_revenue_b = e(b)[1,1]

// STEP 10.2 B: Create the post-reform wealth variable
gen net_wealth_posttax_b = net_wealth - additional_tax_kor_b

// STEP 10.3 B: Intermediate Gini ("Tax effect")
ineqdec0 net_wealth_posttax_b [pweight=universe_wt]

//==============================================================================
// 11. REDISTRIBUTION SCENARIO B1
//==============================================================================

// Define recipients and calculate the lump-sum transfer
gen is_recipient_scen_b1 = (wealth_dec == 1)
svy: total is_recipient_scen_b1
scalar num_recipients_scen_b1 = e(b)[1,1]
scalar transfer_amount_scen_b1 = total_revenue_b / num_recipients_scen_b1
display "Transfer per Household (Scenario B1): " %12.2f transfer_amount_scen_b1

// Distribute
gen net_wealth_scen_b1 = net_wealth_posttax_b
replace net_wealth_scen_b1 = net_wealth_scen_b1 + transfer_amount_scen_b1 if is_recipient_scen_b1 == 1

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen_b1 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/southkoreaB1.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop is_recipient_scen_b1 net_wealth_scen_b1
matrix drop G

//==============================================================================
// 12. REDISTRIBUTION SCENARIO B2
//==============================================================================

// --- Define recipients and their total number of components ---
gen is_recipient_scen_b2 = (wealth_dec == 1)
gen recipient_components_scen_b2 = is_recipient_scen_b2 * n_comp

svy: total recipient_components_scen_b2
scalar total_components_scen_b2 = e(b)[1,1]

// --- Calculate transfer amount PER COMPONENT ---
scalar transfer_per_comp_scen_b2 = total_revenue_b / total_components_scen_b2
display "Transfer per Household Component (Scenario B2): " %12.2f transfer_per_comp_scen_b2

// --- Create wealth variable and distribute transfers ---
gen net_wealth_scen_b2 = net_wealth_posttax_b
gen transfer_amount_scen_b2 = transfer_per_comp_scen_b2 * n_comp
replace net_wealth_scen_b2 = net_wealth_scen_b2 + transfer_amount_scen_b2 if is_recipient_scen_b2 == 1

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen_b2 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/southkoreaB2.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop is_recipient_scen_b2 recipient_components_scen_b2 transfer_amount_scen_b2 net_wealth_scen_b2
matrix drop G

//==============================================================================
// 13. REDISTRIBUTION SCENARIO B3
//==============================================================================

// --- Calculate number of total households and transfer amount ---
gen all_hh_b = 1
svy: total all_hh_b
scalar num_total_hh_b = e(b)[1,1]
scalar transfer_amount_scen_b3 = total_revenue_b / num_total_hh_b
display "Transfer per Household (Scenario B3): " %12.2f transfer_amount_scen_b3

// --- Create wealth variable and distribute transfers ---
gen net_wealth_scen_b3 = net_wealth_posttax_b + transfer_amount_scen_b3

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen_b3 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/southkoreaB3.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop all_hh_b net_wealth_scen_b3
matrix drop G

//==============================================================================
// 14. REDISTRIBUTION SCENARIO B4
//==============================================================================

// --- Calculate total number of components in the whole population ---
svy: total n_comp
scalar total_components_scen_b4 = e(b)[1,1]

// --- Calculate transfer amount PER COMPONENT ---
scalar transfer_per_comp_scen_b4 = total_revenue_b / total_components_scen_b4

// --- Create wealth variable and distribute transfers ---
gen transfer_amount_scen_b4 = transfer_per_comp_scen_b4 * n_comp
gen net_wealth_scen_b4 = net_wealth_posttax_b + transfer_amount_scen_b4

// --- Calculate and export post-reform inequality ---
ineqdec0 net_wealth_scen_b4 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/southkoreaB4.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop transfer_amount_scen_b4 net_wealth_scen_b4
matrix drop G


// Close the log 
log close
