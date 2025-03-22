clear all
cls
capture log close
/*******************************************************************************
PROJECT:	Tabulations of Deaths by 5-year age groups, education, sex, race, 
			and by cause, *by county of residence of decedent*
			
CREATED BY:	vincent pancini
CREATED ON:
UPDATED BY: tim
UPDATED ON: 2022-03-24	; 2024-01-26

INPUTS:		mortYYYY.dta

OUTSTANDING: 

********************************************************************************
**************************************NOTES*************************************

*******************************************************************************/
global	logs	"[your log file directory]"
global	do	"[your do file directory]"
global 	mort	"$data\mortality"
global  out	"[analysis file directory]"
********************************************************************************
* log using $logs/deaths_bycause_county.log, replace

* define program used to create death counts by cause
do $do\2b_deathcause_220222.do

foreach yr in 1989 1990 1991 2016 2017 2018 {
	di "`yr'"
	tempfile base`yr'
	
	* load data
	use $mort\mort`yr'.dta, clear
	
	if `yr' <= 2002 {
		drop if inlist(fipssto, 13, 22, 36, 40, 44, 46, 53)
	}
	else if `yr' > 2002 {
		drop if inlist(fipssto, "13", "22", "36", "40", "44", "46", "53")
	}	
	
	drop fipssto fipsctyo
	* drop Non-US residents
	drop if restatus == 4		
	
	* if statement to recode state (two-digit statefips) and sex (1 = M, 2 = F)
	* different sections of the statement for earliest-2001,2002, and 2003-latest
	if `yr' < 2002 {
		tostring fipsstr, gen(statefips) format("%02.0f") force
	}
	else if `yr' == 2002 {
		rename fipsstr statefips
		destring sex, force replace
	}
	else {
		rename fipsstr fipssto
		merge m:1 fipssto using G:\NIH_Weat\data\fipssto.dta, nogen
		rename sex sexo
		
		gen sex = 1
		replace sex = 2 if sexo == "F"
		drop sexo
	}
	
	* turn county fips codes into a three-digit string
	tostring fipsctyr, gen(countyfips) format("%03.0f") force
	
	* replace countyfips by a 5-digit combination of state and county fips 
	* (still a string)
	replace countyfips = statefips + countyfips	
	
	* create a dummy variable "no_ed_state90" where if statefips is in the list,
	* then the dummy equals 1
	
	* recode age variable using an if statement
	* within the if statement, we use logical tests (ie, "(age < 200)") to create
	* flags or dummy vars that are then multiplied by the original age variable
	* in order to measure age in years consistently across all records
    if `yr' < 2003 {
		gen age_yrs = (age < 200) * age if age < 999
	}
	else {
		gen age_yrs = (age4d < 1999) * (age4d - 1000) if age4d < 9999
	}
	
	* create year of birth var
	gen birthyear = `yr' - age_yrs
	
	* use floor function to group by categories (digits of 5)
	* e.g., if you are 39, age_lt below equals 35
	gen age_lt = 5 * floor(age_yrs / 5)
		replace age_lt = 1 if inrange(age_yrs, 1, 4)
		replace age_lt = 85 if age_lt > 85 & !missing(age_lt)
	
	* recode race variable into race/ethnicity factor variable
	gen race = 9
		replace race = 1 if hspanicr == 6
		replace race = 2 if hspanicr == 7
		replace race = 3 if inrange(hspanicr, 1, 5)
		replace race = 4 if hspanicr == 8
		label define _rac 1 "Non-Hispanic White" 2 "Non-Hispanic Black" 3 "Hispanic" 4 "Non-Hispanic Other" 9 "Refused/Unknown"
		label values race _rac
	
	*Create a couple additional flags for NHB and Female
	gen black = (race == 2)
	gen female = (sex == 2)
	
	* keep records if age category falls betweens 25 and 80, race is NHW or NHB,
	* and if it is a state for which we have education data
	keep if inrange(age_lt, 25, 80) & inlist(race, 1, 2) 
	
	*Create death counts by cause
	deathcause, year(`yr')
	save "`base`yr''", replace
	
	*Loop for 1989 to 2017
	if inrange(`yr', 1989, 2017) {
		
		rename educ educ_89
		keep if !missing(educ_89) 
		
		* recode original education var into edcommon89 that goes from 1 - 11
		* 1=0-4; 2=5-8; 3=9; 4=10;...11=17+
		* we are recoding the way in which education is categorized on the
		* mortality files and matching that to the census catgories
		* (you can check on IPUMS)
		recode educ_89 (0/4 = 1) (5/8 = 2) (9 = 3) (10 = 4) ///
						 (11 = 5) (12 = 6) (13 = 7) (14 = 8) ///
						 (15 = 9) (16 = 10) (17 = 11), gen(edcommon89)
		
        * procedure to impute education for records with missing education 
		* in same proportions as non-missing records by age,race, sex, and county
	    egen shr_deaths_nme = mean(edcommon89 < 99), by(sex race age_lt statefips countyfips)	
		replace deaths = deaths / shr_deaths_nme if edcommon89 < 99
		
		* create separate death variables by missing education status
		forval i = 1/27 {
			replace deaths_`i' = deaths_`i' / shr_deaths_nme if edcommon89 < 99
			capture noisily {
				foreach j in `c(alpha)' {
					replace deaths_`i'`j' = deaths_`i'`j' / shr_deaths_nme if edcommon89 < 99
				}
			}
		}
			drop if edcommon89 == 99
		collapse (sum) deaths*, by(sex race edcommon89 birthyear age_lt statefips countyfips)
		compress
		*Check that each death is counted once and only once
