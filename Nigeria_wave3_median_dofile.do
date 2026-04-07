












clear



global Nigeria_GHS_W3_raw_data 		"C:\Users\obine\Music\Documents\Smallholder lsms STATA\NGA_2015_GHSP-W3_v02_M_Stata"
global Nigeria_GHS_W3_created_data  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_three"




********************************************************************************
* AG FILTER *
********************************************************************************

use "${Nigeria_GHS_W3_raw_data}/sect11a_plantingw3.dta" , clear

keep hhid s11aq1
rename (s11aq1) (ag_rainy_15)
save  "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", replace



*merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

*keep if ag_rainy_15==1




/********************************************************************
WHO 2006 Height-for-Age Z-score (HAZ)
Case where measurement position variable is NOT available
Use age-based WHO convention:
  0–23 months  = recumbent length
  24–59 months = standing height
********************************************************************/

use "${Nigeria_GHS_W3_raw_data}\sect4a_harvestw3.dta", clear
merge 1:1 hhid indiv using "${Nigeria_GHS_W3_raw_data}\sect1_harvestw3.dta", nogen

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
replace haz = . if haz > 1000
replace haz = . if haz < -6 | haz > 6

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
tab haz, missing
tab haz2, missing
sum haz, detail
sum haz2, detail

tab child1, missing
save  "${Nigeria_GHS_W3_created_data}/haz.dta", replace





********************************************************************************
* SHOCK *
********************************************************************************

use "${Nigeria_GHS_W3_raw_data}\sect15a_harvestw3.dta", clear

keep if  s15aq1==1
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
count
save  "${Nigeria_GHS_W3_created_data}/shock.dta", replace



























********************************************************************************
* WEIGHTS *
********************************************************************************

use "${Nigeria_GHS_W3_raw_data}/secta_plantingw3.dta" , clear
*merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

*keep if ag_rainy_15==1
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave3 rural
ren wt_wave3 weight
collapse (max) weight, by (hhid)
save  "${Nigeria_GHS_W3_created_data}/weight.dta", replace












********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
global Nigeria_GHS_W3_exchange_rate 401.15  		// https://www.bloomberg.com/quote/USDETB:CUR, https://data.worldbank.org/indicator/PA.NUS.FCRF?end=2023&locations=NG&start=2011
// {2017:315,2021:401.15}
global Nigeria_GHS_W3_gdp_ppp_dollar 146.72		// https://data.worldbank.org/indicator/PA.NUS.PRVT //2021
global Nigeria_GHS_W3_cons_ppp_dollar 155.72		// https://data.worldbank.org/indicator/PA.NUS.PRVT.P //2021
global Nigeria_GHS_W3_inflation 0.519052 //2017: 183.9/214.2, 2021: 183.9/354.3 //https://data.worldbank.org/indicator/FP.CPI.TOTL?end=2024&locations=NG&start=2008

global Nigeria_GHS_W3_poverty_190 ((1.90*83.58) * (183.9/110.8)) //2016 val / 2011 val, updated to 83.58 on 6/1
global Nigeria_GHS_W3_poverty_npl (361 * (183.9/267.5)) //361 in 2019
global Nigeria_GHS_W3_poverty_215 (2.15*(0.858196 * 112.0983276))  //New 2023 WB poverty threshold														
global Nigeria_GHS_W3_poverty_300 (3*($Nigeria_GHS_W3_inflation * $Nigeria_GHS_W3_cons_ppp_dollar ))							   

 
*DYA.11.1.2020 Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Nigeria_GHS_W3_pop_tot 183995785
global Nigeria_GHS_W3_pop_rur 95975881
global Nigeria_GHS_W3_pop_urb 88019904

 
 
 
 
********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Nigeria_GHS_W3_raw_data}/HHTrack.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W3_raw_data}/sectaa_plantingw3.dta"
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave3 rural
ren wt_wave3 weight
drop if weight==. //Non-surveyed households
recast double weight
save  "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_hhids.dta", replace

 
 
 
 
********************************************************************************
* INDIVIDUAL IDS *
********************************************************************************
use "${Nigeria_GHS_W3_raw_data}/sect1_plantingw3.dta", clear
gen season="plan"
append using "${Nigeria_GHS_W3_raw_data}/sect1_harvestw3.dta"
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
merge m:1 hhid using  "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_hhids.dta", keep(2 3) nogen  // keeping hh surveyed
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_person_ids.dta", replace

 
 
 
 
********************************************************************************
* HOUSEHOLD SIZE *
********************************************************************************


*Initial individidual not longer in the hh were counted as hh members though they have moved away
use "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_person_ids.dta", clear
gen member=1
collapse (max) fhh (sum) hh_members=member, by (hhid)
lab var hh_members "Number of household members"
lab var fhh "1= Female-headed household"
*DYA.11.1.2020 Re-scaling survey weights to match population estimates
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_hhids.dta", nogen
*Adjust to match total population
total hh_members [pweight=weight]
matrix temp =e(b)
gen weight_pop_tot=weight*${Nigeria_GHS_W3_pop_tot}/el(temp,1,1)
total hh_members [pweight=weight_pop_tot]
lab var weight_pop_tot "Survey weight - adjusted to match total population"
*Adjust to match total population but also rural and urban
total hh_members [pweight=weight] if rural==1
matrix temp =e(b)
gen weight_pop_rur=weight*${Nigeria_GHS_W3_pop_rur}/el(temp,1,1) if rural==1
total hh_members [pweight=weight_pop_tot]  if rural==1

total hh_members [pweight=weight] if rural==0
matrix temp =e(b)
gen weight_pop_urb=weight*${Nigeria_GHS_W3_pop_urb}/el(temp,1,1) if rural==0
total hh_members [pweight=weight_pop_urb]  if rural==0

egen weight_pop_rururb=rowtotal(weight_pop_rur weight_pop_urb)
total hh_members [pweight=weight_pop_rururb]  
lab var weight_pop_rururb "Survey weight - adjusted to match rural and urban population"
drop weight_pop_rur weight_pop_urb
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_weights.dta", replace
 
 

 
 
 
********************************************************************************
*CONSUMPTION
********************************************************************************
*first get adult equivalent
use "${Nigeria_GHS_W3_raw_data}/PTrack.dta", clear
ren sex gender
gen adulteq=.
replace adulteq=0.4 if (age<3 & age>=0)
replace adulteq=0.48 if (age<5 & age>2)
replace adulteq=0.56 if (age<7 & age>4)
replace adulteq=0.64 if (age<9 & age>6)
replace adulteq=0.76 if (age<11 & age>8)
replace adulteq=0.80 if (age<=12 & age>10) & gender==1		//1=male, 2=female
replace adulteq=0.88 if (age<=12 & age>10) & gender==2 //ALT 01.04.21: Changed from <12 to <=12 because 12-year-olds were being excluded.
replace adulteq=1 if (age<15 & age>12)
replace adulteq=1.2 if (age<19 & age>14) & gender==1
replace adulteq=1 if (age<19 & age>14) & gender==2
replace adulteq=1 if (age<60 & age>18) & gender==1
replace adulteq=0.88 if (age<60 & age>18) & gender==2
replace adulteq=0.8 if (age>59 & age!=.) & gender==1
replace adulteq=0.72 if (age>59 & age!=.) & gender==2
replace adulteq=. if age==999
collapse (sum) adulteq, by(hhid)
lab var adulteq "Adult-Equivalent"
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_hh_adulteq.dta", replace


 
 
 
use "${Nigeria_GHS_W3_raw_data}/cons_agg_wave3_visit2.dta", clear
 

egen cereals_only = rowtotal (fdsorby fdmilby fdmaizby fdriceby fdyamby fdcasby fdcereby fdbrdby fdsorpr fdmilpr fdmaizpr fdricepr fdyampr fdcaspr fdcerepr fdbrdpr)
egen protein_only = rowtotal (fdpoulby fdmeatby fdfishby fddairby fdfatsby fdbeanby  fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdbeanpr )
egen fruits_vegetables = rowtotal (fdtubby fdfrutby fdvegby fdtubpr fdfrutpr fdvegpr)


merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_weights.dta", nogen keepusing(hh_members)
save "${Nigeria_GHS_W3_created_data}/cons_agg_wave3_visit2group.dta", replace

 

use "${Nigeria_GHS_W3_raw_data}/cons_agg_wave3_visit1.dta", clear
 

egen cereals_only = rowtotal (fdsorby fdmilby fdmaizby fdriceby fdyamby fdcasby fdcereby fdbrdby fdsorpr fdmilpr fdmaizpr fdricepr fdyampr fdcaspr fdcerepr fdbrdpr)
egen protein_only = rowtotal (fdpoulby fdmeatby fdfishby fddairby fdfatsby fdbeanby  fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdbeanpr )
egen fruits_vegetables = rowtotal (fdtubby fdfrutby fdvegby fdtubpr fdfrutpr fdvegpr)


merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_weights.dta", nogen keepusing(hh_members)
save "${Nigeria_GHS_W3_created_data}/cons_agg_wave3_visit1group.dta", replace



ren cereals_only totcons_cereal_pp
ren protein_only totcons_protein_pp 
ren fruits_vegetables totcons_veg_pp


merge 1:1 hhid using  "${Nigeria_GHS_W3_created_data}/cons_agg_wave3_visit2group.dta", nogen keepusing(cereals_only protein_only fruits_vegetables)
ren cereals_only totcons_cereal_ph
ren protein_only totcons_protein_ph 
ren fruits_vegetables totcons_veg_ph

*gen totcons_cereal = (totcons_cereal_pp+totcons_cereal_ph)/2
gen totcons_cereal = totcons_cereal_pp
*gen totcons_protein = (totcons_protein_pp+totcons_protein_ph)/2
gen totcons_protein = totcons_protein_pp
*gen totcons_fruit_veg = (totcons_veg_pp+totcons_veg_ph)/2
gen totcons_fruit_veg = totcons_veg_pp

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_hh_adulteq.dta", nogen keep(1 3) keepusing(adulteq)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", nogen



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


gen totcons_cereal = totcons_cereal_n /0.302788
gen totcons_protein = totcons_protein_n /0.302788
gen totcons_fruit_veg = totcons_fruit_veg_n /0.302788

gen peraeq_cons_cereal = peraeq_cons_cereal_n /0.302788
gen peraeq_cons_protein = peraeq_cons_protein_n /0.302788
gen peraeq_cons_veg = peraeq_cons_veg_n /0.302788


gen totalcons_cereal = totalcons_cereal_n /0.302788
gen totalcons_protein = totalcons_protein_n /0.302788
gen totalcons_veg = totalcons_veg_n /0.302788
    
		
keep hhid adulteq totcons_cereal totcons_protein  totcons_fruit_veg peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_consumption_group2.dta", replace



use "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_consumption_group2.dta", clear 

merge 1:1 hhid using   "${Nigeria_GHS_W3_created_data}/haz.dta", nogen

keep if s4aq51 ==1
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_consumption_group2.dta", replace 

 
********************************************************************************
* PLOT AREAS *
********************************************************************************
*starting with planting
clear
//ALT 06.03.21: I think it'd be easier if we just built a file for area conversions.

*using conversion factors from LSMS-ISA Nigeria Wave 2 Basic Information Document (Wave 3 unavailable, but Waves 1 & 2 are identical) 
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
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_landcf.dta", replace

use "${Nigeria_GHS_W3_raw_data}/sect11a1_plantingw3", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using "${Nigeria_GHS_W3_raw_data}/sect11b1_plantingw3", nogen
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W3_raw_data}/secta1_harvestw3.dta", gen(plot_merge)
ren s11aq4a area_size
ren s11aq4b area_unit
ren sa1q9a area_size2
ren sa1q9b area_unit2
ren s11aq4c area_meas_sqm
ren sa1q9c area_meas_sqm2
gen cultivate = s11b1q27 ==1 
recode area_size area_size2 area_meas_sqm area_meas_sqm2 (0=.)

*assuming new plots are cultivated
replace cultivate = 1 if sa1q3==1
merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_landcf.dta", nogen keep(1 3) //Should be no unmatched values.
*farmer reported field size for post-planting
gen field_size= area_size*conversion
drop area_unit conversion
*farmer reported field size for post-harvest added fields
ren area_unit2 area_unit
merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_landcf.dta", nogen keep(1 3)
replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.       
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.         				
gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
la var field_size "Area of plot (ha)"
ren plotid plot_id
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_plot_areas.dta", replace








********************************************************************************
* PLOT DECISION MAKERS *
********************************************************************************
/*
*Creating gender variables for plot manager from post-planting
use "${Nigeria_GHS_W3_raw_data}/sect1_plantingw3.dta", clear
gen female = s1q2==2 if s1q2!=.
gen age = s1q6
*dropping duplicates (data is at holder level so some individuals are listed multiple times, we only need one record for each)
duplicates drop hhid indiv, force
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_gender_merge_temp.dta", replace

*adding in gender variables for plot manager from post-harvest
use "${Nigeria_GHS_W3_raw_data}/sect1_harvestw3.dta", clear
gen female = s1q2==2 if s1q2!=.
gen age = s1q4
duplicates drop hhid indiv, force
merge 1:1 hhid indiv using "$Nigeria_GHS_W3_created_data/Nigeria_GHS_W3_gender_merge_temp.dta", nogen 		
keep hhid indiv female age
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_gender_merge.dta", replace
*/
*Using planting data 	
use "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_plot_areas.dta", clear 	
gen indiv1=s11aq6a
gen indiv2=s11aq6b 
gen indiv3=sa1q11
gen indiv4=sa1q11b
replace indiv1=indiv3 if indiv1==.
keep hhid plot_id indiv* 
reshape long indiv, i(hhid plot_id) j(id_no)
drop if indiv==.
merge m:1 hhid indiv using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_person_ids.dta", keep(1 3) nogen keepusing(female)
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_dm_ids.dta", replace
gen dm1_gender=female+1 if id_no==1
gen dm1_id = indiv if id_no==1
collapse (mean) female (firstnm) dm1_gender dm1_id, by(hhid plot_id)
gen dm_gender = 3
replace dm_gender = 1 if female==0
replace dm_gender = 2 if female==1
la def dm_gender 1 "Male only" 2 "Female only" 3 "Mixed gender"
*replacing observations without gender of plot manager with gender of HOH
merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_weights.dta", nogen keep(1  3) keepusing (fhh)
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
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_plot_decision_makers", replace
*/



********************************************************************************
*Formalized Land Rights*
********************************************************************************
use "${Nigeria_GHS_W3_raw_data}/sect11b1_plantingw3.dta", clear
*DYA.11.21.2020  we need to recode . to 0 or exclude them as . as treated as very large numbers in Stata
*recode s11b1q8 (.=0)
gen formal_land_rights = 1 if (s11b1q8>=1 & s11b1q8!=.)	| (s11b1q10a>=1 & s11b1q10a!=.)  | (s11b1q10b>=1 & s11b1q10b!=.) | (s11b1q10c>=1 & s11b1q10c!=.) | (s11b1q10d>=1 & s11b1q10d!=.)						
*Individual level (for women)
*Starting with first owner
preserve
ren s11b1q8b1 indiv
merge m:1 hhid indiv using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_person_ids.dta", nogen keep(3)		
keep hhid indiv female formal_land_rights
tempfile p1
save `p1', replace
restore
*Now second owner
preserve
ren s11b1q8b2 indiv		
merge m:1 hhid indiv using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_person_ids.dta", nogen keep(3)		
keep hhid indiv female
tempfile p2
save `p2', replace
restore	
*Now third owner
preserve
ren s11b1q8b3 indiv		
merge m:1 hhid indiv using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_person_ids.dta", nogen keep(3)	
keep hhid indiv female
append using `p1'
append using `p2' 
gen formal_land_rights_f = formal_land_rights==1 if female==1
collapse (max) formal_land_rights_f, by(hhid indiv)		
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_land_rights_ind.dta", replace
restore	
collapse (max) formal_land_rights_hh=formal_land_rights, by(hhid)		// taking max at household level; equals one if they have official documentation for at least one plot
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_land_rights_hh.dta", replace

































********************************************************************************
*crop unit conversion factors
********************************************************************************
use "${Nigeria_GHS_W3_raw_data}/ag_conv_w3", clear
ren crop_cd crop_code
ren conv_NC_1 conv_fact1
ren conv_NE_2 conv_fact2
ren conv_NW_3 conv_fact3
ren conv_SE_4 conv_fact4
ren conv_SS_5 conv_fact5
ren conv_SW_6 conv_fact6
sort crop_code unit_cd conv_national
reshape long conv_fact, i(crop_code unit_cd conv_national) j(zone)
fillin crop_code unit_cd zone
	//bys unit_cd zone state: egen state_conv_unit = median(conv_fact) //We don't have state-level factors
	bys unit_cd zone: egen zone_conv_unit = median(conv_fact)
	bys unit_cd: egen national_conv = median(conv_fact)	
	replace conv_fact = zone_conv_unit if conv_fact==. & unit_cd!=900		
	replace conv_fact = national_conv if conv_fact==. & unit_cd!=900
	replace conv_fact = 1958 if unit_cd==180 //Pickups, using the local weights and measures handbook cited in wave 4
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_ng3_cf.dta", replace


********************************************************************************
*ALL PLOTS
********************************************************************************
				
	***************************
	*Crop Values
	***************************
	//Nonstandard unit values (kg values in plot variables section)
