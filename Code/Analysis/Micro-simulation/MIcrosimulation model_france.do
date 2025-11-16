clear all

// Set the path to your working directory
cd "C:\Users\paose\Desktop\Thesis"

// Open a log file to record all commands and output
capture log close
log using "Finished\MicrosimulationModel\log_microsimulation_france.log", replace text

// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"

// ====================================================================================
//
//  FRENCH REGIME (https://www.service-public.fr/particuliers/vosdroits/F14198?lang=en)
//
// ====================================================================================

//==============================================================================
// 1. SETUP AND CONSTANTS
//==============================================================================

// --- Define French tax parameters (parent-to-child) ---
scalar fr_allowance = 100000
scalar fr_bracket1 = 8072
scalar fr_bracket2 = 12109
scalar fr_bracket3 = 15932
scalar fr_bracket4 = 552324
scalar fr_bracket5 = 902838
scalar fr_bracket6 = 1805677

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

// Since in the SHIW there aren't info about the eligibility for the
// 20% allowance on the market value, I'll do 2 scenarios (one in which it
// applies for every heir, and one in which it doesn't apply to anyone)

//==============================================================================
//                 SCENARIO A: 20% allowance to every heir
//==============================================================================

// STEP A.1: Calculate hypothetical French tax due (with 20% allowance)
gen tax_base_A = value_2022 * (1 - 0.20) if owner_status == 2
gen taxable_amount_A = tax_base_A - fr_allowance
replace taxable_amount_A = 0 if taxable_amount_A < 0

gen tax_due_fr_A = 0
replace tax_due_fr_A = . if owner_status != 2

replace tax_due_fr_A = taxable_amount_A * 0.05 if taxable_amount_A > 0 & taxable_amount_A <= fr_bracket1
replace tax_due_fr_A = (fr_bracket1 * 0.05) + (taxable_amount_A - fr_bracket1) * 0.10 if taxable_amount_A > fr_bracket1 & taxable_amount_A <= fr_bracket2
replace tax_due_fr_A = (fr_bracket1 * 0.05) + (fr_bracket2 - fr_bracket1) * 0.10 + (taxable_amount_A - fr_bracket2) * 0.15 if taxable_amount_A > fr_bracket2 & taxable_amount_A <= fr_bracket3
replace tax_due_fr_A = (fr_bracket1 * 0.05) + (fr_bracket2 - fr_bracket1) * 0.10 + (fr_bracket3 - fr_bracket2) * 0.15 + (taxable_amount_A - fr_bracket3) * 0.20 if taxable_amount_A > fr_bracket3 & taxable_amount_A <= fr_bracket4
replace tax_due_fr_A = (fr_bracket1 * 0.05) + (fr_bracket2 - fr_bracket1) * 0.10 + (fr_bracket3 - fr_bracket2) * 0.15 + (fr_bracket4 - fr_bracket3) * 0.20 + (taxable_amount_A - fr_bracket4) * 0.30 if taxable_amount_A > fr_bracket4 & taxable_amount_A <= fr_bracket5
replace tax_due_fr_A = (fr_bracket1 * 0.05) + (fr_bracket2 - fr_bracket1) * 0.10 + (fr_bracket3 - fr_bracket2) * 0.15 + (fr_bracket4 - fr_bracket3) * 0.20 + (fr_bracket5 - fr_bracket4) * 0.30 + (taxable_amount_A - fr_bracket5) * 0.40 if taxable_amount_A > fr_bracket5 & taxable_amount_A <= fr_bracket6
replace tax_due_fr_A = (fr_bracket1 * 0.05) + (fr_bracket2 - fr_bracket1) * 0.10 + (fr_bracket3 - fr_bracket2) * 0.15 + (fr_bracket4 - fr_bracket3) * 0.20 + (fr_bracket5 - fr_bracket4) * 0.30 + (fr_bracket6 - fr_bracket5) * 0.40 + (taxable_amount_A - fr_bracket6) * 0.45 if taxable_amount_A > fr_bracket6

