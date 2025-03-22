cls
clear all
putexcel clear
capture log close
/*******************************************************************************
Cause codes
0 All Causes 
22 Infectious and Parasitic Diseases
23 Cancers
24 Cardio and Metabolic Diseases
25 Substance Use and Mental Health
	16a All opioid drug deaths
	17 Suicide
26 Other Body System Diseases
27 Other Causes of Death
*******************************************************************************/
* SELECT 1
// global measure "asdr"
global measure "yll"

global sample_restriction "ed1990"

global distance 100 

if "$sample_restriction"=="wbcz"{
	global racelist "NHW"
}
else{
	global racelist "NHW NHB"
}

if "$measure" == "asdr"{
	local mdir "ndx"
	global age "4564"
	gl causelist "0 22 23 24 25 16a 17 26 27"
}
else{
	local mdir "yll"
	global age "2584"
	gl causelist "0"
}

do "$code\ols_spatial_HAC.ado"
do "$code\reg2hdfespatial.ado"

log using "$logfile", replace

********************************************************************************

capture program drop allmods
program define allmods
local age_group `1'
local race_group `2'
cap drop touse_here exclude_here
gen byte touse_here=touse_base
gen byte exclude_here=touse_base-touse_$sample_restriction

foreach rhsv of varlist pc_inc_???_1980 Mt_* bartik_totemp_r_???{
	cap gen ex_`rhsv'=exclude_here*`rhsv'
}

if "`race_group'" == "NHW" {
	local rnum = 1
	global spec_1 "pc_inc_NHW_1980 Mt_1940 Mt_1950 Mt_1960 "
	global spec_2 "pc_inc_NHW_1980 Mt_total "
	global spec_3 "pc_inc_NHW_1980 "
	global spec_4 ""
	global spec_1x " ex_pc_inc_NHW_1980 ex_Mt_1940 ex_Mt_1950 ex_Mt_1960 exclude_here"
	global spec_2x " ex_pc_inc_NHW_1980 ex_Mt_total exclude_here"
	global spec_3x " ex_pc_inc_NHW_1980 exclude_here"
	global spec_4x "exclude_here"
}
else {
	local rnum = 2
	global spec_1 "pc_inc_NHB_1980 Mt_1940 Mt_1950 Mt_1960 "
	global spec_2 "pc_inc_NHB_1980 Mt_total "
	global spec_3 "pc_inc_NHB_1980 "
	global spec_4 ""
	global spec_1x "ex_pc_inc_NHB_1980 ex_Mt_1940 ex_Mt_1950 ex_Mt_1960 exclude_here "
	global spec_2x "ex_pc_inc_NHB_1980 ex_Mt_total exclude_here "
	global spec_3x "ex_pc_inc_NHB_1980 exclude_here "
	global spec_4x "exclude_here"
}

putexcel set "${output}\spatial_res_${measure}_${vintage}_${distance}_`race_group'_SD", modify sheet("`race_group'_`age_group' ${sample_restriction}SD" replace)