use "${Nigeria_GHS_W3_raw_data}/secta3ii_harvestw3.dta", clear
	keep if sa3iiq3==1
	ren sa3iiq5a qty
	ren sa3iiq5b unit_cd
	ren sa3iiq6 value
	keep zone state lga sector ea hhid cropcode qty unit_cd value
	merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_weights.dta", nogen keepusing(weight_pop_rururb)
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
	collapse (median) price_unit_country = price_unit (rawsum) obs_country_price=obs [aw=weight], by(crop_code unit_cd)
	tempfile price_unit_country_median
	save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_crop_prices_median_country.dta", replace
	//Unfortunately, only a small number of obs for shelled/unshelled (the ***1 ***2 etc cropcodes) Not entirely clear what the *0's represent (probably shelled?)
	//ALT 05.09.23: Bringing this over from the other file 
	use "${Nigeria_GHS_W3_raw_data}/secta3ii_harvestW3.dta", clear
	keep if sa3iiq3==1
	ren sa3iiq5a qty
	ren sa3iiq5b unit_cd
	ren sa3iiq6 value
	keep zone state lga sector ea hhid cropcode qty unit_cd value
	ren cropcode crop_code
	merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_weights.dta", nogen keepusing(weight_pop_rururb) keep(1 3)
	merge m:1 crop_code unit_cd zone using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_ng3_cf.dta", nogen keep(1 3)
	//ren cropcode crop_code
	gen qty_kg = qty*conv_fact 
	drop if qty_kg==. //34 dropped; largely basin and bowl.
	gen price_kg = value/qty_kg
	gen obs=price_kg !=.
	keep if obs == 1
	replace weight = qty_kg*weight_pop_rururb
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

	
	
	***************************
	*Plot variables
	***************************	
	//issue with incorrect ea id for two households here.
use	"${Nigeria_GHS_W3_raw_data}/secta3i_harvestw3.dta", clear
drop zone state lga ea 
tempfile harvest_vars
save `harvest_vars'

use "${Nigeria_GHS_W3_raw_data}/sect11e_plantingw3.dta", clear
gen use_imprv_seed=s11eq3b==1 |  s11eq3b==2
gen use_hybrid_seed=s11eq3b==1
ren plotid plot_id
ren cropcode crop_code
//Crop recode
recode crop_code (1053=1050) (1061 1062 = 1060) (1081 1082=1080) (1091 1092 1093 = 1090) (1111=1110) (2191 2192 2193=2190) /*Counting this generically as pumpkin, but it is different commodities
	*/				 (3181 3182 3183 3184 = 3180) (2170=2030) (3113 3112 3111 = 3110) (3022=3020) (2142 2141 = 2140) (1121 1122 1123=1120)
collapse (max) use_imprv_seed use_hybrid_seed, by(hhid plot_id crop_code)
tempfile imprv_seed
save `imprv_seed'

use "${Nigeria_GHS_W3_raw_data}/sect11f_plantingw3.dta", clear
drop zone state lga ea
	ren cropcode crop_code_11f
	merge 1:1 hhid plotid /*cropcode*/ cropid using `harvest_vars'
	merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_hhids.dta", nogen keepusing(zone state lga ea) keep(3)
	ren plotid plot_id
	//sort hhid plot_id
	//bys hhid : gen plot_id2 = _n
	ren s11fq5 number_trees_planted
	//merge m:1 plot_id hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_plot_areas", nogen keep(1 3)
	ren cropcode crop_code_a3i //i.e., if harvested units are different from planted units
	//Consolidating cropcodes
	replace crop_code_11f=crop_code_a3i if crop_code_11f==.
	//not necessary for Ethiopia - replace with crop_code 
	gen crop_code_master =crop_code_11f //Generic level
	ren crop_code_11f crop_code
	recode crop_code_master (1053=1050) (1061 1062 = 1060) (1081 1082=1080) (1091 1092 1093 = 1090) (1111=1110) (2191 2192 2193=2190) /*Counting this generically as pumpkin, but it is different commodities
	*/				 (3181 3182 3183 3184 = 3180) (2170=2030) (3113 3112 3111 = 3110) (3022=3020) (2142 2141 = 2140) (1121 1122 1123=1120) //Cutting three-leaved yams from generic yam category because crop calendar is different.
	la values crop_code_master cropcode
	gen area_unit=s11fq1b
	replace area_unit=s11fq4b if area_unit==.
	merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_landcf.dta", nogen keep(1 3)
	gen ha_planted = s11fq1a*conversion
	replace ha_planted = s11fq4a*conversion if ha_planted==. & s11fq4a!=0 //Tree crops.A few obs reported in stands equal to the number of trees reported. The WB conversion for "stand" is probably for something different, because it results in very low converted hectares. Might distort yields for oil palm a little.
	
	recode ha_planted (0=.)
	drop conversion area_unit
	ren sa3iq5b area_unit
	merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_landcf.dta", nogen keep(1 3)
	gen ha_harvest = sa3iq5a*conversion
	merge m:1 hhid plot_id using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_plot_areas.dta", nogen keep(1 3) //keepusing(field_size)
	replace ha_harvest = field_size*sa3iq5c/100 if sa3iq5c!=. & sa3iq5c!=0  //Preferring percentage estimates over area estimates when we have both.
	replace ha_harvest = ha_planted if s11fq11a!=0 & s11fq11a!=. & ha_planted!=. 
	replace ha_planted = ha_harvest if ha_planted==. & ha_harvest!=. & ha_harvest!=0
	
	gen month_planted = s11fq3a+(s11fq3b-2014)*12
	gen month_harvested = sa3iq4a1 + (sa3iq4a2-2014)*12
	gen months_grown = month_harvested-month_planted if s11fc5==1 //Ignoring permanent crops that may be grown multiple seasons
	replace months_grown=. if months_grown < 1 | month_planted==. | month_harvested==.
	
	//ALT 05.09.2023: Plot workdays
	preserve
	gen days_grown = months_grown*30 
	collapse (max) days_grown, by(hhid plot_id)
	save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_plot_season_length.dta", replace
	restore
	//ALT 05.09.23: END Update
/* To revisit
	preserve
		gen obs=1
		replace obs=0 if inrange(sa3iq4,1,5) & s11fc5==1
		collapse (sum) crops_plot=obs, by(hhid plot_id)
		tempfile ncrops 
		save `ncrops'
	restore //286 plots have >1 crop but list monocropping, 382 say intercropping; meanwhile 130 list intercropping or mixed cropping but only report one crop
	merge m:1 hhid plot_id using `ncrops', nogen

	gen lost_crop=inrange(sa3iq4,1,5) & s11fc5==1
	bys hhid plot_id : egen max_lost = max(lost_crop)
	gen replanted = (max_lost==1 & crops_plot>0)
		preserve 
		keep if replanted == 1 & lost_crop == 1 //we'll keep this for planting area, which might cause the plot to go over 100% planted 
		drop crop_code 
		ren crop_code_master crop_code
		keep zone state lga ea hhid crop_code plot_id ha_planted lost_crop
		tempfile lost_crops
		save `lost_crops'
	restore
	drop if replanted==1 & lost_crop==1 
	//95 plots did not replant; keeping and assuming yield is 0.
*/
	bys hhid plot_id : gen n_crops=_N
	replace ha_planted = ha_harvest if ha_planted > field_size & ha_harvest < ha_planted & ha_harvest!=. 
	gen percent_field=ha_planted/field_size
	gen pct_harv = ha_harvest/ha_planted //This will allow us to rescale harvests based on rescaled planted areas and catch issues where we only had area harvested reported and not percentage harvested. 
	replace pct_harv = 1 if ha_harv > ha_planted & ha_harv!=.
	replace pct_harv = 0 if pct_harv==. & sa3iq4 < 6
