// Set the path to your working directory
cd "C:\Users\paose\Desktop\Thesis"

// Open a log file to record all commands and output
capture log close

log using "Finished\DataCleaning\log_data_cleaning.log", replace text


// =============================================================================
//
//                          DATA PREPARATION
//
// =============================================================================


// =============================================================================
// START WITH PARENTS' EDUCATION DATA CLEANING
// =============================================================================
use "Finished\Datasets\Source\fami.dta", clear
drop if anno == 2022
keep anno nquest stupcf stumcf
drop if missing(stupcf) & missing(stumcf)
sort nquest anno
bysort nquest: keep if _n == _N
rename stupcf panel_stupcf
rename stumcf panel_stumcf
save "Finished\Datasets\Derived\panel parent education.dta", replace

use "Finished\Datasets\Source\q22a.dta", clear
merge m:1 nquest using "Finished\Datasets\Derived\panel parent education.dta"
replace stupcf = panel_stupcf if quest == 3
replace stumcf = panel_stumcf if quest == 3
drop if _merge == 2
egen parent_edu = rowmax(stupcf stumcf) // use only the maximum level of the education among the 2 parents
keep nquest parent_edu
label define parent_edu_labels 1 "None" 2 "Primary School" 3 "Lower Secondary School" 4 "Upper Secondary School" 5 "Bachelor's Degree" 6 "Post-Graduate Specialization" 7 "No Response/Don't Know"
label values parent_edu parent_edu_labels
save "Finished\Datasets\Derived\parent education.dta", replace

// =============================================================================
// IMPORT THE MASTER DATASET WITH THE HOUSEHOLDS' CHARACTERISTICS
// CREATE THE VARIABLE FOR BIRTH COHORTS (ACCORDING TO SOCIOLOGY), AND CLEAN
// =============================================================================
use "Finished\Datasets\Source\carcom22.dta", clear
rename (ncomp anasc studio qual cfred area3 nascarea pesofit pesofit2 aningr) ///
(n_comp birth_year edu work_status head_of_family resid_area birth_area sample_wt universe_wt immigr_year)

// Now assume that the socioeconomic characteristics of the households are represented
// by their maximum income receiver, and delete the rows about the other components
keep if head_of_family == 1 
drop head_of_family

gen birth_cohort = .
replace birth_cohort = 1 if birth_year <= 1927 & !missing(birth_year)
replace birth_cohort = 2 if birth_year >= 1928 & birth_year <= 1945
replace birth_cohort = 3 if birth_year >= 1946 & birth_year <= 1964
replace birth_cohort = 4 if birth_year >= 1965 & birth_year <= 1980
replace birth_cohort = 5 if birth_year >= 1981 & birth_year <= 1996
replace birth_cohort = 6 if birth_year >= 1997 & birth_year <= 2012
label define cohort_labels ///
    1 "Greatest Generation" ///
    2 "Silent Generation" ///
    3 "Baby Boomers" ///
    4 "Generation X" ///
    5 "Millennials/Generation Y" ///
    6 "Zoomers/Generation Z"
label values birth_cohort cohort_labels


// Now use the info on the immigration year to fill the missing data in birth area
replace birth_area = 4 if immigr_year != .
label define areas_labels 1 "North" 2 "Centre" 3 "South" 4 "Foreign"
label values resid_area areas_labels
label values birth_area areas_labels

// Create other labels
label define occupation_labels 1 "Worker" 2 "Clerk" 3 "Manager" 4 "Entrepreneur/Self-employed Professional" 5 "Other Self-employed" 6 "Retired" 7 "Other Not Employed"
label values work_status occupation_labels
label define edu_labels 1 "None" 2 "Primary School" 3 "Lower Secondary School" 4 "Professional Diploma (3 years)" 5 "Upper Secondary School" 6 "Bachelor's Degree" 7 "Master's Degree" 8 "Post-lauream Specialization"
label values edu edu_labels


// =============================================================================
// MERGE SEQUENTIALLY THE OTHER DATASETS, CREATE AND RENAME VARIABLES
// =============================================================================
merge 1:1 nquest using "Finished\Datasets\Derived\parent education.dta"
drop _merge

