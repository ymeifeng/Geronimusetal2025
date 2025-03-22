capture program drop deathcause
/*******************************************************************************
PROJECT:	Generate Program to allocate each death in the CDC Multiple Cause of
			Death files to a category based on NAS categorization

CREATED BY:	vincent pancini

UPDATED BY:	vincent pancini
EDITED ON:  2022-03-23


INPUTS:		N/A
********************************************************************************	
**************************************NOTES*************************************			
HIV/AIDS
Non-HIV/AIDS Infectious and Parasitic Diseases
Liver Cancer
Lung Cancer
All Other Cancers
	Prostate cancer (men)
	Breast cancer (women)
	Colon cancer
	Blood cancers including Leukemia and Lymphoma
Endocrine, Nutritional, and Metabolic Diseases
	Diabetes mellitus
Hypertensive Disease
Ischemic Heart Disease and Other Diseases of the Circulatory System
Mental and Behavioral Disorders
Diseases of the Nervous System
Diseases of the Respiratory System
	Asthma and lower respiratory
Diseases of the Digestive System
Diseases of the Genitourinary System
	Acute kidney failure and chronic kidney disease
Homicide
Alcohol-Induced
Drug Poisoning
	All opioid drug deaths
		All heroin drug deaths
		All non-heroin drug deaths
	All non-opioid drug deaths		
Suicide
Transport Accidents
Other External Causes of Death
All Other Causes
********************************************************************************
Autoimmune conditions
********************************************************************************
Infectious and Parasitic Diseases
	includes HIV/AIDS, Non-HIV/AIDS
Cancers
	includes Liver Cancer, Lung Cancer, All Other Cancers
Cardio and Metabolic Diseases
	includes Endocrine, Nutritional, & Metabolic, Hypertensive Heart Disease, Ischemic & Other Circulatory System
Substance Use and Mental Health
	includes Drug Poisoning, Alcohol-Induced, Suicide, Mental & Behavioral Disorders
Other Body System Diseases
	includes Nervous System, Genitourinary System, Respiratory System, Digestive System
Other Causes of Death
	includes Homicide, Transport Accidents, Other External Causes of Death, All Other Causes of Death
********************************************************************************
Changes in the International Classification of Diseases (ICD)-10 code for diseases of the digestive system in 2006 affected the comparability of both
digestive system deaths and alcohol-induced deaths before and after that year.

ICD-9 Notes:

ICD-10 Notes:
- in table 5-1 of the NAS report, "Ischemic heart disease and other diseases of the circulatory system" excludes icd-10 code I142.6. Tim and vincent concluded that this was supposed to be I42.6, because that code is excluded from this category but shows up in another category
- K70 was originally counted twice; in the "Diseases of the Digestive System" and "Alcohol-Induced" groups. we remove it from the digestive system group.
- K29.2 (Alcoholic gastritis), K85.2 (Alcohol induced acute pancreatitis), and K86.0 (Alcohol-induced chronic pancreatitis) were excluded from the "Diseases of the Digestive System" group in the NAS report, but not included elsewhere. We allocated them to the "Alcohol-Induced" group.
*******************************************************************************/

program define deathcause, rclass
	syntax[, year(integer 1)]