/*		egen test_d = rowtotal(deaths_1-deaths_17)
		assert test_d==deaths
		drop test_*
		*/
		save "$out\deathtab`yr'_89ed_res.dta", replace
	}
	
	/*In 2003, the way in which education gets coded on the data changed.
	We have 1989 education coding, and 2003 education coding. Starting in 2003,
	some states started using the new 2003 coding, but many others were still
	using the 1989 coding. As the years go by, more and more states start using
	the 2003 coding until eventually, in 2018, they all report in 2003 coding.
	The next sections turn the education vars into a consistent coding scheme*/
	*Loop for 2003 to 2019
	*Recall that for these years, both versions of the education vars are used
	if inrange(`yr', 2003, 2019) {
		
		*Reload the "base" dataset, which is the one produced on line 114, prior
		*to any education-related changes
		use "`base`yr''", clear
		
		*Rename educr as ed_mort03 because that var contains the 2003 educ codes
		*and keep records that use this scheme (and drop those that use educ 89)
		rename educr ed_mort03
		keep if !missing(ed_mort03)
		
		*Similar to line 182 above, recode 03 education into ed_mortX
		recode ed_mort03 (1 = 1) (2 = 2) (3 = 3) (4/5 = 4) (6 = 5) (7/8 = 6) (9 = 99), gen(edcommon03)
		
	    egen shr_deaths_nme = mean(edcommon03 < 99), by(sex race age_lt statefips countyfips)	
		replace deaths = deaths / shr_deaths_nme if edcommon03 < 99
		
		* create separate death variables by missing education status
		forval i = 1/27 {
			replace deaths_`i' = deaths_`i' / shr_deaths_nme if edcommon03 < 99
			capture noisily {
				foreach j in `c(alpha)' {
					replace deaths_`i'`j' = deaths_`i'`j' / shr_deaths_nme if edcommon03 < 99
				}
			}
		}
			drop if edcommon03 == 99
		collapse (sum) deaths*, by(sex race edcommon03 birthyear age_lt statefips countyfips)
		compress
		*Check that each death is counted once and only once
/*
		egen test_d = rowtotal(deaths_1-deaths_17)
		assert test_d==deaths
		drop test_*
*/
		save "$out\deathtab`yr'_03ed_res.dta", replace

	}			
	

}
