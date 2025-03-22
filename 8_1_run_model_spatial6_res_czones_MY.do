cls
clear all
putexcel clear
capture log close
/*******************************************************************************
PURPOSE: Runs core models of mortality on bartik measures
         separately by sex, race, education (levels and ranks), for several age brackets

Cause codes
0 All Causes 
22 Infectious and Parasitic Diseases
	1 HIV/AIDS
	2 Non-HIV/AIDS Infectious and Parasitic Diseases
23 Cancers
	3 Liver Cancer
	4 Lung Cancer
	5 Other Cancers
		5a Prostate cancer (men) / Breast cancer (women)
		5b Colon cancer
		5c Blood cancers including Leukemia and Lymphoma
		5d All other cancers
24 Cardio and Metabolic Diseases
	6 Endocrine, Nutritional, and Metabolic Diseases
		6a Diabetes mellitus
		6b Other endocrine, nutritional, and metabolic diseases
	7 Hypertensive Disease
	8 Ischemic Heart Disease and Other Diseases of the Circulatory System
25 Substance Use and Mental Health
	9 Mental and Behavioral Disorders
	15 Alcohol-Induced
	16 Drug Poisoning
		16a All opioid drug deaths
			16b All heroin drug deaths
			16c All non-heroin opioid drug deaths
		16d All non-opioid drug deaths
	17 Suicide
26 Other Body System Diseases
	10 Diseases of the Nervous System
	11 Diseases of the Respiratory System
		11a Chronic lower respiratory diseases
		11b Other diseases of the respiratory system
	12 Diseases of the Digestive System
	13 Diseases of the Genitourinary System
		13a Acute kidney failure and chronic kidney disease
		13b Other Genitourinary
27 Other Causes of Death
	14 Homicide
	18 Transport Accidents
	19 Other External Causes of Death
	20 All Other Causes 

21 Autoimmune conditions
*******************************************************************************/
* SELECT 1
// global measure "asdr"
global measure "yll"

*SELECT 1
// global sample_restriction "base"
global sample_restriction "wbcz"
// global sample_restriction "plany"
// global sample_restriction "pl10p"

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
gen byte touse_here=touse_${sample_restriction}
gen byte exclude_here=touse_base-touse_here

foreach rhsv of varlist pc_inc_???_1980 Mt_* bartik_totemp_r_???{
	cap gen ex_`rhsv'=exclude_here*`rhsv'
}

if "`race_group'" == "NHW" {
	local rnum = 1
	global spec_1 "pc_inc_NHW_1980 Mt_1940 Mt_1950 Mt_1960 "
	global spec_2 "pc_inc_NHW_1980 Mt_total "
	global spec_3 "pc_inc_NHW_1980 "
	global spec_4 ""
	global spec_5 "Mt_total"
	global spec_1x " ex_pc_inc_NHW_1980 ex_Mt_1940 ex_Mt_1950 ex_Mt_1960 exclude_here"
	global spec_2x " ex_pc_inc_NHW_1980 ex_Mt_total exclude_here"
	global spec_3x " ex_pc_inc_NHW_1980 exclude_here"
	global spec_4x "exclude_here"
	global spec_5x "ex_Mt_total exclude_here"
}
else {
	local rnum = 2
	global spec_1 "pc_inc_NHB_1980 Mt_1940 Mt_1950 Mt_1960 "
	global spec_2 "pc_inc_NHB_1980 Mt_total "
	global spec_3 "pc_inc_NHB_1980 "
	global spec_4 ""
	global spec_5 "Mt_total"
	global spec_1x "ex_pc_inc_NHB_1980 ex_Mt_1940 ex_Mt_1950 ex_Mt_1960 exclude_here "
	global spec_2x "ex_pc_inc_NHB_1980 ex_Mt_total exclude_here "
	global spec_3x "ex_pc_inc_NHB_1980 exclude_here "
	global spec_4x "exclude_here"
	global spec_5x "ex_Mt_total exclude_here"
}

putexcel set "${output}\spatial_res_${measure}_${vintage}_${distance}_`race_group'", modify sheet("`race_group'_`age_group' ${sample_restriction}" replace)

