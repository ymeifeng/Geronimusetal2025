clear
capture log close
global	dornxw	"[dorn data directory]"
global  data    "[main data directory]"
********************************************************************************
tempfile y1990 y2000
********************************************************************************
use $dornxw\cw_puma1990_czone.dta, clear
rename puma1990 puma
collapse (sum) afactor, by(puma czone)
tostring puma, replace format("%06.0f")
gen statefips = substr(puma,1,2)
replace puma = substr(puma,3,.)
destring puma, replace
gen year = 1990
gen fileyear = 1990
save "`y1990'"
********************************************************************************
use $dornxw\cw_puma1990_czone.dta, clear
rename puma2000 puma
tostring puma, replace format("%06.0f")
collapse (sum) afactor, by(puma czone)
gen statefips = substr(puma,1,2)
replace puma = substr(puma,3,.)
destring puma, replace
gen year = 2000
expand 14
bys statefips puma afactor czone: replace year = year + _n - 1
keep if inlist(year,2000,2005,2006,2007,2008,2009, 2010, 2011, 2012, 2013)
gen fileyear = 2000
save "`y2000'"
********************************************************************************
use $dornxw\cw_puma2010_czone.dta, clear
rename puma2010 puma
collapse (sum) afactor, by(puma czone)
tostring puma, replace format("%07.0f")
gen statefips = substr(puma,1,2)
replace puma = substr(puma,3,.)
destring puma, replace
gen year = 2010
expand 8
bys statefips puma afactor czone: replace year = year + _n - 1
keep if inrange(year,2010,2017)
gen fileyear = 2010
********************************************************************************
append using "`y2000'"
append using "`y1990'"
tab year
tab statefips
order year statefips puma czone afactor
sort year statefips puma czone
compress
save $data\pop\cz_puma.dta, replace

