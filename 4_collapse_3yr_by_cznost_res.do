clear all
capture log close
cls
/*******************************************************************************
PROJECT:	Pools death counts in three year groups (in a moving-average way) 
			and collapses to the cause, age, sex, race, commuting zone level
			7/10/24: remove state separation of CZones
			
CREATED BY:	Tim Waidmann

UPDATED BY:	 Tim Waidmann, Vincent Pancini, Luis Basurto, Justin Morgan,
UPDATED ON: 07/10/24,01/26/24, 8/26/21, 05/01/2019

INPUTS:		deathtab_YYYY_final_res.dta
			deathtab_YYYY_final_res.dta
*******************************************************************************/
global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global	dorn	"$data\dorn" /*data downloaded from https://www.ddorn.net/data.htm*/
global  dosource "$do\4_collapse_3yr_by_cznost_res.do"
********************************************************************************
* log using $logs\collapse_by_cz_mort3.log, replace

foreach yr2 in 1990 2017 {
	*if you want to run one or the other, just comment out the one you don't want

		local yr1 = `yr2' - 1
		local yr3 = `yr2' + 1
		use "$out\deathtab_`yr1'_final_res", clear
			append using "$out\deathtab_`yr2'_final_res"
			append using "$out\deathtab_`yr3'_final_res"
		if `yr2' >= 2010 {
			/*Broomfield county (08014) is created out of parts of Adams (08001), Boulder (08013), Jefferson (08059), and Weld (08123) in 2001*/
			replace countyfips = "08059" if countyfips == "08014" 
			/*Dade county (12025) is renamed as Miami-Dade (12086) in 1997*/
			replace countyfips = "12025" if countyfips == "12086" 
		}
		drop if statefips=="33"  
		merge m:1 statefips countyfips using $dorn\cz_state.dta
			list countyfips cza _merge if _merge!=3
		collapse (sum) deaths*, by(sex race age_lt cza _merge)
			notes : Created on ${S_DATE} by $dosource 
		save $out/deathtab`yr2'_3yr_cznost_res, replace
	}


