cls
clear all
putexcel clear
capture log close

/*******************************************************************************
PURPOSE: Runs balance tests of 1990 mortality on bartik measures
         separately by sex, race, education (levels and ranks), for several age brackets
			
CREATED BY:	Tim Waidmann
UPDATED ON: 2024-09-25

INPUTS:	hist_race_income_bartik_mortchg_cznost_res.dta

OUTPUTS: balance90_res_DDMMYYYY.xlsx

Cause codes
0 All Causes 

*******************************************************************************/

*SELECT 1
global sample_restriction "base"
*global sample_restriction "wbcz"
*global sample_restriction "plany"
*global sample_restriction "pl10p"
*global sample_restriction "ed1990"

if "$sample_restriction"=="wbcz"{
	global racelist "NHW"
}
else{
	global racelist "NHW NHB"
}

global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global  output	"[tabular output file directory]"
global 	data	"[data directory]"
global	dorn	"$data\dorn" /*data downloaded from https://www.ddorn.net/data.htm*/

global analysisfile 	"$out\hist_race_income_bartik_mortchg_cznost_res.dta"
global output 	    	"$output\spatial\placebo\"
global logfile	    	"$logs\spatial\balance1990_$S_DATE.log"
global dosource		"$do\12_balance1990_spatial6_cznost_res.do"


do "$do\ols_spatial_HAC.ado"
do "$do\reg2hdfespatial.ado"

log using "$logfile", replace

********************************************************************************


capture program drop allmods
program define allmods
local age_group `1'
local race_group `2'
cap drop touse_here exclude_here
gen byte touse_here=touse_${sample_restriction}
gen byte exclude_here=touse_base-touse_here

foreach rhsv of varlist pc_inc_???_1990  bartik_totemp_r_???{
	cap gen ex_`rhsv'=exclude_here*`rhsv'
}
if "`age_group'" == "4564"{
	global measure "asdr"
	global causelist "0"
}
else {
	global measure "yll"
	global causelist "0"
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

putexcel set "${output}\balance90_nostcz", modify sheet("`race_group'_`age_group'" replace)


*******************************************************************************
* ECONOMIC GROWTH EFFECTS (bartik) + 1980 PER CAPITA INCOME (separate by race)
* + MIGRATION VARIABLES
* ON MALE (i = 1) and FEMALE (i = 0)
********************************************************************************
forval i = 0/1 {
	di "Started Bartik male = `i' / race = `race_group' / age = `age_group'"
	forval j = 3/4 {
	foreach cod in $causelist {
			foreach edgrp in all coll ltcol  hi75 lo25  {
				 reg2hdfespatial ${measure}_`cod'_`edgrp'_1990 bartik_totemp_r_`race_group' ${spec_`j'} [aw = Px_all_1990] ///
					if male == `i' & age_cat == `age_group' & race == `rnum' & touse_here == 1, ///
					lat(_CY) lon(_CX) timevar(year) panelvar(panel) distcutoff(100)
					scalar obs = e(N)
					
					matrix b = r(table)
					if _rc == 506 & `j' == 1 {
						matrix b0 = J(2,5,.)
						matrix colnames b0 = bartik pc_inc Mt_1940 Mt_1950 Mt_1960
					}
					else if `j' == 1 {
					    matrix b0 = b[1..2,1..5]
						matrix colnames b0 = bartik pc_inc Mt_1940 Mt_1950 Mt_1960
					}
					else if _rc == 506 & `j' == 2 {
					    matrix b0 = J(2,3,.)
						matrix colnames b0 = bartik pc_inc Mt_total
					}
					else if `j' == 2 {
					    matrix b0 = b[1..2,1..3]
						matrix colnames b0 = bartik pc_inc Mt_total
					}
					else if _rc == 506 & `j' == 3 {
						matrix b0 = J(2,2,.)
						matrix colnames b0 = bartik pc_inc
					}
					else if `j' == 3 {
						matrix b0 = b[1..2,1..2]
						matrix colnames b0 = bartik pc_inc
					}
					else if _rc == 506 & `j' == 4 {
						matrix b0 = J(2,1,.)
						matrix colnames b0 = bartik
					}
					else if `j' == 4 {
						matrix b0 = b[1..2,1]
						matrix colnames b0 = bartik
					}
					matrix rownames b0 = b_`cod' se_`cod'
				
				if 	"`edgrp'" == "all" {
					matrix b_`cod'_emp = b0
				}
				else {
					matrix b_`cod'_emp = b_`cod'_emp, b0
				}
			}
		
		
		
		matrix b_`cod' = b_`cod'_emp
		
		if "`cod'" == "0" {
			matrix b_allc = b_`cod'
			matrix n_allc = obs
		}
		else {
			matrix b_allc = b_allc \ b_`cod'
		}
	}
	
	if `i' == 1 {
		matrix bBARTIK_male_`race_group'_`j' = b_allc
		matrix nBARTIK_male_`race_group'_`j' = n_allc
	}
	else if `i' == 0 {
		matrix bBARTIK_female_`race_group'_`j' = b_allc
		matrix nBARTIK_female_`race_group'_`j' = n_allc
	}	

	}
