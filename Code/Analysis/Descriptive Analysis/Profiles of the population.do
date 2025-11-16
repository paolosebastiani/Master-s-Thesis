clear all

// Set the path to your working directory
cd "C:\Users\paose\Desktop\Thesis"


// Open a log file to record all commands and output
capture log close
log using "Finished\DescriptiveAnalysis\log_pro_population.log", replace text

// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"

// Install the packages for inequality indexes and Lorenz curve (cite Jenkins and other creators)
//ssc install ineqdeco, replace
//ssc install ineqdec0, replace
//ssc install glcurve, replace
//ssc install lorenz, replace
//ssc install svylorenz, replace
//ssc install svygei_svyatk, replace
//ssc install sumdist, replace
//ssc install estout, replace
//ssc install outreg2, replace
//ssc install tabout, replace
//ssc install heatplot, replace
//ssc install palettes, replace
//ssc install colrspace, replace
//ssc install asdoc, replace
//net install mat2tex, from(https://raw.githubusercontent.com/avila/mat2tex/master/)
//ssc install blindschemes, replace


// =============================================================================
//
//                 DESCRIPTIVE ANALYSIS - PROFILES OF THE POPULATION
//
// =============================================================================

// NOTE: The inheritance share variables should have missing values for the non-iheritors, and not zero!!!!!

//------------------------------------------------------------------------------
// SUMMARY STATISTICS
//------------------------------------------------------------------------------

// Start with the continuous and binary variables
cd "C:\Users\paose\Desktop\Thesis\Finished\Tables\Population"

asdoc sum n_comp net_income net_wealth selfmade_wealth savings saving_rate poss_year ///
	poss_value value_2022 inher_share inheritor is_owner [aweight=universe_wt], ///
	stat(N mean sd min max p25 p50 p75) replace save(DescStat.doc) title(\i)
// In the exported table, add manually the number of households with negative wealth (in debt)
count if net_wealth < 0
count if net_wealth == 0
cd "C:\Users\paose\Desktop\Thesis"


// Now let's pass to categorical variables
estpost svy: tab birth_cohort, se ci
esttab using "Finished/Appendix/Tables/pop_birthcohort.tex", cells("b se ci") nonumbers nomtitles replace

estpost svy: tab birth_area, se ci
esttab using "Finished/Appendix/Tables/pop_birtharea.tex", cells("b se ci") nonumbers nomtitles replace

estpost svy: tab resid_area, se ci
esttab using "Finished/Appendix/Tables/pop_residarea.tex", cells("b se ci") nonumbers nomtitles replace

estpost svy: tab edu, se ci
esttab using "Finished/Appendix/Tables/pop_edu.tex", cells("b se ci") nonumbers nomtitles replace

estpost svy: tab parent_edu, se ci
esttab using "Finished/Appendix/Tables/pop_parentedu.tex", cells("b se ci") nonumbers nomtitles replace

estpost svy: tab work_status, se ci
esttab using "Finished/Appendix/Tables/pop_workstatus.tex", cells("b se ci") nonumbers nomtitles replace

estpost svy: tab owner_status, se ci
esttab using "Finished/Appendix/Tables/pop_ownerstatus.tex", cells("b se ci") nonumbers nomtitles replace


//------------------------------------------------------------------------------
// DETAILED STATISTICS
//------------------------------------------------------------------------------
// Nelle tab includere anche i C.I. e il design effect? (, ci deff)

// Number of components of the households
svy: tab n_comp, se
graph bar [pweight=universe_wt], over(n_comp) title("Number of components of italian households") ytitle("Percent")

// Birth cohorts
svy: tab birth_cohort, se
graph hbar [pweight=universe_wt], over(birth_cohort) title("Birth cohorts of the 'heads of family'") ytitle("Percent")

// Birth areas
svy: tab birth_area, se
graph bar [pweight=universe_wt], over(birth_area) title("Birth areas of the 'heads of family'") ytitle("Percent")

// Education 
svy: tab edu, se
graph hbar [pweight=universe_wt], over(edu) title("Education level of the 'heads of family'", size(medium)) ytitle("Percent")

// Parents' education 
svy: tab parent_edu, se
graph hbar [pweight=universe_wt], over(parent_edu) title("Education level of the most educated parent of the 'heads of family'", size(medium) span)

// Working status
svy: tab work_status, se
graph hbar [pweight=universe_wt], over(work_status, relabel(4 "Entrepreneur/Self-employed")) title("Working status of the 'heads of family'") ytitle("Percent")


