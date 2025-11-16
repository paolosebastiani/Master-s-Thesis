clear all

// Set the path to your working directory
cd "C:\Users\paose\Desktop\Thesis"

// Open a log file to record all commands and output
capture log close
log using "Finished\MicrosimulationModel\log_microsimulation_ireland.log", replace text

// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"

// ====================================================================================
//
//  IRISH REGIME (https://www.revenue.ie/en/gains-gifts-and-inheritance/gift-and-inheritance-tax-cat/index.aspx)
//
// ====================================================================================
* Assumptions:
* 1. All heirs are children of the disponer and fall under "Group A".
* 2. The 2022 Group A tax-free threshold of €335,000 is used.
* 3. The 2022 tax rate of 33% on the excess is applied.

//==============================================================================
// 1. SETUP AND CONSTANTS
//==============================================================================

// --- Define Irish tax parameters for 2022 ---
scalar irl_tax_rate = 0.33
scalar irl_threshold_eur = 335000

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
// 3. IRISH TAX SIMULATION
//==============================================================================

// STEP 3.1: Calculate the tax due under Irish rules
gen tax_due_irl = 0
replace tax_due_irl = . if owner_status != 2

replace tax_due_irl = (value_2022 - irl_threshold_eur) * irl_tax_rate ///
    if owner_status == 2 & value_2022 > irl_threshold_eur

replace tax_due_irl = 0 if tax_due_irl < 0
label var tax_due_irl "Tax Due under Irish Regime"

// STEP 3.2: Calculate the ADDITIONAL tax due under the reform
// This is the key step: we only collect the difference.
gen additional_tax_irl = max(0, tax_due_irl - tax_due_ita)
label var additional_tax_irl "Additional Tax Due under Irish Regime Simulation"

//==============================================================================
// 4. REVENUE COLLECTION AND INTERMEDIATE GINI
//==============================================================================

// STEP 4.1: Compute the total ADDITIONAL revenue
svy: total additional_tax_irl
scalar total_revenue = e(b)[1,1]

// STEP 4.2: Create the post-reform wealth variable
gen net_wealth_posttax = net_wealth - additional_tax_irl

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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Flat Regimes/irish1.tex", replace label booktabs

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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Flat Regimes/irish2.tex", replace label booktabs


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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Flat Regimes/irish3.tex", replace label booktabs

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
esttab matrix(G, fmt(%18.6fc)) using "Finished/Tables/Microsimulation/Flat Regimes/irish4.tex", replace label booktabs

// --- Clean up scenario-specific variables ---
drop transfer_amount_scen4 net_wealth_scen4
matrix drop G

// =============================================================================
// save "microsimulation_finished.dta", replace


// Close the log 
log close