* ICD-9 version
if `year' <= 1998 {
	* create death counts by cause using ICD-9 codes
	gen str3 ucod_whole_s = substr(ucod, 1, 3), after(ucod)
	gen str1 ucod_dec_s = substr(ucod, 4, 1), after(ucod_whole_s)
	gen str4 ucod_new = ucod_whole_s, after(ucod_dec_s)
		replace ucod_new = ucod_whole_s + "." + ucod_dec_s if ucod_dec_s != ""
		destring ucod_new, replace

	gen byte deaths = 1
	gen byte deaths_1 = inrange(ucod_new, 42, 44.9)
		label variable deaths_1 "HIV/AIDS"
	gen byte deaths_2 = inrange(ucod_new, 1, 41.9) | ///
						inrange(ucod_new, 45, 139.9) 
		label variable deaths_2 "Non-HIV/AIDS Infectious and Parasitic Diseases"
	gen byte deaths_3 = inrange(ucod_new, 155, 155.9)
		label variable deaths_3 "Liver cancer"
	gen byte deaths_4 = inrange(ucod_new, 162, 162.9)
		label variable deaths_4 "Lung cancer"
	gen byte deaths_5 = (inrange(ucod_new, 140, 239.9) & !inrange(ucod_new, 155, 155.9) & !inrange(ucod_new, 162, 162.9))
		label variable deaths_5 "All other cancers"
			gen byte deaths_5a = (inrange(ucod_new, 185, 185.9) | ///
								  inrange(ucod_new, 174, 174.9))
				label variable deaths_5a "Prostate cancer and Breast cancer"
			gen byte deaths_5b = inrange(ucod_new, 153, 153.9)
				label variable deaths_5b "Colon cancer"	
			gen byte deaths_5c = inrange(ucod_new, 200, 208.9)
				label variable deaths_5c "Blood cancers including leukemia and lymphoma"
			gen byte deaths_5d = deaths_5 - deaths_5a - deaths_5b - deaths_5c
				label variable deaths_5d "Other all other cancers"
	gen byte deaths_6 = inrange(ucod_new, 240, 279.9)
		label variable deaths_6 "Endocrine, nutritional, and metabolic diseases"
			gen byte deaths_6a = inrange(ucod_new, 250, 250.9)
				label variable deaths_6a "Diabetes mellitus"
			gen byte deaths_6b = deaths_6 - deaths_6a
				label variable deaths_6b "Other endocrine, nutritional, and metabolic diseases"
	gen byte deaths_7 = inrange(ucod_new, 401, 405.9)
		label variable deaths_7 "Hypertensive diseases"
	gen byte deaths_8 = inrange(ucod_new, 390, 459.9) & !inrange(ucod_new, 401, 405.9) & ucod_new != 425.5
		label variable deaths_8 "Ischemic heart disease and other diseases of the circulatory system"
	gen byte deaths_9 = inrange(ucod_new, 290, 319.9)
		label variable deaths_9 "Mental and behavioral disorders"
	gen byte deaths_10 = inrange(ucod_new, 320, 359.9) & ucod_new != 357.5
		label variable deaths_10 "Diseases of the nervous system"
	gen byte deaths_11 = inrange(ucod_new, 460, 519.9)
		label variable deaths_11 "Diseases of the respiratory system"
			gen byte deaths_11a = inrange(ucod_new, 490, 496.9)
				label variable deaths_11a "Chronic lower respiratory diseases"
			gen byte deaths_11b = deaths_11 - deaths_11a
				label variable deaths_11b "Other diseases of the respiratory system"
	gen byte deaths_12 = inrange(ucod_new, 520, 579.9) & !inlist(ucod_new, 535.3, 571.0, 571.1, 571.2, 571.3)
		label variable deaths_12 "Diseases of the digestive system"
	gen byte deaths_13 = inrange(ucod_new, 580, 629.9)
		label variable deaths_13 "Diseases of the genitourinary system"
			gen byte deaths_13a = inrange(ucod_new, 584, 586.9) | ///
							   inrange(ucod_new, 588, 589.9)
				label variable deaths_13a "Acute kidney failure and chronic kidney disease"
			gen byte deaths_13b = deaths_13 - deaths_13a	
				label variable deaths_13b "Other diseases of the genitourinary system"
	gen byte deaths_14 = inrange(ucod_new, 960, 961.9) | ///
						 inlist(ucod_new, 962.1, 962.2, 962.9) | ///
						 inrange(ucod_new, 963, 969.9)
		label variable deaths_14 "Homicide"
	gen byte deaths_15 = inlist(ucod_new, 357.5, 425.5, 535.3, 790.3) | ///
						 inrange(ucod_new, 571.0, 571.3) | ///
						 inrange(ucod_new, 860, 860.9)
		label variable deaths_15 "Alcohol-induced"
		
	gen byte deaths_16 = inrange(ucod_new, 850, 858.9) | ///
						 inrange(ucod_new, 950.0, 950.5) | ///
						 ucod_new == 962.0 | ///
						 inrange(ucod_new, 980.0, 980.5)
		label variable deaths_16 "Drug poisoning"	
		
			tempvar drug_pois opioid heroin
			gen byte `drug_pois' = inrange(ucod_new, 850, 858.9) | ///
								   inrange(ucod_new, 950.0, 950.5) | ///
								   ucod_new == 962.0 | ///
								   inrange(ucod_new, 980.0, 980.5)
			gen byte `opioid' = 0
				foreach i of numlist 8500/8502 96500/96502 96509 {
					forval j = 1/20 {
						replace `opioid' = 1 if deaths_16 == 1 & record_`j' == "`i'"
					}
				}
			gen byte `heroin' = 0
				forval j = 1/20 {
					replace `heroin' = 1 if record_`j' == "96501"
				}
			
			gen byte deaths_16a = `drug_pois' * `opioid' // all opioids
				label variable deaths_16a "All opioid drug deaths"
					gen byte deaths_16b = `drug_pois' * `heroin' // heroin
						label variable deaths_16b "All heroin opioid drug deaths"
					gen byte deaths_16c = `drug_pois' * `opioid' * (1 - `heroin') // non-heroin opioids
						label variable deaths_16c "All non-heroin opioid drug deaths"
			gen byte deaths_16d = `drug_pois' * (1 - `opioid') // non-opioid drug deaths
				label variable deaths_16d "All non-opioid drug deaths"
					egen temp = rowtotal(deaths_16b deaths_16c)
					assert temp == deaths_16a
					egen temp2 = rowtotal(deaths_16a deaths_16d)
					assert temp2 == deaths_16
						drop temp temp2
	
	gen byte deaths_17 = inrange(ucod_new, 950.6, 950.9) | ///
						 inrange(ucod_new, 951, 959.9)
		label variable deaths_17 "Suicide"		
	gen byte deaths_18 = inrange(ucod_new, 800, 848.9) | ///
						 inrange(ucod_new, 929.0, 929.1)
		label variable deaths_18 "Transport accidents"		
	gen byte deaths_19 = inrange(ucod_new, 861, 899.9) | ///
						 inrange(ucod_new, 900, 928.9) | ///
						 inrange(ucod_new, 929.2, 929.9) | ///
						 inrange(ucod_new, 930, 949.9) | ///
						 inrange(ucod_new, 970, 979.9) | ///
						 inrange(ucod_new, 980.6, 980.9) | ///
						 inrange(ucod_new, 981, 999.9)
		label variable deaths_19 "Other external causes of death"		
	gen byte deaths_20 = inrange(ucod_new, 280, 289.9) | ///
						 inrange(ucod_new, 360, 379.9) | ///
						 inrange(ucod_new, 380, 389.9) | ///
						 inrange(ucod_new, 630, 676.9) | ///
						 inrange(ucod_new, 680, 709.9) | ///
						 inrange(ucod_new, 710, 739.9) | ///
						 inrange(ucod_new, 740, 759.9) | ///
						 inrange(ucod_new, 760, 779.9) | ///
						 (inrange(ucod_new, 780, 799.9) & ucod_new != 790.3)
		label variable deaths_20 "All other causes"	
	
	egen test = rowtotal(deaths_? deaths_1? deaths_20)
	assert deaths == test
	drop test
