






clear

global Nigeria_GHS_W2_raw_data 		"C:\Users\obine\Music\Documents\Smallholder lsms STATA\NGA_2012_GHSP-W2_v02_M_STATA_Copy" 
global Nigeria_GHS_W2_created_data  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_two"



********************************************************************************
* AG FILTER *
********************************************************************************

use "${Nigeria_GHS_W2_raw_data}/Post Planting Wave 2\Agriculture\sect11a_plantingw2.dta" , clear

keep hhid s11aq1
rename (s11aq1) (ag_rainy_12)
save  "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", replace



*merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

*keep if ag_rainy_12==1



/********************************************************************
WHO 2006 Height-for-Age Z-score (HAZ)
Case where measurement position variable is NOT available
Use age-based WHO convention:
  0–23 months  = recumbent length
  24–59 months = standing height
********************************************************************/

use "${Nigeria_GHS_W2_raw_data}\sect4a_harvestw2.dta", clear
merge 1:1 hhid indiv using "${Nigeria_GHS_W2_raw_data}\sect1_harvestw2.dta", nogen

*--------------------------------------------------------------*
* 0. Keep children aged 0–59 months
*--------------------------------------------------------------*
keep if s4aq51 == 1


gen child = (s4aq51 == 1)
tab child
*--------------------------------------------------------------*
* 1. Age in months
*    Replace s1q4 with the correct age-in-years variable if needed
*--------------------------------------------------------------*
gen age_months = s1q4 * 12
replace age_months = 59 if age_months < 0 | age_months > 59
tab age_months
*--------------------------------------------------------------*
* 2. Sex (WHO coding: 1 = boy, 2 = girl)
*--------------------------------------------------------------*
gen sex = s1q2
replace sex = . if sex != 1 & sex != 2

*--------------------------------------------------------------*
* 3. Height/length in cm
*--------------------------------------------------------------*
gen height_cm = s4aq53
replace height_cm = . if height_cm < 45 | height_cm > 120

*--------------------------------------------------------------*
* 4. Create measurement type from age
*    WHO convention:
*      1 = recumbent length
*      2 = standing height
*--------------------------------------------------------------*
gen meas = .
replace meas = 1 if age_months >= 0  & age_months < 24
replace meas = 2 if age_months >= 24 & age_months <= 59

*--------------------------------------------------------------*
* 5. Install zscore06 if needed
*--------------------------------------------------------------*
capture which zscore06
if _rc ssc install zscore06, replace

*--------------------------------------------------------------*
* 6. Calculate HAZ
*--------------------------------------------------------------*
capture drop haz06 waz06 whz06 bmiz06
zscore06, a(age_months) s(sex) h(height_cm) ///
          measure(meas) recum(1) stand(2)

*--------------------------------------------------------------*
* 7. Clean HAZ output
*--------------------------------------------------------------*
gen haz = haz06
sum haz, detail
replace haz = . if haz > 1000
replace haz = -1 if haz < -6 | haz > 6
sum haz, detail
*--------------------------------------------------------------*
* 8. Optional stunting indicators
*--------------------------------------------------------------*
gen stunted        = haz < -2 if haz < .
gen severe_stunted = haz < -3 if haz < .

*--------------------------------------------------------------*
* 9. Check
*--------------------------------------------------------------*
sum haz, detail
tab stunted if haz < ., missing



*--------------------------------------------------------------*
* 9. Validation check (this should now look right)
*--------------------------------------------------------------*
sum haz, detail
tab stunted if haz < ., missing

collapse (mean) haz (sum) child1 = child (max) child s4aq51, by(hhid)

egen med = median(haz)

gen haz2 = haz
replace haz2 = med if haz ==.
sum haz, detail
sum haz2, detail
tab child1, missing
save  "${Nigeria_GHS_W2_created_data}/haz.dta", replace





********************************************************************************
* SHOCK *
********************************************************************************

use "${Nigeria_GHS_W2_raw_data}\sect15a_harvestw2.dta", clear

keep if s15aq1==1
gen nonag_shock = 1 if shock_cd ==2 | shock_cd ==3 | shock_cd ==4 | shock_cd ==5 | shock_cd ==6 | shock_cd ==7 | shock_cd ==8 | shock_cd ==11 | shock_cd ==15

replace nonag_shock = 0 if nonag_shock==.

gen ag_shock = 1 if shock_cd ==9 | shock_cd ==12 | shock_cd ==13 | shock_cd ==14 | shock_cd ==16 | shock_cd ==17 | shock_cd ==18 | shock_cd ==19 | shock_cd ==20 

replace ag_shock = 0 if ag_shock==.

tab ag_shock, missing 
tab nonag_shock, missing

gen shock =1 if (s15aq1==1)
replace shock = 0 if shock==.
collapse (max) shock ag_shock nonag_shock, by (hhid)
tab shock, missing
tab ag_shock, missing
tab nonag_shock, missing
save  "${Nigeria_GHS_W2_created_data}/shock.dta", replace









********************************************************************************
* WEIGHTS *
********************************************************************************

use "${Nigeria_GHS_W2_raw_data}/Post Planting Wave 2\Household\secta_plantingw2.dta" , clear
*merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

*keep if ag_rainy_12==1
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave2 rural
ren wt_wave2 weight
collapse (max) weight, by (hhid)
save  "${Nigeria_GHS_W2_created_data}/weight.dta", replace






********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
global Nigeria_GHS_W2_exchange_rate 401.15  		// https://www.bloomberg.com/quote/USDETB:CUR, https://data.worldbank.org/indicator/PA.NUS.FCRF?end=2023&locations=NG&start=2011
// {2017:315,2021:401.15}
global Nigeria_GHS_W2_gdp_ppp_dollar  146.72		// https://data.worldbank.org/indicator/PA.NUS.PRVT //2021
global Nigeria_GHS_W2_cons_ppp_dollar  155.72		// https://data.worldbank.org/indicator/PA.NUS.PRVT.P //2021
global Nigeria_GHS_W2_inflation 0.380751		// 2017: 134.9/214.2, 2021: 134.9/354.3 inflation rate 2013-2016. Data was collected during 2012-2013. We want to ajhust value to 2017


//Poverty threshold calculation
//Per W3, we convert WB's international poverty threshold to 2011$ using the PA.NUS.PRVT.PP WB info then inflate to the last year of the survey using CPI
global Nigeria_GHS_W2_poverty_190 ((1.90*83.58) * (134.9/110.8))
global Nigeria_GHS_W2_poverty_npl (376.52 * $Nigeria_GHS_W2_inflation ) //ALT: To do: adjust for inflation
global Nigeria_GHS_W2_poverty_215 (2.15*(0.587791 * 112.0983276))  //New 2023 WB poverty threshold
global Nigeria_GHS_W2_poverty_300 (3*($Nigeria_GHS_W2_inflation * $Nigeria_GHS_W2_cons_ppp_dollar ))  //New 2025 WB poverty threshold

********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables



*DYA.11.1.2020 Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Nigeria_GHS_W2_pop_tot 170075932
global Nigeria_GHS_W2_pop_rur 93123376
global Nigeria_GHS_W2_pop_urb 76952556

/*
********************************************************************************
*PRIORITY CROPS //change these globals if you are interested in a different crop
********************************************************************************
////Limit crop names in variables to 6 characters or the variable names will be too long! 
global topcropname_area "maize rice sorgum millet cowpea grdnt yam swtptt cassav banana cocoa soy" 
global comma_topcrop_area "1080, 1110, 1070, 1100, 1010, 1060, 1120, 2181, 1020, 2030, 3040, 2220"
global topcrop_area = subinstr("$comma_topcrop_area",","," ",.) //removing commas from the list above
global nb_topcrops : list sizeof global(topcropname_area) // Gets the current length of the global macro list "topcropname_area" 
display "$nb_topcrops"
global nb_topcrops : list sizeof global(topcropname_area) // Gets the current length of the global macro list "topcropname_area" 
set obs $nb_topcrops //Update if number of crops changes
egen rnum = seq(), f(1) t($nb_topcrops)
gen crop_code = .
gen crop_name = ""
forvalues k=1(1)$nb_topcrops {
	local c : word `k' of $topcrop_area
	local cn : word `k' of $topcropname_area 
	replace crop_code = `c' if rnum==`k'
	replace crop_name = "`cn'" if rnum==`k'
}
drop rnum
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_cropname_table.dta", replace //This gets used to generate the monocrop files.
*/






********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Nigeria_GHS_W2_raw_data}/HHTrack.dta", clear
keep if (hhstatus_w2v1==1 | hhstatus_w2v1==5) & (hhstatus_w2v2==1 | hhstatus_w2v2==5)
gen filesource=1
append using "${Nigeria_GHS_W2_raw_data}/secta_plantingw2.dta"
replace filesource=2 if file==.
gen rural = (sector==2)
lab var rural "1= Rural"
//keep hhid zone state lga ea wt_wave2 rural
ren wt_wave2 weight
replace weight = wt_w2v1 if weight==.
replace weight= wt_w2v2 if weight==.
collapse (mean) weight (max) ea rural filesource, by(hhid zone state lga) //A few households reported as moving or with inconsistent urban/rural assignments
//Some households moved from the hhtrack location, leading to duplicates. We'll take the moved location.
duplicates tag hhid, g(dupes)
drop if dupes & file==1
drop dupes file
recast double weight
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_hhids.dta", replace






********************************************************************************
* INDIVIDUAL IDS *
********************************************************************************
use "${Nigeria_GHS_W2_raw_data}/sect1_plantingw2.dta", clear
gen season="plan"
append using "${Nigeria_GHS_W2_raw_data}/sect1_harvestw2.dta", force
replace season="harv" if season==""
*keep if s1q4==1 //Drop individuals who've left household   // AYW_3.5.20 This question wasn't asked of all individuals. 
gen member = s1q4
replace member = 1 if s1q3 != . 
drop if member!=1
gen female= s1q2==2
gen fhh = s1q3==1 & female
recode fhh (.=0)
preserve 
collapse (max) fhh, by(hhid)
tempfile fhh
save `fhh'
restore 
la var female "1= individual is female"
ren s1q6 age
la var age "Individual age"
keep hhid indiv female age season
ren female female_
ren age age_ 
reshape wide female_ age_, i(hhid indiv) j(season) string
gen age = age_plan 
replace age=age_harv if age==.
gen female=female_plan 
replace female=female_harv if female==.
drop *harv *plan
merge m:1 hhid using `fhh', nogen
//merge m:1 hhid using  "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_hhids.dta", keep(2 3) nogen  // keeping hh surveyed //Dropping households with recorded harvest info.
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_person_ids.dta", replace







********************************************************************************
* HOUSEHOLD SIZE *
********************************************************************************
use "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_person_ids.dta", clear
gen member=1
collapse (max) fhh (sum) hh_members=member, by (hhid)
lab var hh_members "Number of household members"
lab var fhh "1= Female-headed household"
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_hhids.dta", nogen keep(3)
*Adjust to match total population
total hh_members [pweight=weight]
matrix temp =e(b)
gen weight_pop_tot=weight*${Nigeria_GHS_W2_pop_tot}/el(temp,1,1)
total hh_members [pweight=weight_pop_tot]
lab var weight_pop_tot "Survey weight - adjusted to match total population"
*Adjust to match total population but also rural and urban
total hh_members [pweight=weight] if rural==1
matrix temp =e(b)
gen weight_pop_rur=weight*${Nigeria_GHS_W2_pop_rur}/el(temp,1,1) if rural==1
total hh_members [pweight=weight_pop_tot]  if rural==1

total hh_members [pweight=weight] if rural==0
matrix temp =e(b)
gen weight_pop_urb=weight*${Nigeria_GHS_W2_pop_urb}/el(temp,1,1) if rural==0
total hh_members [pweight=weight_pop_urb]  if rural==0