// Self-made wealth
scatter universe_wt selfmade_wealth
sum selfmade_wealth [aweight = universe_wt], detail
sumdist pos_net_wealth [pweight=universe_wt]
graph box selfmade_wealth [pweight=universe_wt]
graph box selfmade_wealth [pweight=universe_wt] if selfmade_wealth < 500000
hist selfmade_wealth [fw = int_universewt], percent title(`"'Self-made' wealth distribution"') xtitle(`"'Self-made' wealth"')
hist selfmade_wealth [fw = int_universewt] if selfmade_wealth < 500000, percent bin(50) title(`"'Self-made' wealth distribution (< 500.000€)"') xtitle(`"'Self-made' wealth"')

// Saving rate
sum saving_rate [aweight = universe_wt], detail
hist saving_rate [fw = int_universewt] if saving_rate >= 0, percent bin(50) title("Saving rate distribution (bounded between 0 and 1)") xtitle("Saving rate")

// Current (2022) real estate values
scatter universe_wt value_2022
sum value_2022 [aweight = universe_wt], detail
sumdist value_2022 [pweight=universe_wt]
graph box value_2022 [pweight=universe_wt]
graph box value_2022 [pweight=universe_wt] if value_2022 < 1000000
hist value_2022 [fw = int_universewt], percent title("Distribution of current values (at 2022) of real estates") xtitle("2022 estimated market value")
hist value_2022 [fw = int_universewt] if value_2022 < 1000000, percent ///
	bin(50) title("Distribution of current values (at 2022) of real estates (< 1.000.000€)", size(medium)) xtitle("2022 estimated market value")



//------------------------------------------------------------------------------
// DISTRIBUTION OF INCOME AND WEALTH
//------------------------------------------------------------------------------
// It's informative to plot the scatter of the survey weights against the
// variable of interest (see 5.2.1 of Applied Survey Data Analysis).

// Net income
scatter universe_wt net_income
sum net_income [aweight = universe_wt], detail
//sumdist net_income [pweight=universe_wt]
graph box net_income [pweight=universe_wt], ytitle("Net income")
hist net_income [fw = int_universewt], percent title("Net income distribution") xtitle("Net income")

// Net wealth
scatter universe_wt net_wealth
sum net_wealth [aweight = universe_wt], detail
//sumdist net_wealth [pweight=universe_wt]
graph box net_wealth [pweight=universe_wt], ytitle("Net wealth")
hist net_wealth [fw = int_universewt], percent title("Net wealth distribution") xtitle("Net wealth")

// CREATE MATRIX WITH SKEWNESS AND KURTOSIS
quietly sum net_income [aweight = universe_wt], detail
matrix SkewA = ( r(skewness) \ r(kurtosis) )
quietly sum net_wealth [aweight = universe_wt], detail
matrix SkewB = ( r(skewness) \ r(kurtosis) )
matrix skew = SkewA, SkewB
matrix colnames skew = "Net Income" "Net Wealth"
matrix rownames skew = "Skewness" "Kurtosis"
esttab matrix(skew) using "Finished/Tables/Population/skewness_kurtosis.tex", title("Skewness and Kurtosis of the distribution of Income and Wealth") ///
    replace label booktabs

// CREATE SIDE-BY-SIDE BOX-PLOT
graph box log_income asinh_net_wealth [pweight=universe_wt], ///
	ytitle("Value (Transformed Scale)") ylabel(, angle(horizontal)) ///
	legend(label(1 "Log Income") label(2 "Asinh Wealth"))
graph export "Finished/Figures/Population/boxplots_transformed.pdf", replace


//------------------------------------------------------------------------------
// INEQUALITY ANALYSIS
//------------------------------------------------------------------------------
// PER LE LORENZ INVECE, METTERE IN UNO STESSO GRAFICO QUELLA DELL'INCOME E QUELLA DEL NET WEALTH TRASFORMATO

////////////////// NET INCOME
ineqdeco net_income [pweight=universe_wt]
matrix A = ( r(gini) \ r(p90p10) \ r(p90p50) \ r(p10p50) \ r(p75p25) \ r(ge0) \ r(ge1) \ r(ge2) \ r(ahalf) \ r(a1) \ r(a2))
//svygei net_income
//svyatk net_income
//svylorenz net_income


////////////////// NET WEALTH
ineqdec0 net_wealth [pweight=universe_wt]
matrix B = ( r(gini) \ r(p90p10) \ r(p90p50) \ r(p10p50) \ r(p75p25) \ r(ge0) \ r(ge1) \ r(ge2) \ r(ahalf) \ r(a1) \ r(a2))
//svygei net_wealth
//svyatk net_wealth
//svylorenz net_wealth


////////////////// TRANSFORMED NET WEALTH
ineqdeco pos_net_wealth [pweight=universe_wt]
matrix C = ( r(gini) \ r(p90p10) \ r(p90p50) \ r(p10p50) \ r(p75p25) \ r(ge0) \ r(ge1) \ r(ge2) \ r(ahalf) \ r(a1) \ r(a2))
//svygei pos_net_wealth
//svyatk pos_net_wealth
//svylorenz pos_net_wealth


// Create the table with the inequality indexes for all these 3 variables
matrix D = A, B, C
matrix colnames D = "Net Income" "Net Wealth" "Transformed Net Wealth"
matrix rownames D = "Gini Coefficient" "p90/p10 Ratio" "p90/p50 Ratio" "p10/p50 Ratio" "p75/p25 Ratio" "GE(0)" "GE(1)" "GE(2)" "Atk(0.5)" "Atk(1)" "Atk(2)"
esttab matrix(D) using "Finished/Tables/Population/inequalityindexes.tex", title("Inequality Indices for Income and Wealth") ///
    replace label booktabs

// Create the Lorenz curves for income and transformed wealth
lorenz net_income pos_net_wealth [pweight=universe_wt], ///
	graph(overlay xlabels(, grid) labels("Net income" "Transformed Net Wealth") legend(position(6)))
graph export "Finished/Figures/Population/lorenz_curves.pdf", replace

// Test for Lorenz Dominance
lorenz pos_net_wealth net_income [pweight=universe_wt], contrast graph
graph export "Finished/Figures/Population/lorenz_dominance.pdf", replace


//------------------------------------------------------------------------------
// DISTRIBUTION OF WEALTH vs SELF-MADE WEALTH
//------------------------------------------------------------------------------
sum net_wealth [aweight=universe_wt], det
matrix E = ( r(mean) \ r(sd) \ r(skewness) \ r(kurtosis) \ r(p1) \ r(p5) \ r(p10) \ r(p25) \ r(p50) \ r(p75) \ r(p90) \ r(p95) \ r(p99))
sum selfmade_wealth [aweight=universe_wt], det
matrix F = ( r(mean) \ r(sd) \ r(skewness) \ r(kurtosis) \ r(p1) \ r(p5) \ r(p10) \ r(p25) \ r(p50) \ r(p75) \ r(p90) \ r(p95) \ r(p99))
matrix G = E,F
matrix colnames G = "Net Wealth" "'Self-made' wealth"
matrix rownames G = "Mean" "SD" "Skewness" "Kurtosis" "p1" "p5" "p10" "p25" "Median" "p75" "p90" "p95" "p99"
esttab matrix(G) using "Finished/Tables/Population/w_vs_selfmadew.tex", replace label booktabs

ineqdec0 selfmade_wealth [pweight=universe_wt]
matrix H = ( r(gini) \ r(p90p10) \ r(p90p50) \ r(p10p50) \ r(p75p25) \ r(ge0) \ r(ge1) \ r(ge2) \ r(ahalf) \ r(a1) \ r(a2))
matrix I = B,H
matrix colnames I = "Net Wealth" "'Self-made' wealth"
matrix rownames I = "Gini Coefficient" "p90/p10 Ratio" "p90/p50 Ratio" "p10/p50 Ratio" "p75/p25 Ratio" "GE(0)" "GE(1)" "GE(2)" "Atk(0.5)" "Atk(1)" "Atk(2)"
esttab matrix(I) using "Finished/Tables/Population/ineq_w_vs_selfmadew.tex", replace label booktabs

lorenz net_wealth selfmade_wealth [pweight=universe_wt], ///
	graph(overlay xlabels(, grid) labels("Net wealth" "Self-made Wealth") legend(position(6)))
graph export "Finished/Figures/Population/lorenz_w_vs_selfmadew.pdf", replace

lorenz selfmade_wealth net_wealth [pweight=universe_wt], contrast graph
graph export "Finished/Figures/Population/dominance_w_vs_selfmadew.pdf", replace


//------------------------------------------------------------------------------
// DECOMPOSITION ANALYSIS
//------------------------------------------------------------------------------
ineqdeco net_income [pweight=universe_wt], by(inheritor)
matrix K = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2))


ineqdec0 net_wealth [pweight=universe_wt], by(inheritor)
matrix L = ( r(gini) \ r(ge2) \ r(v_0) \ r(theta_0) \ r(lambda_0) \ r(v_1) \ r(theta_1) \ r(lambda_1) \ r(gini_0) \ r(gini_1) \ r(within_ge2) \ r(between_ge2))

matrix M = K, L
matrix colnames M = "Net Income" "Net Wealth"
matrix rownames M = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
esttab matrix(M) using "Finished/Tables/Population/decompositioninequality.tex", replace label booktabs

// BASELINE MODEL DATA
matrix colnames L = "Pre-Reform indices"
matrix rownames L = "Gini Coefficient" "GE(2)" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Population Share" "Income/Wealth Share" "Relative Income/Wealth" "Gini (Non-Inheritors)" "Gini (Inheritors)" "Within-Group Component (GE_W)" "Between-Group Component (GE_B)"
esttab matrix(L) using "Finished/Tables/Microsimulation/baseline.tex", replace label booktabs


//------------------------------------------------------------------------------
// Close the log
log close