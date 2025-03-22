clear all
cls
capture log close
/*******************************************************************************
PROJECT:	Pools death counts in three year groups (in a moving-average way) 
			and collapses to the cause, age, sex, race, commuting zone level
			
CREATED BY:	Vincent Pancini
UPDATED ON: 2023-06-15	

INPUTS:		deathtabYYYYlevel_final.dta, deathtabYYYYrank_final.dta
OUTPUTS:    deathtabYYYY_alled.dta

*******************************************************************************/
global	logs	"G:\logs\all_ed_version"
global	dorn	"G:\data\dorn"
global 	data	"G:\data\mortality"
global  out		"G:\data\mortality\all_ed_version"
********************************************************************************
* log using $logs\collapse_by_cz_.log, replace

foreach yr2 in 1990 2017 {
	*if you want to run one or the other, just comment out the one you don't want

		local yr1 = `yr2' - 1
		local yr3 = `yr2' + 1
		use "$out\deathtab`yr1'_alled_res", clear
			append using "$out\deathtab`yr2'_alled_res"
			append using "$out\deathtab`yr3'_alled_res"
		if `yr2' >= 2010 {
			/*Broomfield county (08014) is created out of parts of Adams (08001), Boulder (08013), Jefferson (08059), and Weld (08123) in 2001*/
			replace countyfips = "08059" if countyfips == "08014" 
			/*Dade county (12025) is renamed as Miami-Dade (12086) in 1997*/
			replace countyfips = "12025" if countyfips == "12086" 
		}
		merge m:1 statefips countyfips using $dorn\cz_state.dta
			list statefips countyfips cza _merge if _merge!=3
			collapse (sum) deaths*, by(sex race age_lt statefips cza _merge)
		save $out/deathtab`yr2'_3yr_czone_alled_res, replace
}


