clear all

// Set the path to your working directory
cd "C:\Users\paose\Desktop\Thesis"

// Open a log file to record all commands and output
capture log close
log using "Finished\MicrosimulationModel\log_microsimulation_spain.log", replace text

// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"

// ====================================================================================
//
//  SPANISH REGIME (https://www.boe.es/buscar/act.php?id=BOE-A-1987-28141&tn=1&p=20221228)
//
// ====================================================================================
* Assumptions:
* 1. National law is used, ignoring regional variations.
* 2. All heirs are considered "Group II" (children over 21).
* 3. The variable `selfmade_wealth` represents the heir's pre-existing wealth.

//==============================================================================
// 1. SETUP AND CONSTANTS
//==============================================================================

// --- Define Spanish tax parameters ---
// Allowance for Group II children
scalar esp_allowance = 15956.87

// Progressive tax brackets (Base liquidable - "Taxable base")
scalar esp_bracket1 = 7993.46
scalar esp_bracket2 = 15980.91
scalar esp_bracket3 = 23968.36
scalar esp_bracket4 = 31955.81
scalar esp_bracket5 = 39943.26
scalar esp_bracket6 = 47930.72
scalar esp_bracket7 = 55918.17
scalar esp_bracket8 = 63905.62
scalar esp_bracket9 = 71893.07
scalar esp_bracket10 = 79880.52
scalar esp_bracket11 = 119757.67
scalar esp_bracket12 = 159634.83
scalar esp_bracket13 = 239389.13
scalar esp_bracket14 = 398777.54
scalar esp_bracket15 = 797555.08

// Multiplier thresholds based on pre-existing wealth (`selfmade_wealth`)
scalar esp_mult_thresh1 = 402678.11
scalar esp_mult_thresh2 = 2007380.43
scalar esp_mult_thresh3 = 4020770.98

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
// 3. SPANISH TAX SIMULATION
//==============================================================================

// STEP 3.1: Calculate the taxable amount after the allowance
gen taxable_amount_esp = 0
replace taxable_amount_esp = . if owner_status != 2
replace taxable_amount_esp = value_2022 - esp_allowance if owner_status == 2
replace taxable_amount_esp = 0 if taxable_amount_esp < 0

// STEP 3.2: Calculate the INITIAL tax bill using progressive rates
gen initial_tax_esp = 0
replace initial_tax_esp = . if owner_status != 2