***********************************************************************************
* CHANGES IN ${measure} RATES, by cause, education, sex, and race
***********************************************************************************
forval i = 0/1 {
	di "Started ${measure} male = `i' / race = `race_group' / age = `age_group'"
	foreach cod in $causelist {
		cap gen d_${measure}_`cod'_dncol = d_${measure}_`cod'_ltcol-d_${measure}_`cod'_coll
		cap gen d_${measure}_`cod'_dlo25 = d_${measure}_`cod'_lo25-d_${measure}_`cod'_hi75
		
		
			summarize d_${measure}_`cod' [aw = Px_all_1990] if ///
			male == `i' & age_cat == `age_group' & race == `rnum' & touse_here == 1
			matrix a = ( r(mean) \ r(sd) )
			
			matrix a_`cod' = a
		
		matrix colnames a_`cod' = ed_all
		matrix rownames a_`cod' = D_`cod' se_`cod'
		
		di "Ran `cod' sample size " r(N)
		if "`cod'" == "0" {
			matrix a_allc = a_`cod'
		}
		else {
			matrix a_allc = a_allc \ a_`cod'
		}
	}
	
	if `i' == 1 {
		matrix a${measure}_male_`race_group' = a_allc
	}
	else if `i' == 0 {
		matrix a${measure}_female_`race_group' = a_allc
	}
	*in cases where sample is not all cases, test for differences between excluded and included cases
	if "$sample_restriction" !="base"{
	foreach cod in $causelist {
			summarize d_${measure}_`cod' exclude_here [aw = Px_all_1990] if ///
			male == `i' & age_cat == `age_group' & race == `rnum' & touse_base == 1
			matrix a = ( r(mean) \ r(sd) )
			
			matrix a_`cod' = a
		
		matrix colnames a_`cod' = ed_all
		matrix rownames a_`cod' = D_`cod' se_`cod'
		
		di "Ran `cod' sample size " r(N)
		if "`cod'" == "0" {
			matrix a_allc = a_`cod'
		}
		else {
			matrix a_allc = a_allc \ a_`cod'
		}
	}
	
	if `i' == 1 {
		matrix xa${measure}_male_`race_group' = a_allc
	}
	else if `i' == 0 {
		matrix xa${measure}_female_`race_group' = a_allc
	}
		
	}
	di "Finished ${measure} male = `i' / race = `race_group' / age = `age_group'"
}


*output to excel file	

 {
putexcel A3  =  "Cause of Death" ///
		 A5  =  "All Causes" 
putexcel A7  =  "Infectious and Parasitic Diseases" ///
		 A9 = 	"Cancers" ///
		 A11 =  "Cardio and metabolic diseases" ///
		 A13 =	"Substance use and mental health" ///
		 A15 =	"	Opioid drug deaths" /// 
		 A17 =	"	Suicide"  ///
		 A19 =	"Other body systems" ///
		 A21 =  "Other Causes of Death" ///
		 A23 =  "Observations"

putexcel A24  =  "Interactions with excluded group" ///
		 A25  =  "All Causes"
putexcel A27  =  "Infectious and Parasitic Diseases" ///
		 A29 = 	"Cancers" ///
		 A31 =  "Cardio and metabolic diseases" ///
		 A33 =	"Substance use and mental health" ///
		 A35 =	"	Opioid drug deaths" /// 
		 A37 =	"	Suicide"  ///
		 A39 =	"Other body systems" ///
		 A41 =  "Other Causes of Death"
		 
putexcel A53  =  "Cause of Death" ///
		 A55  =  "All Causes"
putexcel A57  =  "Infectious and Parasitic Diseases" ///
		 A59 = 	"Cancers" ///
		 A61 =  "Cardio and metabolic diseases" ///
		 A63 =	"Substance use and mental health" ///
		 A65 =	"	Opioid drug deaths" /// 
		 A67 =	"	Suicide"  ///
		 A69 =	"Other body systems" ///
		 A71 =  "Other Causes of Death" ///
		 A73 =  "Observations"
		 
putexcel A74  =  "Interactions with excluded group" ///
		 A75  =  "All Causes"
putexcel A77  =  "Infectious and Parasitic Diseases" ///
		 A79 = 	"Cancers" ///
		 A81 =  "Cardio and metabolic diseases" ///
		 A83 =	"Substance use and mental health" ///
		 A85 =	"	Opioid drug deaths" /// 
		 A87 =	"	Suicide"  ///
		 A89 =	"Other body systems" ///
		 A91 =  "Other Causes of Death"


putexcel A95 = "Created on ${S_DATE} by $dosource"
		 
putexcel B1     =	"${measure} change, 1990-2018" ///
		 B2   	=	"MALE"
		 
putexcel B52    	=	"FEMALE"
		 
 
putexcel CB53     = "ED_ALL" 
		 
putexcel B4 	   =     matrix(a${measure}_male_`race_group'), colnames nformat(number_d2) right

if "$sample_restriction" != "base"{
putexcel B24 	   =     matrix(xa${measure}_male_`race_group'), colnames nformat(number_d2) right
}
putexcel B54       =     matrix(a${measure}_female_`race_group'), colnames nformat(number_d2) right

if "$sample_restriction" != "base"{
putexcel B74       =     matrix(xa${measure}_female_`race_group'), colnames nformat(number_d2) right
}
		 }