egen weight_pop_rururb=rowtotal(weight_pop_rur weight_pop_urb)
total hh_members [pweight=weight_pop_rururb]  
lab var weight_pop_rururb "Survey weight - adjusted to match rural and urban population"
drop weight_pop_rur weight_pop_urb
recast double weight*
keep hhid zone state lga ea weight* rural hh_members fhh
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_weights.dta", replace


********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Nigeria_GHS_W2_raw_data}/PTrack.dta", clear //Update this to use individual ids
ren sex gender
gen adulteq=.
replace adulteq=0.4 if (age<3 & age>=0)
replace adulteq=0.48 if (age<5 & age>2)
replace adulteq=0.56 if (age<7 & age>4)
replace adulteq=0.64 if (age<9 & age>6)
replace adulteq=0.76 if (age<11 & age>8)
replace adulteq=0.80 if (age<=12 & age>10) & gender==1		//1=male, 2=female
replace adulteq=0.88 if (age<=12 & age>10) & gender==2 		//ALT 01.04.21: Updated to <=12 b/c 12 yo's were being excluded from analysis
replace adulteq=1 if (age<15 & age>12)
replace adulteq=1.2 if (age<19 & age>14) & gender==1
replace adulteq=1 if (age<19 & age>14) & gender==2
replace adulteq=1 if (age<60 & age>18) & gender==1
replace adulteq=0.88 if (age<60 & age>18) & gender==2
replace adulteq=0.8 if (age>59 & age!=.) & gender==1
replace adulteq=0.72 if (age>59 & age!=.) & gender==2
replace adulteq=. if age==999
collapse (sum) adulteq (count) hhsize=adulteq, by(hhid)
lab var adulteq "Adult-Equivalent"
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_hh_adulteq.dta", replace 



use "${Nigeria_GHS_W2_raw_data}/cons_agg_wave2_visit2.dta", clear

egen cereals_only = rowtotal (fdsorby fdmilby fdmaizby fdriceby fdyamby fdcasby fdcereby fdbrdby fdsorpr fdmilpr fdmaizpr fdricepr fdyampr fdcaspr fdcerepr fdbrdpr)
egen protein_only = rowtotal (fdpoulby fdmeatby fdfishby fddairby fdfatsby fdbeanby  fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdbeanpr )
egen fruits_vegetables = rowtotal (fdtubby fdfrutby fdvegby fdtubpr fdfrutpr fdvegpr)


merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_weights.dta", nogen keepusing(hh_members)
save "${Nigeria_GHS_W2_created_data}/cons_agg_wave2_visit2group.dta", replace





use "${Nigeria_GHS_W2_raw_data}/cons_agg_wave2_visit1.dta", clear


egen cereals_only = rowtotal (fdsorby fdmilby fdmaizby fdriceby fdyamby fdcasby fdcereby fdbrdby fdsorpr fdmilpr fdmaizpr fdricepr fdyampr fdcaspr fdcerepr fdbrdpr)
egen protein_only = rowtotal (fdpoulby fdmeatby fdfishby fddairby fdfatsby fdbeanby  fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdbeanpr )
egen fruits_vegetables = rowtotal (fdtubby fdfrutby fdvegby fdtubpr fdfrutpr fdvegpr)


merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_weights.dta", nogen keepusing(hh_members)
save "${Nigeria_GHS_W2_created_data}/cons_agg_wave2_visit1group.dta", replace




ren cereals_only totcons_cereal_pp
ren protein_only totcons_protein_pp 
ren fruits_vegetables totcons_veg_pp


merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/cons_agg_wave2_visit2group.dta", nogen keepusing(cereals_only protein_only fruits_vegetables)
ren cereals_only totcons_cereal_ph
ren protein_only totcons_protein_ph 
ren fruits_vegetables totcons_veg_ph

*gen totcons_cereal = (totcons_cereal_pp+totcons_cereal_ph)/2
gen totcons_cereal = totcons_cereal_pp
*gen totcons_protein = (totcons_protein_pp+totcons_protein_ph)/2
gen totcons_protein = totcons_protein_pp
*gen totcons_fruit_veg = (totcons_veg_pp+totcons_veg_ph)/2
gen totcons_fruit_veg = totcons_veg_pp

merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_hh_adulteq.dta", nogen keep(1 3) keepusing(adulteq)


merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/weight.dta", nogen





gen daily_peraeq_cons1 = totcons_cereal/adulteq 
gen daily_peraeq_cons2 = totcons_protein/adulteq 
gen daily_peraeq_cons3 = totcons_fruit_veg/adulteq 

gen peraeq_cons_cereal = daily_peraeq_cons1*365
gen peraeq_cons_protein = daily_peraeq_cons2*365
gen peraeq_cons_veg = daily_peraeq_cons3*365

gen totalcons_cereal = totcons_cereal*365
gen totalcons_protein = totcons_protein*365
gen totalcons_veg = totcons_fruit_veg*365


foreach v of varlist  peraeq_cons_protein  {
	_pctile `v' [aw=weight] , p(1 95) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}

foreach v of varlist  totalcons_protein  {
	_pctile `v' [aw=weight] , p(1 95) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}

ren peraeq_cons_protein you 
ren totalcons_protein me

ren totcons_cereal totcons_cereal_n
ren totcons_protein totcons_protein_n
ren totcons_fruit_veg totcons_fruit_veg_n


ren peraeq_cons_cereal peraeq_cons_cereal_n
ren peraeq_cons_protein_w peraeq_cons_protein_n
ren peraeq_cons_veg peraeq_cons_veg_n


ren totalcons_cereal totalcons_cereal_n
ren totalcons_protein_w totalcons_protein_n
ren totalcons_veg totalcons_veg_n


gen totcons_cereal = totcons_cereal_n /0.236945
gen totcons_protein = totcons_protein_n /0.236945
gen totcons_fruit_veg = totcons_fruit_veg_n /0.236945

gen peraeq_cons_cereal = peraeq_cons_cereal_n /0.236945
gen peraeq_cons_protein = peraeq_cons_protein_n /0.236945
gen peraeq_cons_veg = peraeq_cons_veg_n /0.236945


gen totalcons_cereal = totalcons_cereal_n /0.236945
gen totalcons_protein = totalcons_protein_n /0.236945
gen totalcons_veg = totalcons_veg_n /0.236945
    
		
keep hhid adulteq totcons_cereal totcons_protein  totcons_fruit_veg peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_consumption_group2.dta", replace




use "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_consumption_group2.dta", clear 

merge 1:1 hhid using   "${Nigeria_GHS_W2_created_data}/haz.dta", nogen

keep if s4aq51 ==1
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_consumption_group2.dta", replace 







********************************************************************************
* PLOT AREAS *
********************************************************************************
*starting with planting
clear


*using conversion factors from LSMS-ISA Nigeria Wave 2 Basic Information Document (Waves 1 & 2 are identical)
*found at http://econ.worldbank.org/WBSITE/EXTERNAL/EXTDEC/EXTRESEARCH/EXTLSMS/0,,contentMDK:23635560~pagePK:64168445~piPK:64168309~theSitePK:3358997,00.html
*General Conversion Factors to Hectares
//		Zone   Unit         Conversion Factor
//		All    Plots        0.0667
//		All    Acres        0.4
//		All    Hectares     1
//		All    Sq Meters    0.0001
*Zone Specific Conversion Factors to Hectares
//		Zone           Conversion Factor
//				 Heaps      Ridges      Stands
//		1 		 0.00012 	0.0027 		0.00006
//		2 		 0.00016 	0.004 		0.00016
//		3 		 0.00011 	0.00494 	0.00004
//		4 		 0.00019 	0.0023 		0.00004
//		5 		 0.00021 	0.0023 		0.00013
//		6  		 0.00012 	0.00001 	0.00041
set obs 42 //6 zones x 7 units
egen zone=seq(), f(1) t(6) b(7)
egen area_unit=seq(), f(1) t(7)
gen conversion=1 if area_unit==6
gen area_size=1 //This makes it easy for me to copy-paste existing code rather than having to write a new block
replace conversion = area_size*0.0667 if area_unit==4									//reported in plots
replace conversion = area_size*0.404686 if area_unit==5		    						//reported in acres
replace conversion = area_size*0.0001 if area_unit==7									//reported in square meters

replace conversion = area_size*0.00012 if area_unit==1 & zone==1						//reported in heaps
replace conversion = area_size*0.00016 if area_unit==1 & zone==2
replace conversion = area_size*0.00011 if area_unit==1 & zone==3
replace conversion = area_size*0.00019 if area_unit==1 & zone==4
replace conversion = area_size*0.00021 if area_unit==1 & zone==5
replace conversion = area_size*0.00012 if area_unit==1 & zone==6

replace conversion = area_size*0.0027 if area_unit==2 & zone==1							//reported in ridges
replace conversion = area_size*0.004 if area_unit==2 & zone==2
replace conversion = area_size*0.00494 if area_unit==2 & zone==3
replace conversion = area_size*0.0023 if area_unit==2 & zone==4
replace conversion = area_size*0.0023 if area_unit==2 & zone==5
replace conversion = area_size*0.00001 if area_unit==2 & zone==6

replace conversion = area_size*0.00006 if area_unit==3 & zone==1						//reported in stands
replace conversion = area_size*0.00016 if area_unit==3 & zone==2
replace conversion = area_size*0.00004 if area_unit==3 & zone==3
replace conversion = area_size*0.00004 if area_unit==3 & zone==4
replace conversion = area_size*0.00013 if area_unit==3 & zone==5
replace conversion = area_size*0.00041 if area_unit==3 & zone==6

drop area_size
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_landcf.dta", replace

use "${Nigeria_GHS_W2_raw_data}/sect11a1_plantingw2"
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using "${Nigeria_GHS_W2_raw_data}/sect11b1_plantingw2", nogen
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W2_raw_data}/secta1_harvestw2.dta", gen(plot_merge)
ren s11aq4a area_size
ren s11aq4b area_unit
ren sa1q9a area_size2
ren sa1q9b area_unit2
ren s11aq4c area_meas_sqm
ren sa1q9c area_meas_sqm2
recode area_size area_size2 area_meas_sqm area_meas_sqm2 (0=.)
gen cultivate = s11b1q27 ==1 
*assuming new plots are cultivated
replace cultivate = 1 if sa1q3==1
merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_landcf.dta", nogen keep(1 3) 
*farmer reported field size for post-planting
gen field_size= area_size*conversion
*farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit
merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_landcf.dta", nogen keep(1 3)
replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.               
la var field_size "Area of plot (ha)"
ren plotid plot_id
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_plot_areas.dta", replace




********************************************************************************
* PLOT DECISION MAKERS *
********************************************************************************

*Using planting data 	
use "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_plot_areas.dta", clear 
gen indiv1 = s11aq6a
gen indiv2 = s11aq6b
gen indiv3 = sa1q11
gen indiv4 = sa1q11b
replace indiv1=indiv3 if indiv1==.
keep hhid plot_id indiv* 
reshape long indiv, i(hhid plot_id) j(id_no)
drop if indiv==.
merge m:1 hhid indiv using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_person_ids.dta", keep(1 3) nogen keepusing(female)
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_dm_ids.dta", replace
gen dm1_gender=female+1 if id_no==1
gen dm1_id = indiv if id_no==1
collapse (mean) female (firstnm) dm1_id dm1_gender, by(hhid plot_id)
gen dm_gender = 3
replace dm_gender = 1 if female==0
replace dm_gender = 2 if female==1
la def dm_gender 1 "Male only" 2 "Female only" 3 "Mixed gender"
*replacing observations without gender of plot manager with gender of HOH
merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_weights.dta", nogen keep(1  3) keepusing (fhh)
replace dm_gender=1 if fhh ==0 & dm_gender==. 
replace dm_gender=2 if fhh ==1 & dm_gender==. 
gen dm_male = dm_gender==1
gen dm_female = dm_gender==2
gen dm_mixed = dm_gender==3
keep plot_id hhid dm* 
la var dm_gender "Gender category of all plot decisionmakers"
//la var dm_primary "Individual ID of main decisionmaker"
la var dm1_gender "Gender of main decisionmaker"
la def genderlab 1 "Male" 2 "Female" 3 "Mixed"
la val dm_gender genderlab
la val dm1_gender genderlab
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_plot_decision_makers", replace





