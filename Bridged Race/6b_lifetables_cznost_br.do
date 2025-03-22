/*******************************************************************************
PROJECT:	Create Survival and YPLL tables by age, race, sex, education, and czone
			
CREATED BY:	Tim Waidmann
CREATED ON:
UPDATED BY:	Vincent Panicni, Justin Morgan
UPDATED ON: 07/10/2024;2022-03-25

INPUTS:		deathtabYYYY_3yr_rank_czone
*******************************************************************************/
global	logs	"[log file directory]"
global  out	"[analysis file directory]"
********************************************************************************

gen lowpop = Px_tot < 500
bys  czone sex race: egen flag_pop = max(lowpop)
	mdesc Mx_deaths_0 if czone == 10302 // 816 missings
* drop if lowpop
*	mdesc Mx_tot if czone == 10302 // 8 missings
quietly keep if age_lt >= 25
	mdesc Mx_deaths_0 if czone == 10302 // 816 missings
	
* dropping tables where an age group (not inclusive of 85) is missing
gen agecheck = 0
local check = 1
forvalues age = 25(5)80 {
	bys year  czone race sex (age_lt): replace agecheck = `age' if age_lt[`check'] != `age' & agecheck == 0
	local check = `check' + 1
}
tab agecheck
	mdesc Mx_deaths_0 if czone == 10302 // 816 missings
	
/*If we want to include tables with missing age groups, we could create a 
variable nyears with varying length of years between strata, to replace the 
constant 5 (or nyears / 2 for 2.5) in the below formulas used below
gen nyears = .
bys year czone educ race sex (age_lt): replace nyears = age_lt[_n + 1] - age_lt
*/
bys  czone sex race: egen flag_missing_age = max(agecheck)
drop if agecheck
	
	
* qx - probability that someone who survives to exact age X dies before they reach X + 5 (because we're using 5 year age groups, e.g., the probability that someone age 25 dies before age 30)
* Mx_deaths_0 is ratio of deaths to population for this age group. 
gen qx_deaths_0 = min(1,(5 * Mx_deaths_0) / (1 + 2.5 * Mx_deaths_0))

* lx - number of people who have survived to age X out of the original l25
quietly gen lx_ = 1 if age_lt == 25
forvalues age = 30(5)85 {
	quietly bys year  czone race sex (age_lt): replace lx_ = lx_[_n-1] * (1 - qx_deaths_0[_n-1]) if age_lt == `age'
	}

summ lx_*, det // looks good, runs 0 to 1


* dx - the difference between lx and lx+5 (fraction of original population who dies between age x and age x+5)
quietly bys year  czone race sex (age_lt): gen dx_deaths_0 = abs(lx_[_n+1] - lx_)

* Lx - person years lived between x and x+5 (a person who dies at 57.5, L55 only counts 2.5 years for that person. Makes assumption that peple die at even rate between X and X+5, average size of lx between Lx is the integral of lx from x to x+5)
quietly bys year  czone race sex (age_lt): gen Lx_ = 2.5 * (lx_ + lx_[_n + 1])
summ Lx_, det // looks good, runs 0 to 5
	
	
*YPLL
gen yll_0 = 5 - Lx_ 

 // Looks great!
order year  czone race sex age* Px* deaths* Mx* qx* lx_* dx* Lx_ yll* 
keep year  czone race sex age* Px* deaths* Mx* qx* lx_* dx* Lx_ yll*

sort year  czone race sex age_lt

notes : Created on ${S_DATE} by $dosource 
save $out\detailed_deathrates_cznost_br.dta, replace