// STEP A.2: Calculate the ADDITIONAL tax due under the reform
gen additional_tax_fr_A = max(0, tax_due_fr_A - tax_due_ita)
label var additional_tax_fr_A "Additional Tax Due under French Regime A (20% allowance)"

// STEP A.3: Compute the total ADDITIONAL revenue
svy: total additional_tax_fr_A
scalar total_revenue_A = e(b)[1,1]

// STEP A.4: Create the post-reform wealth variable
gen net_wealth_posttax_A = net_wealth - additional_tax_fr_A

// STEP A.5: Intermediate Gini ("Tax effect")
ineqdec0 net_wealth_posttax_A [pweight=universe_wt]


//==============================================================================
// SCENARIO A1: Transfer to bottom decile (equal per household)
//==============================================================================

gen is_recipient_A1 = (wealth_dec == 1)
svy: total is_recipient_A1
scalar num_recipients_A1 = e(b)[1,1]
scalar transfer_amount_A1 = total_revenue_A / num_recipients_A1
display "Transfer per Household (Scenario A1): " %12.2f transfer_amount_A1

gen net_wealth_A1 = net_wealth_posttax_A
replace net_wealth_A1 = net_wealth_A1 + transfer_amount_A1 if is_recipient_A1 == 1

ineqdec0 net_wealth_A1 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/frenchA1.tex", replace label booktabs

drop is_recipient_A1 net_wealth_A1
matrix drop G


//==============================================================================
// SCENARIO A2: Transfer to bottom decile (proportional to components)
//==============================================================================

gen is_recipient_A2 = (wealth_dec == 1)
gen recipient_components_A2 = is_recipient_A2 * n_comp

svy: total recipient_components_A2
scalar total_components_A2 = e(b)[1,1]

scalar transfer_per_comp_A2 = total_revenue_A / total_components_A2
display "Transfer per Household Component (Scenario A2): " %12.2f transfer_per_comp_A2

gen net_wealth_A2 = net_wealth_posttax_A
gen transfer_amount_A2 = transfer_per_comp_A2 * n_comp
replace net_wealth_A2 = net_wealth_A2 + transfer_amount_A2 if is_recipient_A2 == 1

ineqdec0 net_wealth_A2 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/frenchA2.tex", replace label booktabs

drop is_recipient_A2 recipient_components_A2 transfer_amount_A2 net_wealth_A2
matrix drop G


//==============================================================================
// SCENARIO A3: Universal transfer (equal per household)
//==============================================================================

gen all_hh = 1
svy: total all_hh
scalar num_total_hh = e(b)[1,1]
scalar transfer_amount_A3 = total_revenue_A / num_total_hh
display "Transfer per Household (Scenario A3): " %12.2f transfer_amount_A3

gen net_wealth_A3 = net_wealth_posttax_A + transfer_amount_A3

ineqdec0 net_wealth_A3 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/frenchA3.tex", replace label booktabs

drop all_hh net_wealth_A3
matrix drop G


//==============================================================================
// SCENARIO A4: Universal transfer (proportional to components)
//==============================================================================

svy: total n_comp
scalar total_components_A4 = e(b)[1,1]

scalar transfer_per_comp_A4 = total_revenue_A / total_components_A4

gen transfer_amount_A4 = transfer_per_comp_A4 * n_comp
gen net_wealth_A4 = net_wealth_posttax_A + transfer_amount_A4

ineqdec0 net_wealth_A4 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/frenchA4.tex", replace label booktabs

drop transfer_amount_A4 net_wealth_A4
matrix drop G


//==============================================================================
//                 SCENARIO B: 0% allowance
//==============================================================================

// STEP B.1: Calculate hypothetical French tax due (with 0% allowance)
gen tax_base_B = value_2022 if owner_status == 2
gen taxable_amount_B = tax_base_B - fr_allowance
replace taxable_amount_B = 0 if taxable_amount_B < 0

