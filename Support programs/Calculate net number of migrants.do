clear all
cls
capture log close
/*******************************************************************************
PROJECT:	

CREATED BY:	vincent pancini
UPDATED ON: 2022-09-20
			2022-10-17


INPUTS:		mx194070.xlsx, black_pop_40_70.dta

OUTPUTS:    lifetable_4069.dta, birthrates_by_race.xlsx, 
*******************************************************************************/
* Set $root
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
    if ("${weathering_root}"=="") do `"`c(sysdir_personal)'profile.do"'
    do "${weathering_root}\code\set_environment.do"
}

log using "${log}\_03b_create_black_mig_rates`: di  %tdCY-N-D  daily("$S_DATE", "DMY")'.log", replace

********************************************************************************
* Load death rates from selected causes by 10-year age groups for both sexes/all
* non-white races for 1940-1969 (from https://www.cdc.gov/nchs/nvss/mortality/hist290.htm#anchor_1551748566004)
import excel using "$migdata\mx194070", firstrow clear
	foreach var of varlist age_* {
		rename `var' Dx_`var'
	}
	reshape long Dx_, i(year race total) j(agecat) string
		replace agecat = "1"  if agecat == "age_lt1"
		replace agecat = "2"  if agecat == "age_1_4"
		replace agecat = "3"  if agecat == "age_5_14"
		replace agecat = "4"  if agecat == "age_15_24"
		replace agecat = "5"  if agecat == "age_25_34"
		replace agecat = "6"  if agecat == "age_35_44"
		replace agecat = "7"  if agecat == "age_45_54"
		replace agecat = "8"  if agecat == "age_55_64"
		replace agecat = "9"  if agecat == "age_65_74"
		replace agecat = "10" if agecat == "age_75_84"
		replace agecat = "11" if agecat == "age_gte85"
		gen year2 = substr(year, 1, 3)
			destring agecat, replace
			rename Dx_ Dx
			sort year agecat
			collapse (mean) Dx, by(year2 agecat)
				// desired length of string
				local len 4
				// desired trailing character
				local pad 0
				gen str`len' year = year2+"`pad'"*`len'
					drop year2
				

* Already have Dx which is the national death rate per 100,000 population, by agecat
* calculate n_m_x = n_D_x / n_P_x (central death rate for age range x to x+n)
gen mx = Dx / 100000


* 2. Calculate all the life table death rates n_q_x = (n * n_m_x) / (1 + n(1-n_a_x) * n_m_x)
* where n_a_x = 0.2 if x = 0, 0.5 otherwise
gen qx_ = (10 * mx) / (1 + 10*(1 - 0.5) * mx) if agecat >= 3
	replace qx_ = (1 * mx) / (1 + 1*(1 - 0.2) * mx) if agecat == 1
	replace qx_ = (4 * mx) / (1 + 4*(1 - 0.5) * mx) if agecat == 2

	
* 3. Calculate the full set of l_x values (x = 0, 1, 5, 15, 25,..., 85) where
* l_x+n = l_x * (1 - n_q_x)
gen lx_ = 1 if agecat == 1
forvalues agec = 2/11 {
	quietly bys year (agecat): replace lx_ = lx_[_n-1] * (1 - qx_[_n-1]) if agecat == `agec'
}


* 4. Calculate the full set of n_L_x = n(l_x+n) + n * n_(a_x l_x) * n_q_x.  Which simplifies to
** a. 1_L_0 = 0.2 + 0.8 * l_1
quietly bys year (agecat): gen Lx = 0.2 + 0.8 * lx[_n + 1] if agecat == 1

** b. 4_L_1 = 2 * (l_5 + l_1)
	quietly bys year (agecat): replace Lx = 2 * (lx + lx[_n + 1]) if agecat == 2

** c. 10_L_x = 5 * (l_(x + 10) + lx)
	quietly bys year (agecat): replace Lx = 5 * (lx + lx[_n + 1]) if inrange(agecat, 3, 10)
	
** d. Special case: inf_L_85 = l_85 * (a / inf_M_85) where a for black men is 0.853
** and for black women is 0.807. If you're pooling men and women, average the two numbers
	quietly bys year (agecat): replace Lx = lx * (0.83 / mx) if agecat == 11
	*** what is M_x as written in the Box Note?

** e. Interpolate to find l_10 and thus 5_L_10. If we assume the deaths between 
** ages 5 and 10 are evenly distributed, then l_10 = 0.5 * (l_5 + l_15)
bys year: gen L10 = 5/4 * (lx[3] + 3*(lx[4]))


* 5. Calculate "adult" survival ratio to time t+10 of those alive at time t
egen T0 = total(Lx), by(year)
egen T15 = total(Lx * (agecat >= 4)), by(year)
gen T10 = T15 + L10

gen Sa = T10 / T0

tempfile lifetable
save `lifetable'

* 6. Calculate ratio of surviving kids age 0-10, i.e., those who were born since previous 
* census.
import excel "\\Client\C$\Users\Vinnie\Box\NIH Weathering Project\Migration Data\derenoncourt_replication\birthrates_by_race.xlsx", sheet("Sheet1") firstrow clear
	keep year black
	drop if year == 1970
	
tostring year, replace
	gen year_cat = real(substr(year, 4, 1))
		replace year_cat = 4 if inrange(year_cat, 0, 4)
		replace year_cat = 8 if inrange(year_cat, 5, 8)
	replace year = substr(year, 1, 3) + "0"
	
collapse (sum) black, by(year year_cat)

rename black Bt_
reshape wide Bt_, i(year) j(year_cat)
	rename Bt_4 Bt_0_4
	rename Bt_8 Bt_5_8
	
foreach var in Bt_0_4 Bt_5_8 Bt_9 {
	replace `var' = `var' / 1000
}
	
merge 1:m year using `lifetable'

bys year (agecat): gen Sk = ((Bt_0_4 * (0.5 * Lx[3])) / 5) + ((Bt_5_8 * (Lx[2]) / 4) + (Bt_9 * (Lx[1])))

* merge on to county-level population
collapse (mean) Sa Sk, by(year) 
gen i = "_"

reshape wide Sa Sk, i(i) j(year, string)
drop i

scalar Sa1940 = Sa1940
scalar Sk1940 = Sk1940
scalar Sa1950 = Sa1950
scalar Sk1950 = Sk1950
scalar Sa1960 = Sa1960
scalar Sk1960 = Sk1960

use "$migdata\black_pop_40_70.dta", clear

gen Sa1940 = Sa1940
gen Sk1940 = Sk1940
gen Sa1950 = Sa1950
gen Sk1950 = Sk1950
gen Sa1960 = Sa1960
gen Sk1960 = Sk1960

foreach var of varlist black_pop* {
	replace `var' = 0 if `var' ==.
} 

* 8. Calculate net number of (out) migrants
foreach decade in 1940 1950 1960 1970 {
	rename black_pop_`decade' Nt_`decade'
}

gen Mt_1940 = (Nt_1950 - (Nt_1940 * Sa1940) - (Nt_1940 * Sk1940)) * -1
gen Mt_1950 = (Nt_1960 - (Nt_1950 * Sa1950) - (Nt_1950 * Sk1950)) * -1
gen Mt_1960 = (Nt_1970 - (Nt_1960 * Sa1960) - (Nt_1960 * Sk1960)) * -1

drop _merge

save "$migdata\lifetable_4069.dta", replace


import excel "$geoxwalk\xwcountycz_608090.xls", sheet ("Sheet1") firstrow clear
duplicates drop countyfip, force // Norfolk/South Norfolk, VA & Suffolk/Nansemond, VA & Park/Yellowstone NP, WY
destring countyfip, gen(fips)
	merge 1:m fips using "$migdata\lifetable_4069.dta"
		tab fips _merge if _merge != 3, m
	replace czone = "07000" if fips == 12086 // Miami-Dade County
	replace statefip = 15 if czone == "34703" & countyfip == "15005" // Maui County
	replace czone = "27603" if fips == 46131 // Washabaugh County
** What to do about Alaska observations?

collapse (sum) Mt_1940 Mt_1950 Mt_1960, by(statefip czone)

save "$migdata\net_migrants.dta", replace