********************************************************************************
*formalized land rights*
********************************************************************************
use "${Nigeria_GHS_W2_raw_data}/sect11b1_plantingw2.dta", clear
*DYA.11.21.2020  we need to recode . to 0 or exclude them as . as treated as very large numbers in Stata
gen formal_land_rights=1 if (s11b1q8>=1 & s11b1q8!=.) | (s11b1q10a>=1 & s11b1q10a!=.)  | (s11b1q10b>=1 & s11b1q10b!=.) | (s11b1q10c>=1 & s11b1q10c!=.) | (s11b1q10d>=1 & s11b1q10d!=.)								// Note: Including anything other than "no documents" as formal
*Individual level (for women)
*Starting with first owner
preserve
ren s11b1q6a indiv
merge m:1 hhid indiv using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_person_ids.dta", nogen keep(3)		
keep hhid indiv female formal_land_rights
tempfile p1
save `p1', replace
restore
*Now second owner
preserve
ren s11b1q6b indiv		
merge m:1 hhid indiv using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_person_ids.dta", nogen keep(3)		
keep hhid indiv female
append using `p1'
gen formal_land_rights_f = formal_land_rights==1 if female==1
collapse (max) formal_land_rights_f, by(hhid indiv)		
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_land_rights_ind.dta", replace
restore	
collapse (max) formal_land_rights_hh=formal_land_rights, by(hhid)		// taking max at household level; equals one if they have official documentation for at least one plot
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_land_rights_hh.dta", replace




********************************************************************************
*crop unit conversion factors
********************************************************************************
use "${Nigeria_GHS_W2_raw_data}/w2agnsconversion", clear
ren cropcode crop_code
ren nscode unit_cd
drop if kg==0
ren conversion  conv_fact
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_ng3_cf.dta", replace






********************************************************************************
*ALL PLOTS
********************************************************************************
use "${Nigeria_GHS_W2_raw_data}/secta3_harvestW2.dta", clear
	keep if sa3q3==1
	ren sa3q11a qty1
	ren sa3q11b unit_cd1
	ren sa3q12 value1
	replace unit_cd1 = sa3q6a2 if unit_cd1==.
	replace qty1=sa3q6a1 if unit_cd1!=. & unit_cd1==sa3q6a2 & (qty1==0 | qty1==.)
	replace qty1 = . if unit_cd1==. | qty1==0 

	ren sa3q16a qty2
	ren sa3q16b unit_cd2
	ren sa3q17 value2 
	keep zone state lga sector ea hhid cropcode qty* unit_cd* value*
	gen dummy = _n
	reshape long qty unit_cd value, i(zone state lga sector ea hhid cropcode dummy) j(idno)
	drop idno dummy //not necessary
	merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_weights.dta", nogen keepusing(weight_pop_rururb)
	gen weight = weight_pop_rururb*qty 
	ren cropcode crop_code
	gen price_unit = value/qty
	gen obs=price_unit!=.
	foreach i in zone state lga ea hhid {
		preserve
		collapse (median) price_unit_`i'=price_unit (rawsum) obs_`i'_price=obs [aw=weight], by (`i' unit_cd crop_code) 
		tempfile price_unit_`i'_median
		save `price_unit_`i'_median'
		restore
	}
	preserve
	collapse (median) price_unit_country = price_unit (rawsum) obs_country_price=obs [aw=weight], by(crop_code unit_cd)
	tempfile price_unit_country_median
	//save `price_unit_country_median'
	save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_crop_prices_median_country.dta", replace
	restore
	merge m:1 crop_code unit_cd using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_ng3_cf.dta", nogen keep(1 3)
	replace conv_fact=1 if unit==1 & conv_fact==.
	replace conv_fact=0.001 if unit==2 & conv_fact==. 
	//ren cropcode crop_code
	gen qty_kg = qty*conv_fact 
	drop if qty_kg==. //34 dropped; largely basin and bowl.
	gen price_kg = value/qty_kg
	drop obs
	gen obs=price_kg !=.
	keep if obs == 1
	replace weight = weight_pop_rururb*qty_kg
	foreach i in zone state lga ea hhid {
		preserve
		collapse (median) price_kg_`i'=price_kg (rawsum) obs_`i'_pkg=obs [aw=weight], by (`i' crop_code)
		tempfile price_kg_`i'_median
		save `price_kg_`i'_median'
		restore
	}
	collapse (median) price_kg_country = price_kg (rawsum) obs_country_pkg=obs [aw=weight], by(crop_code)
	tempfile price_kg_country_median
	save `price_kg_country_median'

use "${Nigeria_GHS_W2_raw_data}/sect11f_plantingW2.dta", clear
merge 1:1 hhid plotid cropid using "${Nigeria_GHS_W2_raw_data}/sect11g_plantingW2.dta", nogen 
	ren cropcode crop_code_11f
	gen perm_crop=(s11gq2!=.)
	gen number_trees_planted = s11gq2
	replace number_trees_planted=. if number_trees_planted==999 //999 = farmer doesn't know. Still a permanent crop, we just don't know how many there are. Attempting to estimate based on normal stand densities is unreliable.
	merge 1:1 hhid plotid /*cropcode*/ cropid using "${Nigeria_GHS_W2_raw_data}/secta3_harvestW2.dta"
	ren plotid plot_id
	drop if strpos(sa3q4b, "BEFORE") | strpos(sa3q4b, "PP") | strpos(sa3q4b, "P.") | strpos(sa3q4b, "ALREADY") | strpos(sa3q4b, "BEEFORE") | strpos(sa3q4b, "BEFORRE") //Drop crops that were completely harvested prior to previous interview.
	
	ren cropcode crop_code_a3i //i.e., if harvested units are different from planted units
	//Consolidating cropcodes
	replace crop_code_11f=crop_code_a3i if crop_code_11f==.
	gen crop_code_master =crop_code_11f //Generic level
	ren crop_code_11f crop_code
	drop crop_code_a3i
	recode crop_code_master (1053=1050) (1061 1062 = 1060) (1081 1082=1080) (1091 1092 1093 = 1090) (1111=1110) (2191 2192 2193=2190) /*Counting this generically as pumpkin, but it is different commodities
	*/				 (3181 3182 3183 3184 = 3180) (2170=2030) (3113 3112 3111 = 3110) (3022=3020) (2142 2141 = 2140) (1121 1122 1123 1124 =1120) //Lumping three-leaved yams for price & unit conversions.
	la values crop_code_master SECTA3_Q2
	gen area_unit=s11fq1b
	replace area_unit=s11gq1b if area_unit==.
	merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_landcf.dta", nogen keep(1 3)
	gen ha_planted = s11fq1a*conversion
	replace ha_planted = s11gq1a*conversion if ha_planted==.
	drop conversion area_unit
	ren sa3q5b area_unit
	merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_landcf.dta", nogen keep(1 3)
	gen ha_harvest = sa3q5a*conversion
	merge m:1 hhid plot_id using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_plot_areas.dta", nogen keep(1 3) //keepusing(field_size)
	replace ha_harvest = ha_planted if perm_crop==1 & s11gq8a!=0 & s11gq8a!=. & ha_planted!=.
	replace ha_planted = ha_harvest if ha_planted==. & ha_harvest!=. & ha_harvest!=0 

	preserve
		gen obs=1
		//replace obs=0 if inrange(sa3q4,1,5) & perm_crop!=1
		collapse (max) crops_plot=obs, by(hhid plot_id crop_code)
		collapse (sum) crops_plot, by(hhid plot_id)
		tempfile ncrops 
		save `ncrops'
	restore //286 plots have >1 crop but list monocropping, 382 say intercropping; meanwhile 130 list intercropping or mixed cropping but only report one crop
	merge m:1 hhid plot_id using `ncrops', nogen
	
	
	
	
	
	gen purestand = crops_plot==1 //This includes replanted crops
	replace perm_crop = 1 if crop_code_master==1020 //I don't see any indication that cassava is grown as a seasonal crop in Nigeria
	
	gen percent_field=ha_planted/field_size
	gen pct_harv = ha_harvest/ha_planted 
	replace pct_harv = 1 if ha_harv > ha_planted & ha_harv!=.
	replace pct_harv = 0 if pct_harv==. & sa3q4 < 6
	
*Generating total percent of purestand and monocropped on a field
	bys hhid plot_id: egen tot_ha_planted = sum(ha_planted)
	replace field_size = tot_ha_planted if field_size==. //assuming crops are filling the plot when plot area is not known.
	replace percent_field = ha_planted/tot_ha_planted if tot_ha_planted >= field_size & purestand==0 //Adding the = to catch plots that were filled in previous line
	replace percent_field = 1 if tot_ha_planted>=field_size & purestand==1
	replace ha_planted = percent_field*field_size if (tot_ha_planted > field_size) & field_size!=. & ha_planted!=.
	replace ha_harvest = pct_harv*ha_planted

	
	*renaming unit code for merge
	ren sa3q6a2 unit_cd 
	//replace unit_cd = s11fq11b if unit_cd==.
	ren sa3q6a1 quantity_harvested
	//replace quantity_harvested = s11fq11a if quantity_harvested==.
	*merging in conversion factors
	merge m:1 crop_code unit_cd using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_ng3_cf.dta", keep(1 3) gen(cf_merge)
	
	//ALT: Back-converting processed palm oil into oil palm fruit kg from code I wrote for W4
	replace quantity_harvested = quantity_harvested*0.89*10 if crop_code==3180 & unit_cd==91
	replace quantity_harvested = quantity_harvested*0.89*20 if crop_code==3180 & unit_cd==92
	replace quantity_harvested = quantity_harvested*0.89*25 if crop_code==3180 & unit_cd==93
	replace quantity_harvested = quantity_harvested*0.89*50 if crop_code==3180 & unit_cd==94
	replace quantity_harvested = quantity_harvested*0.89 if crop_code==3180 & unit==3
	replace quantity_harvested=quantity_harvested/0.17 if crop_code==3180 & inlist(unit_cd,91,92,93,94,3) //Oil content (w/w) of oil palm fruit, 
	replace unit_cd=1 if crop_code==3180 & inlist(unit_cd,91,92,93,94,3)
	replace conv_fact=1 if unit_cd==1
	replace conv_fact=0.001 if unit_cd==2
	//92 entries w/o conversions at this point.
	gen quant_harv_kg= quantity_harvested*conv_fact
	/*
	ren sa3q18 value_harvest
	gen val_unit = value_harvest/quantity_harvested
	gen val_kg = value_harvest/quant_harv_kg
	merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_weights.dta", nogen keep(1 3)
	gen plotweight = ha_planted*weight_pop_rururb
	
	gen obs=quantity_harvested>0 & quantity_harvested!=.
	foreach i in zone state lga ea hhid {
preserve
	bys crop_code `i' : egen obs_`i'_kg = sum(obs)
	collapse (median) val_kg_`i'=val_kg [aw=plotweight], by (`i' crop_code obs_`i'_kg)
	tempfile val_kg_`i'_median
	save `val_kg_`i'_median'
restore
}
preserve
collapse (median) val_kg_country = val_kg (sum) obs_country_kg=obs [aw=plotweight], by(crop_code)
tempfile val_kg_country_median
save `val_kg_country_median'
restore

foreach i in zone state lga ea hhid {
preserve
	bys `i' crop_code unit_cd : egen obs_`i'_unit = sum(obs)
	collapse (median) val_unit_`i'=val_unit, by (`i' unit_cd crop_code obs_`i'_unit)
	tempfile val_unit_`i'_median
	save `val_unit_`i'_median'
restore
	merge m:1 `i' unit_cd crop_code using `price_unit_`i'_median', nogen keep(1 3)
	merge m:1 `i' unit_cd crop_code using `val_unit_`i'_median', nogen keep(1 3)
	merge m:1 `i' crop_code using `val_kg_`i'_median', nogen keep(1 3)
}
preserve
collapse (median) val_unit_country = val_unit (sum) obs_country_unit=obs [aw=plotweight], by(crop_code unit_cd)
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_crop_prices_median_country.dta", replace //This gets used for self-employment income.
restore

merge m:1 unit_cd crop_code using `price_unit_country_median', nogen keep(1 3)
merge m:1 unit_cd crop_code using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_crop_prices_median_country.dta", nogen keep(1 3)
merge m:1 crop_code using `val_kg_country_median', nogen keep(1 3)
*/
//We're going to prefer observed prices first
foreach i in zone state lga ea hhid {
	merge m:1 `i' unit_cd crop_code using `price_unit_`i'_median', nogen keep(1 3)
	merge m:1 `i' crop_code using `price_kg_`i'_median', nogen keep(1 3)
}