********************************************************************************		
	gen byte deaths_21 = inrange(ucod_new, 714, 714.9) | ///
						 inrange(ucod_new, 555, 555.9) | ///
						 inrange(ucod_new, 340, 340.9) | ///
						 inrange(ucod_new, 720, 720.9) | ///
						 inrange(ucod_new, 135, 135.9) | ///
						 inlist(ucod_new, 556.5, 556.6, 556.8, 556.9, 710.0, 696.0, 358.0, 710.4, 710.3, 359.71, 446.5, 710.1, 701.1)
		label variable deaths_21 "Autoimmune conditions"
********************************************************************************
	egen byte deaths_22 = rowtotal(deaths_1 deaths_2)
		label variable deaths_22 "Infectious and parasitic diseases"
	egen byte deaths_23 = rowtotal(deaths_3 deaths_4 deaths_5)
		label variable deaths_23 "Cancers"
	egen byte deaths_24 = rowtotal(deaths_6 deaths_7 deaths_8)
		label variable deaths_24 "Cardio and metabolic diseases"
	egen byte deaths_25 = rowtotal(deaths_16 deaths_15 deaths_17 deaths_9)
		label variable deaths_25 "Substance use and mental health"
	egen byte deaths_26 = rowtotal(deaths_10 deaths_13 deaths_11 deaths_12)
		label variable deaths_26 "Other body system diseases"
	egen byte deaths_27 = rowtotal(deaths_14 deaths_18 deaths_19 deaths_20)
		label variable deaths_27 "Other causes of death"
