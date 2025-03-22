clear all
cls
capture log close
/*******************************************************************************
PROJECT:	

CREATED BY:	vincent pancini
UPDATED ON: 
INPUTS:		
OUTPUTS:     
*******************************************************************************/

use "$migdata\net_migrants.dta", clear
	rename czone czone1935
	rename statefip statefip1935
	
merge 1:m czone1935 statefip1935 using ///
	"$migdata\prop_migrants_czone.dta", gen(_merge2)


replace Mt_1940 = 0 if Mt_1940 == . & (Mt_1950 != . | Mt_1960 != .)
replace Mt_1950 = 0 if Mt_1950 == . & (Mt_1940 != . | Mt_1960 != .)
replace Mt_1960 = 0 if Mt_1960 == . & (Mt_1940 != . | Mt_1950 != .)
	
* multiply each Mt by prop_mig
foreach mig in Mt_1940 Mt_1950 Mt_1960 {
	replace `mig' = `mig'*prop_mig
}

* collapse to czone/state
collapse (sum) Mt_1940 Mt_1950 Mt_1960, by(statefip1940 czone1940)

rename statefip1940 statefip
rename czone1940 czone
	destring czone, replace

save "$data\predicted_migrants.dta", replace