merge 1:1 nquest using "Finished\Datasets\Source\q22d.dta"
drop _merge
rename (anposs impacq2 poss1 valabit debita1) (poss_year poss_value poss_way value_2022 mortgage)
recode mortgage (2=0)
gen log_value_2022 = log(value_2022)

merge 1:1 nquest using "Finished\Datasets\Source\rfam22.dta"
drop _merge
rename (y cly cly2) (net_income income_dec income_qui)
// 24 obs have a disposable income <= 0: it's the case of the autonomous workers.
// We deal with them by simply setting them to 0.1 (otherwise there would be problems with Gini computation)
replace net_income = 0.1 if net_income <=0


merge 1:1 nquest using "Finished\Datasets\Source\ricfam22.dta"
drop _merge
rename (w clw clw2) (net_wealth wealth_dec wealth_qui)

merge 1:1 nquest using "Finished\Datasets\Source\risfam22.dta"
drop _merge
rename s savings
gen saving_rate = savings / net_income

merge m:1 poss_year using "Finished\Datasets\Derived\deflator.dta"
drop _merge


// =============================================================================
// CREATE A CATEGORICAL VARIABLE FOR THE OWNERSHIP STATUS: 0 = NON-OWNER ; 
// 1 = "SELF-MADE" OWNER; 2 = INHERITOR OWNER.
// THEN CREATE OTHER VARIABLES
// =============================================================================
gen owner_status = 0 if missing(poss_way)
replace owner_status = 1 if poss_way != 3 & !missing(poss_way)
replace owner_status = 2 if poss_way == 3
label define owner_lbl 0 "Non-Owner" 1 `""Self-made" Owner"' 2 "Inheritor Owner"
label values owner_status owner_lbl

// Create the "inheritance share variable". For rare cases where inherited value might be
// reported as higher than net wealth (due to debt), we cap the share at 100.
gen inher_share = 0
replace inher_share = (value_2022 / net_wealth) * 100 if owner_status == 2 & net_wealth > 0
// replace inher_share = 100 if inher_share > 100

// Create the "non-inherited wealth" variable
gen selfmade_wealth = net_wealth - value_2022
replace selfmade_wealth = net_wealth if owner_status != 2

// =============================================================================
// CLEAN AND ORDER
// =============================================================================
keep nquest n_comp birth_year edu birth_area work_status resid_area sample_wt universe_wt /// 
	birth_cohort parent_edu poss_year poss_value poss_way value_2022 log_value_2022 owner_status ///
	net_income income_dec income_qui net_wealth wealth_dec wealth_qui savings saving_rate inher_share selfmade_wealth deflator mortgage

order nquest n_comp birth_year birth_cohort birth_area resid_area edu work_status parent_edu ///
	net_income net_wealth mortgage selfmade_wealth savings saving_rate poss_year poss_way owner_status ///
	poss_value deflator value_2022 log_value_2022 inher_share income_dec income_qui wealth_dec wealth_qui sample_wt universe_wt

//For future histograms, the histogram command will only accept a frequency weight, which, by definition, can have only integer values. 
//A suggestion by Heeringa, West and Berglund (2010, pages 121-122) is to simply use the integer part of the sampling weight.
gen int_universewt = int(universe_wt)
gen int_samplewt = int(sample_wt)

// =============================================================================
// REVIEW THE PLAUSIBILITY OF VALUES
// =============================================================================
// Check for uniqueness of ID variable
duplicates example nquest

// Plausibility check
codebook, problems
codebook, compact

// About the saving_rate: the very negative ones are plausible (when C > Y thanks to debt);
// the single obs with >=1 is an anomaly, so I cap it at 0.99
replace saving_rate = 0.99 if saving_rate >=1

// How to deal with all the poss_value very small (e.g. < 5000€)? Are they plausible? 
// Yes, they're the houses in micro towns.
// (Keep in mind that there are 1987 missing values, so an histogram would be disturbed on the right tail since .=99999)

// How to deal with values for 2022 very small (only 4 obs < 10.000€)? Same

// =============================================================================
// MISSING DATA ANALYSIS (https://doi.org/10.1080/14639220903470205)
// =============================================================================
misstable summarize
misstable patterns

// Missing parent edu? Leave it (it's just 1 obs) or impute it
// Since he has a master's degree, see the most frequent level of education for
// the parents, and impute it
tab parent_edu edu if edu == 7
replace parent_edu = 4 if parent_edu == .

// Missing birth_area? Leave it (it's just 1 obs) or impute it
// Impute the same birth area as the actual residence area for simplicity
replace birth_area = resid_area if birth_area == .

// There's 1 non-owner that reported poss_value (replace it as missing)
replace poss_value = . if owner_status == 0

// Check again to be sure
misstable summarize
missingplot


// =============================================================================
// ADD WEIGHTS FOR JACKKNIFE
// =============================================================================
merge 1:1 nquest using "Finished\Datasets\Source\pesijack22.dta"
drop _merge
rename nquest ID


// =============================================================================
// CREATE VARIABLE FOR FUTURE ANALYSES
// =============================================================================
// Create a binary variable inheritors vs non-inheritors (both owner and renter)
gen inheritor = 0
replace inheritor = 1 if owner_status == 2
label define inheritorbinary 0 "Non-inheritor" 1 "Inheritor"
label val inheritor inheritorbinary

// Create the subpopulation of house-owners
gen is_owner = (owner_status > 0)
// We're studying the probability of receiving an inheritance among the ONLY OWNERS
// So it's better to create a binary variable
gen inheritor_owner = 0 if owner_status == 1
replace inheritor_owner = 1 if owner_status == 2
label def owner_dichot 0 `""Self-made" Owner"' 1 "Inheritor owner"
label val inheritor_owner owner_dichot