merge m:1 unit_cd crop_code using"${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_crop_prices_median_country.dta", nogen keep(1 3)
merge m:1 crop_code using `price_kg_country_median', nogen keep(1 3)

unab obs_vars : obs_*
foreach var in `obs_vars' {
	recode `var' (.=0)
}
gen price_unit = .
gen price_kg = .

foreach i in country zone state lga ea {
	replace price_unit = price_unit_`i' if obs_`i'_price>9 
	replace price_kg = price_kg_`i' if obs_`i'_pkg>9
}

replace price_unit_hh=price_unit if price_unit_hh==.
replace price_kg_hh=price_kg if price_kg_hh==.
	gen value_harvest = price_unit * quantity_harvested
	replace value_harvest=price_kg*quant_harv_kg if value_harvest==.
	gen value_harvest_hh=price_unit_hh*quantity_harvested
	replace value_harvest_hh=price_kg_hh*quant_harv_kg if value_harvest_hh==.
	gen val_unit = value_harvest/quantity_harvested
	
preserve
	ren unit_cd unit
	collapse (mean) val_unit, by (hhid crop_code unit)
	ren val_unit hh_price_mean
	lab var hh_price_mean "Average price reported for this crop-unit in the household"
	save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_hh_crop_prices_for_wages.dta", replace
restore
	gen no_harvest = sa3q4 >= 6 & sa3q4 <= 10 | strpos(sa3q4b, "MATURE") | strpos(sa3q4b, "NOT DUE") | strpos(sa3q4b, "NOT RIPE") | strpos(sa3q4b, "YET TO")
	
	ren crop_code crop_code_full //We drop this here and report everything as the consolidated crop group, but it could be retained here.
	ren crop_code_master crop_code 
	replace crop_code = 1124 if crop_code_full==1124 //unlumping yams.
	collapse (sum) quant_harv_kg value_harvest* ha_planted ha_harvest number_trees_planted percent_field /*(max) months_grown*/ (max) no_harvest, by(zone state lga sector ea hhid plot_id crop_code purestand field_size gps_meas)
	drop if (ha_planted==0 | ha_planted==.) & (ha_harv==0 | ha_harv==.) & (quant_harv_kg==0)
	replace ha_harvest=. if (ha_harvest==0 & no_harvest==1) | (ha_harvest==0 & quant_harv_kg>0 & quant_harv_kg!=.)
	replace quant_harv_kg = . if quant_harv_kg==0 & no_harvest==1
	replace value_harvest =. if value_harvest==0 & (no_harvest==1 | (quant_harv_kg!=0 & quant_harv_kg!=.))
	drop no_harvest
	recode ha_planted (0=.) 
	bys hhid plot_id : egen percent_area = sum(percent_field)
	bys hhid plot_id : gen percent_inputs = percent_field/percent_area
	drop percent_area //Assumes that inputs are +/- distributed by the area planted. Probably not true for mixedtree/field crops, but reasonable for plots that are all field crops
	//append using `lost_crops'
	//recode lost_crop (.=0)
	//Labor should be weighted by growing season length, though. 
	gen ha_harv_yld=ha_harvest if ha_planted >= 0.05
	gen ha_plan_yld=ha_planted if ha_planted >= 0.05
	merge m:1 hhid plot_id using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_plot_decision_makers.dta", nogen keep(1 3) keepusing(dm*)
	save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_all_plots.dta",replace





















************************
*Geodata Variables
************************

use "${Nigeria_GHS_W2_raw_data}\Geodata Wave 2\NGA_PlotGeovariables_Y2.dta", clear

collapse (max) srtmslp_nga srtm_nga twi_nga, by (hhid)

merge 1:m hhid using "${Nigeria_GHS_W2_raw_data}\Geodata Wave 2\NGA_HouseholdGeovars_Y2.dta"

*merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

*keep if ag_rainy_12==1

ren dist_market dist_market
sum dist_market, detail


collapse (max) dist_market, by (hhid)
sort hhid



merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)
*merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

*keep if ag_rainy_12==1

************winzonrizing total_qty
foreach v of varlist  dist_market  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 1%"
}


tab dist_market
tab dist_market_w, missing
sum dist_market dist_market_w, detail

keep hhid dist_market_w

save "${Nigeria_GHS_W2_created_data}\geodata_2012.dta", replace







****************************
*Subsidized Fertilizer
****************************


use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11d_plantingw2.dta",clear 
*merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

*keep if ag_rainy_12==1
*************Checking to confirm its the subsidized price *******************

*s11dq14 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq26 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq16 s11dq28  qty of inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer






encode s11dq14, gen(institute)
label list institute


encode s11dq26, gen(institute2)
label list institute2




gen pricefert = s11dq19/ s11dq16


gen subsidy_check = pricefert if institute ==1
sum subsidy,detail


gen private_check = pricefert if institute ==4
sum private,detail




*N2 AND N3 IS 4 AND 5 WHILE N1 IS 1
*institute2 is N2 AND N3 2 and 3 WHILE N1 IS 1


*************Getting Subsidized quantity and Dummy Variable *******************
gen subsidy_qty1 = s11dq16 if institute ==4 | institute ==5 //6 
tab subsidy_qty1
gen subsidy_qty2 = s11dq28 if institute2 ==2 | institute2 ==3  //
tab subsidy_qty2


egen subsidy_qty = rowtotal(subsidy_qty1 subsidy_qty2)
tab subsidy_qty,missing
sum subsidy_qty,detail


gen subsidy_dummy = (subsidy_qty !=0)

tab subsidy_dummy, missing

collapse (sum)subsidy_qty (max) subsidy_dummy, by (hhid)



merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)
*merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

*keep if ag_rainy_12==1

************winzonrizing subsidy_qty
foreach v of varlist  subsidy_qty  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 1%"
}

tab subsidy_qty
tab subsidy_qty_w, missing
sum subsidy_qty subsidy_qty_w, detail







keep hhid  subsidy_qty_w

save "${Nigeria_GHS_W2_created_data}\subsidized_fert_2012.dta", replace




***************************************************
*Transport Cost
***************************************************



use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11d_plantingw2.dta",clear  
*merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

*keep if ag_rainy_12==1


encode s11dq14, gen(institute)
label list institute


encode s11dq26, gen(institute2)
label list institute2

gen tp1 = s11dq17 if institute ==1
tab tp1
gen tp2 = s11dq31  if institute2 ==1
tab tp2

egen transport = rowtotal(tp1 tp2)



collapse  (sum) transport, by(hhid)
merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)
*merge m:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)

*keep if ag_rainy_12==1


************winzonrizing fertilizer market price
foreach v of varlist  transport  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}

sum transport transport_w, detail

gen transport_cost = transport_w    /0.236945
sum transport_cost, detail
keep hhid transport_cost

save "${Nigeria_GHS_W2_created_data}\transport.dta", replace




*********************************************** 
*Purchased Fertilizer
***********************************************

use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11d_plantingw2.dta",clear  

*s11dq14 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq26 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq16 s11dq28  qty of inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer




encode s11dq14, gen(institute)
label list institute


encode s11dq26, gen(institute2)
label list institute2




***fertilzer total quantity, total value & total price****

gen private_fert1_qty = s11dq16 if institute ==1
tab private_fert1_qty, missing
gen private_fert2_qty = s11dq28 if institute2 ==1
tab private_fert2_qty,missing

gen private_fert1_val = s11dq19 if institute ==1
tab private_fert1_val,missing
gen private_fert2_val = s11dq29 if institute2 ==1
tab private_fert2_val,missing

egen total_qty = rowtotal(private_fert1_qty private_fert2_qty)
tab  total_qty, missing

egen total_valuefert = rowtotal(private_fert1_val private_fert2_val)
tab total_valuefert,missing

gen tpricefert = total_valuefert/total_qty
tab tpricefert



gen tpricefert_cens = tpricefert
replace tpricefert_cens = 600 if tpricefert_cens > 600 & tpricefert_cens < . //winzorizing at top 5%
replace tpricefert_cens = 12 if tpricefert_cens < 12
tab tpricefert_cens, missing  //winzorizing at bottom 5%


egen medianfert_pr_ea = median(tpricefert_cens), by (ea)

egen medianfert_pr_lga = median(tpricefert_cens), by (lga)

egen num_fert_pr_ea = count(tpricefert_cens), by (ea)

egen num_fert_pr_lga = count(tpricefert_cens), by (lga)

egen medianfert_pr_state = median(tpricefert_cens), by (state)
egen num_fert_pr_state = count(tpricefert_cens), by (state)

egen medianfert_pr_zone = median(tpricefert_cens), by (zone)
egen num_fert_pr_zone = count(tpricefert_cens), by (zone)



tab medianfert_pr_ea
tab medianfert_pr_lga
tab medianfert_pr_state
tab medianfert_pr_zone



tab num_fert_pr_ea
tab num_fert_pr_lga
tab num_fert_pr_state
tab num_fert_pr_zone

gen tpricefert_cens_mrk = tpricefert_cens

replace tpricefert_cens_mrk = medianfert_pr_ea if tpricefert_cens_mrk ==. & num_fert_pr_ea >= 7

tab tpricefert_cens_mrk,missing


replace tpricefert_cens_mrk = medianfert_pr_lga if tpricefert_cens_mrk ==. & num_fert_pr_lga >= 7

tab tpricefert_cens_mrk,missing



replace tpricefert_cens_mrk = medianfert_pr_state if tpricefert_cens_mrk ==. & num_fert_pr_state >= 7

tab tpricefert_cens_mrk,missing


replace tpricefert_cens_mrk = medianfert_pr_zone if tpricefert_cens_mrk ==. & num_fert_pr_zone >= 7
*/
tab tpricefert_cens_mrk,missing


***************
*organic fertilizer
***************
gen org_fert = 1 if  s11dq3==3 | s11dq7==3 | s11dq15==3 |  s11dq27==3
tab org_fert, missing
replace org_fert = 0 if org_fert==.
tab org_fert, missing




collapse zone lga sector ea (sum) total_qty total_valuefert (max)  org_fert tpricefert_cens_mrk, by(hhid)


merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)



************winzonrizing total_qty
foreach v of varlist  total_qty  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 1%"
}


tab total_qty
tab total_qty_w, missing
sum total_qty total_qty_w, detail




************winzonrizing fertilizer market price
foreach v of varlist  tpricefert_cens_mrk  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}

sum tpricefert_cens_mrk tpricefert_cens_mrk_w, detail

gen rea_tpricefert_cens_mrk = tpricefert_cens_mrk_w   /0.236945
gen real_tpricefert_cens_mrk = rea_tpricefert_cens_mrk
replace real_tpricefert_cens_mrk= 364 if hhid == 10062 
replace real_tpricefert_cens_mrk= 286 if hhid == 20064 
tab real_tpricefert_cens_mrk
sum real_tpricefert_cens_mrk, detail


keep hhid zone lga sector ea org_fert total_qty_w total_valuefert real_tpricefert_cens_mrk