*Generating total percent of purestand and monocropped on a field
	bys hhid plot_id: egen tot_ha_planted = sum(ha_planted)
	replace field_size = tot_ha_planted if field_size==. //assuming crops are filling the plot when plot area is not known.
	replace percent_field = ha_planted/tot_ha_planted if tot_ha_planted >= field_size & n_crops > 1 //Adding the = to catch plots that were filled in previous line
	replace percent_field = 1 if tot_ha_planted>=field_size & n_crops==1
	replace ha_planted = percent_field*field_size if (tot_ha_planted > field_size) & field_size!=. & ha_planted!=.
	replace ha_harvest = pct_harv*ha_planted
	
	*renaming unit code for merge
	ren sa3iq6ii unit_cd 
	replace unit_cd = s11fq11b if unit_cd==.
	ren sa3iq6i quantity_harvested
	replace quantity_harvested = s11fq11a if quantity_harvested==.
	//we recoded plantains to bananas in the yield section - doing the same here
	//recode crop_code (2170=2030) - see above; we account for the plantain/banana stuff in the master crop_code variable
	*merging in conversion factors
	merge m:1 crop_code unit_cd zone using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_ng3_cf.dta", keep(1 3) gen(cf_merge) //1829 not matched, but only 304 have units. We should still see if we can fill in from W4.
	gen quant_harv_kg= quantity_harvested*conv_fact
	ren sa3iq6a val_harvest_est
	gen val_unit_est = val_harvest_est/quantity_harvested
	gen val_kg_est = val_harvest_est/quant_harv_kg
	merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_weights.dta", nogen keep(1 3)
	gen plotweight = ha_planted*weight_pop_rururb
	//IMPLAUSIBLE ENTRIES - at least 100x the typical yield
	//A lot of extremely high yields are relatively normal amounts from small numbers of fruit-bearing trees whose planted area estimates are likely too small; I leave those alone 
	//ALT note 09.29.22: some of these issues may result from flaws in area measurement/estimation rather than yield estimates.
	//10 sq m is 0.0001 ha; hard to see plantings occurring smaller than this 
	/* ALT 03.21.25 Alternative trimming now @ end of section.
	gen yield = quant_harv_kg/ha_planted
	foreach var in quantity_harvested quant_harv_kg val_harvest_est val_unit_est val_kg_est {
	replace `var' = . if (hhid == 18089 & plot_id == 2 & cropid==2) | /* 5 tons sorghum on 0.0000246 Ha. Plot  is 2500 sq m, so even if the whole plot was planted the yield would still be way high 
	*/ (hhid == 230067 & plot_id == 1 & cropid == 1) | /* 13 tons yam on 0.0024 ha
	*/ (hhid == 260040 & plot_id == 1 & cropid == 1) | /* 3500 sacks of yam on < 1 ha
	*/ (crop_code_11f==1080 & yield > 1e+6) //Many corn obs w/ million-plus per-ha yields. I think plot area is an issue here.
	}
	drop yield
	*/
	gen obs=quantity_harvested>0 & quantity_harvested!=.

foreach i in zone state lga ea hhid {
	merge m:1 `i' unit_cd crop_code using `price_unit_`i'_median', nogen keep(1 3)
	merge m:1 `i' crop_code using `price_kg_`i'_median', nogen keep(1 3)
}

merge m:1 unit_cd crop_code using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_crop_prices_median_country.dta", nogen keep(1 3)
merge m:1 crop_code using `price_kg_country_median', nogen keep(1 3)

gen price_unit = price_unit_hh
gen price_kg = price_kg_hh

foreach i in country zone state lga ea {
	replace price_unit = price_unit_`i' if obs_`i'_price>9 & obs_`i'_price != .
	replace price_kg = price_kg_`i' if obs_`i'_pkg>9 & obs_`i'_pkg != .
}

	gen value_harvest = price_unit * quantity_harvested
	replace value_harvest=price_kg*quant_harv_kg if value_harvest==.
	gen value_harvest_hh=price_unit_hh * quantity_harvested
	replace value_harvest_hh=price_kg_hh*quant_harv_kg 
	replace value_harvest = val_harvest_est if value_harvest == . & val_harvest_est!=0 //Some zeroes for expected harvest crops														   
	replace val_unit = value_harvest/quantity_harvested if val_unit==.
preserve
	ren unit_cd unit
	collapse (mean) val_unit, by (hhid crop_code unit)
	ren val_unit hh_price_mean
	lab var hh_price_mean "Average price reported for this crop-unit in the household"
	save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_hh_crop_prices_for_wages.dta", replace
restore
	//still-to-harvest value, only for plots where some crop was harvested.
	gen same_unit=unit_cd==sa3iq6d2
	drop unit_cd quantity_harvested *conv* cf_merge
	ren sa3iq6d2 unit_cd
	ren sa3iq6d1 quantity_harvested
	merge m:1 crop_code unit_cd zone using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_ng3_cf.dta", nogen keep(1 3)
	gen quant_harv_kg2= quantity_harvested*conv_fact
	gen val_harv2 = 0
	gen val_harv2_hh=0
	recode quant_harv_kg2 quantity_harvested (.=0)
	replace val_harv2=quantity_harvested*price_unit if same_unit==1
	replace val_harv2_hh=quantity_harvested*price_unit_hh if same_unit==1
	replace val_harv2=quant_harv_kg2*price_kg if val_harv2==0
	replace val_harv2_hh=quant_harv_kg2*price_kg_hh if val_harv2_hh==0
	gen missing_unit =val_harv2 == 0		
	
	recode quant_harv* val*_harv* (.=0)
	replace quant_harv_kg = quant_harv_kg+quant_harv_kg2
	replace value_harvest = value_harvest+val_harv2	
	replace value_harvest_hh=value_harvest+val_harv2_hh
	gen lost_drought = sa3iq4==6 |  s11fq10==1 
	gen lost_flood = sa3iq4==5 |  s11fq10==2 
	gen lost_pest = sa3iq4==12 |  s11fq10==5 
	//Only affects 966 obs 
	drop val_harv2 quant_harv_kg2 val_* obs*
	
	gen no_harvest = sa3iq4 >= 6 & sa3iq4 <= 10
	ren crop_code crop_code_full //We drop this here and report everything as the consolidated crop group, but it could be retained here.
	ren crop_code_master crop_code 

	collapse (sum) quant_harv_kg value_harvest* ha_planted ha_harvest number_trees_planted percent_field (max) lost_pest lost_flood lost_drought no_harvest, by(zone state lga sector ea hhid plot_id crop_code field_size gps_meas)
	//no need for a collapse because there's no duplicates
	drop if (ha_planted==0 | ha_planted==.) & (ha_harv==0 | ha_harv==.) & (quant_harv_kg==0)
	replace ha_harvest=. if (ha_harvest==0 & no_harvest==1) | (ha_harvest==0 & quant_harv_kg>0 & quant_harv_kg!=.)
	replace value_harvest = . if value_harvest==0 & (no_harvest==1 | quant_harv_kg!=0)
	replace quant_harv_kg = . if quant_harv_kg==0 & no_harvest==1
	recode ha_planted (0=.)
	bys hhid plot_id : egen percent_area = sum(percent_field)
	bys hhid plot_id : gen percent_inputs = percent_field/percent_area
	bys hhid plot_id : gen purestand = _N 
	replace purestand=0 if purestand >1
	drop percent_area //Assumes that inputs are +/- distributed by the area planted. Probably not true for mixed tree/field crops, but reasonable for plots that are all field crops
	//Labor should be weighted by growing season length, though. 
	//We remove small planted areas from the sample for yield, as these areas are likely undermeasured/underestimated and cause substantial outliers. The harvest quantities are retained for farm income and production estimates. 
	gen ha_harv_yld= ha_harvest if ha_planted >= 0.05
	gen ha_plan_yld= ha_planted if ha_planted >= 0.05
	merge m:1 hhid plot_id using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_plot_decision_makers.dta", nogen keep(1 3) keepusing(dm*)
	merge 1:1 hhid plot_id crop_code using `imprv_seed', nogen
	save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_all_plots.dta",replace
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
************************
*Geodata Variables
************************

use "${Nigeria_GHS_W3_raw_data}\NGA_PlotGeovariables_Y3.dta", clear

collapse (max) srtmslp_nga srtm_nga twi_nga, by (hhid)

merge 1:m hhid using "${Nigeria_GHS_W3_raw_data}\NGA_HouseholdGeovars_Y3.dta"


ren dist_market dist_market
sum dist_market, detail


collapse (max) dist_market, by (hhid)
sort hhid

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)

*merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

*keep if ag_rainy_15==1

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

save "${Nigeria_GHS_W3_created_data}\geodata_2015.dta", replace












****************************
*Subsidized Fertilizer
****************************

use "${Nigeria_GHS_W3_raw_data}\secta11d_harvestw3.dta",clear 


*s11dq14 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq26 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq16a s11dq28a  qty of inorg purchased fertilizer
*s11dq16b s11dq28b  units for inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer

*************Checking to confirm its the subsidized price *******************


encode s11dq14, gen(institute)
label list institute

encode s11dq26, gen(institute2)
label list institute2

*encode s11dq40, gen(institute3)
*label list institute3

label list s11dq16b
******conversion from gram to kilogram
replace s11dq16a = 0.001*s11dq16a if s11dq16b==2
tab s11dq16a
replace s11dq28a = 0.001*s11dq28a if s11dq28b==2
tab s11dq28a
*replace s11dq37a = 0.001*s11dq37a if s11dq37b==2
*tab s11dq37a



*************Getting Subsidized quantity and Dummy Variable ******************* N2 AND N3 ARE 2 AND 3 RESPECTIVELY WHILE N1 IS 1

gen subsidy_qty1 = s11dq16a if institute ==2 | institute ==3
tab subsidy_qty1
gen subsidy_qty2 = s11dq28a if institute2 ==2 | institute2 ==3
tab subsidy_qty2


**************
*E-WALLET SUBSIDY
**************

