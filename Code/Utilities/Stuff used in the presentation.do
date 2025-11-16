clear all

// Set the path to your working directory
cd "C:\Users\paose\Desktop\Thesis"
//cd "C:\Users\Paolo\Desktop\Thesis"


// Open a log file to record all commands and output
capture log close
log using "Finished\log_presentation_stuff.log", replace text

// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"


//==============================================================================
// LORENZ CURVES 
//==============================================================================
// Create the Lorenz curves for income and transformed wealth
lorenz net_income pos_net_wealth [pweight=universe_wt], ///
    graph(overlay o1(color(green)) o2(color(blue) note("Note: the shaded area represents the 95% confidence interval", position(6))) ///
	xlabels(, grid) labels("Net income" "Transformed Net Wealth") legend(position(6))) 
graph export "Finished/Figures/Population/lorenz_curves.pdf", replace


//==============================================================================
// REAL WEALTH AND FINANCIAL WEALTH
//==============================================================================
rename ID nquest
merge 1:1 nquest using "Finished\Datasets\Source\ricfam22.dta"
drop _merge
rename nquest ID

ineqdec0 ar [pweight=universe_wt], by(inheritor)
scalar relative_ar = r(lambda_1)

ineqdec0 af [pweight=universe_wt], by(inheritor)
scalar relative_af = r(lambda_1)

di "Relative mean of Real Wealth of Inheritors:" relative_ar
di "Relative mean of Financial Wealth of Inheritors:" relative_af


//==============================================================================
// NET WEALTH GRAPH
//==============================================================================
* 1. Clear and input data from your Table 4.8
clear
input str15 group str10 percentile value
"Non-Inheritor" "p10" 0
"Non-Inheritor" "p25" 450
"Non-Inheritor" "p50" 2120
"Inheritor"     "p10" 7500
"Inheritor"     "p25" 10500
"Inheritor"     "p50" 15700
end

* 2. Encode the percentile variable so it graphs in the correct order
encode percentile, gen(p_order)

* 3. Create the grouped bar chart
graph bar (mean) value, over(percentile, sort(p_order) label(labsize(small))) ///
	over(group, label(angle(0) labsize(medium))) asyvars ytitle("Net Wealth (€)") ///
	title("Net Wealth at Bottom Percentiles (households in 1st Wealth Quintile)", size(medium)) blabel(bar, format(%9.0fc) color(black) size(vsmall)) legend(rows(1))
graph export "Finished/Figures/Inheritors/bottom_p_comparison.pdf", replace

clear all
use "Finished\Datasets\Derived\master dataset.dta"



//==============================================================================
// MICROSIMULATION RESULT
//==============================================================================

// Initial S80/S20 share
sumdist net_wealth [pweight=universe_wt], ngp(5)
matrix shares = r(shares)
di "S80/S20 Ratio:" shares[1,5]/shares[1,1]

// For the S80/S20 after tax and after redistributions, see the .do files of the
// countries.


//==============================================================================
// WINNERS/LOSERS RATIO
//==============================================================================

// For the computation, see the .do files of the countries

clear
input str20 regime ratio_targeted ratio_universal
"French" 1.1 9.59
"Irish"              6.63 43.32
"Japanese"           4.59 29.22
"Spanish"            0.67 6.56
end

rename ratio_targeted ratio1
rename ratio_universal ratio2

reshape long ratio, i(regime) j(policy)

label define policy 1 "Targeted" 2 "Universal"
label values policy policy

graph bar (asis) ratio, over(policy) over(regime) asyvars ///
	blabel(bar, size(small) format(%9.2f)) ytitle(Winners-to-Losers Ratio) ///
	yscale(range(0 45)) title(Ratio of Winners to Losers under Alternative Regimes, size(medlarge))
graph export "Finished/Figures/winners_losers.pdf", replace

clear all
use "Finished\Datasets\Derived\master dataset.dta"




//------------------------------------------------------------------------------
// Close the log
log close