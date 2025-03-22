clear all
cls
capture log close
/*******************************************************************************
PROJECT:	Merges counts of deaths by 5-year age groups, education, sex, race, 
			and by cause to create county level counts of death by level (lehs/ghs), (coll/ltcol)
			and by rank (lowest quartile (lo25)/top 3 quartiles (hi75))
			*by county of residence*
CREATED BY:	Tim Waidmann

UPDATED BY:	vincent pancini; tim waidmann
EDITED ON: 2022-03-24; 2023-07-17 (adding college/less level split); 2024-01-26 *tab by residence

INPUTS:		deathtabYYYY_89ed_res.dta & deathtabYYYY_03ed_res.dta
OUTPUTS: $out\deathtab_YYYY_final_res
********************************************************************************
*******************************************************************************/
global	logs	"[log file directory]"
global	do	"[your do file directory]"
global  out	"[analysis file directory]"
global 	data	"[data directory]"
global  dosource "$do\3_mort_tabs_by_ed_res.do"
********************************************************************************
* log using $logs/mort_tabs_bycause_level.log, replace

foreach yr in 1989 1990 1991 2016 2017 2018 {
		tempfile b_`yr'_89 b_`yr'_03
		* statement to select which year to load
	if `yr' < 2018 {
		use "$out\deathtab`yr'_89ed_res.dta", clear
		gen byte ed_ghs = inrange(edcommon89, 7, 11) 
		gen deaths_ghs = ed_ghs * deaths
		gen deaths_lehs = (1 - ed_ghs) * deaths
		gen byte ed_coll=inrange(edcommon89, 10,11)
		gen deaths_coll=ed_coll * deaths
		gen deaths_ltcol=(1 - ed_coll) * deaths
		
		forval i = 1/27 {
			gen deaths_`i'_ghs = ed_ghs * deaths_`i'
			gen deaths_`i'_lehs = (1 - ed_ghs) * deaths_`i'
			gen deaths_`i'_coll = ed_coll * deaths_`i'
			gen deaths_`i'_ltcol = (1 - ed_col) * deaths_`i'
			capture noisily {
				foreach j in `c(alpha)' {
					gen deaths_`i'`j'_ghs = ed_ghs * deaths_`i'`j'
					gen deaths_`i'`j'_lehs = (1 - ed_ghs) * deaths_`i'`j'
					gen deaths_`i'`j'_coll = ed_coll * deaths_`i'`j'
					gen deaths_`i'`j'_ltcol = (1 - ed_coll) * deaths_`i'`j'
				}
			}
		}
		
         * create deaths by ed rank 
		merge m:1 sex race birthyear edcommon89 using $data\edrank_xw89
		gen deaths_hi75 = (1 - p_lo25) * deaths
		gen deaths_lo25 = p_lo25 * deaths
		forval i = 1/27 {
			gen deaths_`i'_hi75 = (1 - p_lo25) * deaths_`i'
			gen deaths_`i'_lo25 = p_lo25 * deaths_`i'
			capture noisily {
				foreach j in `c(alpha)' {
					gen deaths_`i'`j'_hi75 = (1 - p_lo25) * deaths_`i'`j'
					gen deaths_`i'`j'_lo25 = p_lo25 * deaths_`i'`j'
				}
			}
		}
		collapse (sum) deaths*, ///
				   by(sex race age_lt statefips countyfips)
		compress
		save `b_`yr'_89', replace
	}
	
	if `yr' >= 2003 {
		use "$out\deathtab`yr'_03ed_res.dta", clear
		* create deaths by ed level
		gen byte ed_ghs = inrange(edcommon03,4,6) 
		gen byte ed_coll = inrange(edcommon03,5,6) 
		
		gen deaths_ghs = ed_ghs * deaths
		gen deaths_lehs = (1 - ed_ghs) * deaths
		gen deaths_coll = ed_coll * deaths
		gen deaths_ltcol = (1 - ed_coll) * deaths
		forval i = 1/27 {
			gen deaths_`i'_ghs = ed_ghs * deaths_`i'
			gen deaths_`i'_lehs = (1 - ed_ghs) * deaths_`i'
			gen deaths_`i'_coll = ed_coll * deaths_`i'
			gen deaths_`i'_ltcol = (1 - ed_coll) * deaths_`i'
			capture noisily {
				foreach j in `c(alpha)' {
					gen deaths_`i'`j'_ghs = ed_ghs * deaths_`i'`j'
					gen deaths_`i'`j'_lehs = (1 - ed_ghs) * deaths_`i'`j'
					gen deaths_`i'`j'_coll = ed_coll * deaths_`i'`j'
					gen deaths_`i'`j'_ltcol = (1 - ed_coll) * deaths_`i'`j'
				}
			}
		}
		
         * create deaths by ed rank
		merge m:1 sex race birthyear edcommon03 using $data\edrank_xw03
		gen deaths_hi75 = (1 - p_lo25) * deaths
		gen deaths_lo25 = p_lo25 * deaths
		forval i = 1/27 {
			gen deaths_`i'_hi75 = (1 - p_lo25) * deaths_`i'
			gen deaths_`i'_lo25 = p_lo25 * deaths_`i'
			capture noisily {
				foreach j in `c(alpha)' {
					gen deaths_`i'`j'_hi75 = (1 - p_lo25) * deaths_`i'`j'
					gen deaths_`i'`j'_lo25 = p_lo25 * deaths_`i'`j'
				}
			}
		}
		
		collapse (sum) deaths*, ///
				   by(sex race age_lt statefips countyfips)
		compress
		save `b_`yr'_03', replace
		
	}
	
	if `yr' < 2003 {
	    use `b_`yr'_89'
		gen int year = `yr'
		notes : Created on ${S_DATE} by $dosource 
		save "$out\deathtab_`yr'_final_res", replace
	}
	
	else if `yr' < 2018 {
	    use `b_`yr'_89'
	    append using `b_`yr'_03'
		gen int year = `yr'
		notes : Created on ${S_DATE} by $dosource 
		save "$out\deathtab_`yr'_final_res", replace
	}
	
	else if `yr' >= 2018 {
	    use `b_`yr'_03'
		gen int year = `yr'
		notes : Created on ${S_DATE} by $dosource 
		save "$out\deathtab_`yr'_final_res", replace
	}
}