***********************************************************************************
* CHANGES IN ${measure} RATES, by cause, education, sex, and race
***********************************************************************************
forval i = 0/1 {
	di "Started ${measure} male = `i' / race = `race_group' / age = `age_group'"
	foreach cod in $causelist {
		cap gen d_${measure}_`cod'_dncol = d_${measure}_`cod'_ltcol-d_${measure}_`cod'_coll
		cap gen d_${measure}_`cod'_dlo25 = d_${measure}_`cod'_lo25-d_${measure}_`cod'_hi75
		
		foreach edgrp in all coll ltcol dncol hi75 lo25 dlo25 {
				regress d_${measure}_`cod'_`edgrp' [aw = Px_all_1990] if ///
				male == `i' & age_cat == `age_group' & race == `rnum' & touse_here == 1, vce(robust)
			matrix a = r(table)
			matrix a=a[1..2,1]	
			if "`edgrp'" == "all" {
				matrix a_`cod' = a
			}
			else {
				matrix a_`cod' = a_`cod', a
			}
		}
		matrix colnames a_`cod' = ed_all ED_COLL ED_LTCOL DIF_NCOL ed_HI75 ed_LO25 DIF_LO25
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
		foreach edgrp in all coll ltcol dncol hi75 lo25 dlo25 {
				regress d_${measure}_`cod'_`edgrp' exclude_here [aw = Px_all_1990] if ///
				male == `i' & age_cat == `age_group' & race == `rnum' & touse_base == 1, vce(robust)
			matrix a = r(table)
			matrix a=a[1..2,1]	
			
			if "`edgrp'" == "all" {
				matrix a_`cod' = a
			}
			else {
				matrix a_`cod' = a_`cod', a
			}
		}
		matrix colnames a_`cod' = ed_all ED_COLL ED_LTCOL DIF_NCOL ed_HI75 ed_LO25 DIF_LO25
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


*******************************************************************************
* ECONOMIC GROWTH EFFECTS (bartik) + 1980 PER CAPITA INCOME (separate by race)
* + MIGRATION VARIABLES
* ON MALE (i = 1) and FEMALE (i = 0)
********************************************************************************
forval i = 0/1 {
	di "Started Bartik male = `i' / race = `race_group' / age = `age_group'"
	forval j = 1/5 {
	foreach cod in $causelist {
		di "Started Bartik male = `i' / race = `race_group' / age = `age_group' / spec = `j' / causelist = `cod'" 
			foreach edgrp in all coll ltcol dncol hi75 lo25 dlo25 {
				 reg2hdfespatial d_${measure}_`cod'_`edgrp' bartik_totemp_r_`race_group' ${spec_`j'} [aw = Px_all_1990] ///
					if male == `i' & age_cat == `age_group' & race == `rnum' & touse_here == 1, ///
					lat(_CY) lon(_CX) timevar(year) panelvar(panel) distcutoff($distance)
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
					else if _rc == 506 & `j' == 5 {
						matrix b0 = J(2,2,.)
						matrix colnames b0 = bartik Mt_total
					}
					else if `j' == 5 {
						matrix b0 = b[1..2,1..2]
						matrix colnames b0 = bartik Mt_total
					}
					matrix rownames b0 = b_`cod' se_`cod'
					predict p_d if e(sample)
					
					qui xtile quartile = bartik_totemp_r_`race_group' if e(sample)==1 [aw = Px_all_1990], nquantiles(4)
					qui summ p_d [aw = Px_all_1990] if e(sample) & quartile == 1, d
						scalar mean_q1 = r(mean)
					qui summ p_d [aw = Px_all_1990] if e(sample) & quartile == 4, d	
						scalar mean_q4 = r(mean)
							drop p_d
							drop quartile
					matrix p0 = mean_q1, mean_q4 \.,. 
					matrix colnames p0 = mean_q1_`edgrp'_emp mean_q4_`edgrp'_emp
					matrix rownames p0 = p_`cod' . 
				if 	"`edgrp'" == "all" {
					matrix b_`cod'_emp = b0
					matrix p_`cod'_emp = p0
				}
				else {
					matrix b_`cod'_emp = b_`cod'_emp, b0
					matrix p_`cod'_emp = p_`cod'_emp, p0
				}
			}
		
		
		
		matrix b_`cod' = b_`cod'_emp
		matrix p_`cod' = p_`cod'_emp
		
		if "`cod'" == "0" {
			matrix b_allc = b_`cod'
			matrix p_allc = p_`cod'
			matrix n_allc = obs
		}
		else {
			matrix b_allc = b_allc \ b_`cod'
			matrix p_allc = p_allc \ p_`cod'
		}
	}
	
	if `i' == 1 {
		matrix bBARTIK_male_`race_group'_`j' = b_allc
		matrix pBARTIK_male_`race_group'_`j' = p_allc
		matrix nBARTIK_male_`race_group'_`j' = n_allc
	}
	else if `i' == 0 {
		matrix bBARTIK_female_`race_group'_`j' = b_allc
		matrix pBARTIK_female_`race_group'_`j' = p_allc
		matrix nBARTIK_female_`race_group'_`j' = n_allc
	}	

	}
	*test subgroup difference from excluded group
