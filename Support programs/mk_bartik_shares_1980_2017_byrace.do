clear
capture log close
cls
/*******************************************************************************

*******************************************************************************/
**Move comments to run on either Tim's or Vincent's machine ***

global 	data	"[data directory]"
global  dornxw  "[dorn data directory]"
global	do	"[do file directory]"
global  log     "[log file directory]"

********************************************************************************
* log using "$log/mk_bartik_1980_2017.log", replace
*******************************************************************************


use "$dornxw/cw_ctygrp1980_czone_corr.dta", clear
	gen byte statefip=floor(ctygrp1980/1000)
	gen int cntygp98=ctygrp1980-1000*statefip
	joinby statefip cntygp98 using "$data/1980_indagg_byrace.dta"
foreach pv of varlist tot*{
	replace `pv'=`pv'*afactor
}
collapse (sum) tot*, by(czone ind_2dig)
keep czone ind_2dig totemp_r_*		
rename totemp_r_nhw totemp1
rename totemp_r_nhb totemp2
reshape long totemp, i(czone ind_2dig) j(race)
merge m:1 ind_2dig using "$data\1980_2017_ind2dig.dta"
drop if ind_2dig>93 | _merge!=3 //drops military employment	
drop _merge
egen totemp_gr_1980=total(totemp), by(czone race)
gen shr_r_1980=totemp/totemp_gr_1980
gen lnchsh_=ln(sh_emp2017/sh_emp1980)
gen shrXlnchind=shr_r_1980*lnchsh_
egen Bartik_gr=total(shrXlnchind), by(race czone)
rename shr_r_1980 shr_
keep shr_ lnchsh_ ind_2dig czone race Bartik_gr totemp_gr_1980
reshape wide shr_ lnchsh_, j(ind_2dig) i(czone race Bartik_gr totemp_gr_1980)
save g:\data\bartik_shares_cz_byrace, replace