ren s11dq5a esubsidy_dummy 
tab esubsidy_dummy,missing
tab esubsidy_dummy, nolabel
replace esubsidy_dummy =0 if esubsidy_dummy==2 | esubsidy_dummy==.
tab esubsidy_dummy,missing
tab esubsidy_dummy, nolabel


ren s11dq5c1 esubsidy_qty 
tab esubsidy_qty, missing











************
*Getting total subsidy_dummy
**********

egen subsidy_qty = rowtotal(subsidy_qty1 subsidy_qty2 esubsidy_qty)
tab subsidy_qty,missing
sum subsidy_qty,detail



gen subsidy_dummy = (subsidy_qty !=0)

tab subsidy_dummy, missing
replace subsidy_dummy = 1 if esubsidy_dummy ==1
tab subsidy_dummy, missing

collapse (sum)subsidy_qty (max) subsidy_dummy, by (hhid)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)



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

save "${Nigeria_GHS_W3_created_data}\subsidized_fert_2015.dta", replace



***********************************
*Transport Cost
***********************************

use "${Nigeria_GHS_W3_raw_data}\secta11d_harvestw3.dta",clear 



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
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)




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

gen transport_cost = transport_w   /0.302788
sum transport_cost, detail
keep hhid transport_cost

save "${Nigeria_GHS_W3_created_data}\transport.dta", replace


*********************************************** 
*Purchased Fertilizer
***********************************************

use "${Nigeria_GHS_W3_raw_data}\secta11d_harvestw3.dta",clear 


*s11dq14 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq26 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq16a s11dq28a  qty of inorg purchased fertilizer
*s11dq16b s11dq28b  units for inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer

encode s11dq14, gen(institute)
label list institute
encode s11dq26, gen(institute2)
label list institute2

encode s11dq40, gen(institute3)
label list institute3


*****Coversion of fertilizer's gram into kilogram using 0.001
replace s11dq16a = 0.001*s11dq16a if s11dq16b==2 
tab s11dq16a

replace s11dq28a = 0.001*s11dq28a if s11dq28b==2
tab s11dq28a


*replace s11dq37a = 0.001*s11dq37a if s11dq37b==2
*tab s11dq37a



***fertilzer total quantity, total value & total price****

gen private_fert1_qty = s11dq16a if institute ==1
tab private_fert1_qty, missing
gen private_fert2_qty = s11dq28a if institute2 ==1
tab private_fert2_qty,missing
*gen private_fert3_qty = s11dq37a if institute3 ==1
*tab private_fert3_qty,missing

gen private_fert1_val = s11dq19 if institute ==1
tab private_fert1_val,missing
gen private_fert2_val = s11dq29 if institute2 ==1
tab private_fert2_val,missing
*gen private_fert3_val = s11dq39 if institute3 ==1
*tab private_fert3_val,missing

egen total_qty  = rowtotal(private_fert1_qty private_fert2_qty)
tab  total_qty, missing

egen total_valuefert  = rowtotal(private_fert1_val private_fert2_val)
tab total_valuefert,missing

gen tpricefert  = total_valuefert /total_qty 
tab tpricefert , missing

gen tpricefert_cens = tpricefert  
replace tpricefert_cens = 800 if tpricefert_cens > 800 & tpricefert_cens < .
replace tpricefert_cens = 12 if tpricefert_cens < 12
tab tpricefert_cens, missing 



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


***************
*organic fertilizer
***************
gen org_fert = 1 if  s11dq36==1
tab org_fert, missing
replace org_fert = 0 if org_fert==.
tab org_fert, missing



collapse  zone lga sector ea (sum) total_qty  total_valuefert  (max)  org_fert tpricefert_cens_mrk, by(hhid)


merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)



sum tpricefert_cens_mrk, detail

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


gen rea_tpricefert_cens_mrk = tpricefert_cens_mrk_w  /0.302788
gen real_tpricefert_cens_mrk = rea_tpricefert_cens_mrk
replace real_tpricefert_cens_mrk= 416 if hhid == 10062 
replace real_tpricefert_cens_mrk= 184 if hhid == 20064
tab real_tpricefert_cens_mrk
sum real_tpricefert_cens_mrk, detail


keep hhid zone lga sector ea org_fert total_qty_w total_valuefert real_tpricefert_cens_mrk

sort hhid
save "${Nigeria_GHS_W3_created_data}\purchased_fert_2015.dta", replace


******************************* 
*Extension Visit 
*******************************


use "${Nigeria_GHS_W3_raw_data}\sect11l1_plantingw3.dta",clear 

merge 1:1 hhid topic_cd using "${Nigeria_GHS_W3_raw_data}\secta5a_harvestw3.dta"

replace s11l1q1=1 if s11l1q1==. & sa5aq1==1
ren s11l1q1 ext_acess 

tab ext_acess, missing
tab ext_acess, nolabel

replace ext_acess = 0 if ext_acess==2 | ext_acess==.
tab ext_acess, missing
collapse (max) ext_acess, by (hhid)
la var ext_acess "=1 if received advise from extension services"
save "${Nigeria_GHS_W3_created_data}\extension_access_2015.dta", replace




*****************************
*Community 
****************************

use "${Nigeria_GHS_W3_raw_data}\sectc2_harvestw3.dta", clear
*is_cd  219 for market infrastructure
*c2q3  distance to infrastructure in km

gen mrk_dist = c2q3 if is_cd==222
tab mrk_dist if is_cd==222, missing
egen median_lga = median(mrk_dist), by (zone state lga)
egen median_state = median(mrk_dist), by (zone state)
egen median_zone = median(mrk_dist), by (zone)


replace mrk_dist =0 if is_cd==222 & mrk_dist==. & c2q1==1
tab mrk_dist if is_cd==222, missing

replace mrk_dist = median_lga if mrk_dist==. & is_cd==222
replace mrk_dist = median_state if mrk_dist==. & is_cd==222
replace mrk_dist = median_zone if mrk_dist==. & is_cd==222
tab mrk_dist if is_cd==222, missing

replace mrk_dist= 50 if mrk_dist>=50 & mrk_dist<. & is_cd==222
tab mrk_dist if is_cd==222, missing

sort zone state ea
collapse (max) median_lga median_state median_zone mrk_dist, by (zone state lga sector ea)
replace mrk_dist = median_lga if mrk_dist ==.
tab mrk_dist, missing
replace mrk_dist = median_state if mrk_dist ==.
tab mrk_dist, missing
replace mrk_dist = median_zone if mrk_dist ==.
tab mrk_dist, missing
la var mrk_dist "=distance to the market"

save "${Nigeria_GHS_W3_created_data}\market_distance.dta", replace 




*********************************
*Demographics 
*********************************



use "${Nigeria_GHS_W3_raw_data}\sect1_plantingw3.dta",clear 


merge 1:1 hhid indiv using "${Nigeria_GHS_W3_raw_data}\sect2_harvestw3.dta" , gen(household)

merge m:1 zone state lga sector ea using "${Nigeria_GHS_W3_created_data}\market_distance.dta", keepusing (median_lga median_state median_zone mrk_dist)
*merge m:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

*keep if ag_rainy_15==1
**************
*market distance
*************
*replace mrk_dist = median_lga if mrk_dist==.
*tab mrk_dist, missing

*replace mrk_dist = median_state if mrk_dist==.
*tab mrk_dist, missing

*replace mrk_dist = median_zone if mrk_dist==.
*tab mrk_dist, missing



*s1q2   sex
*s1q3   relationship to household head
*s1q6   age in years


sort hhid indiv 
 
gen num_mem = 1



******** female head****

gen femhead  = 0
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
*s2aq6   1= attended school
*s2aq9	 highest education level
*s1q3    relationship to household head


ren  s2aq6 attend_sch 
tab attend_sch
replace attend_sch = 0 if attend_sch ==2
tab attend_sch, nolabel
*tab s1q4 if s2q7==.

replace s2aq9= 0 if attend_sch==0
tab s2aq9
tab s1q3 if _merge==1

tab s2aq9 if s1q3==1
replace s2aq9 = 16 if s2aq9==. &  s1q3==1

*** Education Dummy Variable*****

 label list s2aq9

gen pry_edu  = 1 if s2aq9 >= 1 & s2aq9 < 16 & s1q3==1
gen finish_pry  = 1 if s2aq9 >= 16 & s2aq9 < 26 & s1q3==1
gen finish_sec  = 1 if s2aq9 >= 26 & s2aq9 < 43 & s1q3==1

replace pry_edu =0 if pry_edu ==. & s1q3==1
replace finish_pry  =0 if finish_pry==. & s1q3==1
replace finish_sec =0 if finish_sec ==. & s1q3==1
tab pry_edu if s1q3==1 , missing
tab finish_pry if s1q3==1 , missing 
tab finish_sec if s1q3==1 , missing