if "$sample_restriction" != "base"{
		forval j = 1/5 {
	foreach cod in $causelist {
			foreach edgrp in all coll ltcol dncol hi75 lo25 dlo25 {
				 reg2hdfespatial d_${measure}_`cod'_`edgrp' bartik_totemp_r_`race_group' ${spec_`j'} ex_bartik_totemp_r_`race_group' ${spec_`j'x} [aw = Px_all_1990] ///
					if male == `i' & age_cat == `age_group' & race == `rnum' & touse_base == 1, ///
					lat(_CY) lon(_CX) timevar(year) panelvar(panel) distcutoff($distance)
					*di "N is " e(N)
					
					matrix b = r(table) 
					capture matrix v = vecdiag(cholesky(get(VCE)))
					if _rc == 506 & `j' == 1 {
						matrix b0 = J(2,5,.)
						matrix colnames b0 = bartik pc_inc Mt_1940 Mt_1950 Mt_1960
					}
					else if `j' == 1 {
					    matrix b0 = b[1..2,6..10]
						matrix colnames b0 = bartik pc_inc Mt_1940 Mt_1950 Mt_1960
					}
					else if _rc == 506 & `j' == 2 {
					    matrix b0 = J(2,3,.)
						matrix colnames b0 = bartik pc_inc Mt_total
					}
					else if `j' == 2 {
					    matrix b0 = b[1..2,4..6]
						matrix colnames b0 = bartik pc_inc Mt_total
					}
					else if _rc == 506 & `j' == 3 {
						matrix b0 = J(2,2,.)
						matrix colnames b0 = bartik pc_inc
					}
					else if `j' == 3 {
						matrix b0 = b[1..2,3..4]
						matrix colnames b0 = bartik pc_inc
					}
					else if _rc == 506 & `j' == 4 {
						matrix b0 = J(2,1,.)
						matrix colnames b0 = bartik
					}
					else if `j' == 4 {
						matrix b0 = b[1..2,2]
						matrix colnames b0 = bartik
					}
					else if _rc == 506 & `j' == 5 {
						matrix b0 = J(2,2,.)
						matrix colnames b0 = bartik Mt_total
					}
					else if `j' == 5 {
						matrix b0 = b[1..2,3..4]
						matrix colnames b0 = bartik Mt_total
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
		}
		else {
			matrix b_allc = b_allc \ b_`cod'
		}
	}
	
	if `i' == 1 {
		matrix xbBARTIK_male_`race_group'_`j' = b_allc
	}
	else if `i' == 0 {
		matrix xbBARTIK_female_`race_group'_`j' = b_allc
	}	

}	
}
di "Finished Bartik male = `i' / race = `race_group' / age = `age_group'"
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
		 
