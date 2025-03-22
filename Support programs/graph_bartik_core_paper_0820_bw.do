global bartikfile "G:\data\bartik_1980_2017_cz_edrace.dta"
use $bartikfile, clear
keep czone bartik_totemp_all
rename bartik_totemp_all bartik_regv
merge 1:1 czone using  "$data\bartik_cz_1980_2017_v2023.dta"
drop if _merge==1
summ bartik_regv [aw= totczpop1990] , d
local p25= r(p25)
local p50=r(p50)
local p75=r(p75)
local p10=r(p10)
local p90=r(p90)
local n=r(N)
di `n'
twoway kdensity bartik_sh_1980_2017 [aw= totczpop1990] , lcolor(black) xline(`p10' `p25' `p50' `p75' `p90') title("") xtitle("Bartik Value") area(1) ytitle("Density") xmlabel(-.6675842 "Greenville SC" `p10' "P10" `p25' "P25" `p50' "P50" `p75' "P75" `p90' "P90" .1140409 "Santa Fe NM", angle(45)) n(300)
return list
graph export "$output\bartik_fig1_kdensity_bw.png", as(png) name("Graph") replace