sort hhid
save "${Nigeria_GHS_W2_created_data}\purchased_fert_2012.dta", replace




******************************* 
*Extension Visit 
*******************************



use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11l1_plantingw2.dta",clear  


ren s11l1q1 ext_acess

tab ext_acess, missing
tab ext_acess, nolabel

replace ext_acess = 0 if ext_acess==2 | ext_acess==.
tab ext_acess, missing
collapse (max) ext_acess, by (hhid)
la var ext_acess "=1 if received advise from extension services"
save "${Nigeria_GHS_W2_created_data}\extension_visit_2012.dta", replace





*****************************
*Community 
****************************

use "${Nigeria_GHS_W2_raw_data}\Post Harvest Wave 2\Community\sectc2_harvestw2.dta", clear

*is_cd  219 for market infrastructure
*c2q3  distance to infrastructure in km

gen mrk_dist = c2q3 if is_cd==219
tab mrk_dist,missing
egen median_lga = median(mrk_dist), by (zone state lga)
egen median_state = median(mrk_dist), by (zone state)
egen median_zone = median(mrk_dist), by (zone)


replace mrk_dist =0 if is_cd==219 & mrk_dist==. & c2q1==1
tab mrk_dist if is_cd==219, missing

replace mrk_dist = median_lga if mrk_dist==. & is_cd==219
replace mrk_dist = median_state if mrk_dist==. & is_cd==219
replace mrk_dist = median_zone if mrk_dist==. & is_cd==219
tab mrk_dist if is_cd==219, missing

*replace mrk_dist= 45 if mrk_dist>=45 & mrk_dist<. & is_cd==219
*tab mrk_dist if is_cd==219, missing

sort zone state ea
collapse (max) median_lga median_state median_zone mrk_dist, by (zone state lga sector ea)
replace mrk_dist = median_lga if mrk_dist ==.
tab mrk_dist, missing
replace mrk_dist = median_state if mrk_dist ==.
tab mrk_dist, missing
replace mrk_dist = median_zone if mrk_dist ==.
tab mrk_dist, missing
la var mrk_dist "=distance to the market"

save "${Nigeria_GHS_W2_created_data}\market_distance.dta", replace 






*********************************
*Demographics 
*********************************

use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Household\sect1_plantingw2.dta",clear 

merge 1:1 hhid indiv using "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Household\sect2_plantingw2.dta", gen(household)

merge m:1 zone state lga sector ea using "${Nigeria_GHS_W2_created_data}\market_distance.dta", keepusing (median_lga median_state median_zone mrk_dist)

**************
*market distance
*************
replace mrk_dist = median_lga if mrk_dist==.
tab mrk_dist, missing

replace mrk_dist = median_state if mrk_dist==.
tab mrk_dist, missing

replace mrk_dist = median_zone if mrk_dist==.
tab mrk_dist, missing




*s1q2   sex
*s1q3   relationship to hhead
*s1q6   age in years




sort hhid indiv 
 
gen num_mem = 1



******** female head****

gen femhead = 0
replace femhead = 1 if s1q2== 2 & s1q3==1
tab femhead,missing

********Age of HHead***********
ren s1q6 hh_age
gen hh_headage = hh_age if s1q3==1

tab hh_headage

replace hh_headage = 100 if hh_headage > 100 & hh_headage < .
tab hh_headage
tab hh_headage, missing

************generating the median age**************

egen medianhh_pr_ea = median(hh_headage), by (ea)

egen medianhh_pr_lga = median(hh_headage), by (lga)

egen num_hh_pr_ea = count(hh_headage), by (ea)

egen num_hh_pr_lga = count(hh_headage), by (lga)

egen medianhh_pr_state = median(hh_headage), by (state)
egen num_hh_pr_state = count(hh_headage), by (state)

egen medianhh_pr_zone = median(hh_headage), by (zone)
egen num_hh_pr_zone = count(hh_headage), by (zone)


tab medianhh_pr_ea
tab medianhh_pr_lga
tab medianhh_pr_state
tab medianhh_pr_zone



tab num_hh_pr_ea
tab num_hh_pr_lga
tab num_hh_pr_state
tab num_hh_pr_zone



replace hh_headage = medianhh_pr_ea if hh_headage ==. & num_hh_pr_ea >= 30

tab hh_headage,missing


replace hh_headage = medianhh_pr_lga if hh_headage ==. & num_hh_pr_lga >= 30

tab hh_headage,missing



replace hh_headage = medianhh_pr_state if hh_headage ==. & num_hh_pr_state >= 30

tab hh_headage,missing


replace hh_headage = medianhh_pr_zone if hh_headage ==. & num_hh_pr_zone >= 30

tab hh_headage,missing

sum hh_headage, detail


********************Education****************************************************

*s2q5  1= attended school
*s2q8  highest education level
*s1q3 relationship to hhead


ren s2q5 attend_sch
tab attend_sch
replace attend_sch = 0 if attend_sch ==2
tab attend_sch, nolabel
*tab s1q4 if s2q7==.

replace s2q8= 0 if attend_sch==0
tab s2q8
tab s1q3 if _merge==1

tab s2q8 if s1q3==1
replace s2q8 = 16 if s2q8==. &  s1q3==1

*** Education Dummy Variable*****

 label list S2Q8

gen pry_edu = 1 if s2q8 >= 1 & s2q8 < 16 & s1q3==1
gen finish_pry = 1 if s2q8 >= 16 & s2q8 < 26 & s1q3==1
gen finish_sec = 1 if s2q8 >= 26 & s2q8 < 43 & s1q3==1

replace pry_edu =0 if pry_edu==. & s1q3==1
replace finish_pry =0 if finish_pry==. & s1q3==1
replace finish_sec =0 if finish_sec==. & s1q3==1
tab pry_edu if s1q3==1 , missing
tab finish_pry if s1q3==1 , missing 
tab finish_sec if s1q3==1 , missing

collapse (sum) num_mem (max) mrk_dist hh_headage femhead attend_sch pry_edu finish_pry finish_sec, by (hhid)

merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)


tab mrk_dist
************winzonrizing distance to market
foreach v of varlist  mrk_dist  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}


tab mrk_dist
tab mrk_dist_w, missing
sum mrk_dist mrk_dist_w, detail


keep hhid mrk_dist_w num_mem femhead hh_headage attend_sch pry_edu finish_pry finish_sec

tab attend_sch, missing
egen mid_attend= median(attend_sch)
replace attend_sch = mid_attend if attend_sch==.

tab pry_edu, missing
tab finish_pry, missing
tab finish_sec, missing

egen mid_pry_edu= median(pry_edu)
egen mid_finish_pry= median(finish_pry)
egen mid_finish_sec= median(finish_sec)

replace pry_edu = mid_pry_edu if pry_edu==.
replace finish_pry = mid_finish_pry if finish_pry==.
replace finish_sec = mid_finish_sec if finish_sec==.



la var num_mem "household size"
la var mrk_dist_w "distance to the nearest market in km"
la var femhead "=1 if head is female"
la var hh_headage "age of household head in years"
la var attend_sch "=1 if respondent attended school"
la var pry_edu "=1 if household head attended pry school"
la var finish_pry "=1 if household head finished pry school"
la var finish_sec "=1 if household head finished sec school"
save "${Nigeria_GHS_W2_created_data}\demographics_2012.dta", replace


**************************************
*Food Prices
**************************************
use "${Nigeria_GHS_W2_raw_data}\Post Harvest Wave 2\Community\sectc8_harvestw2.dta", clear



gen maize_price=c8q2 if item_cd==3
tab maize_price,missing
sum maize_price,detail
tab maize_price

replace maize_price = 900 if maize_price >900 & maize_price<.  //bottom 2%



egen median_pr_ea = median(maize_price), by (ea)
egen median_pr_lga = median(maize_price), by (lga)
egen median_pr_state = median(maize_price), by (state)
egen median_pr_zone = median(maize_price), by (zone)

egen num_pr_ea = count(maize_price), by (ea)
egen num_pr_lga = count(maize_price), by (lga)
egen num_pr_state = count(maize_price), by (state)
egen num_pr_zone = count(maize_price), by (zone)

tab num_pr_ea
tab num_pr_lga
tab num_pr_state
tab num_pr_zone


gen maize_price_mr = maize_price

replace maize_price_mr = median_pr_ea if maize_price_mr==. & num_pr_ea>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_lga if maize_price_mr==. & num_pr_lga>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_state if maize_price_mr==. & num_pr_state>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_zone if maize_price_mr==. & num_pr_zone>=2
tab maize_price_mr,missing



****************
*rice price
***************


gen rice_price=c8q2 if item_cd==7
tab rice_price,missing
sum rice_price,detail
tab rice_price

replace rice_price = 750 if rice_price >750 & rice_price<.   //top 2%
tab rice_price,missing



egen median_rice_ea = median(rice_price), by (ea)
egen median_rice_lga = median(rice_price), by (lga)
egen median_rice_state = median(rice_price), by (state)
egen median_rice_zone = median(rice_price), by (zone)

egen num_rice_ea = count(rice_price), by (ea)
egen num_rice_lga = count(rice_price), by (lga)
egen num_rice_state = count(rice_price), by (state)
egen num_rice_zone = count(rice_price), by (zone)

tab num_rice_ea
tab num_rice_lga
tab num_rice_state
tab num_rice_zone


gen rice_price_mr = rice_price

replace rice_price_mr = median_rice_ea if rice_price_mr==. & num_rice_ea>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_lga if rice_price_mr==. & num_rice_lga>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_state if rice_price_mr==. & num_rice_state>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_zone if rice_price_mr==. & num_rice_zone>=2
tab rice_price_mr,missing


sort zone state ea
collapse (max) maize_price_mr rice_price_mr , by (zone state lga sector ea)


save "${Nigeria_GHS_W2_created_data}\food_prices.dta", replace

use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Household\sect7b_plantingw2.dta", clear
merge m:1 zone state lga sector ea using "${Nigeria_GHS_W2_created_data}\food_prices.dta", keepusing ( maize_price_mr rice_price_mr)

**********
*maize
*********
egen median_pr_ea = median(maize_price), by (ea)
egen median_pr_lga = median(maize_price), by (lga)
egen median_pr_state = median(maize_price), by (state)
egen median_pr_zone = median(maize_price), by (zone)

egen num_pr_ea = count(maize_price), by (ea)
egen num_pr_lga = count(maize_price), by (lga)
egen num_pr_state = count(maize_price), by (state)
egen num_pr_zone = count(maize_price), by (zone)

tab num_pr_ea
tab num_pr_lga
tab num_pr_state
tab num_pr_zone



replace maize_price_mr = median_pr_ea if maize_price_mr==. & num_pr_ea>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_lga if maize_price_mr==. & num_pr_lga>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_state if maize_price_mr==. & num_pr_state>=2
tab maize_price_mr,missing

replace maize_price_mr = median_pr_zone if maize_price_mr==. & num_pr_zone>=2
tab maize_price_mr,missing


****************
*rice price
***************


egen median_rice_ea = median(rice_price), by (ea)
egen median_rice_lga = median(rice_price), by (lga)
egen median_rice_state = median(rice_price), by (state)
egen median_rice_zone = median(rice_price), by (zone)

egen num_rice_ea = count(rice_price), by (ea)
egen num_rice_lga = count(rice_price), by (lga)
egen num_rice_state = count(rice_price), by (state)
egen num_rice_zone = count(rice_price), by (zone)

tab num_rice_ea
tab num_rice_lga
tab num_rice_state
tab num_rice_zone



replace rice_price_mr = median_rice_ea if rice_price_mr==. & num_rice_ea>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_lga if rice_price_mr==. & num_rice_lga>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_state if rice_price_mr==. & num_rice_state>=2
tab rice_price_mr,missing

replace rice_price_mr = median_rice_zone if rice_price_mr==. & num_rice_zone>=2
tab rice_price_mr,missing

collapse  (max) maize_price_mr rice_price_mr, by(hhid)

