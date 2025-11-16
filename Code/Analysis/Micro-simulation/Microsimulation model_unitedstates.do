clear all

// Set the path to your working directory
cd "C:\Users\paose\Desktop\Thesis"

// Open a log file to record all commands and output
capture log close
log using "Finished\MicrosimulationModel\log_microsimulation_unitedstates.log", replace text

// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"

// ====================================================================================
//
//  UNITED STATES REGIME (https://www.congress.gov/bill/115th-congress/house-bill/1/text)
//
// ====================================================================================

// The exemption in 2022 was $12,060,000.
// The average exchange rate in 2022 was:
// https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/eurofxref-graph-usd.en.html

//==============================================================================
// 1. SETUP AND CONSTANTS
//==============================================================================

// --- Define U.S. tax parameters for 2022 ---
scalar usd_to_eur_2022 = 0.9497
scalar us_exemption_usd = 12060000
scalar us_exemption_eur = us_exemption_usd * usd_to_eur_2022
scalar us_tax_rate = 0.40

// --- Define current Italian tax parameters (parent-to-child) ---
scalar ita_tax_rate = 0.04
scalar ita_threshold_eur = 1000000

// Display constants for verification
di "U.S. Exemption Threshold (EUR): " %12.0fc us_exemption_eur

//==============================================================================
// 2. BASELINE AND COMMON CALCULATIONS
//==============================================================================

// --- Display Baseline Wealth Inequality (Pre-Reform) ---
display "--- Baseline Wealth Inequality (Pre-Reform) ---"
ineqdec0 net_wealth [pweight=universe_wt], by(inheritor)

// --- Calculate tax already paid under current Italian rules ---
// This is necessary for methodological consistency, even if the result is zero.
gen tax_due_ita = 0
replace tax_due_ita = . if owner_status != 2

replace tax_due_ita = (value_2022 - ita_threshold_eur) * ita_tax_rate ///
    if owner_status == 2 & value_2022 > ita_threshold_eur

replace tax_due_ita = 0 if tax_due_ita < 0
label var tax_due_ita "Tax Paid under Current Italian Regime"

//==============================================================================
// 3. U.S. TAX SIMULATION
//==============================================================================

// STEP 3.1: Compute the hypothetical tax due under U.S. rules
// Note: This will be zero for all observations in the SHIW sample as no 
// single inherited property value exceeds the ~€11.45M threshold.
gen tax_due_us = 0
replace tax_due_us = . if owner_status != 2

replace tax_due_us = (value_2022 - us_exemption_eur) * us_tax_rate ///
    if owner_status == 2 & value_2022 > us_exemption_eur

// STEP 3.2: Calculate the ADDITIONAL tax due under the reform
gen additional_tax_us = max(0, tax_due_us - tax_due_ita)
label var additional_tax_us "Additional Tax Due under U.S. Regime Simulation"

//==============================================================================
// 4. REVENUE COLLECTION AND REDISTRIBUTION (NULL RESULT)
//==============================================================================

// STEP 4.1: Compute the total ADDITIONAL revenue (will be 0)
svy: total additional_tax_us
scalar total_revenue = e(b)[1,1]

// STEP 4.2: Create the post-reform wealth variable
// Since additional tax is 0, this will be identical to net_wealth
gen net_wealth_posttax_us = net_wealth - additional_tax_us

// STEP 4.3: Define recipients and calculate the lump-sum transfer (will be 0)
gen is_recipient = (wealth_dec == 1)
svy: total is_recipient
scalar num_recipients = e(b)[1,1]
scalar transfer_amount = total_revenue / num_recipients // Will be 0 / N = 0

// Display simulation results to confirm the null finding
di "Total ADDITIONAL Revenue Collected (U.S.): " %20.2fc total_revenue
di "Number of Recipient Households: " %20.0fc num_recipients
di "Transfer per Household: " %12.2f transfer_amount

// STEP 4.4: Distribute the transfers (distributing €0)
replace net_wealth_posttax_us = net_wealth_posttax_us + transfer_amount if is_recipient == 1

//==============================================================================
// 5. POST-REFORM INEQUALITY
//==============================================================================
ineqdec0 net_wealth_posttax_us [pweight=universe_wt], by(inheritor)



// Close the log 
log close