//mrk_dist
collapse (sum) num_mem (max)  hh_headage femhead attend_sch pry_edu finish_pry finish_sec mrk_dist, by (hhid)


merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)

*merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)

*keep if ag_rainy_15==1

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

*/

keep hhid  num_mem femhead hh_headage attend_sch pry_edu finish_pry finish_sec mrk_dist_w

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
la var femhead  "=1 if head is female"
la var hh_headage "age of household head in years"
la var attend_sch "=1 if respondent attended school"
la var pry_edu "=1 if household head attended pry school"
la var finish_pry "=1 if household head finished pry school"
la var finish_sec  "=1 if household head finished sec school"

misstable summarize num_mem hh_headage femhead attend_sch  pry_edu finish_pry finish_sec


save "${Nigeria_GHS_W3_created_data}\demographics_2015.dta", replace



**************************
*Food Prices from Community
**************************
use "${Nigeria_GHS_W3_raw_data}\sectc2a_plantingw3.dta", clear

*br if item_cd == 20
*br if item_cd ==20 & c2q2==1
tab c2q3 if item_cd ==20 & c2q2==1
tab c2q2 if item_cd==20



gen conversion =1
tab conversion, missing
gen food_size=1 //This makes it easy for me to copy-paste existing code rather than having to write a new block
replace conversion = food_size*2.696 if c2q2 == 11
replace conversion = food_size*0.001 if  c2q2 == 2
replace conversion = food_size*0.175 if  c2q2 == 12		
replace conversion = food_size*0.23 if  c2q2 == 13
replace conversion = food_size*1.5 if  c2q2 == 20 |c2q2 == 21  |c2q2 == 30  |c2q2 == 31 	
replace conversion = food_size*0.35 if  c2q2 == 40 
replace conversion = food_size*0.70 if  c2q2 == 41
replace conversion = food_size*3.00 if  c2q2 == 51  |c2q2 == 52 
replace conversion = food_size*0.718 if  c2q2 == 70	 |c2q2 == 71  |c2q2 == 72
replace conversion = food_size*1.615 if  c2q2 == 80  |c2q2 == 81  |c2q2 == 82
replace conversion = food_size*1.135 if   c2q2 == 90  |c2q2 == 91  |c2q2 == 92
				
tab conversion, missing	



gen maize_price= c2q3* conversion if item_cd==20
tab maize_price

sum maize_price, detail


tab maize_price,missing
sum maize_price,detail
tab maize_price

replace maize_price = 400 if maize_price >400 & maize_price<.  //bottom 5%
replace maize_price = 0.04 if maize_price< 0.04        ////top 1%



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






****************rice

gen rice_price = c2q3* conversion if item_cd==13

sum rice_price,detail
tab rice_price

replace rice_price = 1350 if rice_price >1350 & rice_price<.   //bottom 5%
replace rice_price = 5 if rice_price< 5   //top 5%
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

replace rice_price_mr = median_rice_ea if rice_price_mr==. & num_rice_ea>=7
tab rice_price_mr,missing

replace rice_price_mr = median_rice_lga if rice_price_mr==. & num_rice_lga>=7
tab rice_price_mr,missing

replace rice_price_mr = median_rice_state if rice_price_mr==. & num_rice_state>=7
tab rice_price_mr,missing

replace rice_price_mr = median_rice_zone if rice_price_mr==. & num_rice_zone>=7
tab rice_price_mr,missing


sort zone state ea
collapse (max) maize_price_mr rice_price_mr  median_pr_lga median_pr_state median_pr_zone median_pr_ea , by (zone state lga sector ea)


save "${Nigeria_GHS_W3_created_data}\food_prices.dta", replace


use "${Nigeria_GHS_W3_raw_data}\sect7b_plantingw3.dta", clear
merge m:1 zone state lga sector ea using "${Nigeria_GHS_W3_created_data}\food_prices.dta", keepusing (median_pr_ea median_pr_lga median_pr_state median_pr_zone maize_price_mr rice_price_mr)



**************
*maize price
*************
//missing values persists even after i did this
replace maize_price_mr = median_pr_ea if maize_price_mr==.
tab maize_price_mr, missing

replace maize_price_mr = median_pr_lga if maize_price_mr==.
tab maize_price_mr, missing

replace maize_price_mr = median_pr_state if maize_price_mr==.
tab maize_price_mr, missing

replace maize_price_mr = median_pr_zone if maize_price_mr==.
tab maize_price_mr, missing


tab rice_price_mr, missing


collapse  (max) maize_price_mr rice_price_mr, by(hhid)


gen rea_maize_price_mr = maize_price_mr   /0.302788
gen real_maize_price_mr = rea_maize_price_mr
tab real_maize_price_mr
sum real_maize_price_mr, detail
gen rea_rice_price_mr = rice_price_mr    /0.302788
gen real_rice_price_mr = rea_rice_price_mr
tab real_rice_price_mr
sum real_rice_price_mr, detail

sort hhid
save "${Nigeria_GHS_W3_created_data}\food_prices_2015.dta", replace




*****************************
*Household Assests
****************************


use "${Nigeria_GHS_W3_raw_data}\sect5_plantingw3.dta",clear 

*s5q1 qty of items
*s5q4 scrap value of item 

sort hhid item_cd

gen hhasset_value  = s5q4*s5q1
tab hhasset_value,missing
sum hhasset_value,detail

/*
replace hhasset_value = 1000000 if hhasset_value > 1000000 & hhasset_value <.
replace hhasset_value = 200 if hhasset_value <200
*/

tab hhasset_value,missing

sum hhasset_value, detail



collapse (sum) hhasset_value, by (hhid)



merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)




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

gen rea_hhvalue = hhasset_value_w    /0.302788
gen real_hhvalue = rea_hhvalue/1000
sum hhasset_value_w real_hhvalue, detail


keep  hhid real_hhvalue

la var real_hhvalue "total value of household asset"
save "${Nigeria_GHS_W3_created_data}\household_asset_2015.dta", replace





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
save "${Nigeria_GHS_W3_created_data}\land_cf.dta", replace

 
 
 
 
 
 
 *************** Plot Size **********************

use "${Nigeria_GHS_W3_raw_data}\sect11a1_plantingw3",clear 
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using  "${Nigeria_GHS_W3_raw_data}\sect11b1_plantingw3"
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W3_raw_data}\secta1_harvestw3.dta", gen(plot_merge)


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
merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}\land_cf.dta", nogen keep(1 3) 


 
 *farmer reported field size for post-planting
gen field_size= area_size*conversion
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
*farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit

 
 
 ***************Measurement in hectares for the additional plots from post-harvest************
******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}\land_cf.dta", nogen keep(1 3) 


replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.               
la var field_size "Area of plot (ha)"
ren plotid plot_id
sum field_size, detail


*Total land holding including cultivated and rented out
collapse (sum) field_size, by (hhid)

merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", gen(wgt)



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
save "${Nigeria_GHS_W3_created_data}\land_holding_2015.dta", replace

 





*******************************
*Soil Quality
*******************************

use "${Nigeria_GHS_W3_raw_data}\sect11a1_plantingw3",clear 
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using  "${Nigeria_GHS_W3_raw_data}\sect11b1_plantingw3"
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W3_raw_data}\secta1_harvestw3.dta", gen(plot_merge)

 
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
merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}\land_cf.dta", nogen keep(1 3) 


 
 *farmer reported field size for post-planting
gen field_size= area_size*conversion
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
*farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit
 ***************Measurement in hectares for the additional plots from post-harvest************
******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W3_created_data}\land_cf.dta", nogen keep(1 3) 


replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.               
la var field_size "Area of plot (ha)"
sum field_size, detail
keep zone state lga sector ea hhid plotid field_size

merge 1:1 hhid plotid using "${Nigeria_GHS_W3_raw_data}\sect11b1_plantingw3.dta"




ren s11b1q45 soil_quality
tab soil_quality, missing


order field_size soil_quality hhid 
sort hhid


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

replace soil_qty_rev3= 2 if soil_qty_rev3==1.5
tab soil_qty_rev3, missing

collapse (mean) soil_qty_rev3  (max)  good_soil fairr_soil, by (hhid)

save "${Nigeria_GHS_W3_created_data}\soil_quality_2015.dta", replace