putexcel B1:H1     =	"${measure} change, 1990-2018" ///
		 J1:AR1     =	"d ${measure}/dx Specification 1" ///
		 AS1:BM1   =    "d ${measure}/dx Specification 2" ///
		 BN1:CA1   =    "d ${measure}/dx Specification 3" ///
		 CB1:CH1   =    "d ${measure}/dx Specification 4" ///
		 CI1:CV1   =    "d ${measure}/dx Specification 5" ///
		 DJ1:DW1    =	"Predicted ${measure} changes (Specification 1)" ///
		 DX1:EK1    =   "Predicted ${measure} changes (Specification 2)" ///
		 EL1:EY1    =   "Predicted ${measure} changes (Specification 3)" ///
		 EZ1:FM1    =   "Predicted ${measure} changes (Specification 4)" ///
		 B51:H51     =	"${measure} change, 1990-2018" ///
		 J51:AR51       =	"d ${measure}/dx Specification 1" ///
		 AS51:BM51     =    "d ${measure}/dx Specification 2" ///
		 BN51:CA51     =    "d ${measure}/dx Specification 3" ///
		 CB51:CH51     =    "d ${measure}/dx Specification 4" ///
		 CI51:CV51   =    "d ${measure}/dx Specification 5" ///
		 DJ51:DW51      =	"Predicted ${measure} changes (Specification 1)" ///
		 DX51:EK51      =   "Predicted ${measure} changes (Specification 2)" ///
		 EL51:EY51      =   "Predicted ${measure} changes (Specification 3)" ///
		 EZ51:FM51      =   "Predicted ${measure} changes (Specification 4)" ///
		 B2:H2    	=	"MALE" ///
		 J2:AR2     =	"MALE" ///
		 AS2:BM2    =	"MALE" ///
		 BN2:CA2    =	"MALE" ///
		 CB2:CH2    =	"MALE" ///
		 CI2:CV2    =	"MALE" ///
		 DJ2:DW2    =	"MALE" ///
		 DX2:EK2    =	"MALE" ///
		 EL2:EY2    =	"MALE" ///
		 EZ2:FM2    =	"MALE" ///
		 J3:N3    	= "ED_ALL" ///
		 O3:S3    	= "ED_coll" ///
		 T3:X3    	= "ED_LTCOL" ///
		 Y3:AC3    	= "DIF_NCOL" ///
		 AD3:AH3   	= "ED_HI75" ///
		 AI3:AM3  	= "ED_LO25" ///
		 AN3:AR3  	= "DIF_LO25" ///
		 AS3:AU3    = "ED_ALL" ///
		 AV3:AX3    = "ED_COLL" ///
		 AY3:BA3    = "ED_LTCOL" ///
		 BB3:BD3    = "DIF_NCOL" ///
		 BE3:BG3 	= "ED_HI75" ///
		 BH3:BJ3 	= "ED_LO25" ///
		 BK3:BM3 	= "DIF_LO25" ///
		 BN3:BO3    = "ED_ALL" ///
		 BP3:BQ3    = "ED_COLL" ///
		 BR3:BS3    = "ED_LTCOL" ///
		 BT3:BU3    = "DIF_NCOL" ///
		 BV3:BW3 	= "ED_HI75" ///
		 BX3:BY3 	= "ED_LO25" ///
		 BZ3:CA3	= "DIF_LO25" , merge
putexcel	CB3     = "ED_ALL" ///
		 CC3     = "ED_COLL" ///
		 CD3     = "ED_LTCOL" ///
		 CE3     = "DIF_NCOL" ///
		 CF3     = "ED_HI75" ///
		 CG3     = "ED_LO25" ///
		 CH3     = "DIF_LO25" 
putexcel CI3:CJ3     = "ED_ALL" ///
		 CK3:CL3     = "ED_COLL" ///
		 CM3:CN3     = "ED_LTCOL" ///
		 CO3:CP3    = "DIF_NCOL" ///
		 CQ3:CR3     = "ED_HI75" ///
		 CS3:CT3     = "ED_LO25" ///
		 CU3:CV3     = "DIF_LO25"  , merge