********************************************************************************		
	
	forval j = 1/27 {
		tab deaths_`j'
	}
}
	
********************************************************************************

* ICD-10 version	
else if year >= 1999 {
	* create death counts by cause using ICD-10 codes
	gen str1 ucod_letter = substr(ucod, 1, 1), after(ucod)
	gen str2 ucod_whole_s = substr(ucod, 2, 2), after(ucod_letter)
	gen str1 ucod_dec_s = substr(ucod, 4, 1), after(ucod_whole_s)
	gen str4 ucod_num_s = ucod_whole_s, after(ucod_dec_s)
	replace ucod_num_s = ucod_whole_s + "." + ucod_dec_s if ucod_dec_s != ""
	destring ucod_num_s, gen(ucod_digits)

	gen byte deaths = 1
	gen byte deaths_1 = ucod_letter == "B" & inrange(ucod_digits, 20, 24.9) 
		label variable deaths_1 "HIV/AIDS"
	gen byte deaths_2 = ucod_letter == "A" & inrange(ucod_digits, 0, 99.9) | ///
						ucod_letter == "B" & (inrange(ucod_digits, 0, 19.9) | inrange(ucod_digits, 25, 99.9)) 
		label variable deaths_2 "Non-HIV/AIDS Infectious and Parasitic Diseases"		
	gen byte deaths_3 = ucod_letter == "C" & inrange(ucod_digits, 22, 22.9)
		label variable deaths_3 "Liver cancer"		
	gen byte deaths_4 = ucod_letter == "C" & inrange(ucod_digits, 33, 34.9)
		label variable deaths_4 "Lung cancer"		
	gen byte deaths_5 = ucod_letter == "C" & (inrange(ucod_digits, 0, 99.9) & !inrange(ucod_digits, 22, 22.9) & !inrange(ucod_digits, 33, 34.9)) | ///
						(ucod_letter == "D" & inrange(ucod_digits, 0, 49.9))
		label variable deaths_5 "All other cancers"	
			gen byte deaths_5a = ucod_letter == "C" & (inrange(ucod_digits, 61, 61.9) | ///
													   inrange(ucod_digits, 50, 50.9))
				label variable deaths_5a "Prostate cancer and Breast cancer"			
			gen byte deaths_5b = ucod_letter == "C" & inrange(ucod_digits, 18, 18.9)
				label variable deaths_5b "Colon cancer"			
			gen byte deaths_5c = ucod_letter == "C" & inrange(ucod_digits, 81, 96.9)
				label variable deaths_5c "Blood cancers including leukemia and lymphoma"
			gen byte deaths_5d = deaths_5 - deaths_5a - deaths_5b - deaths_5c
				label variable deaths_5d "Other all other cancers"
	gen byte deaths_6 = ucod_letter == "E" & inrange(ucod_digits, 0, 88.9) & ucod_digits != 24.4
		label variable deaths_6 "Endocrine, nutritional, and metabolic diseases"	
			gen byte deaths_6a = ucod_letter == "E" & inrange(ucod_digits, 8, 13.9)
				label variable deaths_6a "Diabetes mellitus"
			gen byte deaths_6b = deaths_6 - deaths_6a
				label variable deaths_6b "Other endocrine, nutritional, and metabolic diseases"
	gen byte deaths_7 = ucod_letter == "I" & inrange(ucod_digits, 10, 15.9)
		label variable deaths_7 "Hypertensive diseases"		
	gen byte deaths_8 = ucod_letter == "I" & inrange(ucod_digits, 0, 99.9) & !inrange(ucod_digits, 10, 15.9) & ucod_digits != 42.6
		label variable deaths_8 "Ischemic heart disease and other diseases of the circulatory system"		
	gen byte deaths_9 = ucod_letter == "F" & inrange(ucod_digits, 1, 99.9)
		label variable deaths_9 "Mental and behavioral disorders"		
	gen byte deaths_10 = ucod_letter == "G" & inrange(ucod_digits, 0, 98.9) & !inlist(ucod_digits, 31.2, 62.1, 72.1)
		label variable deaths_10 "Diseases of the nervous system"		
	gen byte deaths_11 = ucod_letter == "J" & inrange(ucod_digits, 0, 98.9)
		label variable deaths_11 "Diseases of the respiratory system"
			gen byte deaths_11a = ucod_letter == "J" & inrange(ucod_digits, 40, 47.9)
				label variable deaths_11a "Chronic lower respiratory diseases"
			gen byte deaths_11b = deaths_11 - deaths_11a
				label variable deaths_11b "Other diseases of the respiratory system"
	gen byte deaths_12 = ucod_letter == "K" & inrange(ucod_digits, 0, 92.9) & !inlist(ucod_digits, 29.2, 70, 85.2, 86.0)
		label variable deaths_12 "Diseases of the digestive system"		
	gen byte deaths_13 = ucod_letter == "N" & inrange(ucod_digits, 0, 98.9)
		label variable deaths_13 "Diseases of the genitourinary system"	
			gen byte deaths_13a = ucod_letter == "N" & inrange(ucod_digits, 17, 19.9)
				label variable deaths_13a "Acute kidney failure and chronic kidney disease"
			gen byte deaths_13b = deaths_13 - deaths_13a
				label variable deaths_13b "Other diseases of the genitourinary system"
	gen byte deaths_14 = (ucod_letter == "X" & inrange(ucod_digits, 86, 99.9)) | ///
						 (ucod_letter == "Y" & (inrange(ucod_digits, 0, 9.9) | ucod_digits == 87.1))
		label variable deaths_14 "Homicide"		
	gen byte deaths_15 = (ucod_letter == "E" & ucod_digits == 24.4) | ///
						 (ucod_letter == "G" & inlist(ucod_digits, 31.2, 62.1, 72.1)) | ///
						 (ucod_letter == "I" & ucod_digits == 42.6) | ///
						 (ucod_letter == "K" & inlist(ucod_digits, 29.2, 70, 85.2, 86.0)) | ///
						 (ucod_letter == "R" & ucod_digits == 78.0) | ///
						 (ucod_letter == "X" & inlist(ucod_digits, 45, 65)) | ///
						 (ucod_letter == "Y" & ucod_digits == 15)
		label variable deaths_15 "Alcohol-induced"		
	gen byte deaths_16 = (ucod_letter == "X" & (inrange(ucod_digits, 40, 44.9) | inrange(ucod_digits, 60, 64.9) | inrange(ucod_digits, 85, 85.9))) | ///
						 (ucod_letter == "Y" & inrange(ucod_digits, 10, 14.9))
		label variable deaths_16 "Drug poisoning"	
				tempvar drug_pois opioid heroin synthetic presc_op othdr
				gen byte `drug_pois' = (ucod_letter == "X" & (inrange(ucod_digits, 40, 44.9) | ///
									  inrange(ucod_digits, 60, 64.9) | inrange(ucod_digits, 85, 85.9))) | ///
									 (ucod_letter == "Y" & inrange(ucod_digits, 10, 14.9))
				gen byte `opioid' = 0 // all opioids
				foreach i in 400 401 402 403 404 406 {
					forval j = 1/20 {
						replace `opioid' = 1 if record_`j'=="T`i'"
						}
					}
				gen byte `heroin' = 0
				foreach i in 401 {
					forval j = 1/20 {
						replace `heroin' = 1 if record_`j'=="T`i'"
					}
				}
			/*	gen byte `synthetic' = 0
				foreach i in 404 {
					forval j = 1/20 {
						replace `synthetic' = 1 if record_`j'=="T`i'"
					}
				}		
				gen byte `presc_op' = 0
				foreach i in 402 403 {
					forval j = 1/20 {
						replace `presc_op' = 1 if record_`j'=="T`i'"
					}
				}
            */
				gen byte deaths_16a = `drug_pois' * `opioid' // all opioids
					label variable deaths_16a "All opioid drug deaths"
						gen byte deaths_16b = `drug_pois' * `opioid' * `heroin' // heroin
							label variable deaths_16b "All heroin opioid drug deaths"
						gen byte deaths_16c = `drug_pois' * `opioid' * (1 - `heroin') // non-heroin
							label variable deaths_16c "All non-heroin opioid drug deaths"
				gen byte deaths_16d = `drug_pois' * (1 - `opioid') // all non-opioid drug poisonings
					label variable deaths_16d "All non-opioid drug deaths"
						egen temp = rowtotal(deaths_16b deaths_16c)
						assert temp == deaths_16a
						egen temp2 = rowtotal(deaths_16a deaths_16d)
						assert temp2 == deaths_16
							drop temp temp2
	gen byte deaths_17 = (ucod_letter == "X" & inrange(ucod_digits, 66, 84.9)) | ///
						 (ucod_letter == "Y" & ucod_digits == 87.0)
		label variable deaths_17 "Suicide"	
	gen byte deaths_18 = (ucod_letter == "V" & inrange(ucod_digits, 1, 99.9)) | ///
						 (ucod_letter == "Y" & inrange(ucod_digits, 85, 85.9))
		label variable deaths_18 "Transport accidents"		
	gen byte deaths_19 = (ucod_letter == "W" & inrange(ucod_digits, 0, 99.9)) | ///
						 (ucod_letter == "X" & (inrange(ucod_digits, 0, 39.9) | inrange(ucod_digits, 46, 59.9))) | ///
						 (ucod_letter == "Y" & (inrange(ucod_digits, 16, 36.9) | inrange(ucod_digits, 40, 84.9) | inrange(ucod_digits, 86, 86.9) | ucod_digits == 87.2 | inrange(ucod_digits, 88, 88.9) | inrange(ucod_digits, 89, 89.9)))
		label variable deaths_19 "Other external causes of death"		
	gen byte deaths_20 = (ucod_letter == "D" & inrange(ucod_digits, 50, 89.9)) | ///
						 (ucod_letter == "H" & (inrange(ucod_digits, 0, 57.9) | inrange(ucod_digits, 60, 93.9))) | ///
						 (ucod_letter == "L" & inrange(ucod_digits, 0, 98.9)) | ///
						 (ucod_letter == "M" & inrange(ucod_digits, 0, 99.9)) | ///
						 (ucod_letter == "O" & inrange(ucod_digits, 0, 99.9)) | ///
						 (ucod_letter == "P" & inrange(ucod_digits, 0, 96.9)) | ///
						 (ucod_letter == "Q" & inrange(ucod_digits, 0, 99.9)) | ///
						 (ucod_letter == "R" & (inrange(ucod_digits, 0, 99.9) & ucod_digits != 78.0)) | ///
						 (ucod_letter == "U" & inrange(ucod_digits, 0, 99.9))
		label variable deaths_20 "All other causes"
		
	egen test = rowtotal(deaths_? deaths_1? deaths_20)
	assert deaths == test
	drop test
