/*******************************************************************************
PROJECT:	Create Survival and YPLL tables by age, race, sex, education, and CZA
			
CREATED BY:	Tim Waidmann
CREATED ON:
UPDATED BY:	Vincent Panicni, Justin Morgan
UPDATED ON: 07/10/2024;2022-03-25

INPUTS:		deathtabYYYY_3yr_rank_czone
*******************************************************************************/
global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global	dorn	"$data\dorn" /*data downloaded from https://www.ddorn.net/data.htm*/
********************************************************************************
gl causelist "0 1 2 3 4 5 5a 5b 5c 5d 6 6a 6b 7 8 9 10 11 11a 11b 12 13 13a 13b 14 15 16 16a 16b 16c 16d 17 18 19 20 21 22 23 24 25 26 27"
gl edlist "ghs lehs coll ltcol hi75 lo25"

gen lowpop = Px_tot < 500
bys  cza sex race: egen flag_pop = max(lowpop)
	mdesc Mx_deaths_0 if cza == "10302" // 816 missings
* drop if lowpop
*	mdesc Mx_tot if cza == "10302" // 8 missings
quietly keep if age_lt >= 25
	mdesc Mx_deaths_0 if cza == "10302" // 816 missings
	
* dropping tables where an age group (not inclusive of 85) is missing
gen agecheck = 0
local check = 1
forvalues age = 25(5)80 {
	bys year  cza race sex (age_lt): replace agecheck = `age' if age_lt[`check'] != `age' & agecheck == 0
	local check = `check' + 1
}
tab agecheck
	mdesc Mx_deaths_0 if cza == "10302" // 816 missings
	
/*If we want to include tables with missing age groups, we could create a 
variable nyears with varying length of years between strata, to replace the 
constant 5 (or nyears / 2 for 2.5) in the below formulas used below
gen nyears = .
bys year cza educ race sex (age_lt): replace nyears = age_lt[_n + 1] - age_lt
*/
bys  cza sex race: egen flag_missing_age = max(agecheck)
drop if agecheck
	
	
* qx - probability that someone who survives to exact age X dies before they reach X + 5 (because we're using 5 year age groups, e.g., the probability that someone age 25 dies before age 30)
* Mx_deaths_0 is ratio of deaths to population for this age group. 
quietly gen qx_deaths_0 = (5 * Mx_deaths_0) / (1 + 2.5 * Mx_deaths_0)
foreach ed of global edlist {
	quietly gen qx_deaths_0_`ed' = (5 * Mx_deaths_0_`ed') / (1 + 2.5 * Mx_deaths_0_`ed')
}
foreach cod of global causelist {
	capture noisily {
		quietly gen qx_deaths_`cod' = qx_deaths_0 * (Mx_deaths_`cod' / Mx_deaths_0)
		foreach ed of global edlist {
			quietly gen qx_deaths_`cod'_`ed' = qx_deaths_0 * (Mx_deaths_`cod'_`ed' / Mx_deaths_0_`ed')
		}
	}
}

/*
* reordering so that i can use rowtotal()
forval i = 1/20 {
	order qx_deaths_`i', last
}

* checking for difference between sum of causes and total
egen qxtest = rowtotal(qx_deaths_1 - qx_deaths_20)
gen qtest = qxtest - qx_deaths_0
* summ qx* // what is purpose of this step?
summ qtest, det // looks good, very small difference between sum of causes and total
*/

* lx - number of people who have survived to age X out of the original l25
quietly gen lx_ = 1 if age_lt == 25
foreach ed of global edlist {
	quietly gen lx_`ed' = 1 if age_lt == 25
}
forvalues age = 30(5)85 {
	quietly bys year  cza race sex (age_lt): replace lx_ = lx_[_n-1] * (1 - qx_deaths_0[_n-1]) if age_lt == `age'
	foreach ed of global edlist {
		quietly bys year  cza race sex (age_lt): replace lx_`ed' = lx_`ed'[_n-1] * (1 - qx_deaths_0_`ed'[_n-1]) if age_lt == `age'
	}
}
summ lx_*, det // looks good, runs 0 to 1


* dx - the difference between lx and lx+5 (fraction of original population who dies between age x and age x+5)
quietly bys year  cza race sex (age_lt): gen dx_deaths_0 = abs(lx_[_n+1] - lx_)
foreach ed of global edlist {
	quietly bys year  cza race sex (age_lt): gen dx_deaths_0_`ed' = abs(lx_`ed'[_n+1] - lx_`ed')
}
foreach cod of global causelist {
	capture noisily {
		quietly gen dx_deaths_`cod' = dx_deaths_0 * (Mx_deaths_`cod' / Mx_deaths_0)
		foreach ed of global edlist {
			quietly gen dx_deaths_`cod'_`ed' = dx_deaths_0 * (Mx_deaths_`cod'_`ed' / Mx_deaths_0_`ed')
		}
	}
}

