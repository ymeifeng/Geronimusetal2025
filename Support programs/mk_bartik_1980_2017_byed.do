clear
capture log close
cls
/*******************************************************************************
PROJECT:	creates bartik instruments
			
CREATED BY: Tim Waidmann
CREATED ON: 3/16/22
*******************************************************************************/
global 	data	"[data directory]"
global  dornxw  "[dorn data directory]"
global	do	"[do file directory]"
global  log     "[log file directory]"
********************************************************************************
* log using "$log/mk_bartik_1980_2017.log", replace
********************************************************************************
/* We want our index year to be the middle year rather than the end year. The key
years for the analyses are 1980, 1990, 2000, 2007, 2017, so the files we have 
are 1980 (5%), 1990 (5%), 2000 (5%), 2008 ACS (3%), 2019 ACS (5%)*/



use "$dornxw/cw_ctygrp1980_czone_corr.dta", clear
	gen byte statefip=floor(ctygrp1980/1000)
	gen int cntygp98=ctygrp1980-1000*statefip
	joinby statefip cntygp98 using "$data/1980_indagg_byed.dta"
foreach pv of varlist tot*{
	replace `pv'=`pv'*afactor
}
collapse (sum) tot*, by(czone ind_2dig)
		
merge m:1 ind_2dig using "$data\1980_2017_ind2dig.dta"
drop if ind_2dig>93 //drops military employment		
foreach pv of varlist totemp* tothrs*{
	egen cz_`pv'=total(`pv'), by(czone)
	gen shr_`pv'=`pv'/cz_`pv'
}
	
foreach pv of varlist totemp* {
	gen bartik_`pv'=shr_`pv'*lnchsh_emp
}

foreach pv of varlist tothrs* {
	gen bartik_`pv'=shr_`pv'*lnchsh_hrs
}

collapse (sum) bartik*, by(czone)

summarize
corr bartik*
save "$data/bartik_1980_2017_cz_byed.dta", replace



