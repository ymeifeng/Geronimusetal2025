clear all
capture log close
cls
/*******************************************************************************
PROJECT:	Pools death counts in three year groups (in a moving-average way) 
			and collapses to the cause, age, sex, race, commuting zone level
			7/10/24: remove state separation of CZones
			
CREATED BY:	Tim Waidmann

UPDATED BY:	 Tim Waidmann, Vincent Pancini, Luis Basurto, Justin Morgan,
UPDATED ON: 	07/10/24,01/26/24, 8/26/21, 05/01/2019
*******************************************************************************/
global	logs	"[log file directory]"
global 	data	"[data file directory]"
global  out	"[analysis file directory]"
global 	dorn	"[dorn data directory]"
global  dosource "$do\4_collapse_3yr_by_cznost_br.do"
********************************************************************************
* log using $logs\collapse_by_cz_mort3.log, replace

foreach yr2 in 1990 2017 {
	*if you want to run one or the other, just comment out the one you don't want

		local yr1 = `yr2' - 1
		local yr3 = `yr2' + 1
		use "$out\deathtab_`yr1'_final_res", clear
			append using "$out\deathtab_`yr2'_final_res"
			append using "$out\deathtab_`yr3'_final_res"
/*		if `yr2' >= 2010 {
			/*Broomfield county (08014) is created out of parts of Adams (08001), Boulder (08013), Jefferson (08059), and Weld (08123) in 2001*/
			replace countyfips = "08059" if countyfips == "08014" 
			/*Dade county (12025) is renamed as Miami-Dade (12086) in 1997*/
			replace countyfips = "12025" if countyfips == "12086" 
		}
		*/
		gen county_fips=real(countyfips)
		
		drop if inlist(statefips,"13", "22", "33", "36", "40", "44", "46", "53")
		merge m:1 county_fips using "$data\crosswalks\raw\czlma903_fix"
			list county_fips czone _merge if _merge!=3
			summ deaths if _merge!=3
			drop if _merge!=3
		collapse (sum) deaths*, by(czone sex race age_lt )
		drop deaths_*
			notes : Created on ${S_DATE} by $dosource 
		save $out/deathtab`yr2'_3yr_cznost_br, replace
	}


