clear all
capture log close
cls
/*******************************************************************************
PROJECT:	adds CZ codes to annual death tabs by cause, county for alled version
			
CREATED BY:	Vincent Pancini
UPDATED ON: 2023-06-15

*******************************************************************************/
 global logs       "[log file directory]"
 global do	   "[do file directory]"
 global data	   "[central data directory]"
 global out	   "[analtyic file directory]"
********************************************************************************
* log using $logs\attach_d_p_czone.log, replace

use "$out\deathtab1990_3yr_czone_alled_nostcz_res.dta", clear

gen int year = 1990

append using "$out\deathtab2017_3yr_czone_alled_nostcz_res.dta"
	replace year = 2017 if year ==  .

foreach dvar of varlist death* {
	replace `dvar' = `dvar' / 3
}
	drop if cza == ""
	drop _merge
	
merge 1:1 year  cza noedst sex race age_lt using "$out\poped_wide_nostcz.dta"
	drop if age_lt == 85
	
foreach dvar of varlist death* {
	replace `dvar' = 0 if _merge == 2
}

foreach pvar of varlist po* ob* {
	replace `pvar' = 0 if _merge == 1
}

gen byte nopopdata = (_merge == 1)
gen byte nodeathdata = (_merge == 2)
drop _merge twofiles 
save "$out\death_3yravg_and_pop_nostcza_alled_res.dta", replace

