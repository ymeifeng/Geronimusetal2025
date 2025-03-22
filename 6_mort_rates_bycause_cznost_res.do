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
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global	dorn	"$data\dorn" /*data downloaded from https://www.ddorn.net/data.htm*/
global  dosource "$do\6_mort_rates_bycause_cznost_res.do"
********************************************************************************
log using $logs\mort_rates_cznost.log, replace

use "$out\death_3yravg_and_pop_cznost_res", clear  
merge m:1 sex race age_lt using $data\agestd90_new.dta
* 1,582 not matched from master because missing sex, race, age_lt (and missing czone but not cza)

rename pop_ghs_1    pop_ghs
rename pop_ghs_0    pop_lehs
rename pop_coll_1    pop_coll
rename pop_coll_0    pop_ltcol
rename pop_hi75_1   pop_hi75
rename pop_hi75_0   pop_lo25
rename obs_ghs_1    obs_ghs
rename obs_ghs_0    obs_lehs
rename obs_coll_1    obs_coll
rename obs_coll_0    obs_ltcol
rename obs_hi75_1   obs_hi75
rename obs_hi75_0   obs_lo25

rename deaths 		deaths_0
rename deaths_ghs   deaths_0_ghs
rename deaths_lehs  deaths_0_lehs
rename deaths_coll   deaths_0_coll
rename deaths_ltcol  deaths_0_ltcol
rename deaths_hi75  deaths_0_hi75
rename deaths_lo25  deaths_0_lo25



forval i = 0/27 {
	gen Mx_deaths_`i' = deaths_`i' / pop_tot
	gen Mx_deaths_`i'_ghs = deaths_`i'_ghs / pop_ghs
	gen Mx_deaths_`i'_lehs = deaths_`i'_lehs / pop_lehs
	gen Mx_deaths_`i'_coll = deaths_`i'_coll / pop_coll
	gen Mx_deaths_`i'_ltcol = deaths_`i'_ltcol / pop_ltcol
	gen Mx_deaths_`i'_hi75 = deaths_`i'_hi75 / pop_hi75
	gen Mx_deaths_`i'_lo25 = deaths_`i'_lo25 / pop_lo25
	capture noisily {
		foreach j in `c(alpha)' {
			gen Mx_deaths_`i'`j' = deaths_`i'`j' / pop_tot
			gen Mx_deaths_`i'`j'_ghs = deaths_`i'`j'_ghs / pop_ghs
			gen Mx_deaths_`i'`j'_lehs = deaths_`i'`j'_lehs / pop_lehs
			gen Mx_deaths_`i'`j'_coll = deaths_`i'`j'_coll / pop_coll
			gen Mx_deaths_`i'`j'_ltcol = deaths_`i'`j'_ltcol / pop_ltcol
			gen Mx_deaths_`i'`j'_hi75 = deaths_`i'`j'_hi75 / pop_hi75
			gen Mx_deaths_`i'`j'_lo25 = deaths_`i'`j'_lo25 / pop_lo25
		}
	}
}

summ Mx*


foreach suffix in tot ghs lehs coll ltcol hi75 lo25 {
	rename pop_`suffix' Px_`suffix'_
}

do $do\6b_lifetables_cznost_res.do

use $out\detailed_deathrates_cznost_res.dta, clear

gen agecat = .
	replace agecat = 2564 if age_lt < 65
	replace agecat = 6584 if age_lt >= 65 & !missing(age_lt)
		label values agecat _age
tab agecat, m
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race cza sex agecat)
notes : Created on ${S_DATE} by $dosource 
save $out\stdzd_deathrates_cznost_res_pt1.dta, replace

use $out\detailed_deathrates_cznost_res.dta, replace
keep if inrange(age_lt, 45, 50)
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race cza sex)
gen agecat = 4554
tab agecat, m
notes : Created on ${S_DATE} by $dosource 
save $out\stdzd_deathrates_cznost_res_pt2.dta, replace

use  $out\detailed_deathrates_cznost_res.dta, replace
keep if inrange(age_lt, 45, 60)==1
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race cza sex)
gen agecat = 4564
tab agecat, m
notes : Created on ${S_DATE} by $dosource 
save $out\stdzd_deathrates_cznost_res_pt3.dta, replace


use  $out\detailed_deathrates_cznost_res.dta, replace
collapse (mean) Mx* (rawsum) Px* yll* [aw = agewt90], by(year  race cza sex)
gen agecat = 2584
tab agecat, m
append using  $out\stdzd_deathrates_cznost_res_pt1.dta
append using  $out\stdzd_deathrates_cznost_res_pt2.dta
append using  $out\stdzd_deathrates_cznost_res_pt3.dta

sort agecat  cza year sex
label define _age 2564 "Age 25 - 64" 6585 "Age 65 - 85" 4554 "Age 45 - 54" 4564 "Age 45 - 64" 2584 "Age 25 - 84" 6584 "Age 65 - 84", modify
label values agecat _age
summ Mx* Px* 
* summ yll*
sort year  cza race sex agecat
order year  cza race sex agecat
notes : Created on ${S_DATE} by $dosource 
save $out\stdzd_deathrates_cznost_res.dta, replace