gen tax_due_fr_B = 0
replace tax_due_fr_B = . if owner_status != 2

replace tax_due_fr_B = taxable_amount_B * 0.05 if taxable_amount_B > 0 & taxable_amount_B <= fr_bracket1
replace tax_due_fr_B = (fr_bracket1 * 0.05) + (taxable_amount_B - fr_bracket1) * 0.10 if taxable_amount_B > fr_bracket1 & taxable_amount_B <= fr_bracket2
replace tax_due_fr_B = (fr_bracket1 * 0.05) + (fr_bracket2 - fr_bracket1) * 0.10 + (taxable_amount_B - fr_bracket2) * 0.15 if taxable_amount_B > fr_bracket2 & taxable_amount_B <= fr_bracket3
replace tax_due_fr_B = (fr_bracket1 * 0.05) + (fr_bracket2 - fr_bracket1) * 0.10 + (fr_bracket3 - fr_bracket2) * 0.15 + (taxable_amount_B - fr_bracket3) * 0.20 if taxable_amount_B > fr_bracket3 & taxable_amount_B <= fr_bracket4
replace tax_due_fr_B = (fr_bracket1 * 0.05) + (fr_bracket2 - fr_bracket1) * 0.10 + (fr_bracket3 - fr_bracket2) * 0.15 + (fr_bracket4 - fr_bracket3) * 0.20 + (taxable_amount_B - fr_bracket4) * 0.30 if taxable_amount_B > fr_bracket4 & taxable_amount_B <= fr_bracket5
replace tax_due_fr_B = (fr_bracket1 * 0.05) + (fr_bracket2 - fr_bracket1) * 0.10 + (fr_bracket3 - fr_bracket2) * 0.15 + (fr_bracket4 - fr_bracket3) * 0.20 + (fr_bracket5 - fr_bracket4) * 0.30 + (taxable_amount_B - fr_bracket5) * 0.40 if taxable_amount_B > fr_bracket5 & taxable_amount_B <= fr_bracket6
replace tax_due_fr_B = (fr_bracket1 * 0.05) + (fr_bracket2 - fr_bracket1) * 0.10 + (fr_bracket3 - fr_bracket2) * 0.15 + (fr_bracket4 - fr_bracket3) * 0.20 + (fr_bracket5 - fr_bracket4) * 0.30 + (fr_bracket6 - fr_bracket5) * 0.40 + (taxable_amount_B - fr_bracket6) * 0.45 if taxable_amount_B > fr_bracket6

// STEP B.2: Calculate the ADDITIONAL tax due under the reform
gen additional_tax_fr_B = max(0, tax_due_fr_B - tax_due_ita)
label var additional_tax_fr_B "Additional Tax Due under French Regime B (0% allowance)"

// STEP B.3: Compute the total ADDITIONAL revenue
svy: total additional_tax_fr_B
scalar total_revenue_B = e(b)[1,1]

// STEP B.4: Create the post-reform wealth variable
gen net_wealth_posttax_B = net_wealth - additional_tax_fr_B

// STEP B.5: Intermediate Gini ("Tax effect")
ineqdec0 net_wealth_posttax_B [pweight=universe_wt]

// S80/S20 ratio
sumdist net_wealth_posttax_B [pweight=universe_wt], ngp(5)
matrix shares = r(shares)
di "S80/S20 Ratio:" shares[1,5]/shares[1,1]
matrix drop shares




//==============================================================================
// SCENARIO B1: Transfer to bottom decile (equal per household)
//==============================================================================

gen is_recipient_B1 = (wealth_dec == 1)
svy: total is_recipient_B1
scalar num_recipients_B1 = e(b)[1,1]
scalar transfer_amount_B1 = total_revenue_B / num_recipients_B1
display "Transfer per Household (Scenario B1): " %12.2f transfer_amount_B1