putexcel save
putexcel clear
end


use "$data\hist_race_income_bartik_mortchg_nostcz_alled_res" , replace
capture drop _merge
drop if czone==.
tostring czone, gen(cza)
	
	gen byte male = (sex == 1)
	rename Px_tot_1990 Px_all_1990
	gen Px_dncol_1990=Px_all_1990
	gen Px_dlo25_1990=Px_all_1990
	rename bartik_totemp_r_nhw bartik_totemp_r_NHW
	rename bartik_totemp_r_nhb bartik_totemp_r_NHB
	rename bartik_tothrs_r_nhw bartik_tothrs_r_NHW
	rename bartik_tothrs_r_nhb bartik_tothrs_r_NHB
	rename agecat age_cat
	
preserve 
use "$data\predicted_migrants.dta", clear 
drop if czone==.
collapse (sum) Mt_*, by(czone)
tempfile migrant
save `migrant'
restore 

merge m:1 czone using "`migrant'"
	keep if _merge==3
	drop _merge

* Divide by Black population TW: convert to 10pp effects and reverse sign (03-26-24)
foreach mig in Mt_1940 Mt_1950 Mt_1960 {
	replace `mig' = -10*`mig' / pop_black_1990
}
egen Mt_total = rowtotal(Mt_1940 Mt_1950 Mt_1960)

***********SAMPLE RESTRICTIONS ***********************************************
*keep only age 45-64 and 25-84 black and white non-hispanic observations
keep if inlist(age_cat,4564, 2584) & inlist(race,1,2)

* drop if total deaths>pop
*TW: change restrictions to ba and rank rather than hs and rank (03-26-24)
foreach yr in 1990 2017 {
	drop if asdr_0_`yr' > 100000
}
*flag cases with no missing data 

gl inclvars "d_asdr_0 d_yll_0 bartik_totemp_all Mt_1940 Mt_1950 Mt_1960 Mt_total"

mark touse_base [aw=Px_all_1990] 
markout touse_base $inclvars

*race specific criteria
replace touse_base=0 if race==1 & (pc_inc_NHW_1980==. | bartik_totemp_r_NHW ==.)
replace touse_base=0 if race==2 & (pc_inc_NHB_1980==. | bartik_totemp_r_NHB ==.)

/* these restrict observations to places where both male and female observations available by race, then where all 4 race/sex groups available */
tempvar num_s num_a
egen `num_s'=total(touse_base), by( czone age_cat race)
replace touse_base=0 if `num_s'!=2
egen `num_a'=total(touse_base), by( czone sex race)
replace touse_base=0 if `num_a'!=2

*to make coefficients readable, convert income to $000
replace pc_inc_NHB_1980=pc_inc_NHB_1980/1000
replace pc_inc_NHW_1980=pc_inc_NHW_1980/1000

*to make bartik coefficients interpretable as effect of 10pp multiply by 10 TW 03-26-24
foreach var of varlist bartik_totemp*{
	replace `var'=`var'*10
	}

tempfile core
save `core'


use "$data\cz1990.dta", clear
	rename cz czone 
	merge 1:m czone using `core', gen(merge_spatial)
	gen byte panel = 1
	gen int year = 1990
	gen byte const = 1
	keep if merge_spatial==3

*keep only observations that are ever used
keep if touse_base==1	

tempfile final
save `final', replace
keep czone race sex 
duplicates drop czone race sex , force
save "$data\alled\fullsample", replace

use `final', replace
merge m:1 czone sex race using "$data\alled\fullsample"
gen byte touse_ed1990=(_merge==3)
drop _merge


foreach race_group in $racelist {
	foreach age_group in   $age  {
		di "race group `race_group' ; age group `age_group'"
		allmods `age_group' `race_group'
	}
}

log close 
