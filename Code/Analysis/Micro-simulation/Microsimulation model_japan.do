clear all

// Set the path to your working directory
cd "C:\Users\paose\Desktop\Thesis"

// Open a log file to record all commands and output
capture log close
log using "Finished\MicrosimulationModel\log_microsimulation_japan.log", replace text

// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"


// =============================================================================
//
//   JAPANESE REGIME (https://taxsummaries.pwc.com/japan/individual/other-taxes)
//
// =============================================================================

// For simplicity, the number of legal heirs is assumed to be 1 child 
// (justified by being the most frequent value
// see svy: tab n_comp if owner_status == 2)

// The rates does not depend on the degree of parental relationship.
// The inherited wealth value has an initial automatic deduction of 30M JPY +
// (6M JPY x # of legal heirs).

//==============================================================================
// 1. SETUP AND CONSTANTS
//==============================================================================
// Firstly, the tresholds have to be converted from JPY to EUR
// The average exchange rate in 2022 was:
// https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/eurofxref-graph-jpy.en.html
scalar jpy_to_eur = 0.007245
scalar num_heirs = 1 // Key assumption as per the analysis plan

// Basic deduction = 30M JPY + (6M JPY * Number of Heirs)
scalar jpn_deduction_jpy = 30000000 + (6000000 * num_heirs)
scalar jpn_deduction_eur = jpn_deduction_jpy * jpy_to_eur

// Tax brackets (converted from JPY to EUR)
scalar jpn_bracket1 = 10000000 * jpy_to_eur
scalar jpn_bracket2 = 30000000 * jpy_to_eur
scalar jpn_bracket3 = 50000000 * jpy_to_eur
scalar jpn_bracket4 = 100000000 * jpy_to_eur
scalar jpn_bracket5 = 200000000 * jpy_to_eur
scalar jpn_bracket6 = 300000000 * jpy_to_eur
scalar jpn_bracket7 = 600000000 * jpy_to_eur

// --- Define current Italian tax parameters (parent-to-child) ---
scalar ita_tax_rate = 0.04
scalar ita_threshold_eur = 1000000

// Display constants for verification
di "Japanese Total Deduction (EUR): " %12.0fc jpn_deduction_eur

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
// 3. JAPANESE TAX SIMULATION
//==============================================================================

// STEP 3.1: Calculate the taxable base under Japanese rules
gen taxable_amount_jpn = value_2022 - jpn_deduction_eur if owner_status == 2
replace taxable_amount_jpn = 0 if taxable_amount_jpn < 0

// STEP 3.2: Compute the hypothetical tax due with progressive brackets
gen tax_due_jpn = 0
replace tax_due_jpn = . if owner_status != 2

replace tax_due_jpn = taxable_amount_jpn * 0.10 if taxable_amount_jpn > 0 & taxable_amount_jpn <= jpn_bracket1
replace tax_due_jpn = (jpn_bracket1 * 0.10) + (taxable_amount_jpn - jpn_bracket1) * 0.15 if taxable_amount_jpn > jpn_bracket1 & taxable_amount_jpn <= jpn_bracket2
replace tax_due_jpn = (jpn_bracket1 * 0.10) + (jpn_bracket2 - jpn_bracket1) * 0.15 + (taxable_amount_jpn - jpn_bracket2) * 0.20 if taxable_amount_jpn > jpn_bracket2 & taxable_amount_jpn <= jpn_bracket3
replace tax_due_jpn = (jpn_bracket1 * 0.10) + (jpn_bracket2 - jpn_bracket1) * 0.15 + (jpn_bracket3 - jpn_bracket2) * 0.20 + (taxable_amount_jpn - jpn_bracket3) * 0.30 if taxable_amount_jpn > jpn_bracket3 & taxable_amount_jpn <= jpn_bracket4
replace tax_due_jpn = (jpn_bracket1 * 0.10) + (jpn_bracket2 - jpn_bracket1) * 0.15 + (jpn_bracket3 - jpn_bracket2) * 0.20 + (jpn_bracket4 - jpn_bracket3) * 0.30 + (taxable_amount_jpn - jpn_bracket4) * 0.40 if taxable_amount_jpn > jpn_bracket4 & taxable_amount_jpn <= jpn_bracket5
replace tax_due_jpn = (jpn_bracket1 * 0.10) + (jpn_bracket2 - jpn_bracket1) * 0.15 + (jpn_bracket3 - jpn_bracket2) * 0.20 + (jpn_bracket4 - jpn_bracket3) * 0.30 + (jpn_bracket5 - jpn_bracket4) * 0.40 + (taxable_amount_jpn - jpn_bracket5) * 0.45 if taxable_amount_jpn > jpn_bracket5 & taxable_amount_jpn <= jpn_bracket6
replace tax_due_jpn = (jpn_bracket1 * 0.10) + (jpn_bracket2 - jpn_bracket1) * 0.15 + (jpn_bracket3 - jpn_bracket2) * 0.20 + (jpn_bracket4 - jpn_bracket3) * 0.30 + (jpn_bracket5 - jpn_bracket4) * 0.40 + (jpn_bracket6 - jpn_bracket5) * 0.45 + (taxable_amount_jpn - jpn_bracket6) * 0.50 if taxable_amount_jpn > jpn_bracket6 & taxable_amount_jpn <= jpn_bracket7
replace tax_due_jpn = (jpn_bracket1 * 0.10) + (jpn_bracket2 - jpn_bracket1) * 0.15 + (jpn_bracket3 - jpn_bracket2) * 0.20 + (jpn_bracket4 - jpn_bracket3) * 0.30 + (jpn_bracket5 - jpn_bracket4) * 0.40 + (jpn_bracket6 - jpn_bracket5) * 0.45 + (jpn_bracket7 - jpn_bracket6) * 0.50 + (taxable_amount_jpn - jpn_bracket7) * 0.55 if taxable_amount_jpn > jpn_bracket7