di "Finished Bartik male = `i' / race = `race_group' / age = `age_group'"
}


*output to excel file	

 {
putexcel A3  =  "Cause of Death" ///
		 A5  =  "All Causes" 

putexcel A13  =  "Cause of Death" ///
		 A15  =  "All Causes"

putexcel A25 = "Created on ${S_DATE} by $dosource"
		 
putexcel         B1     	     =	  "${measure}  1990" ///
		 B11     =	  "${measure}, 1990" ///
		 B2    	=	"MALE" ///
		 B3:C3    	= "ED_ALL" ///
		 D3:E3    	= "ED_coll" ///
		 F3:G3    	= "ED_LTCOL" ///
		 H3:I3   	= "ED_HI75" ///
		 J3:K3  	= "ED_LO25" ///
		 L3    = "ED_ALL" ///
		 M3    = "ED_COLL" ///
		 N3    = "ED_LTCOL" ///
		 O3 	= "ED_HI75" ///
		 P3 	= "ED_LO25"
putexcel 	 B12  	=	"FEMALE" ///
		 B13:C13    	= "ED_ALL" ///
		 D13:E13    	= "ED_coll" ///
		 F13:G13    	= "ED_LTCOL" ///
		 H13:I13   	= "ED_HI75" ///
		 J13:K13  	= "ED_LO25" ///
		 L13    = "ED_ALL" ///
		 M13    = "ED_COLL" ///
		 N13    = "ED_LTCOL" ///
		 O13 	= "ED_HI75" ///
		 P13 	= "ED_LO25" 

putexcel B4 	   =       matrix(bBARTIK_male_`race_group'_3) ///
		 L4       =     matrix(bBARTIK_male_`race_group'_4) , colnames nformat(number_d2) right
putexcel B14       =     matrix(bBARTIK_female_`race_group'_3) ///
         L14       =     matrix(bBARTIK_female_`race_group'_4) , colnames nformat(number_d2) right
}
		 
putexcel save
putexcel clear
end

use "$analysisfile" , replace

capture drop _merge
*keep only age 45-64 and 25-84 black and white non-hispanic observations
keep if inlist(agecat,4564, 2584) & inlist(race,1,2)
merge m:1 czone race sex using $data\spatial\fullsample_cznost
keep if _merge==3
drop _merge
merge m:1 czone using $data\cz1990
keep if _merge==3
drop _merge
gen byte touse_base=1
	gen byte panel = 1
	gen int year = 1990
	gen byte const = 1
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

	
*to make coefficients readable, convert income to $000
replace pc_inc_NHB_1990=pc_inc_NHB_1990/1000
replace pc_inc_NHW_1990=pc_inc_NHW_1990/1000

*to make bartik coefficients interpretable as effect of 10pp multiply by 10 TW 03-26-24
foreach var of varlist bartik_totemp*{
	replace `var'=`var'*10
	}


foreach race_group in $racelist {
	foreach age_group in   4564 2584  {
		di "race group `race_group' ; age group `age_group'"
		allmods `age_group' `race_group'
	}
}