gen net_wealth_B1 = net_wealth_posttax_B
replace net_wealth_B1 = net_wealth_B1 + transfer_amount_B1 if is_recipient_B1 == 1

ineqdec0 net_wealth_B1 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/frenchB1.tex", replace label booktabs


// S80/S20
sumdist net_wealth_B1 [pweight=universe_wt], ngp(5)
matrix shares = r(shares)
di "S80/S20 Ratio:" shares[1,5]/shares[1,1]
matrix drop shares

drop is_recipient_B1 net_wealth_B1
matrix drop G

// WINNERS/LOSERS RATIO
gen winner_loser_status = 0
replace winner_loser_status = 1 if net_wealth_B1 > (net_wealth * 1.01)
replace winner_loser_status = -1 if net_wealth_B1 < (net_wealth * 0.99)
label define winner_loser_status_lbl -1 "Loser" 0 "Unchanged (+-1%)" 1 "Winner"
label values winner_loser_status winner_loser_status_lbl
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



//==============================================================================
// SCENARIO B2: Transfer to bottom decile (proportional to components)
//==============================================================================

gen is_recipient_B2 = (wealth_dec == 1)
gen recipient_components_B2 = is_recipient_B2 * n_comp

svy: total recipient_components_B2
scalar total_components_B2 = e(b)[1,1]

scalar transfer_per_comp_B2 = total_revenue_B / total_components_B2
display "Transfer per Household Component (Scenario B2): " %12.2f transfer_per_comp_B2

gen net_wealth_B2 = net_wealth_posttax_B
gen transfer_amount_B2 = transfer_per_comp_B2 * n_comp
replace net_wealth_B2 = net_wealth_B2 + transfer_amount_B2 if is_recipient_B2 == 1

ineqdec0 net_wealth_B2 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/frenchB2.tex", replace label booktabs

drop is_recipient_B2 recipient_components_B2 transfer_amount_B2 net_wealth_B2
matrix drop G


//==============================================================================
// SCENARIO B3: Universal transfer (equal per household)
//==============================================================================

gen all_hh = 1
svy: total all_hh
scalar num_total_hh = e(b)[1,1]
scalar transfer_amount_B3 = total_revenue_B / num_total_hh
display "Transfer per Household (Scenario B3): " %12.2f transfer_amount_B3

gen net_wealth_B3 = net_wealth_posttax_B + transfer_amount_B3

ineqdec0 net_wealth_B3 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/frenchB3.tex", replace label booktabs

// S80/S20
sumdist net_wealth_B3 [pweight=universe_wt], ngp(5)
matrix shares = r(shares)
di "S80/S20 Ratio:" shares[1,5]/shares[1,1]
matrix drop shares

drop all_hh net_wealth_B3
matrix drop G

// WINNERS/LOSERS RATIO
gen winner_loser_status = 0
replace winner_loser_status = 1 if net_wealth_B3 > (net_wealth * 1.01)
replace winner_loser_status = -1 if net_wealth_B3 < (net_wealth * 0.99)
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



//==============================================================================
// SCENARIO B4: Universal transfer (proportional to components)
//==============================================================================

svy: total n_comp
scalar total_components_B4 = e(b)[1,1]

scalar transfer_per_comp_B4 = total_revenue_B / total_components_B4

gen transfer_amount_B4 = transfer_per_comp_B4 * n_comp
gen net_wealth_B4 = net_wealth_posttax_B + transfer_amount_B4

ineqdec0 net_wealth_B4 [pweight=universe_wt], by(inheritor)
matrix G = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2) )
matrix colnames G = "Post-Reform indices"
matrix rownames G = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
matlist G, format(%18.6fc)
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Progressive Regimes/frenchB4.tex", replace label booktabs

drop transfer_amount_B4 net_wealth_B4
matrix drop G


// =============================================================================
// save "microsimulation_finished.dta", replace


// Close the log 
log close
