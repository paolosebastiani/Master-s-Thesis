clear all

// Set the path to your working directory
//cd "C:\Users\paose\Desktop\Thesis"
cd "C:\Users\Paolo\Desktop\Thesis"

// Open a log file to record all commands and output
capture log close
log using "Finished\DescriptiveAnalysis\log_value_inheritance.log", replace text


// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"

// =============================================================================
//
//          DESCRIPTIVE ANALYSIS - VALUE AND IMPORTANCE OF INHERITANCE
//
// =============================================================================

// DISTRIBUTION OF INHERITED REAL ESTATE
summarize value_2022 [aweight = universe_wt] if owner_status == 2, detail
matrix A = ( r(mean) \ r(sd) \ r(skewness) \ r(kurtosis) \ r(p1) \ r(p5) \ r(p10) \ r(p25) \ r(p50) \ r(p75) \ r(p90) \ r(p95) \ r(p99))
matrix rownames A = "Mean" "SD" "Skewness" "Kurtosis" "p1" "p5" "p10" "p25" "Median" "p75" "p90" "p95" "p99"
matrix colnames A = "2022 Market Value"
esttab matrix(A) using "Finished/Tables/Inheritors/value2022_distribution.tex", replace label booktabs
//hist value_2022 [fw = int_universewt] if owner_status == 2, percent xtitle("Market Value at 2022") bin(50)
hist log_value_2022 [fw = int_universewt] if owner_status == 2, percent normal xtitle("Log of Market Value at 2022")
graph export "Finished/Figures/Inheritors/log_2022mktvalue.pdf", replace

// INEQUALITY OF THE DISTRIBUTION
ineqdeco value_2022 [pweight=universe_wt] if owner_status == 2
matrix B = ( r(gini) \ r(p90p10) \ r(p90p50) \ r(p10p50) \ r(p75p25) \ r(ge0) \ r(ge1) \ r(ge2) \ r(ahalf) \ r(a1) \ r(a2))
matrix colnames B = "2022 Market Value"
matrix rownames B = "Gini Coefficient" "p90/p10 Ratio" "p90/p50 Ratio" "p10/p50 Ratio" "p75/p25 Ratio" "GE(0)" "GE(1)" "GE(2)" "Atk(0.5)" "Atk(1)" "Atk(2)"
esttab matrix(B) using "Finished/Tables/Inheritors/ineq_value2022.tex", replace label booktabs


//===============================================================================
// INHERITANCE SHARE ACROSS WEALTH AND INCOME DECILES FOR ALL HOUSEHOLDS
//===============================================================================
// Create a non-negative "non-inherited net wealth" just for the following graphs (we're bounding just 133 values out of 9641)
gen selfmade_wealth_forgraph = max(0, selfmade_wealth)

estpost tabstat inher_share [aweight=universe_wt], by(wealth_dec) stats(mean)
esttab using "Finished/Appendix/Tables/inh_share_population.tex", replace label cells("mean") booktabs
preserve
    collapse (mean) mean_inh=value_2022 mean_selfmade=selfmade_wealth_forgraph [pweight=universe_wt], by(wealth_dec)
    graph bar (mean) mean_inh mean_selfmade, over(wealth_dec) stack percentage ///
    legend(order(2 1) label(2 "Non-Inherited Wealth") label(1 "Inherited real estate"))
restore
graph export "Finished/Figures/Inheritors/inhshare_pop.pdf", replace


//tabstat inher_share [aweight=universe_wt], by(income_dec) stats(mean)
//preserve
    //collapse (mean) mean_inh=value_2022 mean_selfmade=selfmade_wealth_forgraph [pweight=universe_wt], by(income_dec)
    //graph bar (mean) mean_inh mean_selfmade, over(income_dec) stack percentage ///
        //title("Wealth Composition by Net Income Decile (Whole Population)") legend(order(2 1) label(2 "Non-Inherited Wealth") label(1 "Inherited real estate"))
//restore

//===============================================================================
// INHERITANCE SHARE ACROSS WEALTH AND INCOME DECILES FOR INHERITORS ONLY
//===============================================================================
estpost tabstat inher_share [aweight=universe_wt] if owner_status == 2, by(wealth_dec) stats(mean median p25 p75)
esttab using "Finished/Appendix/Tables/inh_share_inheritors.tex", replace label cells("mean p25 median p75") booktabs
preserve
    collapse (mean) mean_inh=value_2022 mean_selfmade=selfmade_wealth_forgraph [pweight=universe_wt] if owner_status == 2, by(wealth_dec)
    graph bar (mean) mean_inh mean_selfmade, over(wealth_dec) stack percentage ///
    legend(order(2 1) label(2 "Non-Inherited Wealth") label(1 "Inherited real estate"))
restore
graph export "Finished/Figures/Inheritors/inhshare_inheritors.pdf", replace


//tabstat inher_share [aweight=universe_wt] if owner_status == 2, by(income_dec) stats(mean median p25 p75)
//preserve
    //collapse (mean) mean_inh=value_2022 mean_selfmade=selfmade_wealth_forgraph [pweight=universe_wt] if owner_status == 2, by(income_dec)
    //graph bar (mean) mean_inh mean_selfmade, over(income_dec) stack percentage ///
        //title("Wealth Composition by Net Income Decile (Inheritors Only)") legend(order(2 1) label(2 "Non-Inherited Wealth") label(1 "Inherited real estate"))
//restore



//==============================================================================
// Close the log
log close
