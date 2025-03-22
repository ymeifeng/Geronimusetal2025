clear all
cls
capture log close
/*******************************************************************************
PROJECT:	Pools death counts in three year groups (in a moving-average way) 
			and collapses to the cause, age, sex, race, commuting zone level
			
CREATED BY:	Vincent Pancini
UPDATED ON: 2023-06-15	


*******************************************************************************/
 global logs       "[log file directory]"
 global do	   "[do file directory]"
 global data	   "[central data directory]"
 global out	   "[analtyic file directory]"
 global geoxwalks  "[geographic crosswalk directory]"

********************************************************************************
* log using $logs\collapse_by_cz_.log, replace
use $geoxwalks\czlma903_fix
rename CountyFIPSCode countyfips
rename CZ90 cza
gen str2 statefips=substr(countyfips,1,2)
tempfile ctycza
save `ctycza', replace
foreach yr2 in 1990 2017 {
	*if you want to run one or the other, just comment out the one you don't want

		local yr1 = `yr2' - 1
		local yr3 = `yr2' + 1
		use "$out\deathtab`yr1'_alled_res", clear
			append using "$out\deathtab`yr2'_alled_res"
			append using "$out\deathtab`yr3'_alled_res"
gen byte noedst=inlist(statefips,"13", "22", "36", "40", "44", "46", "53")
		merge m:1 statefips countyfips using `ctycza'
			list statefips countyfips cza _merge if _merge!=3
			drop if statefips=="33"
			collapse (sum) deaths*, by(sex race age_lt  cza czone noedst _merge)
		save $out/deathtab`yr2'_3yr_czone_alled_nostcz_res, replace
}