putexcel B52:H52    	=	"FEMALE" ///
		 J52:AR52     =	"FEMALE" ///
		 AS52:BM52    =	"FEMALE" ///
		 BN52:CA52    =	"FEMALE" ///
		 CB52:CH52    =	"FEMALE" ///
		 CI52:CV52    =	"FEMALE" ///
		 DJ52:DW52    =	"FEMALE" ///
		 DX52:EK52    =	"FEMALE" ///
		 EL52:EY52    =	"FEMALE" ///
		 EZ52:FM52    =	"FEMALE" ///
		 J53:N53    	= "ED_ALL" ///
		 O53:S53    	= "ED_coll" ///
		 T53:X53    	= "ED_LTCOL" ///
		 Y53:AC53    	= "DIF_NCOL" ///
		 AD53:AH53   	= "ED_HI75" ///
		 AI53:AM53  	= "ED_LO25" ///
		 AN53:AR53  	= "DIF_LO25" ///
		 AS53:AU53    = "ED_ALL" ///
		 AV53:AX53    = "ED_COLL" ///
		 AY53:BA53    = "ED_LTCOL" ///
		 BB53:BD53    = "DIF_NCOL" ///
		 BE53:BG53 	= "ED_HI75" ///
		 BH53:BJ53 	= "ED_LO25" ///
		 BK53:BM53 	= "DIF_LO25" ///
		 BN53:BO53    = "ED_ALL" ///
		 BP53:BQ53    = "ED_COLL" ///
		 BR53:BS53    = "ED_LTCOL" ///
		 BT53:BU53    = "DIF_NCOL" ///
		 BV53:BW53 	= "ED_HI75" ///
		 BX53:BY53 	= "ED_LO25" ///
		 BZ53:CA53	= "DIF_LO25" , merge 
putexcel CB53     = "ED_ALL" ///
		 CC53     = "ED_COLL" ///
		 CD53     = "ED_LTCOL" ///
		 CE53     = "DIF_NCOL" ///
		 CF53     = "ED_HI75" ///
		 CG53     = "ED_LO25" ///
		 CH53     = "DIF_LO25" 
putexcel CI53:CJ53     = "ED_ALL" ///
		 CK53:CL53     = "ED_COLL" ///
		 CM53:CN53     = "ED_LTCOL" ///
		 CO53:CP53    = "DIF_NCOL" ///
		 CQ53:CR53     = "ED_HI75" ///
		 CS53:CT53     = "ED_LO25" ///
		 CU53:CV53     = "DIF_LO25" , merge 
		 
