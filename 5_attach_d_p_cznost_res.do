clear all
capture log close
cls
/*******************************************************************************
PROJECT:	adds CZ codes to annual death tabs by cause, CZ 
			
CREATED BY:	Tim Waidmann
MODIFIED: 07/10/2024

INPUTS:		deathtabYYYY_3yr_czone.dta
			
*******************************************************************************/

global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global	dorn	"$data\dorn" /*data downloaded from https://www.ddorn.net/data.htm*/
global  dosource "$$do\5_attach_d_p_cznost_res.do"
********************************************************************************
* log using $logs\attach_d_p_czone.log, replace

use "$out\deathtab1990_3yr_cznost_res", clear

gen int year = 1990

foreach yr in 2017  {
	append using "$out\deathtab`yr'_3yr_cznost_res"
	replace year = `yr' if year ==  .
}

foreach dvar of varlist death* {
	replace `dvar' = `dvar' / 3
}
	drop if cza == ""
	drop _merge
	
merge 1:1 year cza sex race age_lt using $data\pop\poped_wide_cznost
	drop if age_lt == 85
	
foreach dvar of varlist death* {
	replace `dvar' = 0 if _merge == 2
}

foreach pvar of varlist po* ob* {
	replace `pvar' = 0 if _merge == 1
}

gen byte nopopdata = (_merge == 1)
gen byte nodeathdata = (_merge == 2)
drop _merge 
notes : Created on ${S_DATE} by $dosource 
save "$out\death_3yravg_and_pop_cznost_res", replace