gen rea_maize_price_mr = maize_price_mr   /0.236945
gen real_maize_price_mr = rea_maize_price_mr
tab real_maize_price_mr
sum real_maize_price_mr, detail
gen rea_rice_price_mr = rice_price_mr   /0.236945
gen real_rice_price_mr = rea_rice_price_mr
tab real_rice_price_mr
sum real_rice_price_mr, detail

sort hhid
save "${Nigeria_GHS_W2_created_data}\food_prices_2012.dta", replace





*****************************
*Household Assests
****************************



use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Household\sect5a_plantingw2.dta",clear 

sort hhid item_cd

collapse (sum) s5q1, by (zone state lga ea hhid item_cd)
tab item_cd,missing
save "${Nigeria_GHS_W2_created_data}\item_qty_2012.dta", replace


use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Household\sect5b_plantingw2.dta",clear 
sort hhid item_cd
collapse (mean) s5q4, by (zone state lga ea hhid item_cd)
tab item_cd
save "${Nigeria_GHS_W2_created_data}\item_cost_2012.dta", replace

*******************Merging assest***********************
sort hhid item_cd
merge 1:1 hhid item_cd using "${Nigeria_GHS_W2_created_data}\item_qty_2012.dta", keepusing (zone state lga ea s5q1)
drop _merge

gen hhasset_value = s5q4*s5q1
tab hhasset_value


replace hhasset_value=. if hhasset_value==0

/*
replace hhasset_value = 1000000 if hhasset_value > 1000000 & hhasset_value <.  //bottom 2%
replace hhasset_value = 100 if hhasset_value <100  //top 2%
*/

sum hhasset_value, detail

tab hhasset_value,missing





collapse (sum) hhasset_value, by (hhid)


merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)


foreach v of varlist  hhasset_value  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}


tab hhasset_value
tab hhasset_value_w, missing
sum hhasset_value hhasset_value_w, detail


*Winzorized variables**

*winsor2 hhasset_value, suffix(_s) cuts(5 95) 

*summarize  hhasset_value_w hhasset_value_s , detail

gen rea_hhvalue = hhasset_value_w    /0.236945
gen real_hhvalue = rea_hhvalue/1000
sum hhasset_value_w real_hhvalue, detail


keep  hhid real_hhvalue


la var real_hhvalue "total value of household asset"
save "${Nigeria_GHS_W2_created_data}\asset_value_2012.dta", replace





 ********************************************************************************
* PLOT AREAS *
********************************************************************************
*starting with planting
clear


*using conversion factors from LSMS-ISA Nigeria Wave 2 Basic Information Document (Waves 1 & 2 are identical)
*found at http://econ.worldbank.org/WBSITE/EXTERNAL/EXTDEC/EXTRESEARCH/EXTLSMS/0,,contentMDK:23635560~pagePK:64168445~piPK:64168309~theSitePK:3358997,00.html
*General Conversion Factors to Hectares
//		Zone   Unit         Conversion Factor
//		All    Plots        0.0667
//		All    Acres        0.4
//		All    Hectares     1
//		All    Sq Meters    0.0001
*Zone Specific Conversion Factors to Hectares
//		Zone           Conversion Factor
//				 Heaps      Ridges      Stands
//		1 		 0.00012 	0.0027 		0.00006
//		2 		 0.00016 	0.004 		0.00016
//		3 		 0.00011 	0.00494 	0.00004
//		4 		 0.00019 	0.0023 		0.00004
//		5 		 0.00021 	0.0023 		0.00013
//		6  		 0.00012 	0.00001 	0.00041
set obs 42 //6 zones x 7 units
egen zone=seq(), f(1) t(6) b(7)
egen area_unit=seq(), f(1) t(7)
gen conversion=1 if area_unit==6
gen area_size=1 //This makes it easy for me to copy-paste existing code rather than having to write a new block
replace conversion = area_size*0.0667 if area_unit==4									//reported in plots
replace conversion = area_size*0.404686 if area_unit==5		    						//reported in acres
replace conversion = area_size*0.0001 if area_unit==7									//reported in square meters

replace conversion = area_size*0.00012 if area_unit==1 & zone==1						//reported in heaps
replace conversion = area_size*0.00016 if area_unit==1 & zone==2
replace conversion = area_size*0.00011 if area_unit==1 & zone==3
replace conversion = area_size*0.00019 if area_unit==1 & zone==4
replace conversion = area_size*0.00021 if area_unit==1 & zone==5
replace conversion = area_size*0.00012 if area_unit==1 & zone==6

replace conversion = area_size*0.0027 if area_unit==2 & zone==1							//reported in ridges
replace conversion = area_size*0.004 if area_unit==2 & zone==2
replace conversion = area_size*0.00494 if area_unit==2 & zone==3
replace conversion = area_size*0.0023 if area_unit==2 & zone==4
replace conversion = area_size*0.0023 if area_unit==2 & zone==5
replace conversion = area_size*0.00001 if area_unit==2 & zone==6

replace conversion = area_size*0.00006 if area_unit==3 & zone==1						//reported in stands
replace conversion = area_size*0.00016 if area_unit==3 & zone==2
replace conversion = area_size*0.00004 if area_unit==3 & zone==3
replace conversion = area_size*0.00004 if area_unit==3 & zone==4
replace conversion = area_size*0.00013 if area_unit==3 & zone==5
replace conversion = area_size*0.00041 if area_unit==3 & zone==6

drop area_size
save "${Nigeria_GHS_W2_created_data}\land_cf.dta", replace

 
 
 
 
 
 
 *************** Plot Size **********************

use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11a1_plantingw2",clear  
*merging in planting section to get cultivated status

merge 1:1 hhid plotid using  "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11b1_plantingw2"
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W2_raw_data}\Post Harvest Wave 2\Agriculture\secta1_harvestw2.dta", gen(plot_merge)


ren s11aq4a area_size
ren s11aq4b area_unit
ren sa1q9a area_size2
ren sa1q9b area_unit2
ren s11aq4c area_meas_sqm
ren sa1q9c area_meas_sqm2
gen cultivate = s11b1q27 ==1 
*assuming new plots are cultivated
replace cultivate = 1 if sa1q3==1

******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}\land_cf.dta", nogen keep(1 3) 


gen field_size= area_size*conversion
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
 
 
 ***************Measurement in hectares for the additional plots from post-harvest************
 *farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit
******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}\land_cf.dta", nogen keep(1 3) 


replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.                
la var field_size "Area of plot (ha)"
ren plotid plot_id
sum field_size, detail
*Total land holding including cultivated and rented out
collapse (sum) field_size, by (hhid)

merge 1:1 hhid using  "${Nigeria_GHS_W2_created_data}/weight.dta", gen (wgt)