putexcel B4 	   =     matrix(a${measure}_male_`race_group'), colnames nformat(number_d2) right
putexcel J4        =     matrix(bBARTIK_male_`race_group'_1) ///
		 AS4       =     matrix(bBARTIK_male_`race_group'_2) ///
		 BN4       =     matrix(bBARTIK_male_`race_group'_3) ///
		 CB4       =     matrix(bBARTIK_male_`race_group'_4) ///
		 CI4       =     matrix(bBARTIK_male_`race_group'_5) ///
		 DJ4       =     matrix(pBARTIK_male_`race_group'_1) ///
		 DX4       =     matrix(pBARTIK_male_`race_group'_2) ///
		 EL4       =     matrix(pBARTIK_male_`race_group'_3) ///
		 EZ4	   =	 matrix(pBARTIK_male_`race_group'_4), colnames nformat(number_d2) right
putexcel J23	   =	 matrix(nBARTIK_male_`race_group'_1) ///
		 AS23	   =	 matrix(nBARTIK_male_`race_group'_2) ///
		 BN23	   =	 matrix(nBARTIK_male_`race_group'_3) ///
		 CB23	   =	 matrix(nBARTIK_male_`race_group'_4) ///
		 CI23	   =	 matrix(nBARTIK_male_`race_group'_5)
if "$sample_restriction" != "base"{
putexcel B24 	   =     matrix(xa${measure}_male_`race_group'), colnames nformat(number_d2) right
putexcel J24        =     matrix(xbBARTIK_male_`race_group'_1) ///
		 AS24       =     matrix(xbBARTIK_male_`race_group'_2) ///
		 BN24       =     matrix(xbBARTIK_male_`race_group'_3) ///
		 CB24       =     matrix(xbBARTIK_male_`race_group'_4) ///
		 CI24       =     matrix(xbBARTIK_male_`race_group'_5), colnames nformat(number_d2) right
}
putexcel B54       =     matrix(a${measure}_female_`race_group'), colnames nformat(number_d2) right
putexcel J54       =     matrix(bBARTIK_female_`race_group'_1) ///
		 AS54      =     matrix(bBARTIK_female_`race_group'_2) ///
		 BN54      =     matrix(bBARTIK_female_`race_group'_3) ///
		 CB54      =     matrix(bBARTIK_female_`race_group'_4) ///	
		 CI54      =     matrix(bBARTIK_female_`race_group'_5) ///			 
		 DJ54      =     matrix(pBARTIK_female_`race_group'_1) ///
		 DX54      =     matrix(pBARTIK_female_`race_group'_2) ///
		 EL54      =     matrix(pBARTIK_female_`race_group'_3) ///		 
		 EZ54      =     matrix(pBARTIK_female_`race_group'_4), colnames nformat(number_d2) right
putexcel J73	   =	 matrix(nBARTIK_female_`race_group'_1) ///
		 AS73	   =	 matrix(nBARTIK_female_`race_group'_2) ///
		 BN73	   =	 matrix(nBARTIK_female_`race_group'_3) ///
		 CB73	   =	 matrix(nBARTIK_female_`race_group'_4) ///
		 CI73	   =	 matrix(nBARTIK_female_`race_group'_5)
if "$sample_restriction" != "base"{
putexcel B74       =     matrix(xa${measure}_female_`race_group'), colnames nformat(number_d2) right
putexcel J74       =     matrix(xbBARTIK_female_`race_group'_1) ///
		 AS74      =     matrix(xbBARTIK_female_`race_group'_2) ///
		 BN74      =     matrix(xbBARTIK_female_`race_group'_3) ///
		 CB74      =     matrix(xbBARTIK_female_`race_group'_4) ///
		 CI74      =     matrix(xbBARTIK_female_`race_group'_4), colnames nformat(number_d2) right
}
		 }
putexcel save
putexcel clear
end

*** Analysis begin ***
use "$data\pop_loss.dta", clear
	keep czone loss*
	collapse (max) loss*, by(czone)
	tempfile poploss
	save `poploss', replace

use "$data\hist_race_income_bartik_mortchg_cznost_res" , replace
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

merge m:1 czone using `poploss'
	keep if _merge==3
	gen byte lossany=lossany_NHW if race==1
	replace lossany=lossany_NHB if race==2
	gen byte loss10pct=loss10pct_NHW if race==1
	replace loss10pct=loss10pct_NHB if race==2
	drop _merge

preserve 
use "$data\predicted_migrants.dta", clear 
drop if czone==.
collapse (sum) Mt_*, by(czone)
tempfile migrant
save `migrant', replace
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
foreach edgrp in all coll ltcol hi75 lo25 {
	foreach yr in 1990 2017 {
		drop if asdr_0_`edgrp'_`yr' > 100000 
	}
}
*flag cases with no missing data 

gl inclvars "d_asdr_0_all d_asdr_0_coll d_asdr_0_ltcol d_asdr_0_hi75 d_asdr_0_lo25 d_yll_0_all d_yll_0_coll d_yll_0_ltcol d_yll_0_hi75 d_yll_0_lo25 bartik_totemp_all Mt_1940 Mt_1950 Mt_1960 Mt_total"

mark touse_base [aw=Px_all_1990] 
markout touse_base $inclvars

*race specific criteria
replace touse_base=0 if race==1 & (pc_inc_NHW_1980==. | bartik_totemp_r_NHW ==.)
replace touse_base=0 if race==2 & (pc_inc_NHB_1980==. | bartik_totemp_r_NHB ==.)

/* these restrict observations to places where both male and female observations available by race, then where all 4 race/sex groups available */
tempvar num_s num_a num_r
egen `num_s'=total(touse_base), by( czone age_cat race)
replace touse_base=0 if `num_s'!=2
egen `num_a'=total(touse_base), by( czone sex race)
replace touse_base=0 if `num_a'!=2
egen `num_r'=total(touse_base), by( czone age_cat)
gen byte touse_wbcz=(`num_r'==4)

gen byte touse_plany=touse_base*(1-lossany)
gen byte touse_pl10p=touse_base*(1-loss10pct)

*to make coefficients readable, convert income to $000
replace pc_inc_NHB_1980=pc_inc_NHB_1980/1000
replace pc_inc_NHW_1980=pc_inc_NHW_1980/1000

*to make bartik coefficients interpretable as effect of 10pp multiply by 10 TW 03-26-24
foreach var of varlist bartik_totemp*{
	replace `var'=`var'*10
	}

tempfile core
save `core',replace

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
save "$data\fullsample", replace

use `final', replace

foreach race_group in $racelist {
	foreach age_group in   $age  {
		di "race group `race_group' ; age group `age_group'"
		allmods `age_group' `race_group'
	}
}




 log close
