clear all
cls
capture log close
/*******************************************************************************
PROJECT:	Calculating rates of migration from CZs in 1935 to CZs in 1940

CREATED BY:	vincent pancini, adapted from erik tiersten-nyman
UPDATED ON: 2023-01-04



INPUTS:		

OUTPUTS:     
*******************************************************************************/
* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
    if ("${weathering_root}"=="") do `"`c(sysdir_personal)'profile.do"'
    do "${weathering_root}\code\set_environment.do"
}

log using "$logs\Calculate migrant flow shares_`: di  %tdCY-N-D  daily("$S_DATE", "DMY")'.log", replace

* Set convenient globals
global censdata "[census ipums data extracts]"


********************************************************************************
* Load 1940 black population data from ACS. Clean and drop unnecessary variables   
********************************************************************************
use "$censdata\cens1940_full_count.dta", clear
	drop year sample race raced migrate5 migrate5d
	label drop stateicp_lbl statefip_lbl countyicp_lbl sea_lbl migplac5_lbl
	format stateicp %02.0f
	format statefip %02.0f
	format migplac5 %03.0f
	
	rename stateicp  stateicp1940
	rename statefip  statefip1940
	rename countyicp countyicp1940
	rename sea       sea1940
	rename migplac5  statefip1935
	rename migsea5   sea1935
	rename migcounty countyicp1935
	
	replace statefip1935 = statefip1940 if statefip1935 == 990 // 990 means same house
	replace countyicp1935 = countyicp1940 if countyicp1935 == 9999 // 9999 means Not in Universe. The universe is persons age 5+ in 1940 who lived in a different county 5 years ago.
	drop if inlist(sea1935, 996, 997) // Exclude if in US but location unknown or abroad
	
	* tempfile acs1940_clean
	* save `acs1940_clean'
	save "$censdata\acs1940_clean.dta", replace

********************************************************************************
* Convert 1935 countyicp codes to 1935 countyfips codes using crosswalk   
********************************************************************************
import excel "$geoxwalk\xw_countyicp_countyfips_1940.xlsx", firstrow clear
	rename countyicp countyicp1935
	rename countyfip countyfip1935
	rename stateicp  stateicp1935
	rename statefip  statefip1935
	merge 1:m countyicp1935 statefip1935 using ///
		"$censdata\cens1940_clean.dta"

* We want to retain all possible state/CZ combinations, so instead of dropping 
* counties from the crosswalk that are not in ACS data, we assign them a population
* value of 0
gen pop = .
	replace pop = 1 if inlist(_merge, 2, 3)
	replace pop = 0 if _merge == 1
	
* Checking observations that didn't match
tab countyicp1935 statefip1935 if _merge == 2

** Dade County, FL was renamed to Miami-Dade County
replace countyfip1935 = 12086 if countyicp1935 == 250  & statefip1935 == 12
replace stateicp1935  = 43    if countyicp1935 == 250  & statefip1935 == 12
** Elizabeth City, VA was merged into Hampton City
replace countyfip1935 = 51650 if countyicp1935 == 550  & statefip1935 == 51
replace stateicp1935  = 40    if countyicp1935 == 550  & statefip1935 == 51
** Nansemond County, VA is now part of the indepdent city of Suffolk
replace countyfip1935 = 51800 if countyicp1935 == 1230 & statefip1935 == 51
replace stateicp1935  = 40    if countyicp1935 == 1230 & statefip1935 == 51
** Norfolk County, VA was divided into the cities of Norfolk, Portsmouth, South Norfolk, and Chesapeake. These territories have the same CZ (02000), so I just assign it the Norfolk City fips
replace countyfip1935 = 51710 if countyicp1935 == 1290 & statefip1935 == 51
replace stateicp1935  = 40    if countyicp1935 == 1290 & statefip1935 == 51
** Princess Anne County, VA was merged into the city of Virginia Beach
replace countyfip1935 = 51810 if countyicp1935 == 1510 & statefip1935 == 51
replace stateicp1935  = 40    if countyicp1935 == 1510 & statefip1935 == 51
** Warwick County, VA became the City of Newport News
replace countyfip1935 = 51700 if countyicp1935 == 1875 & statefip1935 == 51
replace stateicp1935  = 40    if countyicp1935 == 1875 & statefip1935 == 51
** Martinsville County, VA has a fips of 51690, but is combined with Henry County (51089) for statistical purposes
replace countyfip1935 = 51089 if countyicp1935 == 6900 & statefip1935 == 51
replace stateicp1935  = 40    if countyicp1935 == 6900 & statefip1935 == 51
** South Norfolk County, VA is now a section of the city of Chesapeake
replace countyfip1935 = 51550 if countyicp1935 == 7850 & statefip1935 == 51
replace stateicp1935  = 40    if countyicp1935 == 7850 & statefip1935 == 51

tab countyfip1935 if _merge == 2, m
drop _merge

* tempfile acs1940_with_countyfips
* save `cens1940_with_countyfips'
save "$censdata\cens1940_with_countyfips.dta", replace