foreach v of varlist  field_size  {
	_pctile `v' [aw=weight] , p(5 99) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top 5% & bottom 1%"
}

tab field_size
tab field_size_w, missing
sum field_size field_size_w, detail



sort hhid
ren field_size_w land_holding
keep hhid land_holding
label var land_holding "land holding in hectares"
save "${Nigeria_GHS_W2_created_data}\land_holding_2012.dta", replace

 




*******************************
*Soil Quality
*******************************

use "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11a1_plantingw2",clear  
*merging in planting section to get cultivated status

merge 1:1 hhid plotid using  "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11b1_plantingw2"
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W2_raw_data}\Post Harvest Wave 2\Agriculture\secta1_harvestw2.dta", gen(plot_merge)


ren s11aq4a area_size
ren s11aq4b area_unit
ren sa1q9a area_size2
ren sa1q9b area_unit2
ren s11aq4c area_meas_sqm
ren sa1q9c area_meas_sqm2
gen cultivate = s11b1q27 ==1 
*assuming new plots are cultivated
replace cultivate = 1 if sa1q3==1

******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}\land_cf.dta", nogen keep(1 3) 


gen field_size= area_size*conversion
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
 
 
 ***************Measurement in hectares for the additional plots from post-harvest************
 *farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit
******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W2_created_data}\land_cf.dta", nogen keep(1 3) 


replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.                
la var field_size "Area of plot (ha)"
sum field_size, detail
*Total land holding including cultivated and rented out
keep zone state lga sector ea hhid plotid field_size

merge 1:1 hhid plotid using "${Nigeria_GHS_W2_raw_data}\Post Planting Wave 2\Agriculture\sect11b1_plantingw2.dta"


ren s11b1q45 soil_quality
tab soil_quality, missing



egen max_fieldsize = max(field_size), by (hhid)
replace max_fieldsize= . if max_fieldsize!= max_fieldsize
order field_size soil_quality hhid max_fieldsize
sort hhid
keep if field_size== max_fieldsize
sort hhid plotid field_size

duplicates report hhid

duplicates tag hhid, generate(dup)
tab dup
list field_size soil_quality dup


list hhid plotid field_size soil_quality dup if dup>0

egen soil_qty_rev = max(soil_quality) 
gen soil_qty_rev3 = soil_quality

replace soil_qty_rev3 = soil_qty_rev if dup>0

list hhid plotid  field_size soil_quality soil_qty_rev soil_qty_rev3 dup if dup>0


gen good_soil = (soil_qty_rev3==1)
gen fairr_soil = (soil_qty_rev3==2)
egen med_soil = median(soil_qty_rev3)

egen med_soil_ea = median(soil_qty_rev3), by (ea)
egen med_soil_lga = median(soil_qty_rev3), by (lga)
egen med_soil_state = median(soil_qty_rev3), by (state)
egen med_soil_zone = median(soil_qty_rev3), by (zone)

replace soil_qty_rev3= med_soil_ea if soil_qty_rev3==.
tab soil_qty_rev3, missing
replace soil_qty_rev3= med_soil_lga if soil_qty_rev3==.
tab soil_qty_rev3, missing
replace soil_qty_rev3= med_soil_state if soil_qty_rev3==.
tab soil_qty_rev3, missing
replace soil_qty_rev3= med_soil_zone if soil_qty_rev3==.
tab soil_qty_rev3, missing


replace soil_qty_rev3= med_soil if soil_qty_rev3==.
tab soil_qty_rev3, missing

tab zone if soil_qty_rev3== 1

collapse (mean) soil_qty_rev3 (max) good_soil fairr_soil , by (hhid)
save "${Nigeria_GHS_W2_created_data}\soil_quality_2012.dta", replace



********************************************************************************
*OFF-FARM HOURS
********************************************************************************
use "${Nigeria_GHS_W2_raw_data}/sect3a_harvestw2.dta", clear
gen  hrs_main_wage_off_farm=s3aq15 if (s3aq11>1 & s3aq11!=.) 	// s3q14 1   is agriculture (exclude mining). 
gen  hrs_sec_wage_off_farm= s3aq27 if (s3aq23>1 & s3aq23!=.) 
egen hrs_wage_off_farm= rowtotal(hrs_main_wage_off_farm hrs_sec_wage_off_farm) 
gen  hrs_main_wage_on_farm=s3aq15 if (s3aq11<=1 & s3aq11!=.)  
gen  hrs_sec_wage_on_farm= s3aq27 if (s3aq23<=1 & s3aq23!=.)  
egen hrs_wage_on_farm= rowtotal(hrs_main_wage_on_farm hrs_sec_wage_on_farm)
egen hrs_unpaid_off_farm= rowtotal(s3aq38)
drop *main* *sec*  
recode s3aq39b1 s3aq39b2 s3aq40b1 s3aq40b2 (.=0) 
gen hrs_domest_fire_fuel=(s3aq39b1+ s3aq39b2/60+s3aq40b1+s3aq40b2/60)*7  // hours worked just yesterday
gen  hrs_ag_activ=.
gen  hrs_self_off_farm=.
egen hrs_off_farm=rowtotal(hrs_wage_off_farm hrs_self_off_farm)
egen hrs_on_farm=rowtotal(hrs_ag_activ hrs_wage_on_farm)
egen hrs_domest_all=rowtotal(hrs_domest_fire_fuel)
egen hrs_other_all=rowtotal(hrs_unpaid_off_farm)
foreach v of varlist hrs_* {
	local l`v'=subinstr("`v'", "hrs", "nworker",.)
	gen  `l`v''=`v'!=0
} 
gen member_count = 1
collapse (sum) nworker_* hrs_*  member_count, by(hhid)
la var member_count "Number of HH members age 5 or above"
la var hrs_unpaid_off_farm  "Total household hours - unpaid activities"
la var hrs_ag_activ "Total household hours - agricultural activities"
la var hrs_wage_off_farm "Total household hours - wage off-farm"
la var hrs_wage_on_farm  "Total household hours - wage on-farm"
la var hrs_domest_fire_fuel  "Total household hours - collecting fuel and making fire"
la var hrs_off_farm  "Total household hours - work off-farm"
la var hrs_on_farm  "Total household hours - work on-farm"
la var hrs_domest_all  "Total household hours - domestic activities"
la var hrs_other_all "Total household hours - other activities"
la var hrs_self_off_farm  "Total household hours - self-employment off-farm"
la var nworker_unpaid_off_farm  "Number of HH members with positve hours - unpaid activities"
la var nworker_ag_activ "Number of HH members with positve hours - agricultural activities"
la var nworker_wage_off_farm "Number of HH members with positve hours - wage off-farm"
la var nworker_wage_on_farm  "Number of HH members with positve hours - wage on-farm"
la var nworker_domest_fire_fuel  "Number of HH members with positve hours - collecting fuel and making fire"
la var nworker_off_farm  "Number of HH members with positve hours - work off-farm"
la var nworker_on_farm  "Number of HH members with positve hours - work on-farm"
la var nworker_domest_all  "Number of HH members with positve hours - domestic activities"
la var nworker_other_all "Number of HH members with positve hours - other activities"
la var nworker_self_off_farm  "Number of HH members with positve hours - self-employment off-farm"
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_off_farm_hours.dta", replace


********************************************************************************
* WAGE INCOME *
********************************************************************************
use "${Nigeria_GHS_W2_raw_data}/sect3a_harvestw2.dta", clear
ren s3aq10b activity_code
ren s3aq11 sector_code
ren s3aq4 mainwage_yesno
ren s3aq13 mainwage_number_months
ren s3aq14 mainwage_number_weeks
ren s3aq15 mainwage_number_hours
ren s3aq18a1 mainwage_recent_payment
gen ag_activity = (sector_code==1)
replace mainwage_recent_payment = . if ag_activity==1 // exclude ag wages 
ren s3aq18a2 mainwage_payment_period
ren s3aq20a mainwage_recent_payment_other
replace mainwage_recent_payment_other = . if ag_activity==1
ren s3aq20b mainwage_payment_period_other
ren s3aq23 sec_sector_code
ren s3aq21 secwage_yesno
ren s3aq25 secwage_number_months
ren s3aq26 secwage_number_weeks
ren s3aq27 secwage_number_hours
ren s3aq30a1 secwage_recent_payment
gen sec_ag_activity = (sec_sector_code==1)
replace secwage_recent_payment = . if sec_ag_activity==1 // exclude ag wages 
ren s3aq30a2 secwage_payment_period
ren s3aq32a secwage_recent_payment_other
replace secwage_recent_payment_other = . if sec_ag_activity==1
ren s3aq32b secwage_payment_period_other
ren s3aq1 worked_as_employee
recode  mainwage_number_months secwage_number_months (12/max=12)
recode  mainwage_number_weeks secwage_number_weeks (52/max=52)
recode  mainwage_number_hours secwage_number_hours (84/max=84)
local vars main sec 
foreach p of local vars {
	replace `p'wage_recent_payment=. if worked_as_employee!=1
	gen `p'wage_salary_cash = `p'wage_recent_payment if `p'wage_payment_period==8
	replace `p'wage_salary_cash = ((`p'wage_number_months/6)*`p'wage_recent_payment) if `p'wage_payment_period==7
	replace `p'wage_salary_cash = ((`p'wage_number_months/4)*`p'wage_recent_payment) if `p'wage_payment_period==6
	replace `p'wage_salary_cash = (`p'wage_number_months*`p'wage_recent_payment) if `p'wage_payment_period==5
	replace `p'wage_salary_cash = (`p'wage_number_months*(`p'wage_number_weeks/2)*`p'wage_recent_payment) if `p'wage_payment_period==4
	replace `p'wage_salary_cash = (`p'wage_number_weeks*`p'wage_recent_payment) if `p'wage_payment_period==3
	replace `p'wage_salary_cash = (`p'wage_number_weeks*(`p'wage_number_hours/8)*`p'wage_recent_payment) if `p'wage_payment_period==2
	replace `p'wage_salary_cash = (`p'wage_number_weeks*`p'wage_number_hours*`p'wage_recent_payment) if `p'wage_payment_period==1

	replace `p'wage_recent_payment_other=. if worked_as_employee!=1
	gen `p'wage_salary_other = `p'wage_recent_payment_other if `p'wage_payment_period_other==8
	replace `p'wage_salary_other = ((`p'wage_number_months/6)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==7
	replace `p'wage_salary_other = ((`p'wage_number_months/4)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==6
	replace `p'wage_salary_other = (`p'wage_number_months*`p'wage_recent_payment_other) if `p'wage_payment_period_other==5
	replace `p'wage_salary_other = (`p'wage_number_months*(`p'wage_number_weeks/2)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==4
	replace `p'wage_salary_other = (`p'wage_number_weeks*`p'wage_recent_payment_other) if `p'wage_payment_period_other==3
	replace `p'wage_salary_other = (`p'wage_number_weeks*(`p'wage_number_hours/8)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==2
	replace `p'wage_salary_other = (`p'wage_number_weeks*`p'wage_number_hours*`p'wage_recent_payment_other) if `p'wage_payment_period_other==1
	recode `p'wage_salary_cash `p'wage_salary_other (.=0)
	gen `p'wage_annual_salary = `p'wage_salary_cash + `p'wage_salary_other
}
gen annual_salary = mainwage_annual_salary + secwage_annual_salary
collapse (sum) annual_salary, by (hhid)
lab var annual_salary "Estimated annual earnings from non-agricultural wage employment over previous 12 months"
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_wage_income.dta", replace

*Ag wage income
use "${Nigeria_GHS_W2_raw_data}/sect3a_harvestw2.dta", clear
ren s3aq10b activity_code
ren s3aq11 sector_code
ren s3aq4 mainwage_yesno
ren s3aq13 mainwage_number_months
ren s3aq14 mainwage_number_weeks
ren s3aq15 mainwage_number_hours
ren s3aq18a1 mainwage_recent_payment
gen ag_activity = (sector_code==1)
replace mainwage_recent_payment = . if ag_activity!=1 // include only ag wages
ren s3aq18a2 mainwage_payment_period
ren s3aq20a mainwage_recent_payment_other
replace mainwage_recent_payment_other = . if ag_activity!=1 // include only ag wages
ren s3aq20b mainwage_payment_period_other
ren s3aq23 sec_sector_code
ren s3aq21 secwage_yesno
ren s3aq25 secwage_number_months
ren s3aq26 secwage_number_weeks
ren s3aq27 secwage_number_hours
ren s3aq30a1 secwage_recent_payment
gen sec_ag_activity = (sec_sector_code==1)
replace secwage_recent_payment = . if sec_ag_activity!=1
ren s3aq30a2 secwage_payment_period
ren s3aq32a secwage_recent_payment_other
replace secwage_recent_payment_other = . if sec_ag_activity!=1 // include only ag wages
ren s3aq32b secwage_payment_period_other
ren s3aq1 worked_as_employee
recode  mainwage_number_months secwage_number_months (12/max=12)
recode  mainwage_number_weeks secwage_number_weeks (52/max=52)
recode  mainwage_number_hours secwage_number_hours (84/max=84)

local vars main sec 
foreach p of local vars {
	replace `p'wage_recent_payment=. if worked_as_employee!=1
	gen `p'wage_salary_cash = `p'wage_recent_payment if `p'wage_payment_period==8
	replace `p'wage_salary_cash = ((`p'wage_number_months/6)*`p'wage_recent_payment) if `p'wage_payment_period==7
	replace `p'wage_salary_cash = ((`p'wage_number_months/4)*`p'wage_recent_payment) if `p'wage_payment_period==6
	replace `p'wage_salary_cash = (`p'wage_number_months*`p'wage_recent_payment) if `p'wage_payment_period==5
	replace `p'wage_salary_cash = (`p'wage_number_months*(`p'wage_number_weeks/2)*`p'wage_recent_payment) if `p'wage_payment_period==4
	replace `p'wage_salary_cash = (`p'wage_number_weeks*`p'wage_recent_payment) if `p'wage_payment_period==3
	replace `p'wage_salary_cash = (`p'wage_number_weeks*(`p'wage_number_hours/8)*`p'wage_recent_payment) if `p'wage_payment_period==2
	replace `p'wage_salary_cash = (`p'wage_number_weeks*`p'wage_number_hours*`p'wage_recent_payment) if `p'wage_payment_period==1

	replace `p'wage_recent_payment_other=. if worked_as_employee!=1
	gen `p'wage_salary_other = `p'wage_recent_payment_other if `p'wage_payment_period_other==8
	replace `p'wage_salary_other = ((`p'wage_number_months/6)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==7
	replace `p'wage_salary_other = ((`p'wage_number_months/4)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==6
	replace `p'wage_salary_other = (`p'wage_number_months*`p'wage_recent_payment_other) if `p'wage_payment_period_other==5
	replace `p'wage_salary_other = (`p'wage_number_months*(`p'wage_number_weeks/2)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==4
	replace `p'wage_salary_other = (`p'wage_number_weeks*`p'wage_recent_payment_other) if `p'wage_payment_period_other==3
	replace `p'wage_salary_other = (`p'wage_number_weeks*(`p'wage_number_hours/8)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==2
	replace `p'wage_salary_other = (`p'wage_number_weeks*`p'wage_number_hours*`p'wage_recent_payment_other) if `p'wage_payment_period_other==1
	recode `p'wage_salary_cash `p'wage_salary_other (.=0)
	gen `p'wage_annual_salary = `p'wage_salary_cash + `p'wage_salary_other
}
gen annual_salary_agwage = mainwage_annual_salary + secwage_annual_salary
collapse (sum) annual_salary_agwage, by (hhid)
lab var annual_salary_agwage "Estimated annual earnings from agricultural wage employment over previous 12 months"
save "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_agwage_income.dta", replace 
















global climate "C:\Users\obine\Music\Documents\food_secure\dofile\original\pp_only\CHIRPS"
*--------------------------------------------------------------*
* 1. Load household rainfall dataset
*--------------------------------------------------------------*
use "$climate\Nigeria_y4_hh_coordinates_rainfall_TS_monthly.dta", clear

* Rename rainfall variables to avoid name conflicts after merge
foreach var of varlist rain_2007_01 - rain_2013_12 {
    rename `var' hh_`var'
}

* Save temporary file of household rainfall
tempfile hh_rain
save `hh_rain', replace

*--------------------------------------------------------------*
* 2. Load plot-level dataset and merge rainfall by hhid
*--------------------------------------------------------------*
use "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_all_plots.dta", clear

merge m:1 hhid using `hh_rain'
drop _merge

*--------------------------------------------------------------*
* 3. Transfer household rainfall into plot rainfall variables
*--------------------------------------------------------------*
foreach var of varlist hh_rain_2007_01 - hh_rain_2013_12 {
    local new = subinstr("`var'", "hh_", "", .)   // remove hh_ prefix
    gen `new' = `var'
}

*--------------------------------------------------------------*
* 4. Remove household-prefixed rainfall variables
*--------------------------------------------------------------*
drop hh_rain_2007_01 - hh_rain_2013_12

		

egen total_rain_18_June = rowtotal(rain_2013_03 rain_2013_04 rain_2013_05 rain_2013_06)
egen total_rain_18_July = rowtotal(rain_2013_03 rain_2013_04 rain_2013_05 rain_2013_06 rain_2013_07)

