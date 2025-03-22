cls
clear
capture log close
/*******************************************************************************
PROJECT: create age-standardized death rates for each cause by dividing each cause of death category by the appropriate population denominator
			
UPDATED BY:	Vincent Pancini
UPDATED ON: 2032-06-15

INPUTS: $out\death_3yravg_and_pop_cza.dta
		$data\agestd90_new.dta
		$rates\detailed_deathrates.dta
*******************************************************************************/
 global logs       "[log file directory]"
 global do	   "[do file directory]"
 global data	   "[central data directory]"
 global out	   "[analtyic file directory]"
********************************************************************************
*log using $logs\mort_rates.log, replace

use "$out\death_3yravg_and_pop_nostcza_alled_res.dta", clear  
merge m:1 sex race age_lt using $data\agestd90_new.dta
* 38 not matched from master because missing sex, race, age_lt (and missing czone but not cza)

rename deaths deaths_0

forval i = 0/27 {
	gen Mx_deaths_`i' = deaths_`i' / pop_tot
	capture noisily {
		foreach j in `c(alpha)' {
			gen Mx_deaths_`i'`j' = deaths_`i'`j' / pop_tot
		}
	}
}

summ Mx*

rename pop_tot Px_tot_

do $do\6b_lifetables_nostcz_alled_res.do

use $out\detailed_deathrates_nostcz_alled_res.dta, clear

gen agecat = .
	replace agecat = 2564 if age_lt < 65
	replace agecat = 6584 if age_lt >= 65 & !missing(age_lt)
		label values agecat _age
tab agecat, m
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race cza noedst sex agecat)
save $out\stdzd_deathrates_pt1_nostcz_alled_res.dta, replace

use $out\detailed_deathrates_nostcz_alled_res.dta, replace
keep if inrange(age_lt, 45, 50)
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race cza noedst sex)
gen agecat = 4554
tab agecat, m
save $out\stdzd_deathrates_pt2_nostcz_alled_res.dta, replace

use  $out\detailed_deathrates_nostcz_alled_res.dta, replace
keep if inrange(age_lt, 45, 60)==1
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race cza noedst sex)
gen agecat = 4564
tab agecat, m
save $out\stdzd_deathrates_pt3_nostcz_alled_res.dta, replace


use  $out\detailed_deathrates_nostcz_alled_res.dta, replace
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race cza noedst sex)
gen agecat = 2584
tab agecat, m
append using  $out\stdzd_deathrates_pt1_nostcz_alled_res.dta
append using  $out\stdzd_deathrates_pt2_nostcz_alled_res.dta
append using  $out\stdzd_deathrates_pt3_nostcz_alled_res.dta

sort agecat  cza year sex
label define _age 2564 "Age 25 - 64" 6585 "Age 65 - 85" 4554 "Age 45 - 54" 4564 "Age 45 - 64" 2584 "Age 25 - 84" 6584 "Age 65 - 84", modify
label values agecat _age
summ Mx* Px* 
* summ yll*
sort year  cza noedst race sex agecat
order year  cza noedst race sex agecat
save $out\stdzd_deathrates_nostcz_alled_res.dta, replace