********************************************************************************
*OFF-FARM HOURS
********************************************************************************
use "${Nigeria_GHS_W3_raw_data}/sect3_harvestw3.dta", clear
gen  hrs_main_wage_off_farm=s3q18 if (s3q14>1 & s3q14!=.) & s3q15b1!=1		// s3q14 1   is agriculture (exclude mining). Also exclude apprenticeship and considered this as unpaid work.
gen  hrs_sec_wage_off_farm= s3q31 if (s3q27>1 & s3q27!=.) & s3q28b1!=1 
gen  hrs_other_wage_off_farm= s3q47 if (s3q44b>1 & s3q44b!=.) 
egen hrs_wage_off_farm= rowtotal(hrs_main_wage_off_farm hrs_sec_wage_off_farm hrs_other_wage_off_farm) 
gen  hrs_main_wage_on_farm=s3q18 if (s3q14<=1 & s3q14!=.)  & s3q15b1!=1		 
gen  hrs_sec_wage_on_farm= s3q31 if (s3q27<=1 & s3q27!=.) & s3q28b1!=1 	 
gen  hrs_other_wage_on_farm= s3q47 if (s3q44b<=1 & s3q44b!=.) 
egen hrs_wage_on_farm= rowtotal(hrs_main_wage_on_farm hrs_sec_wage_on_farm hrs_other_wage_on_farm)
gen  hrs_main_unpaid_off_farm=s3q18 if (s3q14>1 & s3q14!=.) & s3q15b1!=1
gen  hrs_sec_unpaid_off_farm= s3q31 if s3q28b1!=1 
egen hrs_unpaid_off_farm= rowtotal(hrs_main_unpaid_off_farm hrs_sec_unpaid_off_farm)
drop *main* *sec* *other*
recode s3q39_new s3q40_new (.=0) 
gen hrs_domest_fire_fuel=(s3q39_new/60+s3q40_new/60)*7  // hours worked just yesterday
ren  s3q5b hrs_ag_activ
ren  s3q6b hrs_self_off_farm
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
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_off_farm_hours.dta", replace


********************************************************************************
* WAGE INCOME *
********************************************************************************
use "${Nigeria_GHS_W3_raw_data}/sect3_harvestw3.dta", clear
ren s3q13b activity_code
ren s3q14 sector_code
ren s3q12b1 mainwage_yesno
ren s3q16 mainwage_number_months
ren s3q17 mainwage_number_weeks
ren s3q18 mainwage_number_hours
ren s3q21a mainwage_recent_payment
gen ag_activity = (sector_code==1)
replace mainwage_recent_payment = . if ag_activity==1 // exclude ag wages 
ren s3q21b mainwage_payment_period
ren s3q24a mainwage_recent_payment_other
replace mainwage_recent_payment_other = . if ag_activity==1
ren s3q24b mainwage_payment_period_other
ren s3q27 sec_sector_code
ren s3q25 secwage_yesno
ren s3q29 secwage_number_months
ren s3q30 secwage_number_weeks
ren s3q31 secwage_number_hours
ren s3q34a secwage_recent_payment
gen sec_ag_activity = (sec_sector_code==1)
replace secwage_recent_payment = . if sec_ag_activity==1 // exclude ag wages 
ren s3q34b secwage_payment_period
ren s3q37a secwage_recent_payment_other
replace secwage_recent_payment_other = . if sec_ag_activity==1
ren s3q44b other_sector_code
ren s3q37b secwage_payment_period_other
ren s3q42 othwage_yesno
ren s3q45 othwage_number_months
ren s3q46 othwage_number_weeks
ren s3q47 othwage_number_hours
ren s3q49a othwage_recent_payment
replace othwage_recent_payment = . if other_sector_code==1 // exclude ag wages
ren s3q49b othwage_payment_period
gen othwage_recent_payment_other = .
gen othwage_payment_period_other = .
ren s3q4 worked_as_employee
recode  mainwage_number_months secwage_number_months (12/max=12)
recode  mainwage_number_weeks secwage_number_weeks (52/max=52)
recode  mainwage_number_hours secwage_number_hours (84/max=84)
local vars main sec
local vars main sec oth
foreach p of local vars {
	replace `p'wage_recent_payment=. if worked_as_employee!=1
	gen `p'wage_salary_cash = `p'wage_recent_payment if `p'wage_payment_period==8
	replace `p'wage_salary_cash = ((`p'wage_number_months/6)*`p'wage_recent_payment) if `p'wage_payment_period==7
	replace `p'wage_salary_cash = ((`p'wage_number_months/4)*`p'wage_recent_payment) if `p'wage_payment_period==6
	replace `p'wage_salary_cash = (`p'wage_number_months*`p'wage_recent_payment) if `p'wage_payment_period==5
	replace `p'wage_salary_cash = ((`p'wage_number_weeks/2)*`p'wage_recent_payment) if `p'wage_payment_period==4
	replace `p'wage_salary_cash = (`p'wage_number_weeks*`p'wage_recent_payment) if `p'wage_payment_period==3
	replace `p'wage_salary_cash = (`p'wage_number_weeks*(`p'wage_number_hours/8)*`p'wage_recent_payment) if `p'wage_payment_period==2
	replace `p'wage_salary_cash = (`p'wage_number_weeks*`p'wage_number_hours*`p'wage_recent_payment) if `p'wage_payment_period==1
	replace `p'wage_recent_payment_other=. if worked_as_employee!=1
	gen `p'wage_salary_other = `p'wage_recent_payment_other if `p'wage_payment_period_other==8
	replace `p'wage_salary_other = ((`p'wage_number_months/6)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==7
	replace `p'wage_salary_other = ((`p'wage_number_months/4)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==6
	replace `p'wage_salary_other = (`p'wage_number_months*`p'wage_recent_payment_other) if `p'wage_payment_period_other==5
	replace `p'wage_salary_other = ((`p'wage_number_weeks/2)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==4
	replace `p'wage_salary_other = (`p'wage_number_weeks*`p'wage_recent_payment_other) if `p'wage_payment_period_other==3
	replace `p'wage_salary_other = (`p'wage_number_weeks*(`p'wage_number_hours/8)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==2
	replace `p'wage_salary_other = (`p'wage_number_weeks*`p'wage_number_hours*`p'wage_recent_payment_other) if `p'wage_payment_period_other==1
	recode `p'wage_salary_cash `p'wage_salary_other (.=0)
	gen `p'wage_annual_salary = `p'wage_salary_cash + `p'wage_salary_other
}
gen annual_salary = mainwage_annual_salary + secwage_annual_salary + othwage_annual_salary
collapse (sum) annual_salary, by (hhid)
lab var annual_salary "Estimated annual earnings from non-agricultural wage employment over previous 12 months"
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_wage_income.dta", replace


*Ag wage income
use "${Nigeria_GHS_W3_raw_data}/sect3_harvestw3.dta", clear
ren s3q13b activity_code
ren s3q14 sector_code
ren s3q12b1 mainwage_yesno
ren s3q16 mainwage_number_months
ren s3q17 mainwage_number_weeks
ren s3q18 mainwage_number_hours
ren s3q21a mainwage_recent_payment
gen ag_activity = (sector_code==1)
replace mainwage_recent_payment = . if ag_activity!=1 // include only ag wages
ren s3q21b mainwage_payment_period
ren s3q24a mainwage_recent_payment_other
replace mainwage_recent_payment_other = . if ag_activity!=1 // include only ag wages
ren s3q24b mainwage_payment_period_other
ren s3q25 secwage_yesno
ren s3q27 sec_sector_code
ren s3q29 secwage_number_months
ren s3q30 secwage_number_weeks
ren s3q31 secwage_number_hours
ren s3q34a secwage_recent_payment
gen sec_ag_activity = (sec_sector_code==1)
replace secwage_recent_payment = . if sec_ag_activity!=1
ren s3q34b secwage_payment_period
ren s3q37a secwage_recent_payment_other
replace secwage_recent_payment_other = . if sec_ag_activity!=1 // include only ag wages
ren s3q37b secwage_payment_period_other
ren s3q42 othwage_yesno
ren s3q44b other_sector_code
ren s3q45 othwage_number_months
ren s3q46 othwage_number_weeks
ren s3q47 othwage_number_hours
ren s3q49a othwage_recent_payment
replace othwage_recent_payment = . if other_sector_code!=1 // include only ag wages
ren s3q49b othwage_payment_period
gen othwage_recent_payment_other = .
gen othwage_payment_period_other = .
ren s3q4 worked_as_employee
recode  mainwage_number_months secwage_number_months (12/max=12)
recode  mainwage_number_weeks secwage_number_weeks (52/max=52)
recode  mainwage_number_hours secwage_number_hours (84/max=84)
local vars main sec