********************************************************************************
	gen byte deaths_21 = (ucod_letter == "D" & ucod_digits == 86.9) | ///
						 (ucod_letter == "G" & inlist(ucod_digits, 35, 70, 72.4)) | ///
						 (ucod_letter == "M" & ucod_digits == 31.6) | ///
						 (ucod_letter == "K" & inlist(ucod_digits, 50, 50.1, 50.8, 50.9, 51.5, 51, 51.9)) | ///
						 (ucod_letter == "L" & inlist(ucod_digits, 40.5, 11.0, 85.0, 85.1, 85.2, 87.0, 87.2)) | ///
						 (ucod_letter == "M" & inlist(ucod_digits, 32.1, 34.0, 34.1, 34.9, 33.9, 33.2, 6.9, 5, 5.3, 5.6, 6.1, 8.0, 8.3, 8.4, 12.0, 5.1, 6.4, 45.9, 46.0, 46.1, 49.8, 46.8, 49.9))
		label variable deaths_21 "Autoimmune conditions"
********************************************************************************
	egen byte deaths_22 = rowtotal(deaths_1 deaths_2)
		label variable deaths_22 "Infectious and parasitic diseases"
	egen byte deaths_23 = rowtotal(deaths_3 deaths_4 deaths_5)
		label variable deaths_23 "Cancers"
	egen byte deaths_24 = rowtotal(deaths_6 deaths_7 deaths_8)
		label variable deaths_24 "Cardio and metabolic diseases"
	egen byte deaths_25 = rowtotal(deaths_16 deaths_15 deaths_17 deaths_9)
		label variable deaths_25 "Substance use and mental health"
	egen byte deaths_26 = rowtotal(deaths_10 deaths_13 deaths_11 deaths_12)
		label variable deaths_26 "Other body system diseases"
	egen byte deaths_27 = rowtotal(deaths_14 deaths_18 deaths_19 deaths_20)
		label variable deaths_27 "Other causes of death"
********************************************************************************		
	
	forval j = 1/27 {
		tab deaths_`j'
	}
}		
end 