/*
* reordering so that i can use rowtotal()
forval i = 1/20 {
	order dx_deaths_`i', last
}

* checking for difference between sum of causes and total
egen dxtest = rowtotal(dx_deaths_1 - dx_deaths_20)
gen dtest = dxtest - dx_deaths_0
* summ dx* // what is purpose of this step?
summ dtest, det // 
*/

* Lx - person years lived between x and x+5 (a person who dies at 57.5, L55 only counts 2.5 years for that person. Makes assumption that peple die at even rate between X and X+5, average size of lx between Lx is the integral of lx from x to x+5)
quietly bys year  cza race sex (age_lt): gen Lx_ = 2.5 * (lx_ + lx_[_n + 1])
summ Lx_, det // looks good, runs 0 to 5
	
	
*fx - share of cumulative deaths before age in question due to cause in question. so sum of dx terms from age 25 until the one we're working with
foreach cod of global causelist {
	capture noisily {
		quietly bys year  cza race sex (age_lt): ///
			gen fx_deaths_`cod' = sum(dx_deaths_`cod'[_n-1]) / sum(dx_deaths_0[_n-1])
		foreach ed of global edlist {
			quietly bys year  cza race sex (age_lt): ///
				gen fx_deaths_`cod'_`ed' = sum(dx_deaths_`cod'_`ed'[_n-1]) / sum(dx_deaths_0_`ed'[_n-1])
		}
	}
}
** "dx_deaths_0_ghs" not found, explore this later

* reordering so that i can use rowtotal()
forval i = 1/20 {
	order fx_deaths_`i', last
}
egen fxtest = rowtotal(fx_deaths_1 - fx_deaths_20), missing
gen ftest = fxtest - fx_deaths_0
summ ftest, det
summ fx*
* population denominator is too small for the education specific categories
* summ fxtest, det // Looks iffy - OEX, TDD, and CVD are greater than 1 in so the sum is greated than 1


*Implementing fix removing probelematic fx
gen fxflg = fxtest > 1.01 & !missing(fxtest)
/*
*	replace fx_oex = (1 - fx_opi - fx_odd - fx_cvd - fx_can - fx_oin) if fxtest != 0
bys year  cza sex race educ (age_lt): ereplace fxflg = max(fxflg)
bys  cza sex race educ (age_lt): egen flag_fx = max(fxflg)
*	sum Px if race==1 & educ==2 & cza=="10302" & year==2009 & sex==1 // 13 observations *******************
* drop if fxflg
*	sum Px if race==1 & educ==2 & cza=="10302" & year==2009 & sex==1 // 0 observations *******************
*drop fxflg
summ fx*
summ fxtest, det // Looks good Still 643 CZA's
summ fxtest if fxflg>1.01 // this tells us range of rounding adjustments 
unique  cza
*/
	
*YPLL
gen yll_tot = 5 - Lx_ if fxflg == 0

foreach cod of global causelist {
	capture noisily {
		gen yll_`cod' = 5 * (1 - lx_) * fx_deaths_`cod' + 2.5 * dx_deaths_`cod' if fxflg == 0
		foreach ed of global edlist {
			gen yll_`cod'_`ed'_ = 5 * (1 - lx_`ed') * fx_deaths_`cod'_`ed' + 2.5 * dx_deaths_`cod'_`ed' if fxflg == 0
		}
	}
}
egen yltest = rowtotal(yll_? yll_1? yll_20), missing
	replace yltest = yltest - yll_0
gen ytest = yltest - yll_tot
summ yll*
summ ytest, det
 // Looks great!
order year  cza race sex age* Px* deaths* Mx* qx* lx_* dx* Lx_ fx* yll* 
keep year  cza race sex age* Px* deaths* Mx* qx* lx_* dx* Lx_ fx* yll*
drop *test
sort year  cza race sex age_lt

notes : Created on ${S_DATE} by $dosource 
save $out\detailed_deathrates_cznost_res.dta, replace
