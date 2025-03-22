cls
clear
capture log close
/*******************************************************************************
PROJECT: create age-standardized death rates for each cause (and cause by education) by dividing each cause of death categorie by the appropriate population denominator
			
UPDATED BY:	tim waidmann; vincent pancini
UPDATED ON: 07/10/2024; 2022-03-25

INPUTS: $out\death_3yravg_and_pop_cza.dta
		$data\agestd90_new.dta
		$rates\detailed_deathrates.dta
*******************************************************************************/
global	logs	"[log file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global  do      "[do file directory]"
global  dosource "$do\6_mort_rates_bycause_cznost_br.do"
********************************************************************************
log using $logs\mort_rates_cznost_br.log, replace

use "$out\death_3yravg_and_pop_cznost_br", clear  
merge m:1 sex race age_lt using $data\agestd90_new.dta
* 1,582 not matched from master because missing sex, race, age_lt (and missing czone but not cza)
rename poptot pop_tot
rename deaths 		deaths_0


gen Mx_deaths_0 = deaths_0 / pop_tot
replace Mx_deaths_0 =1 if Mx_deaths_0>1 & Mx_deaths_0!=.
summ Mx*


foreach suffix in tot {
	rename pop_`suffix' Px_`suffix'_
}

do $do\6b_lifetables_cznost_br.do

use $out\detailed_deathrates_cznost_br.dta, clear

gen agecat = .
	replace agecat = 2564 if age_lt < 65
	replace agecat = 6584 if age_lt >= 65 & !missing(age_lt)
		label values agecat _age
tab agecat, m
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race czone sex agecat)
notes : Created on ${S_DATE} by $dosource 
save $out\stdzd_deathrates_cznost_br_pt1.dta, replace

use $out\detailed_deathrates_cznost_br.dta, replace
keep if inrange(age_lt, 45, 50)
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race czone sex)
gen agecat = 4554
tab agecat, m
notes : Created on ${S_DATE} by $dosource 
save $out\stdzd_deathrates_cznost_br_pt2.dta, replace

use  $out\detailed_deathrates_cznost_br.dta, replace
keep if inrange(age_lt, 45, 60)==1
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race czone sex)
gen agecat = 4564
tab agecat, m
notes : Created on ${S_DATE} by $dosource 
save $out\stdzd_deathrates_cznost_br_pt3.dta, replace


use  $out\detailed_deathrates_cznost_br.dta, replace
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race czone sex)
gen agecat = 2584
tab agecat, m
append using  $out\stdzd_deathrates_cznost_br_pt1.dta
append using  $out\stdzd_deathrates_cznost_br_pt2.dta
append using  $out\stdzd_deathrates_cznost_br_pt3.dta

sort agecat  czone year sex
label define _age 2564 "Age 25 - 64" 6585 "Age 65 - 85" 4554 "Age 45 - 54" 4564 "Age 45 - 64" 2584 "Age 25 - 84" 6584 "Age 65 - 84", modify
label values agecat _age
summ Mx* Px* 
* summ yll*
sort year  czone race sex agecat
order year  czone race sex agecat
notes : Created on ${S_DATE} by $dosource 
save $out\stdzd_deathrates_cznost_br.dta, replace