// STEP 3.3: Calculate the ADDITIONAL tax due under the reform
gen additional_tax_jpn = max(0, tax_due_jpn - tax_due_ita)
label var additional_tax_jpn "Additional Tax Due under Japanese Regime Simulation"

//==============================================================================
// 4. REVENUE COLLECTION AND INTERMEDIATE GINI
//==============================================================================

// STEP 4.1: Compute the total ADDITIONAL revenue
svy: total additional_tax_jpn
scalar total_revenue = e(b)[1,1]

// STEP 4.2: Create the post-reform wealth variable
gen net_wealth_posttax = net_wealth - additional_tax_jpn

// STEP 4.3: Intermediate Gini ("Tax effect")
ineqdec0 net_wealth_posttax [pweight=universe_wt]

// S80/S20
sumdist net_wealth_posttax [pweight=universe_wt], ngp(5)
matrix shares = r(shares)
di "S80/S20 Ratio:" shares[1,5]/shares[1,1]
matrix drop shares


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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/japan1.tex", replace label booktabs

// S80/S20
sumdist net_wealth_scen1 [pweight=universe_wt], ngp(5)
matrix shares = r(shares)
di "S80/S20 Ratio:" shares[1,5]/shares[1,1]
matrix drop shares

// WINNERS/LOSERS RATIO
gen winner_loser_status = 0
replace winner_loser_status = 1 if net_wealth_scen1 > (net_wealth * 1.01)
replace winner_loser_status = -1 if net_wealth_scen1 < (net_wealth * 0.99)
gen winner = (winner_loser_status == 1)
gen loser = (winner_loser_status == -1)
quietly svy: total winner
scalar total_winners = e(b)[1,1]
quietly svy: total loser
scalar total_losers = e(b)[1,1]
scalar ratio_wl = total_winners / total_losers
display "-----------------------------------------"
display "Winners-to-Losers Ratio = " %4.2f ratio_wl
display "-----------------------------------------"
drop winner_loser_status winner loser 
scalar drop total_winners total_losers ratio_wl


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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/japan2.tex", replace label booktabs


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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/japan3.tex", replace label booktabs

// S80/S20
sumdist net_wealth_scen3 [pweight=universe_wt], ngp(5)
matrix shares = r(shares)
di "S80/S20 Ratio:" shares[1,5]/shares[1,1]
matrix drop shares


// WINNERS/LOSERS RATIO
gen winner_loser_status = 0
replace winner_loser_status = 1 if net_wealth_scen3 > (net_wealth * 1.01)
replace winner_loser_status = -1 if net_wealth_scen3 < (net_wealth * 0.99)
gen winner = (winner_loser_status == 1)
gen loser = (winner_loser_status == -1)
quietly svy: total winner
scalar total_winners = e(b)[1,1]
quietly svy: total loser
scalar total_losers = e(b)[1,1]
scalar ratio_wl = total_winners / total_losers
display "-----------------------------------------"
display "Winners-to-Losers Ratio = " %4.2f ratio_wl
display "-----------------------------------------"
drop winner_loser_status winner loser 
scalar drop total_winners total_losers ratio_wl

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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/japan4.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop transfer_amount_scen4 net_wealth_scen4
matrix drop G



// =============================================================================
// CLOSE THE LOG
log close