local vars main sec oth
foreach p of local vars {
	replace `p'wage_recent_payment=. if worked_as_employee!=1
	gen `p'wage_salary_cash = `p'wage_recent_payment if `p'wage_payment_period==8
	replace `p'wage_salary_cash = ((`p'wage_number_months/6)*`p'wage_recent_payment) if `p'wage_payment_period==7
	replace `p'wage_salary_cash = ((`p'wage_number_months/4)*`p'wage_recent_payment) if `p'wage_payment_period==6
	replace `p'wage_salary_cash = (`p'wage_number_months*`p'wage_recent_payment) if `p'wage_payment_period==5
	replace `p'wage_salary_cash = ((`p'wage_number_weeks/2)*`p'wage_recent_payment) if `p'wage_payment_period==4
	replace `p'wage_salary_cash = (`p'wage_number_weeks*`p'wage_recent_payment) if `p'wage_payment_period==3
	replace `p'wage_salary_cash = (`p'wage_number_weeks*(`p'wage_number_hours/8)*`p'wage_recent_payment) if `p'wage_payment_period==2
	replace `p'wage_salary_cash = (`p'wage_number_weeks*`p'wage_number_hours*`p'wage_recent_payment) if `p'wage_payment_period==1
	replace `p'wage_recent_payment_other=. if worked_as_employee!=1
	gen `p'wage_salary_other = `p'wage_recent_payment_other if `p'wage_payment_period_other==8
	replace `p'wage_salary_other = ((`p'wage_number_months/6)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==7
	replace `p'wage_salary_other = ((`p'wage_number_months/4)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==6
	replace `p'wage_salary_other = (`p'wage_number_months*`p'wage_recent_payment_other) if `p'wage_payment_period_other==5
	replace `p'wage_salary_other = ((`p'wage_number_weeks/2)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==4
	replace `p'wage_salary_other = (`p'wage_number_weeks*`p'wage_recent_payment_other) if `p'wage_payment_period_other==3
	replace `p'wage_salary_other = (`p'wage_number_weeks*(`p'wage_number_hours/8)*`p'wage_recent_payment_other) if `p'wage_payment_period_other==2
	replace `p'wage_salary_other = (`p'wage_number_weeks*`p'wage_number_hours*`p'wage_recent_payment_other) if `p'wage_payment_period_other==1
	recode `p'wage_salary_cash `p'wage_salary_other (.=0)
	gen `p'wage_annual_salary = `p'wage_salary_cash + `p'wage_salary_other
}
gen annual_salary_agwage = mainwage_annual_salary + secwage_annual_salary + othwage_annual_salary
collapse (sum) annual_salary_agwage, by (hhid)
lab var annual_salary_agwage "Estimated annual earnings from agricultural wage employment over previous 12 months"
save "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_agwage_income.dta", replace 















global climate "C:\Users\obine\Music\Documents\food_secure\dofile\original\pp_only\CHIRPS"
*--------------------------------------------------------------*
* 1. Load household rainfall dataset
*--------------------------------------------------------------*
use "$climate\Nigeria_y4_hh_coordinates_rainfall_TS_monthly.dta", clear

* Rename rainfall variables to avoid name conflicts after merge
foreach var of varlist rain_2007_01 - rain_2016_12 {
    rename `var' hh_`var'
}

* Save temporary file of household rainfall
tempfile hh_rain
save `hh_rain', replace

*--------------------------------------------------------------*
* 2. Load plot-level dataset and merge rainfall by hhid
*--------------------------------------------------------------*
use "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_all_plots.dta", clear

merge m:1 hhid using `hh_rain'
drop _merge

*--------------------------------------------------------------*
* 3. Transfer household rainfall into plot rainfall variables
*--------------------------------------------------------------*
foreach var of varlist hh_rain_2007_01 - hh_rain_2016_12 {
    local new = subinstr("`var'", "hh_", "", .)   // remove hh_ prefix
    gen `new' = `var'
}

*--------------------------------------------------------------*
* 4. Remove household-prefixed rainfall variables
*--------------------------------------------------------------*
drop hh_rain_2007_01 - hh_rain_2016_12

		

egen total_rain_18_June = rowtotal(rain_2016_03 rain_2016_04 rain_2016_05 rain_2016_06)
egen total_rain_18_July = rowtotal(rain_2016_03 rain_2016_04 rain_2016_05 rain_2016_06 rain_2016_07)

egen mean_rain_18_June  = rowmean(rain_2016_03 rain_2016_04 rain_2016_05 rain_2016_06)
egen mean_rain_18_July  = rowmean(rain_2016_03 rain_2016_04 rain_2016_05 rain_2016_06 rain_2016_07)

*--------------------------------------------------------------*
* 1. Remove rainfall for years you don't want (example: drop 2018)
*--------------------------------------------------------------*
drop rain_2016_*


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
egen mean_rain_2015_Mar = rowmean(rain_2015_03 rain_2015_04 rain_2015_05 rain_2015_06)
gen  dev_rain_2015_Mar  = mean_rain_2015_Mar - mean_rain_Mar_June

egen mean_rain_2015_Aug = rowmean(rain_2015_08 rain_2015_09 rain_2015_10 rain_2015_11 rain_2015_12)
gen  dev_rain_2015_Aug  = mean_rain_2015_Aug - mean_rain_Aug_Dec

*----------------------------------------------------------------------
* 5. Annual mean rainfall (for all years)
*----------------------------------------------------------------------
egen mean_annual_rainfall = rowmean(rain_*_01 rain_*_02 rain_*_03 rain_*_04 rain_*_05 rain_*_06 rain_*_07 rain_*_08 rain_*_09 rain_*_10 rain_*_11 rain_*_12)

*----------------------------------------------------------------------
* 6. Annual shortfall (corrected code using loops)
*----------------------------------------------------------------------
forvalues yr = 2007/2015 {
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
forvalues yr = 2007/2015 {
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
     mean_rain_2015_Mar dev_rain_2015_Mar dev_rain_2015_Aug ///
     shortfall_Mar_June shortfall_Mar_July shortfall_Aug_Dec ///
     sd_shortfall_* *_18_June, by (hhid)

save "${Nigeria_GHS_W3_created_data}/rainfall_15.dta", replace 








*******************************
*Merging Household Level Dataset
*******************************
use  "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_all_plots.dta",clear

sort hhid plot_id
count
*count if cropcode==1080
*keep if cropcode==1080
*keep if purestand ==1
order hhid plot_id  quant_harv_kg value_harvest ha_harvest percent_inputs field_size purestand

collapse (sum) quant_harv_kg value_harvest ha_planted field_size (max) percent_inputs  purestand, by (hhid)
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", nogen

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
gen value_harvest  = real_value_harvest_w/0.302788
sum value_harvest, detail
replace value_harvest=  6295494 if value_harvest>= 6295494





merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/purchased_fert_2015.dta", gen(fert)
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/food_prices_2015.dta", gen (food)
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/household_asset_2015.dta", gen (asset)
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/weight.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/ag_rainy_15.dta", gen(filter)
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/extension_access_2015.dta", gen(diet)
*merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_consumption2.dta", gen(exp)
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_consumption_group2.dta", gen (exp2)
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_weights.dta", gen(hh)
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/soil_quality_2015.dta", gen(soil)
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/demographics_2015.dta", gen(house)
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/land_holding_2015.dta", gen(work)
*merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_shannon_diversity_index.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_off_farm_hours.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_wage_income.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/Nigeria_GHS_W3_agwage_income.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/rainfall_15.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/subsidized_fert_2015.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/shock.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W3_created_data}/haz.dta", nogen


***********************Dealing with outliers*************************


gen year = 2015
sort hhid
misstable summarize haz haz2 peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr  total_qty real_hhvalue field_size hh_members num_mem hh_headage femhead attend_sch  mean_annual_rainfall   zone state lga ea ag_shock nonag_shock land_holding 


replace total_qty_w = 0 if total_qty_w==.
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
egen median_field = median(field_size)
replace field_size = median_field if field_size==.




egen medianfert_dist_ea = median(value_harvest), by (ea)
egen medianfert_dist_lga = median(value_harvest), by (lga)
egen medianfert_dist_state = median(value_harvest), by (state)
egen medianfert_dist_zone = median(value_harvest), by (zone)


replace value_harvest = medianfert_dist_ea if value_harvest ==. 
replace value_harvest = medianfert_dist_lga if value_harvest ==. 
replace value_harvest = medianfert_dist_state if value_harvest ==.

replace value_harvest = medianfert_dist_zone if value_harvest ==. 

egen mean1 = mean (dev_rain_2015_Mar)
egen mean2 = mean (dev_rain_2015_Aug)
egen mean3 = mean (shortfall_Mar)
egen mean4 = mean (mean_annual_rainfall)

ren dev_rain_2015_Mar dev_rain_Mar
ren  dev_rain_2015_Aug dev_rain_Aug


replace dev_rain_Mar = mean1 if dev_rain_Mar ==. 
replace dev_rain_Aug = mean2 if dev_rain_Aug ==. 
replace shortfall_Mar = mean3 if shortfall_Mar ==. 
replace mean_annual_rainfall = mean4 if mean_annual_rainfall ==. 


tabstat haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea  [w=weight], statistics( mean median sd min max ) columns(statistics)


misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr  total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea

misstable summarize hhid haz haz2 peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr  total_qty real_hhvalue field_size hh_members num_mem hh_headage femhead attend_sch  mean_annual_rainfall   zone state lga ea ag_shock nonag_shock land_holding 

save "${Nigeria_GHS_W3_created_data}/final_15.dta", replace