// Now create the log of net income and net wealth since they're very right-skewed
// However, there are 258 obs of net_wealth <=0 and 25 obs of net_inome <=0.
// Can I simply not consider them or should I use the Inverse Hyperbolic Sine transformation???
gen log_income = ln(net_income + 1) //add 1 for the values very close to 0

gen log_wealth = ln(net_wealth + 1) if net_wealth >= 0
gen neg_wealth_dummy = (net_wealth < 0) // to be added in the regression otherwise selection bias

// Since the boxplots will be too influenced by outliers, let's use the log variables
// However, since net_wealth can be <=0, let's use the asinh transformation (cite a paper to justify)
gen asinh_net_wealth = asinh(net_wealth)

// =============================================================================
// CREATE VARIABLE FOR FUTURE MICROSIMULATION MODEL
// =============================================================================
// Bring the value of the inherited real estates forward to the 2022 equivalent value
gen poss_value_reevaluated = poss_value * deflator if owner_status == 2
// the reevaluated values are very different from the 2022 declared values, see:
sum value_2022 if owner_status == 2, det
sum poss_value_reevaluated if owner_status == 2, det
// Recall Bias: The "value at time of inheritance" might suffer from significant recall bias, especially for transfers
// that happened long ago, and especially when converting lira/euro. Relying on the current market value could be more robust.

// I might run the microsimulation first with 2022 value and then with reevaluated past value, to check if the 
// results on Gini etc... are robust.

// SINCE GINI INDEX IS COMPUTED ONLY ON >= 0 VALUES, CREATE A NON-NEGATIVE NET WEALTH VARIABLE!!!
gen pos_net_wealth = net_wealth
replace pos_net_wealth = 1.01 if net_wealth <= 0


// =============================================================================
// DESCRIBE THE SURVEY DESIGN
// =============================================================================
svyset [pweight = universe_wt], vce(jackknife) jkrw(pwt*) mse
// Capire se devo usare solo queste opzioni per gli errori standard oppure devo metterne di più
// per riflettere gli stage e gli strata del sampling (vedi file "Metodologia SHIW"). 
// Sembra  di no, vedi par. 4.2.1 "Applied Survey Data Analysis (2° edition)"

// Al paragrafo 4.2.2 invece dice che è uguale usare sample_wt o universe_wt


// Save the master dataset
save "Finished\Datasets\Derived\master dataset.dta", replace

// Close the log file
log close

