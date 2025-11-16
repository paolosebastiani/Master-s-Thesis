clear all

// Set the path to your working directory
//cd "C:\Users\paose\Desktop\Thesis"
cd "C:\Users\Paolo\Desktop\Thesis"

// Open a log file to record all commands and output
capture log close
log using "Finished\DescriptiveAnalysis\log_pro_inheritors.log", replace text


// Import the master dataset
use "Finished\Datasets\Derived\master dataset.dta"

//ssc install catplot, replace


//------------------------------------------------------------------------------
// DISTRIBUTION OF WEALTH AND INCOME BY QUINTILES (INHERITORS vs. NON-INHERITORS)
//------------------------------------------------------------------------------
/////////////////////////// WEALTH
matrix N = J(10, 8, .)
matrix colnames N = mean sd p10 p25 p50 p75 p90 p99
matrix rownames N = "Q1 - Inheritors" "Q1 - Non-Inheritors" "Q2 - Inheritors" "Q2 - Non-Inheritors" "Q3 - Inheritors" "Q3 - Non-Inheritors" "Q4 - Inheritors" "Q4 - Non-Inheritors" "Q5 - Inheritors" "Q5 - Non-Inheritors"

// The outer loop iterates through wealth quintiles 1 to 5.
forvalues q = 1/5 {
    
    // The inner loop iterates through inheritor status.
    // We loop 1 then 0 (`1(-1)0`) to get "Inheritor" before "Non-inheritor"
    // for each quintile, matching the desired row order.
    forvalues i = 1(-1)0 {
        
        // A. Calculate the correct row number for the matrix.
        // This formula maps (quintile, status) to a unique row from 1 to 10.
        // q=1, i=1 -> row 1; q=1, i=0 -> row 2; q=2, i=1 -> row 3; etc.
        local row_num = (`q'-1)*2 + (2-`i')

        // B. Run the detailed summary for the specific subgroup.
        // `quietly` suppresses the output from appearing in the console 10 times.
        quietly summarize net_wealth if wealth_qui == `q' & inheritor == `i' [aweight=universe_wt], detail

        // C. Populate the calculated row with all 8 statistics at once.
        // This creates a temporary row vector from the r() results and assigns
        // it to the `row_num`-th row of the `results` matrix.
        matrix N[`row_num', 1] = (r(mean), r(sd), r(p10), r(p25), r(p50), r(p75), r(p90), r(p99))
    }
}

esttab matrix(N) using "Finished/Tables/Inheritors/w_by_quint_inh.tex", replace label booktabs


//////////////////////////// SELF-MADE WEALTH
matrix O = J(10, 8, .)
matrix colnames O = mean sd p10 p25 p50 p75 p90 p99
matrix rownames O = "Q1 - Inheritors" "Q1 - Non-Inheritors" "Q2 - Inheritors" "Q2 - Non-Inheritors" "Q3 - Inheritors" "Q3 - Non-Inheritors" "Q4 - Inheritors" "Q4 - Non-Inheritors" "Q5 - Inheritors" "Q5 - Non-Inheritors"

// The outer loop iterates through wealth quintiles 1 to 5.
forvalues q = 1/5 {
    
    // The inner loop iterates through inheritor status.
    // We loop 1 then 0 (`1(-1)0`) to get "Inheritor" before "Non-inheritor"
    // for each quintile, matching the desired row order.
    forvalues i = 1(-1)0 {
        
        // A. Calculate the correct row number for the matrix.
        // This formula maps (quintile, status) to a unique row from 1 to 10.
        // q=1, i=1 -> row 1; q=1, i=0 -> row 2; q=2, i=1 -> row 3; etc.
        local row_num = (`q'-1)*2 + (2-`i')

        // B. Run the detailed summary for the specific subgroup.
        // `quietly` suppresses the output from appearing in the console 10 times.
        quietly summarize selfmade_wealth if wealth_qui == `q' & inheritor == `i' [aweight=universe_wt], detail

        // C. Populate the calculated row with all 8 statistics at once.
        // This creates a temporary row vector from the r() results and assigns
        // it to the `row_num`-th row of the `results` matrix.
        matrix O[`row_num', 1] = (r(mean), r(sd), r(p10), r(p25), r(p50), r(p75), r(p90), r(p99))
    }
}

esttab matrix(O) using "Finished/Tables/Inheritors/selfmadew_by_quint_inh.tex", replace label booktabs


/////////////////////////////// INCOME
matrix P = J(10, 8, .)
matrix colnames P = mean sd p10 p25 p50 p75 p90 p99
matrix rownames P = "Q1 - Inheritors" "Q1 - Non-Inheritors" "Q2 - Inheritors" "Q2 - Non-Inheritors" "Q3 - Inheritors" "Q3 - Non-Inheritors" "Q4 - Inheritors" "Q4 - Non-Inheritors" "Q5 - Inheritors" "Q5 - Non-Inheritors"

// The outer loop iterates through wealth quintiles 1 to 5.
forvalues q = 1/5 {
    
    // The inner loop iterates through inheritor status.
    // We loop 1 then 0 (`1(-1)0`) to get "Inheritor" before "Non-inheritor"
    // for each quintile, matching the desired row order.
    forvalues i = 1(-1)0 {
        
        // A. Calculate the correct row number for the matrix.
        // This formula maps (quintile, status) to a unique row from 1 to 10.
        // q=1, i=1 -> row 1; q=1, i=0 -> row 2; q=2, i=1 -> row 3; etc.
        local row_num = (`q'-1)*2 + (2-`i')

        // B. Run the detailed summary for the specific subgroup.
        // `quietly` suppresses the output from appearing in the console 10 times.
        quietly summarize net_income if wealth_qui == `q' & inheritor == `i' [aweight=universe_wt], detail

        // C. Populate the calculated row with all 8 statistics at once.
        // This creates a temporary row vector from the r() results and assigns
        // it to the `row_num`-th row of the `results` matrix.
        matrix P[`row_num', 1] = (r(mean), r(sd), r(p10), r(p25), r(p50), r(p75), r(p90), r(p99))
    }
}

esttab matrix(P) using "Finished/Tables/Inheritors/y_by_quint_inh.tex", replace label booktabs



// =============================================================================
//
//                 DESCRIPTIVE ANALYSIS - PROFILES OF THE INHERITORS
//
// =============================================================================

// It's better to use the option subpop() after svy, instead of restricting the
// analysis with the "if" condition (see STATA SURVEY DATA REFERENCE MANUAL, subpop)

// Relative frequences of the ownership status
svy: tab owner_status, se
graph bar [pweight=universe_wt], over(owner_status) ytitle("Percent")
graph export "Finished/Figures/Inheritors/ownershipstatus.pdf", replace

// Relative frequences of the inheritors among the house-owners
svy: tab inheritor_owner, se
graph bar [pweight=universe_wt], over(inheritor_owner) title("Ownership status among the only house-owners") ytitle("Percent")

// Descriptive statistics by ownership status
cd "C:\Users\paose\Desktop\Thesis\Finished\Tables\Inheritors"
asdoc sum n_comp net_income net_wealth selfmade_wealth savings saving_rate poss_year ///
	poss_value value_2022 inher_share inheritor is_owner [aweight=universe_wt], ///
	stat(N mean sd min max p25 p50 p75) by(owner_status) replace save(DescStat.doc) title(\i)
cd "C:\Users\paose\Desktop\Thesis"

// Desc stats of the self-made owners by mortgage
cd "C:\Users\paose\Desktop\Thesis\Finished\Tables\Inheritors"
asdoc sum n_comp net_income net_wealth selfmade_wealth savings saving_rate poss_year ///
	poss_value value_2022 [aweight=universe_wt] if owner_status == 1, ///
	stat(N mean sd min max p25 p50 p75) by(mortgage) replace save(DescStat_bymortgage.doc) title(\i)
cd "C:\Users\paose\Desktop\Thesis"


// =============================================================================
// Birth cohort analysis 
// =============================================================================
// Ownership status by birth cohort
//estpost svy: tab birth_cohort owner_status, row se
//esttab using "Finished/Tables/Inheritors/ownbybirthcohort.tex", cells("b col") replace
//graph hbar (percent) [pweight = universe_wt], ///
    //over(owner_status) over(birth_cohort) stack asyvars legend(order(1 2 3) ///
    //label(1 "Non-Owner") label(2 "Self-made Owner") label(3 "Inheritor Owner"))
//graph export "Finished/Figures/Inheritors/ownership_bybirthcohort.pdf", replace

	
// Birth cohorts by ownership status
estpost svy: tab owner_status birth_cohort, col se
esttab using "Finished/Appendix/Tables/birthcohort_byown.tex", cells("b col") replace

preserve
collapse (sum) weighted_size = universe_wt, by(owner_status birth_cohort)
reshape wide weighted_size, i(owner_status) j(birth_cohort)
graph bar (sum) weighted_size1 weighted_size2 weighted_size3 weighted_size4 weighted_size5 weighted_size6, over(owner_status, label(angle(horizontal))) stack percentage ///
    ytitle("Percent") ///
	legend(order(1 2 3 4 5 6) label(1 "Greatest Gen.") label(2 "Silent Gen.") label(3 "Baby Boomers") label(4 "Gen. X") label(5 "Gen. Y") label(6 "Gen. Z") rows(2) position(6))
graph export "Finished/Figures/Population/birthcohorts_byownership.pdf", replace
restore


// Birth cohort distribution among inheritors (vs population)
svy, subpop(inheritor): tab birth_cohort owner_status, se
catplot, over(inheritor) over(birth_cohort) percent(inheritor) asyvars
graph export "Finished/Figures/Inheritors/birthcohort_inh.pdf", replace

// =============================================================================
// Geographical analysis (I've used BIRTH AREA, not RESIDENCE AREA')
// =============================================================================

// Ownership status by birth area
//svy: tab birth_area owner_status, row se
//preserve
//graph bar (percent) [pweight = universe_wt], over(owner_status, nolabel) ///
    //by(birth_area, title("Ownership status by birth area") subtitle("(0 = Non-Owners, 1 = Non-inheritor owners, 2 = Inheritor owners)") note(""))
//restore

// Birth area by ownership status
estpost svy: tab owner_status birth_area, col se
esttab using "Finished/Appendix/Tables/birtharea_byown.tex", cells("b col") replace

preserve
collapse (sum) weighted_size = universe_wt, by(owner_status birth_area)
reshape wide weighted_size, i(owner_status) j(birth_area)
graph bar (sum) weighted_size1 weighted_size2 weighted_size3 weighted_size4, over(owner_status, label(angle(horizontal))) stack percentage ///
    ytitle("Percent") ///
	legend(order(1 2 3 4) label(1 "North") label(2 "Centre") label(3 "South") label(4 "Foreign") rows(1) position(6))
graph export "Finished/Figures/Population/birtharea_byownership.pdf", replace
restore


// Birth area distribution among inheritors (vs population)
svy, subpop(inheritor): tab owner_status birth_area, se
catplot, over(inheritor) over(birth_area) percent(inheritor) asyvars
graph export "Finished/Figures/Inheritors/birtharea_inh.pdf", replace


// =============================================================================
// Education analysis
// =============================================================================

// Ownership status by education
//svy: tab edu owner_status, row se
//preserve
//label define edu_labels 4 "Professional Diploma", modify
//graph bar (percent) [pweight = universe_wt], over(owner_status, nolabel) /// 
     //by(edu, title("Ownership status by education") subtitle("(0 = Non-Owners, 1 = Non-inheritor owners, 2 = Inheritor owners)") note("")) 
//restore

// Education by ownership status
estpost svy: tab owner_status edu, col se
esttab using "Finished/Appendix/Tables/education_byown.tex", cells("b col") replace

preserve
collapse (sum) weighted_size = universe_wt, by(owner_status edu)
reshape wide weighted_size, i(owner_status) j(edu)
graph bar (sum) weighted_size1 weighted_size2 weighted_size3 weighted_size4 weighted_size5 weighted_size6 weighted_size7 weighted_size8, ///
	over(owner_status, label(angle(horizontal))) stack percentage ///
    ytitle("Percent") ///
	legend(order(1 2 3 4 5 6 7 8) label(1 "None") label(2 "Primary School") label(3 "Lower Secondary School") label(4 "Professional Diploma") label(5 "Upper Seconday School") label(6 "Bachelor's Degree") label(7 "Master's Degree") label(8 "Post-Lauream Specialization") rows(4) position(6))
graph export "Finished/Figures/Population/education_byownership.pdf", replace
restore


// Education distribution among inheritors (vs population)
svy, subpop(inheritor): tab edu owner_status, se
catplot, over(inheritor) over(edu) percent(inheritor) asyvars
graph export "Finished/Figures/Inheritors/education_inh.pdf", replace

// =============================================================================
// Parents' education analysis
// =============================================================================

// Ownership status by parents' education
//svy: tab parent_edu owner_status, row se
//preserve
//label define parent_edu_labels 6 "Post-Grad Specialization", modify
//graph bar (percent) [pweight = universe_wt], over(owner_status, nolabel) /// 
     //by(parent_edu, title("Ownership status by parents' education") subtitle("(0 = Non-Owners, 1 = Non-inheritor owners, 2 = Inheritor owners)") note("")) 
//restore

// Parent's education by ownership status
estpost svy: tab owner_status parent_edu, col se
esttab using "Finished/Appendix/Tables/parentedu_byown.tex", cells("b col") replace

preserve
collapse (sum) weighted_size = universe_wt, by(owner_status parent_edu)
reshape wide weighted_size, i(owner_status) j(parent_edu)
graph bar (sum) weighted_size1 weighted_size2 weighted_size3 weighted_size4 weighted_size5 weighted_size6 weighted_size7, ///
	over(owner_status, label(angle(horizontal))) stack percentage ///
    ytitle("Percent") ///
	legend(order(1 2 3 4 5 6 7) label(1 "None") label(2 "Primary School") label(3 "Lower Secondary School") label(4 "Upper Secondary School") label(5 "Bachelor's Degree") label(6 "Post-Graduate Specialization") label(7 "No Response/Don't Know") rows(4) position(6))
graph export "Finished/Figures/Population/parentedu_byownership.pdf", replace
restore

// Parents' education distribution among inheritors (vs population)
svy, subpop(inheritor): tab parent_edu owner_status, se
catplot, over(inheritor) over(parent_edu) percent(inheritor) asyvars
graph export "Finished/Figures/Inheritors/parentedu_inh.pdf", replace


// =============================================================================
// Working status analysis
// =============================================================================

// Ownership status by working status
//svy: tab work_status owner_status, row se
//preserve
//label define occupation_labels 4 "Entrepreneur/Self-employed", modify
//graph bar (percent) [pweight = universe_wt], over(owner_status, nolabel) /// 
     //by(work_status, title("Ownership status by working status") subtitle("(0 = Non-Owners, 1 = Non-inheritor owners, 2 = Inheritor owners)") note(""))
//restore

// Working status by ownership status
estpost svy: tab owner_status work_status, col se
esttab using "Finished/Appendix/Tables/workstatus_byown.tex", cells("b col") replace

preserve
collapse (sum) weighted_size = universe_wt, by(owner_status work_status)
reshape wide weighted_size, i(owner_status) j(work_status)
graph bar (sum) weighted_size1 weighted_size2 weighted_size3 weighted_size4 weighted_size5 weighted_size6 weighted_size7, ///
	over(owner_status, label(angle(horizontal))) stack percentage ///
    ytitle("Percent") ///
	legend(order(1 2 3 4 5 6 7) label(1 "Worker") label(2 "Clerk") label(3 "Manager") label(4 "Entrepreneur/Self-employed") label(5 "Other Self-employed") label(6 "Retired") label(7 "Other Not Employed") rows(4) position(6))
graph export "Finished/Figures/Population/workstatus_byownership.pdf", replace
restore


// Working status distribution among inheritors (vs population)
svy, subpop(inheritor): tab work_status owner_status, se
catplot, over(inheritor) over(work_status) percent(inheritor) asyvars
graph export "Finished/Figures/Inheritors/workstatus_inh.pdf", replace

//==============================================================================
// INEQUALITY ANALYSIS WITHIN HOUSEHOLDS
//==============================================================================
////////////////// NET INCOME
ineqdeco net_income [pweight=universe_wt] if owner_status == 2
matrix A = ( r(gini) \ r(p90p10) \ r(p90p50) \ r(p10p50) \ r(p75p25) \ r(ge0) \ r(ge1) \ r(ge2) \ r(ahalf) \ r(a1) \ r(a2))
//svygei net_income
//svyatk net_income
//svylorenz net_income


////////////////// NET WEALTH
ineqdec0 net_wealth [pweight=universe_wt] if owner_status == 2
matrix B = ( r(gini) \ r(p90p10) \ r(p90p50) \ r(p10p50) \ r(p75p25) \ r(ge0) \ r(ge1) \ r(ge2) \ r(ahalf) \ r(a1) \ r(a2))
//svygei net_wealth
//svyatk net_wealth
//svylorenz net_wealth


////////////////// TRANSFORMED NET WEALTH
ineqdeco pos_net_wealth [pweight=universe_wt] if owner_status == 2
matrix C = ( r(gini) \ r(p90p10) \ r(p90p50) \ r(p10p50) \ r(p75p25) \ r(ge0) \ r(ge1) \ r(ge2) \ r(ahalf) \ r(a1) \ r(a2))
//svygei pos_net_wealth
//svyatk pos_net_wealth
//svylorenz pos_net_wealth


// Create the table with the inequality indexes for all these 3 variables
matrix D = A, B, C
matrix colnames D = "Net Income" "Net Wealth" "Transformed Net Wealth"
matrix rownames D = "Gini Coefficient" "p90/p10 Ratio" "p90/p50 Ratio" "p10/p50 Ratio" "p75/p25 Ratio" "GE(0)" "GE(1)" "GE(2)" "Atk(0.5)" "Atk(1)" "Atk(2)"
esttab matrix(D) using "Finished/Tables/Inheritors/inequalityindexes.tex", title("Inequality Indices for Income and Wealth") ///
    replace label booktabs

// Create the Lorenz curves for income and transformed wealth
lorenz net_income pos_net_wealth [pweight=universe_wt] if owner_status == 2, ///
	graph(overlay xlabels(, grid) labels("Net income" "Transformed Net Wealth") legend(position(6)))
graph export "Finished/Figures/Inheritors/lorenz_curves.pdf", replace

// Test for Lorenz Dominance
lorenz pos_net_wealth net_income [pweight=universe_wt] if owner_status == 2, contrast graph
graph export "Finished/Figures/Inheritors/lorenz_dominance.pdf", replace


//==============================================================================
// Close the log
log close