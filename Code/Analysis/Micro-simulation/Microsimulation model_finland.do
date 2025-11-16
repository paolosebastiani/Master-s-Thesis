clear all

// Set the path to your working directory
cd "C:\Users\paose\Desktop\Thesis"

// Open a log file to record all commands and output
capture log close
log using "Finished\MicrosimulationModel\log_microsimulation_finland.log", replace text

// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"

// ====================================================================================
//
//  FINLAND REGIME (https://www.vero.fi/en/individuals/property/inheritance/inheritance-tax-calculator/)
//
// ====================================================================================

//==============================================================================
// 1. SETUP AND CONSTANTS
//==============================================================================

// --- Define Finnish tax parameters for 2022 ---
scalar fin_allowance = 19999

// Brackets for taxable value (after allowance)
scalar fin_bracket1_min = 20000
scalar fin_bracket1_max = 40000
scalar fin_bracket2_max = 60000
scalar fin_bracket3_max = 200000
scalar fin_bracket4_max = 1000000

// Lump-sum tax at the start of each bracket
scalar fin_lumpsum1 = 100
scalar fin_lumpsum2 = 1500
scalar fin_lumpsum3 = 3500
scalar fin_lumpsum4 = 21700
scalar fin_lumpsum5 = 149700

// Marginal tax rates on the exceeding portion
scalar fin_rate1 = 0.07
scalar fin_rate2 = 0.10
scalar fin_rate3 = 0.13
scalar fin_rate4 = 0.16
scalar fin_rate5 = 0.19

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
// 3. FINNISH TAX SIMULATION
//==============================================================================

// STEP 3.1: Calculate the taxable base after the allowance
gen taxable_amount_fin = 0
replace taxable_amount_fin = . if owner_status != 2
replace taxable_amount_fin = value_2022 - fin_allowance if owner_status == 2
replace taxable_amount_fin = 0 if taxable_amount_fin < 0

// STEP 3.2: Calculate the tax due under Finnish rules
gen tax_due_fin = 0
replace tax_due_fin = . if owner_status != 2

replace tax_due_fin = fin_lumpsum1 + (taxable_amount_fin - fin_bracket1_min) * fin_rate1 if taxable_amount_fin >= fin_bracket1_min & taxable_amount_fin <= fin_bracket1_max
replace tax_due_fin = fin_lumpsum2 + (taxable_amount_fin - fin_bracket1_max) * fin_rate2 if taxable_amount_fin > fin_bracket1_max & taxable_amount_fin <= fin_bracket2_max
replace tax_due_fin = fin_lumpsum3 + (taxable_amount_fin - fin_bracket2_max) * fin_rate3 if taxable_amount_fin > fin_bracket2_max & taxable_amount_fin <= fin_bracket3_max
replace tax_due_fin = fin_lumpsum4 + (taxable_amount_fin - fin_bracket3_max) * fin_rate4 if taxable_amount_fin > fin_bracket3_max & taxable_amount_fin <= fin_bracket4_max
replace tax_due_fin = fin_lumpsum5 + (taxable_amount_fin - fin_bracket4_max) * fin_rate5 if taxable_amount_fin > fin_bracket4_max

replace tax_due_fin = 0 if tax_due_fin < 0
label var tax_due_fin "Tax Due under Finnish Regime"

// STEP 3.3: Calculate the ADDITIONAL tax due under the reform
gen additional_tax_fin = max(0, tax_due_fin - tax_due_ita)
label var additional_tax_fin "Additional Tax Due under Finnish Regime Simulation"

//==============================================================================
// 4. REVENUE COLLECTION AND INTERMEDIATE GINI
//==============================================================================

// STEP 4.1: Compute the total ADDITIONAL revenue
svy: total additional_tax_fin
scalar total_revenue = e(b)[1,1]

// STEP 4.2: Create the post-reform wealth variable
gen net_wealth_posttax = net_wealth - additional_tax_fin

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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/finland1.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop is_recipient_scen1 net_wealth_scen1
matrix drop G


//==============================================================================
// 6. REDISTRIBUTION SCENARIO 2
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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/finland2.tex", replace label booktabs


// --- Clean up scenario-specific variables ---
drop is_recipient_scen2 recipient_components_scen2 transfer_amount_scen2 net_wealth_scen2
matrix drop G



//==============================================================================
// 7. REDISTRIBUTION SCENARIO 3
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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/finland3.tex", replace label booktabs


// --- Clean up scenario-specific variables ---
drop all_hh net_wealth_scen3
matrix drop G


//==============================================================================
// 8. REDISTRIBUTION SCENARIO 4
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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/finland4.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop transfer_amount_scen4 net_wealth_scen4
matrix drop G


// Close the log 
log close