replace initial_tax_esp = taxable_amount_esp * 0.0765 if taxable_amount_esp > 0 & taxable_amount_esp <= esp_bracket1
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (taxable_amount_esp - esp_bracket1) * 0.085 if taxable_amount_esp > esp_bracket1 & taxable_amount_esp <= esp_bracket2
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (taxable_amount_esp - esp_bracket2) * 0.0935 if taxable_amount_esp > esp_bracket2 & taxable_amount_esp <= esp_bracket3
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (taxable_amount_esp - esp_bracket3) * 0.102 if taxable_amount_esp > esp_bracket3 & taxable_amount_esp <= esp_bracket4
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (taxable_amount_esp - esp_bracket4) * 0.1105 if taxable_amount_esp > esp_bracket4 & taxable_amount_esp <= esp_bracket5
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (esp_bracket5 - esp_bracket4) * 0.1105 + (taxable_amount_esp - esp_bracket5) * 0.119 if taxable_amount_esp > esp_bracket5 & taxable_amount_esp <= esp_bracket6
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (esp_bracket5 - esp_bracket4) * 0.1105 + (esp_bracket6 - esp_bracket5) * 0.119 + (taxable_amount_esp - esp_bracket6) * 0.1275 if taxable_amount_esp > esp_bracket6 & taxable_amount_esp <= esp_bracket7
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (esp_bracket5 - esp_bracket4) * 0.1105 + (esp_bracket6 - esp_bracket5) * 0.119 + (esp_bracket7 - esp_bracket6) * 0.1275 + (taxable_amount_esp - esp_bracket7) * 0.136 if taxable_amount_esp > esp_bracket7 & taxable_amount_esp <= esp_bracket8
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (esp_bracket5 - esp_bracket4) * 0.1105 + (esp_bracket6 - esp_bracket5) * 0.119 + (esp_bracket7 - esp_bracket6) * 0.1275 + (esp_bracket8 - esp_bracket7) * 0.136 + (taxable_amount_esp - esp_bracket8) * 0.1445 if taxable_amount_esp > esp_bracket8 & taxable_amount_esp <= esp_bracket9
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (esp_bracket5 - esp_bracket4) * 0.1105 + (esp_bracket6 - esp_bracket5) * 0.119 + (esp_bracket7 - esp_bracket6) * 0.1275 + (esp_bracket8 - esp_bracket7) * 0.136 + (esp_bracket9 - esp_bracket8) * 0.1445 + (taxable_amount_esp - esp_bracket9) * 0.153 if taxable_amount_esp > esp_bracket9 & taxable_amount_esp <= esp_bracket10
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (esp_bracket5 - esp_bracket4) * 0.1105 + (esp_bracket6 - esp_bracket5) * 0.119 + (esp_bracket7 - esp_bracket6) * 0.1275 + (esp_bracket8 - esp_bracket7) * 0.136 + (esp_bracket9 - esp_bracket8) * 0.1445 + (esp_bracket10 - esp_bracket9) * 0.153 + (taxable_amount_esp - esp_bracket10) * 0.1615 if taxable_amount_esp > esp_bracket10 & taxable_amount_esp <= esp_bracket11
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (esp_bracket5 - esp_bracket4) * 0.1105 + (esp_bracket6 - esp_bracket5) * 0.119 + (esp_bracket7 - esp_bracket6) * 0.1275 + (esp_bracket8 - esp_bracket7) * 0.136 + (esp_bracket9 - esp_bracket8) * 0.1445 + (esp_bracket10 - esp_bracket9) * 0.153 + (esp_bracket11 - esp_bracket10) * 0.1615 + (taxable_amount_esp - esp_bracket11) * 0.187 if taxable_amount_esp > esp_bracket11 & taxable_amount_esp <= esp_bracket12
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (esp_bracket5 - esp_bracket4) * 0.1105 + (esp_bracket6 - esp_bracket5) * 0.119 + (esp_bracket7 - esp_bracket6) * 0.1275 + (esp_bracket8 - esp_bracket7) * 0.136 + (esp_bracket9 - esp_bracket8) * 0.1445 + (esp_bracket10 - esp_bracket9) * 0.153 + (esp_bracket11 - esp_bracket10) * 0.1615 + (esp_bracket12 - esp_bracket11) * 0.187 + (taxable_amount_esp - esp_bracket12) * 0.2125 if taxable_amount_esp > esp_bracket12 & taxable_amount_esp <= esp_bracket13
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (esp_bracket5 - esp_bracket4) * 0.1105 + (esp_bracket6 - esp_bracket5) * 0.119 + (esp_bracket7 - esp_bracket6) * 0.1275 + (esp_bracket8 - esp_bracket7) * 0.136 + (esp_bracket9 - esp_bracket8) * 0.1445 + (esp_bracket10 - esp_bracket9) * 0.153 + (esp_bracket11 - esp_bracket10) * 0.1615 + (esp_bracket12 - esp_bracket11) * 0.187 + (esp_bracket13 - esp_bracket12) * 0.2125 + (taxable_amount_esp - esp_bracket13) * 0.255 if taxable_amount_esp > esp_bracket13 & taxable_amount_esp <= esp_bracket14
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (esp_bracket5 - esp_bracket4) * 0.1105 + (esp_bracket6 - esp_bracket5) * 0.119 + (esp_bracket7 - esp_bracket6) * 0.1275 + (esp_bracket8 - esp_bracket7) * 0.136 + (esp_bracket9 - esp_bracket8) * 0.1445 + (esp_bracket10 - esp_bracket9) * 0.153 + (esp_bracket11 - esp_bracket10) * 0.1615 + (esp_bracket12 - esp_bracket11) * 0.187 + (esp_bracket13 - esp_bracket12) * 0.2125 + (esp_bracket14 - esp_bracket13) * 0.255 + (taxable_amount_esp - esp_bracket14) * 0.2975 if taxable_amount_esp > esp_bracket14 & taxable_amount_esp <= esp_bracket15
replace initial_tax_esp = (esp_bracket1 * 0.0765) + (esp_bracket2 - esp_bracket1) * 0.085 + (esp_bracket3 - esp_bracket2) * 0.0935 + (esp_bracket4 - esp_bracket3) * 0.102 + (esp_bracket5 - esp_bracket4) * 0.1105 + (esp_bracket6 - esp_bracket5) * 0.119 + (esp_bracket7 - esp_bracket6) * 0.1275 + (esp_bracket8 - esp_bracket7) * 0.136 + (esp_bracket9 - esp_bracket8) * 0.1445 + (esp_bracket10 - esp_bracket9) * 0.153 + (esp_bracket11 - esp_bracket10) * 0.1615 + (esp_bracket12 - esp_bracket11) * 0.187 + (esp_bracket13 - esp_bracket12) * 0.2125 + (esp_bracket14 - esp_bracket13) * 0.255 + (esp_bracket15 - esp_bracket14) * 0.2975 + (taxable_amount_esp - esp_bracket15) * 0.34 if taxable_amount_esp > esp_bracket15

// STEP 3.3: Determine the wealth multiplier
gen multiplier_esp = 1
replace multiplier_esp = 1.05 if selfmade_wealth > esp_mult_thresh1 & selfmade_wealth <= esp_mult_thresh2
replace multiplier_esp = 1.10 if selfmade_wealth > esp_mult_thresh2 & selfmade_wealth <= esp_mult_thresh3
replace multiplier_esp = 1.20 if selfmade_wealth > esp_mult_thresh3

// STEP 3.4: Calculate the FINAL tax bill by applying the multiplier
gen tax_due_esp = initial_tax_esp * multiplier_esp
label var tax_due_esp "Final Tax Due under Spanish Regime"

// STEP 3.5: Calculate the ADDITIONAL tax due under the reform
gen additional_tax_esp = max(0, tax_due_esp - tax_due_ita)
label var additional_tax_esp "Additional Tax Due under Spanish Regime Simulation"

//==============================================================================
// 4. REVENUE COLLECTION AND INTERMEDIATE GINI
//==============================================================================

// STEP 4.1: Compute the total ADDITIONAL revenue
svy: total additional_tax_esp
scalar total_revenue = e(b)[1,1]

// STEP 4.2: Create the post-reform wealth variable
gen net_wealth_posttax = net_wealth - additional_tax_esp

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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/spain1.tex", replace label booktabs

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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/spain2.tex", replace label booktabs

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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/spain3.tex", replace label booktabs

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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/spain4.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop transfer_amount_scen4 net_wealth_scen4
matrix drop G

// =============================================================================
// save "microsimulation_finished.dta", replace


// Close the log 
log close