egen mean_rain_18_June  = rowmean(rain_2013_03 rain_2013_04 rain_2013_05 rain_2013_06)
egen mean_rain_18_July  = rowmean(rain_2013_03 rain_2013_04 rain_2013_05 rain_2013_06 rain_2013_07)

*--------------------------------------------------------------*
* 1. Remove rainfall for years you don't want (example: drop 2018)
*--------------------------------------------------------------*
drop rain_2013_*


*----------------------------------------------------------------------
* 1. Coefficient of Variation (CV) for March–July
*----------------------------------------------------------------------
egen mean_rain = rowmean(rain_*_03 rain_*_04 rain_*_05 rain_*_06 rain_*_07)
egen sd_rain   = rowsd  (rain_*_03 rain_*_04 rain_*_05 rain_*_06 rain_*_07)
gen  cv_rainfall      = sd_rain / mean_rain
gen  cv_100_rainfall  = 100 * cv_rainfall
gen  ln_cv_rain       = ln(cv_rainfall)
gen  ln_cv_100_rain   = ln(cv_100_rainfall)

*----------------------------------------------------------------------
* 2. CV for March–June
*----------------------------------------------------------------------
egen mean_rain_Mar_June = rowmean(rain_*_03 rain_*_04 rain_*_05 rain_*_06)
egen sd_rain_Mar_June   = rowsd  (rain_*_03 rain_*_04 rain_*_05 rain_*_06)
gen  cv_rain_Mar_June   = sd_rain_Mar_June / mean_rain_Mar_June
gen  cv_100_rain_Mar_June = 100 * cv_rain_Mar_June
gen  ln_cv_rain_Mar_June  = ln(cv_rain_Mar_June)
gen  ln_cv_100_rain_Mar_June = ln(cv_rain_Mar_June)

*----------------------------------------------------------------------
* 3. CV for August–December
*----------------------------------------------------------------------
egen mean_rain_Aug_Dec = rowmean(rain_*_08 rain_*_09 rain_*_10 rain_*_11 rain_*_12)
egen sd_rain_Aug_Dec   = rowsd  (rain_*_08 rain_*_09 rain_*_10 rain_*_11 rain_*_12)
gen  cv_rain_Aug_Dec   = sd_rain_Aug_Dec / mean_rain_Aug_Dec
gen  cv_100_rain_Aug_Dec = 100 * cv_rain_Aug_Dec
gen  ln_cv_rain_Aug_Dec  = ln(cv_rain_Aug_Dec)
gen  ln_cv_100_rain_Aug_Dec = ln(cv_rain_Aug_Dec)

*----------------------------------------------------------------------
* 4. 2017 deviations (your dataset uses rain_2017_MM)
*----------------------------------------------------------------------
egen mean_rain_2012_Mar = rowmean(rain_2012_03 rain_2012_04 rain_2012_05 rain_2012_06)
gen  dev_rain_2012_Mar  = mean_rain_2012_Mar - mean_rain_Mar_June

egen mean_rain_2012_Aug = rowmean(rain_2012_08 rain_2012_09 rain_2012_10 rain_2012_11 rain_2012_12)
gen  dev_rain_2012_Aug  = mean_rain_2012_Aug - mean_rain_Aug_Dec

*----------------------------------------------------------------------
* 5. Annual mean rainfall (for all years)
*----------------------------------------------------------------------
egen mean_annual_rainfall = rowmean(rain_*_01 rain_*_02 rain_*_03 rain_*_04 rain_*_05 rain_*_06 rain_*_07 rain_*_08 rain_*_09 rain_*_10 rain_*_11 rain_*_12)

*----------------------------------------------------------------------
* 6. Annual shortfall (corrected code using loops)
*----------------------------------------------------------------------
forvalues yr = 2007/2012 {
    forvalues mm = 1/12 {
        local m : display %02.0f `mm'
        local var rain_`yr'_`m'

        capture drop dev_`var'
        gen dev_`var' = mean_annual_rainfall - `var'
        replace dev_`var' = . if dev_`var' < 0
    }
}

egen rainfall_shortfall = rowmean(dev_rain_*)
egen shortfall          = rowtotal(dev_rain_*)
gen ln_rain_shortfall   = ln(rainfall_shortfall)

gen shortfall_Mar = mean_rain_Mar_June - mean_annual_rainfall
gen shortfall_Aug = mean_rain_Aug_Dec  - mean_annual_rainfall

*----------------------------------------------------------------------
* 7. Loop for seasonal means by year (2007–2023)
*----------------------------------------------------------------------
forvalues yr = 2007/2012 {
    egen m_rain_`yr'_Mar_June = rowmean(rain_`yr'_03 rain_`yr'_04 rain_`yr'_05 rain_`yr'_06)
    egen m_rain_`yr'_Mar_July = rowmean(rain_`yr'_03 rain_`yr'_04 rain_`yr'_05 rain_`yr'_06 rain_`yr'_07)
    egen m_rain_`yr'_Aug_Dec  = rowmean(rain_`yr'_08 rain_`yr'_09 rain_`yr'_10 rain_`yr'_11 rain_`yr'_12)
}

*----------------------------------------------------------------------
* 8. Deviations for seasonal means
*----------------------------------------------------------------------
foreach var of varlist m_rain_*_Mar_June {
    gen dev_`var' = mean_rain_Mar_June - `var'
    replace dev_`var' = . if dev_`var' < 0
}

foreach var of varlist m_rain_*_Mar_July {
    gen dev_`var' = mean_rain - `var'
    replace dev_`var' = . if dev_`var' < 0
}

foreach var of varlist m_rain_*_Aug_Dec {
    gen dev_`var' = mean_rain_Aug_Dec - `var'
    replace dev_`var' = . if dev_`var' < 0
}

egen shortfall_Mar_June = rowmean(dev_m_rain_*_Mar_June)
egen shortfall_Mar_July = rowmean(dev_m_rain_*_Mar_July)
egen shortfall_Aug_Dec  = rowmean(dev_m_rain_*_Aug_Dec)

egen sd_shortfall_Mar_June = rowsd(dev_m_rain_*_Mar_June)
egen sd_shortfall_Mar_July = rowsd(dev_m_rain_*_Mar_July)
egen sd_shortfall_Aug_Dec  = rowsd(dev_m_rain_*_Aug_Dec)

*----------------------------------------------------------------------
* 9. Keep final variables
*----------------------------------------------------------------------
collapse (sum) mean_rain sd_rain cv_rainfall cv_100_rainfall ln_cv_rain ln_cv_100_rain ///
     mean_rain_Mar_June sd_rain_Mar_June cv_rain_Mar_June cv_100_rain_Mar_June ///
     mean_annual_rainfall rainfall_shortfall ln_rain_shortfall shortfall shortfall_Mar shortfall_Aug ///
     mean_rain_Aug_Dec sd_rain_Aug_Dec cv_rain_Aug_Dec cv_100_rain_Aug_Dec ///
     ln_cv_rain_Aug_Dec ln_cv_100_rain_Aug_Dec ///
     mean_rain_2012_Mar dev_rain_2012_Mar dev_rain_2012_Aug ///
     shortfall_Mar_June shortfall_Mar_July shortfall_Aug_Dec ///
     sd_shortfall_* *_18_June, by (hhid)

save "${Nigeria_GHS_W2_created_data}/rainfall_12.dta", replace 












*******************************
*Merging Household Level Dataset
*******************************
use  "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_all_plots.dta",clear

sort hhid plot_id
count
*count if cropcode==1080
*keep if cropcode==1080
*keep if purestand ==1
order hhid plot_id  quant_harv_kg value_harvest ha_harvest percent_inputs field_size purestand

collapse (sum) quant_harv_kg value_harvest ha_planted field_size (max) percent_inputs  purestand, by (hhid)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/weight.dta", nogen

sum ha_planted, detail

replace ha_planted = 9.5 if ha_planted >= 9.5 
replace field_size = 20 if field_size >= 20
ren value_harvest real_value_harvest

tab real_value_harvest, missing
sum real_value_harvest, detail

foreach v of varlist  real_value_harvest  {
	_pctile `v' [aw=weight] , p(1 99) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}



sum real_value_harvest real_value_harvest_w, detail
gen value_harvest  = real_value_harvest_w/0.236945
sum value_harvest, detail




merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/purchased_fert_2012.dta", gen(fert)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/food_prices_2012.dta", gen (food)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/asset_value_2012.dta", gen (asset)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/weight.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/ag_rainy_12.dta", gen(filter)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/extension_visit_2012.dta", gen(diet)
*merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_consumption2.dta", gen(exp)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_consumption_group2.dta", gen (exp2)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_weights.dta", gen(hh)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/soil_quality_2012.dta", gen(soil)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/demographics_2012.dta", gen(house)
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/land_holding_2012.dta", gen(work)
*merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_shannon_diversity_index.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_off_farm_hours.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_wage_income.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/Nigeria_GHS_W2_agwage_income.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/rainfall_12.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/subsidized_fert_2012.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/shock.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W2_created_data}/haz.dta", nogen

sort hhid


misstable summarize haz haz2 peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr  total_qty real_hhvalue field_size hh_members num_mem hh_headage femhead attend_sch  mean_annual_rainfall   zone state lga ea ag_shock nonag_shock land_holding 



***********************Dealing with outliers*************************


gen year = 2012
sort hhid


misstable summarize haz haz2 peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr  total_qty real_hhvalue field_size hh_members num_mem hh_headage femhead attend_sch  mean_annual_rainfall   zone state lga ea ag_shock nonag_shock land_holding 


replace total_qty = 0 if total_qty==.
replace shock = 0 if shock ==.
replace ag_shock = 0 if ag_shock ==.
replace nonag_shock = 0 if nonag_shock ==.


egen median_maize = median(real_maize_price_mr)
replace real_maize_price_mr = median_maize if real_maize_price_mr==.

egen median_rice = median (real_rice_price_mr)
replace real_rice_price_mr = median_rice if real_rice_price_mr==.

egen median_dist = median (mrk_dist_w)
replace mrk_dist_w = median_dist if mrk_dist_w==.

egen median_real_tpricefert_cens_mrk = median(real_tpricefert_cens_mrk)
replace real_tpricefert_cens_mrk = median_real_tpricefert_cens_mrk if real_tpricefert_cens_mrk==.




egen medianfert_dist_ea = median(value_harvest), by (ea)
egen medianfert_dist_lga = median(value_harvest), by (lga)
egen medianfert_dist_state = median(value_harvest), by (state)
egen medianfert_dist_zone = median(value_harvest), by (zone)


replace value_harvest = medianfert_dist_ea if value_harvest ==. 
replace value_harvest = medianfert_dist_lga if value_harvest ==. 
replace value_harvest = medianfert_dist_state if value_harvest ==.

replace value_harvest = medianfert_dist_zone if value_harvest ==. 

egen mean1 = mean (dev_rain_2012_Mar)
egen mean2 = mean (dev_rain_2012_Aug)
egen mean3 = mean (shortfall_Mar)
egen mean4 = mean (mean_annual_rainfall)



ren dev_rain_2012_Mar dev_rain_Mar
ren  dev_rain_2012_Aug dev_rain_Aug


replace dev_rain_Mar = mean1 if dev_rain_Mar ==. 
replace dev_rain_Aug = mean2 if dev_rain_Aug ==. 
replace shortfall_Mar = mean3 if shortfall_Mar ==. 
replace mean_annual_rainfall = mean4 if mean_annual_rainfall ==. 


tabstat haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea  [w=weight], statistics( mean median sd min max ) columns(statistics)


misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr  total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea

misstable summarize hhid haz haz2 peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr  total_qty real_hhvalue field_size hh_members num_mem hh_headage femhead attend_sch  mean_annual_rainfall   zone state lga ea ag_shock nonag_shock land_holding 

save "${Nigeria_GHS_W2_created_data}/final_12.dta", replace