********************************************************************************
* Convert countyfips codes to CZs using crosswalk for both 1935 and 1940
********************************************************************************
import excel "$geoxwalk\xwcountycz_608090.xls", sheet ("Sheet1") firstrow clear
duplicates drop countyfip, force // Norfolk/South Norfolk, VA & Suffolk/Nansemond, VA & Park/Yellowstone NP, WY
destring countyfip, replace
	rename countyfip countyfip1935
	rename czone czone1935
	drop cntyname90 cntyname80
	
tempfile xwcountycz_1935 
save `xwcountycz_1935'

import excel "$geoxwalk\xwcountycz_608090.xls", sheet ("Sheet1") firstrow clear
duplicates drop countyfip, force // Norfolk/South Norfolk, VA & Suffolk/Nansemond, VA & Park/Yellowstone NP, WY
destring countyfip, replace
	rename countyfip countyfip1940
	rename czone czone1940
	drop cntyname90 cntyname80
	
tempfile xwcountycz_1940 
save `xwcountycz_1940'


use "$censdata\cens1940_with_countyfips.dta", clear

	merge m:1 countyfip1935 using `xwcountycz_1935', gen(merge_1935)
		replace czone1935 = "07000" if countyfip1935 == 12086 // Dade County, FL
		tostring countyfip1935, replace
			replace statefip1935 = real(substr(countyfip1935, 1, 1)) ///
				if (length(countyfip1935) == 4 & merge_1935 == 2)
			replace statefip1935 = real(substr(countyfip1935, 1, 2)) ///
				if (length(countyfip1935) == 5 & merge_1935 == 2)
		destring countyfip1935, replace
		* drop if countyfip1935==. & czone1935 == "02000" // Princess Anne County, VA. Absorbed by another county in 1963, so fips for this county was changed earlier. 
			* drop merge_1935

	merge m:1 countyfip1940 using `xwcountycz_1940', gen(merge_1940)
		replace czone1940 = "07000" if countyfip1940 == 12086 // Dade County, FL
		tostring countyfip1940, replace
			replace statefip1940 = real(substr(countyfip1940, 1, 1)) ///
				if (length(countyfip1940) == 4 & merge_1940 == 2)
			replace statefip1940 = real(substr(countyfip1940, 1, 2)) ///
				if (length(countyfip1940) == 5 & merge_1940 == 2)
		destring countyfip1940, replace

* These are counties that had a match to a CZ in the crosswalk, but were not in
* the ACS data. We keep them and assign a population value of 0 instead of dropping
replace pop = 0 if merge_1935 == 2
replace pop = 0 if merge_1940 == 2

* drop merge_1935 merge_1940


********************************************************************************
* Count total population by source cz and dest cz for percap 
********************************************************************************
tab czone1935 if czone1935 == czone1940 & statefip1935 == statefip1940

* Drop non-movers between czones 
drop if czone1935 == czone1940 & statefip1935 == statefip1940

preserve
collapse (sum) pop, by(czone1935 statefip1935)
save "G:\data\derived_\migration\temp\blackpop_cz_1935.dta", replace
restore

preserve
collapse (sum) pop, by(czone1940 statefip1940)
save "G:\data\derived_\migration\temp\blackpop_cz_1940.dta", replace
restore

collapse (sum) pop, by(statefip1935 czone1935 statefip1940 czone1940)
merge m:1 czone1935 statefip1935 using "G:\data\derived_\migration\temp\blackpop_cz_1935.dta"
	drop _merge // all matched
merge m:1 czone1940 statefip1940 using "G:\data\derived_\migration\temp\blackpop_cz_1940.dta"
	drop _merge // all matched

* Generating per capita values for each source czone and each destination czone
egen tot_out = total(pop), by(czone1935 statefip1935)
	sum tot_out
egen tot_in  = total(pop), by(czone1940 statefip1940)
	sum tot_in
	
gen out_percap = tot_out / pop // should be 1935 population without nonmovers
	sum out_percap
gen in_percap = tot_in / pop
	sum in_percap

* Divide count by total (i.e., total out to all czs)
gen prop_mig = pop / tot_out
	sum prop_mig
gsort -prop_mig
order prop_mig, first

egen total_source = total(prop_mig), by(czone1935 statefip1935)
order prop_mig total_source

save "migdata\prop_migrants_czone.dta", replace

