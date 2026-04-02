



clear

global Nigeria_GHS_W1_raw_data 		"C:\Users\obine\Music\Documents\Smallholder lsms STATA\NGA_2010_GHSP-W1_v03_M_STATA (1)" 
global Nigeria_GHS_W1_created_data  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_one"








********************************************************************************
* AG FILTER *
********************************************************************************

use "${Nigeria_GHS_W1_raw_data}/Post Planting Wave 1\Agriculture\sect11a_plantingw1.dta" , clear

keep hhid s11aq1
rename (s11aq1) (ag_rainy_10)
save  "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", replace



*merge m:1 hhid using ""${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

*keep if ag_rainy_10==1


********************************************************************************
* WEIGHTS *
********************************************************************************

use "${Nigeria_GHS_W1_raw_data}/Post Planting Wave 1\Household\secta_plantingw1.dta" , clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave1 rural
ren wt_wave1 weight
collapse (max) weight rural, by (hhid)
save  "${Nigeria_GHS_W1_created_data}/weight.dta", replace



************************
*Geodata Variables
************************
use "${Nigeria_GHS_W1_raw_data}\Geodata\NGA_PlotGeovariables_Y1.dta", clear

collapse (max) srtmslp_nga srtm_nga twi_nga, by (hhid)

merge 1:m hhid using "${Nigeria_GHS_W1_raw_data}\Geodata\NGA_HouseholdGeovariables_Y1.dta"

merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

ren srtmslp_nga plot_slope
ren srtm_nga  plot_elevation
ren twi_nga   plot_wetness
ren af_bio_12 annual_precipitation
ren af_bio_1 annual_mean_temp
ren dist_market dist_market



tab1 plot_slope plot_elevation plot_wetness, missing

egen med_slope = median( plot_slope)
egen med_elevation = median( plot_elevation)
egen med_wetness = median( plot_wetness)
egen med_prep = median( annual_precipitation)
egen med_temp = median( annual_mean_temp)

replace plot_slope= med_slope if plot_slope==.
replace plot_elevation= med_elevation if plot_elevation==.
replace plot_wetness= med_wetness if plot_wetness==.
replace annual_precipitation= med_prep if annual_precipitation==.
replace annual_mean_temp= med_temp if annual_mean_temp==.

sum annual_precipitation, detail
sum annual_mean_temp, detail
sum dist_market, detail


collapse (max) plot_slope plot_elevation plot_wetness  annual_precipitation annual_mean_temp dist_market, by (hhid)
sort hhid


merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

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

keep hhid plot_slope plot_elevation plot_wetness  annual_precipitation annual_mean_temp dist_market_w

la var plot_slope "slope of plot"
la var plot_elevation "Elevation of plot"
la var plot_wetness "Potential wetness index of plot"
save "${Nigeria_GHS_W1_created_data}\geodata.dta", replace







/********************************************************************
WHO 2006 Height-for-Age Z-score (HAZ)
Case where measurement position variable is NOT available
Use age-based WHO convention:
  0–23 months  = recumbent length
  24–59 months = standing height
********************************************************************/

use "${Nigeria_GHS_W1_raw_data}\sect4a_harvestw1.dta", clear
merge 1:1 hhid indiv using "${Nigeria_GHS_W1_raw_data}\sect1_harvestw1.dta", nogen

*--------------------------------------------------------------*
* 0. Keep children aged 0–59 months
*--------------------------------------------------------------*
keep if s4aq51 == 1

*--------------------------------------------------------------*
* 1. Age in months
*    Replace s1q4 with the correct age-in-years variable if needed
*--------------------------------------------------------------*
gen age_months = s1q4 * 12
replace age_months = . if age_months < 0 | age_months > 59

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

collapse (mean) haz (max) s4aq51, by(hhid)

gen haz2 = haz
replace haz2 = 3.06 if haz > 3.06 
sum haz, detail
sum haz2, detail
save  "${Nigeria_GHS_W1_created_data}/haz.dta", replace





********************************************************************************
* SHOCK *
********************************************************************************

use "${Nigeria_GHS_W1_raw_data}\sect15a_harvestw1.dta", clear

*gen shock = 1 if s15aq1==1 & shock_cd ==12 | shock_cd ==13 | shock_cd ==14
gen ag = 1 if shock_cd ==12 | shock_cd ==13 | shock_cd ==14
gen shock1 if ag = 1 & s15aq1==1
replace shock1 = 0 if shock1==.

gen shock =1 if (s15aq1==1)
replace shock = 0 if shock==.
collapse (max) shock shock1, by (hhid)
tab shock
tab shock1
save  "${Nigeria_GHS_W1_created_data}/shock.dta", replace
















********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
												//ALT NB: These are the 2017 values because we convert to PPP after inflation 
global Nigeria_GHS_W1_exchange_rate 401.15  		// https://www.bloomberg.com/quote/USDETB:CUR, https://data.worldbank.org/indicator/PA.NUS.FCRF?end=2023&locations=NG&start=2011
// {2017:315,2021:401.15}
global Nigeria_GHS_W1_gdp_ppp_dollar 146.72		// https://data.worldbank.org/indicator/PA.NUS.PRVT //2021
global Nigeria_GHS_W1_cons_ppp_dollar 155.72		// https://data.worldbank.org/indicator/PA.NUS.PRVT.P //2021
global Nigeria_GHS_W1_inflation 0.312729		//2017: 110.8/214.2, 2021: 110.8/354.3		// inflation rate 2011-2016. Data was collected during 2010-2011. We want to adjust value to 2016 //ALT 03.09.23 Now 2017 per WB's fall update to the poverty line

global Nigeria_GHS_W1_poverty_190 (1.90*83.58) //Calculation for WB's previous $1.90 (PPP) poverty threshold, 158 N. This controls the indicator poverty_under_1_9; change the 1.9 to get results for a different threshold
global Nigeria_GHS_W1_poverty_npl (151 *(1.108)) //2009-2010 poverty line from https://nigerianstat.gov.ng/elibrary/read/544 adjusted to 2011
global Nigeria_GHS_W1_poverty_215 (2.15 * (0.5173 * 112.1))	 // 2017 poverty line - 124.68 N
global Nigeria_GHS_W1_poverty_300 (3.00 *($Nigeria_GHS_W1_inflation * $Nigeria_GHS_W1_cons_ppp_dollar)) //New 2021 poverty line ~690N
 
********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables



*DYA.11.1.2020 Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Nigeria_GHS_W1_pop_tot 158503197
global Nigeria_GHS_W1_pop_rur 89586007
global Nigeria_GHS_W1_pop_urb 68917190







********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Nigeria_GHS_W1_raw_data}/secta_plantingw1.dta", clear
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave1 rural
ren wt_wave1 weight
save  "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhids.dta", replace




********************************************************************************
* INDIVIDUAL IDS *
********************************************************************************
use "${Nigeria_GHS_W1_raw_data}/sect1_plantingw1.dta", clear
gen season="plan"
append using "${Nigeria_GHS_W1_raw_data}/sect1_harvestw1.dta"
replace season="harv" if season==""

ren s1q2 sex
ren s1q4 age
gen female= sex==2

gen fhh = s1q3==1 & female
recode fhh (.=0)
preserve 
collapse (max) fhh, by(hhid)
tempfile fhh
save `fhh'
restore 
la var female "1= individual is female"
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

la var female "1= individual is female"
la var age "Individual age"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_person_ids.dta", replace






********************************************************************************
* HOUSEHOLD SIZE *
********************************************************************************
use "${Nigeria_GHS_W1_raw_data}/sect1_plantingw1.dta", clear
gen hh_members = 1
ren s1q3 relhead 
ren s1q2 gender
gen fhh = (relhead==1 & gender==2)
collapse (sum) hh_members (max) fhh, by (hhid)
lab var hh_members "Number of household members"
lab var fhh "1= Female-headed household"
*DYA.11.1.2020 Re-scaling survey weights to match population estimates
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhids.dta", nogen
*Adjust to match total population
total hh_members [pweight=weight]
matrix temp =e(b)
gen weight_pop_tot=weight*${Nigeria_GHS_W1_pop_tot}/el(temp,1,1)
total hh_members [pweight=weight_pop_tot]
lab var weight_pop_tot "Survey weight - adjusted to match total population"
*Adjust to match total population but also rural and urban
total hh_members [pweight=weight] if rural==1
matrix temp =e(b)
gen weight_pop_rur=weight*${Nigeria_GHS_W1_pop_rur}/el(temp,1,1) if rural==1
total hh_members [pweight=weight_pop_tot]  if rural==1

total hh_members [pweight=weight] if rural==0
matrix temp =e(b)
gen weight_pop_urb=weight*${Nigeria_GHS_W1_pop_urb}/el(temp,1,1) if rural==0
total hh_members [pweight=weight_pop_urb]  if rural==0

egen weight_pop_rururb=rowtotal(weight_pop_rur weight_pop_urb)
total hh_members [pweight=weight_pop_rururb]  
lab var weight_pop_rururb "Survey weight - adjusted to match rural and urban population"
drop weight_pop_rur weight_pop_urb
recast double weight*
/*
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhsize.dta", replace
*/
keep hhid zone state lga ea weight* rural hh_members fhh
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_weights.dta", replace



********************************************************************************
*CONSUMPTION
********************************************************************************
use "${Nigeria_GHS_W1_raw_data}/sect1_plantingw1.dta", clear
merge 1:1 hhid indiv using "${Nigeria_GHS_W1_raw_data}/sect1_harvestw1.dta"
ren s1q2 gender
ren s1q4 age
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
collapse (sum) adulteq, by(hhid)
lab var adulteq "Adult-Equivalent"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hh_adulteq.dta", replace 




use "${Nigeria_GHS_W1_raw_data}/cons_agg_wave1_visit2.dta", clear

egen cereals_only = rowtotal (fdsorby fdmilby fdmaizby fdriceby fdyamby fdcasby fdcereby fdbrdby fdsorpr fdmilpr fdmaizpr fdricepr fdyampr fdcaspr fdcerepr fdbrdpr)
egen protein_only = rowtotal (fdpoulby fdmeatby fdfishby fddairby fdfatsby fdbeanby  fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdbeanpr )
egen fruits_vegetables = rowtotal (fdtubby fdfrutby fdvegby fdtubpr fdfrutpr fdvegpr)


merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_weights.dta", nogen keepusing(hh_members)
save "${Nigeria_GHS_W1_created_data}/cons_agg_wave1_visit2group.dta", replace





use "${Nigeria_GHS_W1_raw_data}/cons_agg_wave1_visit1.dta", clear


egen cereals_only = rowtotal (fdsorby fdmilby fdmaizby fdriceby fdyamby fdcasby fdcereby fdbrdby fdsorpr fdmilpr fdmaizpr fdricepr fdyampr fdcaspr fdcerepr fdbrdpr)
egen protein_only = rowtotal (fdpoulby fdmeatby fdfishby fddairby fdfatsby fdbeanby  fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdbeanpr )
egen fruits_vegetables = rowtotal (fdtubby fdfrutby fdvegby fdtubpr fdfrutpr fdvegpr)


merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_weights.dta", nogen keepusing(hh_members)
save "${Nigeria_GHS_W1_created_data}/cons_agg_wave1_visit1group.dta", replace




ren cereals_only totcons_cereal_pp
ren protein_only totcons_protein_pp 
ren fruits_vegetables totcons_veg_pp


merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/cons_agg_wave1_visit2group.dta", nogen keepusing(cereals_only protein_only fruits_vegetables)
ren cereals_only totcons_cereal_ph
ren protein_only totcons_protein_ph 
ren fruits_vegetables totcons_veg_ph

*gen totcons_cereal = (totcons_cereal_pp+totcons_cereal_ph)/2
gen totcons_cereal = totcons_cereal_pp
*gen totcons_protein = (totcons_protein_pp+totcons_protein_ph)/2
gen totcons_protein = totcons_protein_pp
*gen totcons_fruit_veg = (totcons_veg_pp+totcons_veg_ph)/2
gen totcons_fruit_veg = totcons_veg_pp

merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hh_adulteq.dta", nogen keep(1 3) keepusing(adulteq)



gen daily_peraeq_cons1 = totcons_cereal/adulteq 
gen daily_peraeq_cons2 = totcons_protein/adulteq 
gen daily_peraeq_cons3 = totcons_fruit_veg/adulteq 

gen peraeq_cons_cereal = daily_peraeq_cons1*365
gen peraeq_cons_protein = daily_peraeq_cons2*365
gen peraeq_cons_veg = daily_peraeq_cons3*365

gen totalcons_cereal = totcons_cereal*365
gen totalcons_protein = totcons_protein*365
gen totalcons_veg = totcons_fruit_veg*365



ren totcons_cereal totcons_cereal_n
ren totcons_protein totcons_protein_n
ren totcons_fruit_veg totcons_fruit_veg_n


ren peraeq_cons_cereal peraeq_cons_cereal_n
ren peraeq_cons_protein peraeq_cons_protein_n
ren peraeq_cons_veg peraeq_cons_veg_n


ren totalcons_cereal totalcons_cereal_n
ren totalcons_protein totalcons_protein_n
ren totalcons_veg totalcons_veg_n


gen totcons_cereal = totcons_cereal_n /0.190511
gen totcons_protein = totcons_protein_n /0.190511
gen totcons_fruit_veg = totcons_fruit_veg_n /0.190511

gen peraeq_cons_cereal = peraeq_cons_cereal_n /0.190511
gen peraeq_cons_protein = peraeq_cons_protein_n /0.190511
gen peraeq_cons_veg = peraeq_cons_veg_n /0.190511


gen totalcons_cereal = totalcons_cereal_n /0.190511
gen totalcons_protein = totalcons_protein_n /0.190511
gen totalcons_veg = totalcons_veg_n /0.190511
    
		
keep hhid adulteq totcons_cereal totcons_protein  totcons_fruit_veg peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_group2.dta", replace




use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_group2.dta", clear 

merge 1:1 hhid using   "${Nigeria_GHS_W1_created_data}/haz.dta", nogen

keep if s4aq51 ==1
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_group2.dta", replace 








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
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_landcf.dta", replace
use "${Nigeria_GHS_W1_raw_data}/sect11a1_plantingw1", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using "${Nigeria_GHS_W1_raw_data}/sect11b_plantingw1", nogen
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W1_raw_data}/secta1_harvestw1.dta", gen(plot_merge)
gen rented_out=s11bq18==2010 //Applies to four plots
ren s11aq4a area_size
ren s11aq4b area_unit
ren sa1q9a area_size2
ren sa1q9b area_unit2
ren s11aq4d area_meas_sqm
ren sa1q9d area_meas_sqm2
recode area_meas_sqm area_meas_sqm2 area_size area_size2 (0=.)
replace area_meas_sqm = . if area_meas_sqm < 10
replace area_meas_sqm2 = . if area_meas_sqm < 10
gen area_meas_ha=area_meas_sqm*0.0001
replace area_meas_ha=area_meas_sqm*0.0001 if area_meas_ha==.
gen cultivate = s11bq16 ==1 
*assuming new plots are cultivated
replace cultivate = 1 if sa1q3==1
merge m:1 zone area_unit using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_landcf.dta", nogen keep(1 3) 
*farmer reported field size for post-planting
gen field_size= area_size*conversion
*farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit
merge m:1 zone area_unit using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_landcf.dta", nogen keep(1 3)
replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_ha if area_meas_ha!=. 			
gen gps_meas = area_meas_ha!=.
la var gps_meas "Plot was measured with GPS, 1=Yes"
*replacing farmer reported with GPS if available
la var field_size "Area of plot (ha)"
ren plotid plot_id
preserve
keep hhid plot_id field_size area_meas_ha gps_meas cultivate rented_out
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_plot_areas.dta", replace
restore

*Plot decisionmakers.
*Using planting data 	
//Post-Planting
*First manager 

gen indiv1 = s11aq6
gen indiv2 = s11bq8a 
gen indiv3 = s11bq8b 
gen indiv4 = s11bq8c 
gen indiv5 = s11bq8d
gen indiv6 = sa1q11
gen indiv7 = sa1q16a
gen indiv8 = sa1q16b 
gen indiv9 = sa1q16c 
gen indiv10 = sa1q16d 

//Using first-listed managers in situations where where the main manager is missing
replace indiv1=indiv6 if indiv1==.
replace indiv1=indiv2 if indiv1==. 
replace indiv1=indiv7 if indiv1==.
keep hhid plot_id indiv* 
reshape long indiv, i(hhid plot_id) j(individ)
collapse (min) individ, by(hhid plot_id indiv) //Remove duplicates, ensure every plot has a manager
merge m:1 hhid indiv using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_person_ids.dta", keep(1 3) nogen
preserve
keep hhid plot_id indiv female
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_dm_ids.dta", replace 
restore
gen dm1_gender=female+1 if individ==1
gen dm1_id=indiv if individ==1
collapse (mean) female (firstnm) dm1_gender dm1_id, by(hhid plot_id)
gen dm_gender = 3 if female!=.
replace dm_gender = 1 if female==0
replace dm_gender = 2 if female==1
*replacing observations without gender of plot manager with gender of HOH
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_weights.dta", nogen keep(1 3) keepusing(fhh)
replace dm1_gender = dm_gender if dm_gender < 3 & dm1_gender==.
replace dm1_gender =fhh +1 if dm_gender==. 
replace dm_gender =fhh+1 if dm_gender==.
gen dm_male = dm_gender==1
gen dm_female = dm_gender==2
gen dm_mixed = dm_gender==3
keep plot_id hhid dm* fhh
la var dm1_id "Individual ID of main decisionmaker"
la var dm_gender "Gender category of all plot decisionmakers"
la var dm1_gender "Gender of main decisionmaker"
la def genderlab 1 "Male" 2 "Female" 3 "Mixed"
la val dm_gender genderlab
la val dm1_gender genderlab
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_plot_decision_makers", replace




********************************************************************************
*crop unit conversion factors
********************************************************************************
use "${Nigeria_GHS_W1_raw_data}/w1agnsconversion", clear
ren agcropid crop_code
/*gen size = 1 if inlist(nscode, 11,21,31...etc)
replace size=2 if inlist(nscode,12,22,..etc)
la def sizecd 1 "small" 2 "medium" 3 "large"
la val size sizecd
gen unit=10 if nscode <=14*/
*gen stringnscode = string(nscode)
*Need to parse this out so that the KGs are in another column... numerical to string?
*drop if kg==0
ren nscode unit
ren conversion  conv_fact
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_ng3_cf.dta", replace





********************************************************************************
*ALL PLOTS
********************************************************************************

use "${Nigeria_GHS_W1_raw_data}/secta3_harvestW1.dta", clear
	keep if sa3q3==1
	ren sa3q11a qty1
	ren sa3q11b unit1
	ren sa3q12 value1
	replace unit1 = sa3q6b if unit1==.
	replace qty1=sa3q6a if unit1!=. & unit1==sa3q6b & (qty1==0 | qty1==.)
	replace qty1 = . if unit1==. | qty1==0 

	//This adds ~150 obs
	ren sa3q16a qty2
	ren sa3q16b unit2
	ren sa3q17 value2
	ren sa3q2 crop_code
	keep zone state lga sector ea hhid crop_code qty* unit* value*
	gen dummy = _n
	reshape long qty unit value, i(zone state lga sector ea hhid crop_code dummy) j(idno)
	drop idno dummy //not necessary
	merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_weights.dta", nogen keepusing(weight_pop_rururb)
	gen weight=weight_pop_rururb*qty
	//ren cropcode crop_code
	gen price_unit = value/qty
	gen obs=price_unit!=.
	foreach i in zone state lga ea hhid {
		preserve
		collapse (median) price_unit_`i'=price_unit (rawsum) obs_`i'_price =obs [aw=weight], by (`i' unit crop_code) 
		tempfile price_unit_`i'_median
		save `price_unit_`i'_median'
		restore
	}
	preserve
	collapse (median) price_unit_country = price_unit (rawsum) obs_country_price=obs [aw=weight], by(crop_code unit)
	tempfile price_unit_country_median
	//save `price_unit_country_median'
	save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_crop_prices_median_country.dta", replace
	restore
	merge m:1 crop_code unit using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_ng3_cf.dta", nogen keep(1 3)
	replace conv_fact=1 if unit==1 & conv_fact==.
	replace conv_fact=0.001 if unit==2 & conv_fact==. 
	gen qty_kg = qty*conv_fact 
	drop if qty_kg==. //34 dropped; largely basin and bowl.
	gen price_kg = value/qty_kg
	replace weight=weight_pop_rururb*qty_kg
	drop obs
	gen obs=price_kg !=.
	keep if obs == 1
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

use "${Nigeria_GHS_W1_raw_data}/sect11f_plantingW1.dta", clear
	gen field_crop = 1
	drop if s11fq1a == . & s11fq4a == . //ALT: a few stray obs 
append using "${Nigeria_GHS_W1_raw_data}/sect11g_plantingW1.dta"
	
	replace field_crop = 0 if field_crop==.
	drop if field_crop == 0 & (s11gq1a == . & s11gq2==. & s11gq8a==.)

//ALT 03.23.23: This should be a straightforward append since one module is for field crops and the other for tree crops, but some harvest information for field crops is present in section g and some planting information for tree crops is present in section f. A collapse firstnm should resolve but won't reveal if there are clashes. 
//Verifying that we aren't losing any information
/*
	preserve 
	ds, has(type string)
	drop `r(varlist)'
	collapse (count) s11fq1a-s11gq8b, by(zone state lga sector ea hhid plotid cropid cropcode)
	sum s11* //max one obs per row
	restore
*/
	collapse (firstnm) s11fq1a-s11gq8c, by(zone state lga sector ea hhid plotid cropid cropcode)
	duplicates report hhid plotid cropid //superfluous obs are trimmed. Only problem is now field crop might be inaccurate
	drop field_crop
	ren cropcode crop_code_full
	gen perm_crop=(s11gq2!=.)
	gen number_trees_planted = s11gq2
	replace number_trees_planted=. if number_trees_planted==999 //999 = farmer doesn't know. Still a permanent crop, we just don't know how many there are. Attempting to estimate based on normal stand densities is unreliable.
	tempfile  droppedid
	save `droppedid'
	use "${Nigeria_GHS_W1_raw_data}/secta3_harvestW1.dta", clear 
	drop if strpos(sa3q4b, "BEFORE") | strpos(sa3q4b, "B/F") | strpos(sa3q4b, "B/4") //Drop crops that were completely harvested prior to previous interview. 
	*took the decision to drop cropid since 8 obs were missing and the data needs to be uniquely identified
	drop if cropid==. | strpos(sa3q1, "FALLOW")
	merge 1:1 hhid plotid cropid using `droppedid', nogen
	replace crop_code_full = sa3q2 if crop_code_full==.
	gen crop_code = crop_code_full
	ren plotid plot_id
	merge m:1 hhid plot_id using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_plot_areas", nogen keep(1 3) keepusing(field_size gps_meas)
		recode crop_code (1053=1051) (1052=1050) /*keeping cottonseed and cotton separate*/ (1061 1062 = 1060) (1081 1082 1083=1080) (1091 1092 = 1090) /*melon seed different from watermelon*/ (1112 1111=1110) (2191 2192 2193=2190) /*Counting this generically as pumpkin, but it is different commodities (note that original cropcode is used for pricing)
	*/				 (3181 3182 3183 3184 = 3180) (2170=2030) (3113 3112 3111 = 3110) (3022=3020) (2142 2141 = 2140) (1121 1122 1123 1124=1120)
	la def cropcode 1120 "yam", modify
	la values crop_code cropcode
	drop if crop_code == . //Non-cultivated plots
	gen area_unit=s11fq1b
	replace area_unit=s11gq1b if area_unit==.
	merge m:1 zone area_unit using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_landcf.dta", nogen keep(1 3)
	gen ha_planted = s11fq1a*conversion
	replace ha_planted = s11gq1a*conversion if ha_planted==.
	recode ha_planted (0=.)
	drop conversion area_unit
	ren sa3q5b area_unit
	merge m:1 zone area_unit using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_landcf.dta", nogen keep(1 3)
	gen ha_harvest = sa3q5a*conversion
	replace ha_harvest = ha_planted if perm_crop==1 & s11gq8a!=0 & s11gq8a!=.
	replace ha_planted = ha_harvest if ha_planted==. & ha_harvest!=. & ha_harvest!=0 //1398 changes
	gen month_planted = s11fq3a
	preserve
		gen obs=1
		collapse (max) obs, by(hhid plot_id crop_code)
		collapse (sum) crops_plot=obs, by(hhid plot_id)
		tempfile ncrops 
		save `ncrops'
	restore //286 plots have >1 crop but list monocropping, 382 say intercropping; meanwhile 130 list intercropping or mixed cropping but only report one crop
	merge m:1 hhid plot_id using `ncrops', nogen
	/* To be revisited.
	gen lost_crop=inrange(sa3q4,1,5) & perm_crop!=1
	bys hhid plot_id : egen max_lost = max(lost_crop)
	gen replanted = (max_lost==1 & crops_plot>0)
	preserve 
		keep if replanted == 1 & lost_crop == 1 //we'll keep this for planting area, which might cause the plot to go over 100% planted 
		keep zone state lga ea hhid crop_code plot_id ha_planted lost_crop dm_gender
		tempfile lost_crops
		save `lost_crops'
	restore
	drop if replanted==1 & lost_crop==1 //Crop expenses should count toward the crop that was kept, probably.
*/
	//95 plots did not replant; keeping and assuming yield is 0.
	//bys hhid plot_id : egen crops_avg = mean(crop_code_master) //Checks for different versions of the same crop in the same plot
	gen purestand=1 if crops_plot==1 //This includes replanted crops
	/*
	replace s11fq3b = . if s11fq3b < 1980 | s11fq3b > 2011 //Some invalid entries
	gen date_planted = ym(s11fq3b, s11fq3a)
	replace date_planted = ym(s11gq3, 1) if date_planted==. // No month, so assuming January
	format date_planted %tm
	//Large number of missing obs here; doesn't look like there's an alternative way to get this info.
	replace perm_crop = 1 if crop_code==1020 & (sa3q4==9)  //ALT: While cassava is typically a multi-year crop, some reports of a roughly 6 month growing turnaround - growing for stems, maybe? Assuming things that haven't been harvested are still on the plot
	bys hhid plot_id : egen permax = max(perm_crop)
	bys hhid plot_id date_planted : gen plant_date_unique=_n
	bys hhid plot_id : egen plant_dates = max(plant_date_unique)
	replace purestand=0 if (crops_plot>1 & !(plant_dates>1))  | (crops_plot>1 & permax==1)  //Multiple crops planted or harvested in the same month are not relayed; may omit some crops that were purestands that preceded or followed a mixed crop.
	gen any_mixed = !(s11fq2==1 | s11fq2==3)
	bys hhid plot_id : egen any_mixed_max = max(any_mixed)
	gen relay=1 if crops_plot>1 & plant_dates>1 /*& harv_dates==1*/ & permax==0 //Looks like relay crops are reported either as relays or as monocrops 
	replace purestand=0 if purestand==.
	drop crops_plot /*crops_avg*/ plant_dates /*harv_dates*/ plant_date_unique /*harv_date_unique*/ permax
	*/
	
	gen percent_field=ha_planted/field_size
	gen pct_harv = ha_harvest/ha_planted 
	replace pct_harv = 1 if ha_harv > ha_planted & ha_harv!=.
	replace pct_harv = 0 if pct_harv==. & sa3q4 < 6
	
*Generating total percent of purestand and monocropped on a field
	bys hhid plot_id: egen tot_ha_planted = sum(ha_planted)
	replace tot_ha_planted=. if ha_planted==.
	replace field_size = tot_ha_planted if field_size==. //assuming crops are filling the plot when plot area is not known.
//about 60% of plots have a total intercropped sum greater than 1
//about 3% of plots have a total monocropped sum greater than 1
//Dealing with crops which have monocropping larger than plot size or monocropping that fills plot size and still has intercropping to add
	replace percent_field = ha_planted/tot_ha_planted if tot_ha_planted >= field_size & purestand==0 //Adding the = to catch plots that were filled in on line 570
	replace percent_field = 1 if tot_ha_planted>=field_size & purestand==1
	replace ha_planted = percent_field*field_size if (tot_ha_planted > field_size) & field_size!=. & ha_planted!=.
	replace ha_harvest = pct_harv*ha_planted


	*renaming unit code for merge
	ren sa3q6b unit 
	//replace unit = s11fq11b if unit==.
	ren sa3q6a quantity_harvested
	//replace quantity_harvested = s11fq11a if quantity_harvested==.
	*merging in conversion factors
	//ren crop_code_a3i crop_code
	//temporary juggle for merge
	ren crop_code crop_code_short
	ren crop_code_full crop_code
	merge m:1 crop_code unit using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_ng3_cf.dta", keep(1 3) gen(cf_merge)

	//Back-converting processed palm oil into oil palm fruit kg 
	replace quantity_harvested = quantity_harvested*0.89*10 if crop_code==3180 & unit==91
	replace quantity_harvested = quantity_harvested*0.89*20 if crop_code==3180 & unit==92
	replace quantity_harvested = quantity_harvested*0.89*25 if crop_code==3180 & unit==93
	replace quantity_harvested = quantity_harvested*0.89*50 if crop_code==3180 & unit==94
	replace quantity_harvested = quantity_harvested*0.89 if crop_code==3180 & unit==3
	replace quantity_harvested=quantity_harvested/0.17 if crop_code==3180 & inlist(unit,91,92,93,94,3) //Oil content (w/w) of oil palm fruit, 
	replace unit=1 if crop_code==3180 & inlist(unit,91,92,93,94,3)
	replace unit=1 if sa3q3==1 & unit==. & quantity_harvested==0
	replace unit=1 if (sa3q19b==1 | sa3q19b==.) & (sa3q20b==1 | sa3q20b==.) & (sa3q21b==1 | sa3q21b==.) & (sa3q22b==. | sa3q22b==1) & (sa3q23b==1 | sa3q23b==.) & !(sa3q19b==. & sa3q20b==. & sa3q21b==. & sa3q22b==.)
	replace conv_fact=1 if unit==1
	replace conv_fact=0.001 if unit==2
	//92 entries w/o conversions at this point.
	gen quant_harv_kg= quantity_harvested*conv_fact

foreach i in zone state lga ea hhid {
	merge m:1 `i' unit crop_code using `price_unit_`i'_median', nogen keep(1 3)
	merge m:1 `i' crop_code using `price_kg_`i'_median', nogen keep(1 3)
}

merge m:1 unit crop_code using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_crop_prices_median_country.dta", nogen keep(1 3)
merge m:1 crop_code using `price_kg_country_median', nogen keep(1 3)

unab obs_vars : obs_*
foreach var in `obs_vars' {
	recode `var' (.=0)
}
gen price_unit = .
gen price_kg = .

foreach i in country zone state lga ea {
	replace price_unit = price_unit_`i' if obs_`i'_price>9 & price_unit_`i' !=.
	replace price_kg = price_kg_`i' if obs_`i'_pkg>9 & price_kg_`i' !=.
}

replace price_unit_hh = price_unit if price_unit_hh==.
replace price_kg_hh = price_kg if price_kg_hh==.
	gen value_harvest = price_unit * quantity_harvested
	replace value_harvest=price_kg*quant_harv_kg if value_harvest==.
	
	gen value_harvest_hh=price_unit_hh*quantity_harvested 
	replace value_harvest_hh=price_kg_hh*quant_harv_kg if value_harvest_hh==.
//Note we can also subsitute local values for households with weird prices, which might work better than winsorizing.
	//Replacing conversions for unknown units
	gen val_unit = value_harvest/quantity_harvested
preserve
	
	collapse (mean) val_unit, by (hhid crop_code unit)
	ren val_unit hh_price_mean
	lab var hh_price_mean "Average price reported for this crop-unit in the household"
	save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hh_crop_prices_for_wages.dta", replace
restore

//restoring shortened crop_code list. 
	ren crop_code crop_code_full
	ren crop_code_short crop_code 
//AgQuery
	//gen date_planted = ym(s11fq3b, s11fq3a)
	//format date_planted %tm
	//ALT: Some duplicate entries with planting date missing 
	//bys hhid plot_id crop_code_full : egen min_date_planted = min(date_planted)
	//replace date_planted = min_date_planted if date_planted == .
	//replace date_planted = . if perm_crop == 1  //Removing perm crops from the picture for the moment because you can have trees/cassava that's been planted years apart 
	//ALT: At this point there are still a few duplicate entries, mainly yam. In the north, there's a couple households that appear to be following a defined pattern of planting one yam species in November and a second in April, probably in some sort of relay fashion (can't tell b/c we don't have harvest dates)
	//Some are missing harvest values and might be replants but they're not always chronologically later
	gen no_harvest = sa3q4 > 6 & sa3q4 < 10
	replace crop_code=1124 if crop_code_full==1124 //Unlumping three-leaved yam.
	collapse (sum) quant_harv_kg value_harvest* ha_planted ha_harvest number_trees_planted percent_field /*(max) months_grown*/ (max) no_harvest, by(zone state lga sector ea hhid plot_id crop_code /*crop_code_full*/ purestand /*relay*/ field_size gps_meas /*date_planted*/) //ALT 06.15.23: To implement
	drop if (ha_planted==0 | ha_planted==.) & (ha_harv==0 | ha_harv==.) & (quant_harv_kg==0)
	replace ha_harvest=. if (ha_harvest==0 & no_harvest==1) | (ha_harvest==0 & quant_harv_kg>0 & quant_harv_kg!=.)
	replace value_harvest =. if value_harvest==0 & (no_harvest==1 | (quant_harv_kg!=0 & quant_harv_kg!=.))
	replace quant_harv_kg = . if quant_harv_kg==0 & no_harvest==1
	drop no_harvest
	recode ha_planted (0=.) 
	bys hhid plot_id : egen percent_area = sum(percent_field)
	bys hhid plot_id : gen percent_inputs = percent_field/percent_area
	bys hhid plot_id : gen obs = _N
	replace purestand=0 if obs > 1 //A few fixes due to the yam recode.
	drop percent_area obs //Assumes that inputs are +/- distributed by the area planted. Probably not true for mixed tree/field crops, but reasonable for plots that are all field crops
	//Labor should be weighted by growing season length, though. 
	//append using `lost_crops'
	//recode lost_crop (.=0)
	merge m:1 hhid plot_id using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_plot_decision_makers.dta", nogen keep(1 3) keepusing(dm*)
	//We remove small planted areas from the sample for yield, as these areas are likely undermeasured/underestimated and cause substantial outliers. The harvest quantities are retained for farm income and production estimates. 
	gen ha_harv_yld = ha_harvest if ha_planted >=0.05
	gen ha_plan_yld = ha_planted if ha_planted >=0.05
	save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_all_plots.dta",replace











****************************
*Subsidized Fertilizer
****************************
use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Agriculture\sect11d_plantingw1.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
*graph bar (count), over(s11dq13)

*s11dq13 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq24 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq15 s11dq26  qty of inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer




encode s11dq13, gen(institute)
label list institute


encode s11dq24, gen(institute2)
label list institute2

**THIS IS BASED ON THE ASSUMPTION THAT GOVERNMENT PURCHASED FERTILIZER IS LESS THAN FERTILIZER PURCHASED IN THE LOCAL MARKET


*************Getting Subsidized quantity and Dummy Variable ******************* we are using N2 and N3
gen subsidy_qty1 = s11dq15 if institute ==6 | institute ==7 //8 should be government extension worker
tab subsidy_qty1
gen subsidy_qty2 = s11dq26 if institute2 ==3 | institute2 ==4 // 5 should be government extension worker
tab subsidy_qty2


egen subsidy_qty = rowtotal(subsidy_qty1 subsidy_qty2)  //or should we replace with the second qty (s11dq26), where the first qty is missing (s11dq15==.)
tab subsidy_qty,missing
sum subsidy_qty,detail


gen subsidy_dummy = (subsidy_qty !=0)

tab subsidy_dummy, missing





collapse (sum)subsidy_qty (max) subsidy_dummy, by (hhid)


merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

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







keep hhid  subsidy_qty_w subsidy_dummy
label var subsidy_qty_w "Quantity of Fertilizer Purchased in kg"
label var subsidy_dummy "=1 if acquired any subsidied fertilizer"
save "${Nigeria_GHS_W1_created_data}\subsidized_fert.dta", replace




******************************* 
*Purchased Fertilizer
*******************************

use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Agriculture\sect11d_plantingw1.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
*graph bar (count), over(s11dq13)

*s11dq13 1st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq24 2st 		source of inorg purchased fertilizer (1=govt, 2=private)
*s11dq40     		source of org purchased fertilizer (1=govt, 2=private)
*s11dq15 s11dq26  qty of inorg purchased fertilizer
*s11dq19  s11dq29	value of inorg purchased fertilizer





encode s11dq13, gen(institute)
label list institute


encode s11dq24, gen(institute2)
label list institute2


***fertilzer total quantity, total value & total price***

gen private_fert1_qty = s11dq15 if institute ==4
tab private_fert1_qty
gen private_fert2_qty = s11dq26 if institute2 ==2
tab private_fert2_qty

gen private_fert1_val = s11dq18 if institute ==4


/*
egen val2_cens = median (s11dq31)
tab val2_cens
replace s11dq31= val2_cens if s11dq31==.
tab s11dq31

*/
gen private_fert2_val = s11dq31 if institute2 ==2
tab private_fert2_val



egen total_qty = rowtotal(private_fert1_qty private_fert2_qty)
tab  total_qty, missing

egen total_valuefert = rowtotal(private_fert1_val private_fert2_val)
tab total_valuefert,missing

gen tpricefert = total_valuefert/total_qty
tab tpricefert


gen tpricefert_cens = tpricefert 
replace tpricefert_cens = 600 if tpricefert_cens > 600 & tpricefert_cens < . //winzonrizing at bottom 3%
replace tpricefert_cens = 12 if tpricefert_cens < 12
tab tpricefert_cens, missing  //winzonrizing at top 5%
*graph box total_valuefert if total_valuefert!=0
*hist total_valuefert, normal width(5)



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

tab tpricefert_cens_mrk


replace tpricefert_cens_mrk = medianfert_pr_lga if tpricefert_cens_mrk ==. & num_fert_pr_lga >= 7

tab tpricefert_cens_mrk



replace tpricefert_cens_mrk = medianfert_pr_state if tpricefert_cens_mrk ==. & num_fert_pr_state >= 7

tab tpricefert_cens_mrk


replace tpricefert_cens_mrk = medianfert_pr_zone if tpricefert_cens_mrk ==. & num_fert_pr_zone >= 7
*/
tab tpricefert_cens_mrk

***************
*organic fertilizer
***************
gen org_fert = 1 if  s11dq3==3 | s11dq7==3 | s11dq14==3 |  s11dq25==3
tab org_fert, missing
replace org_fert = 0 if org_fert==.
tab org_fert, missing



collapse zone lga sector ea (sum) total_qty total_valuefert (max)  org_fert tpricefert_cens_mrk, by(hhid)

tab total_qty, missing
tab tpricefert_cens_mrk, missing



merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

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


/*

************winzonrizing fertilizer market price
foreach v of varlist  tpricefert_cens_mrk  {
	_pctile `v' [aw=weight] , p(5 95) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}

*/
*
gen rea_tpricefert_cens_mrk = tpricefert_cens_mrk   /0.190511
gen real_tpricefert_cens_mrk = rea_tpricefert_cens_mrk
tab real_tpricefert_cens_mrk
sum real_tpricefert_cens_mrk, detail


keep hhid zone lga sector ea org_fert total_qty_w total_valuefert real_tpricefert_cens_mrk

la var org_fert "1 = if used organic fertilizer"
label var total_qty_w "Total quantity of Commercial Fertilizer Purchased in kg"
label var total_valuefert "Total value of commercial fertilizer purchased in naira"
label var real_tpricefert_cens_mrk "price of commercial fertilizer purchased in naira"
sort hhid
save "${Nigeria_GHS_W1_created_data}\purchasefert.dta", replace



***************************
*Savings 
*************************

use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect4_plantingw1.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

*s4q1  1= formal bank account
*s4q5b  s4q5d   s4q5f  types of formal fin institute used to save 
*s4q6   1= used informal saving group

ren s4q1 formal_bank
tab formal_bank, missing
replace formal_bank =0 if formal_bank ==2 | formal_bank ==.
tab formal_bank, nolabel
tab formal_bank,missing

 gen formal_save = 1 if s4q5b !=. | s4q5d !=.| s4q5f !=.
 tab formal_save, missing
 replace formal_save = 0 if formal_save ==.
 tab formal_save, missing

 ren s4q6 informal_save
 tab informal_save, missing
 replace informal_save =0 if informal_save ==2 | informal_save ==.
 tab informal_save, missing

 collapse (max) formal_bank formal_save informal_save, by (hhid)
 la var formal_bank "=1 if respondent have an account in bank"
 la var formal_save "=1 if used formal saving group"
 la var informal_save "=1 if used informal saving group"
save "${Nigeria_GHS_W1_created_data}\savings.dta", replace



***************************
*Credit access 
***************************

use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect4_plantingw1.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
*s4q8b  s4q8d   s4q8f   types of formal fin institute used to borrow 
*s4q9      1= used inoformal group to borrow money


 gen formal_credit =1 if s4q8b !=. | s4q8d !=. | s4q8f !=.
 tab formal_credit,missing
 replace formal_credit =0 if formal_credit ==.
 tab formal_credit,missing
 
 ren  s4q9 informal_credit
 tab informal_credit, missing
 replace informal_credit =0 if informal_credit ==2 | informal_credit ==.
 tab informal_credit,missing


 collapse (max) formal_credit informal_credit, by (hhid)
 la var formal_credit "=1 if borrowed from formal credit group"
 la var informal_credit "=1 if borrowed from informal credit group"
save "${Nigeria_GHS_W1_created_data}\credit_access.dta", replace


*****************************
*Community 
****************************

use "${Nigeria_GHS_W1_raw_data}\Post Harvest Wave 1\Community\sectc2_harvestw1.dta", clear

*is_cd  219 for market infrastructure
*sc2q3  distance to infrastructure in km

gen mrk_dist = sc2q3 if is_cd==219
tab mrk_dist,missing
egen median_lga = median(mrk_dist), by (zone state lga)
egen median_state = median(mrk_dist), by (zone state)
egen median_zone = median(mrk_dist), by (zone)


replace mrk_dist =0 if is_cd==219 & mrk_dist==. & sc2q1==1
tab mrk_dist if is_cd==219, missing

replace mrk_dist = median_lga if mrk_dist==. & is_cd==219
replace mrk_dist = median_state if mrk_dist==. & is_cd==219
replace mrk_dist = median_zone if mrk_dist==. & is_cd==219
tab mrk_dist if is_cd==219, missing

replace mrk_dist= 45 if mrk_dist>=45 & mrk_dist<. & is_cd==219
tab mrk_dist if is_cd==219, missing

sort zone state ea
collapse (max) median_lga median_state median_zone mrk_dist, by (zone state lga sector ea)
replace mrk_dist = median_lga if mrk_dist ==.
tab mrk_dist, missing
replace mrk_dist = median_lga if mrk_dist ==.
tab mrk_dist, missing



la var mrk_dist "=distance to the market"




save "${Nigeria_GHS_W1_created_data}\market_distance.dta", replace 




***************************** 
*Extension Visit 
*******************************
use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Agriculture\sect11l1_plantingw1.dta", clear
ren s11lq1 ext_acess
preserve



use "${Nigeria_GHS_W1_raw_data}/Post Harvest Wave 1\Agriculture\secta5a_harvestw1.dta", clear
ren sa5aq1 ext_acess
tempfile advie_ph
save `advie_ph'
restore
append using `advie_ph'
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

replace ext_acess =0 if ext_acess ==.
 
collapse (max) ext_acess, by (hhid)
la var ext_acess "=1 if received advise from extension services"
save "${Nigeria_GHS_W1_created_data}\extension_visit.dta", replace 


******************************** 
*Demographics 
*********************************
use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect1_plantingw1.dta", clear

merge 1:1 hhid indiv using "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect2_plantingw1.dta", gen(household)

merge m:1 zone state lga sector ea using "${Nigeria_GHS_W1_created_data}\market_distance.dta", keepusing (median_lga median_state median_zone mrk_dist)

merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
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
*s1q4   age in years


sort hhid indiv 
 
gen num_mem = 1


******** female head****

gen femhead = 0
replace femhead = 1 if s1q2== 2 & s1q3==1

********Age of HHead***********
ren s1q4 hh_age
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


*s2q4  1= attended school
*s2q7  highest education level
*s1q3 relationship to hhead

ren s2q4 attend_sch
tab attend_sch
replace attend_sch = 0 if attend_sch ==2
tab attend_sch, nolabel
*tab s1q4 if s2q7==.

replace s2q7= 0 if attend_sch==0
tab s2q7
tab s1q3 if _merge==1

tab s2q7 if s1q3==1
replace s2q7 = 16 if s2q7==. &  s1q3==1

*** Education Dummy Variable*****

 label list s2q7

gen pry_edu = 1 if s2q7 >= 1 & s2q7 < 16 & s1q3==1
gen finish_pry = 1 if s2q7 >= 16 & s2q7 < 26 & s1q3==1
gen finish_sec = 1 if s2q7 >= 26 & s2q7 < 43 & s1q3==1

replace pry_edu =0 if pry_edu==. & s1q3==1
replace finish_pry =0 if finish_pry==. & s1q3==1
replace finish_sec =0 if finish_sec==. & s1q3==1
tab pry_edu if s1q3==1 , missing
tab finish_pry if s1q3==1 , missing 
tab finish_sec if s1q3==1 , missing

collapse (sum) num_mem (max) mrk_dist hh_headage femhead attend_sch pry_edu finish_pry finish_sec, by (hhid)


merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1


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
/*
tab pry_edu, missing
tab finish_pry, missing
tab finish_sec, missing

egen mid_pry_edu= median(pry_edu)
egen mid_finish_pry= median(finish_pry)
egen mid_finish_sec= median(finish_sec)

replace pry_edu = mid_pry_edu if pry_edu==.
replace finish_pry = mid_finish_pry if finish_pry==.
replace finish_sec = mid_finish_sec if finish_sec==.
*/

la var num_mem "household size"
la var mrk_dist_w "distance to the nearest market in km"
la var femhead "=1 if head is female"
la var hh_headage "age of household head in years"
la var attend_sch "=1 if respondent attended school"
la var pry_edu "=1 if household head attended pry school"
la var finish_pry "=1 if household head finished pry school"
la var finish_sec "=1 if household head finished sec school"
save "${Nigeria_GHS_W1_created_data}\demographics.dta", replace




********************************* 
*Labor Age 
*********************************
use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect1_plantingw1.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
ren s1q4 hh_age

gen worker = 1
replace worker = 0 if hh_age < 15 | hh_age > 65

tab worker
sort hhid
collapse (sum) worker, by (hhid)
la var worker "number of members age 15 and older and less than 65"
sort hhid

save "${Nigeria_GHS_W1_created_data}\labor_age.dta", replace



********************************
*Safety Net
*****************************
use "${Nigeria_GHS_W1_raw_data}\Post Harvest Wave 1\Household\sect14_harvestw1.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
gen safety_net = 0
replace safety_net =1 if s14q1 ==1
tab safety_net
collapse (max) safety_net, by (hhid)
tab safety_net
la var safety_net "=1 if received cash transfer, cash for work, food for work or other assistance"
save "${Nigeria_GHS_W1_created_data}\safety_net.dta", replace


**************************************
*Food Prices
**************************************


use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Community\sectc2_plantingw1.dta", clear

*s7bq3a   qty purchased by household (7days)
*sc2q3c     units purchased by household (7days)
*s7bq4    cost of purchase by household (7days)




*********Getting the price for maize only**************
//   Unit           Conversion Factor for maize







gen conversion =1
tab conversion, missing
gen food_size=1 //This makes it easy for me to copy-paste existing code rather than having to write a new block
replace conversion = food_size*0.087 if sc2q3c== 1
replace conversion = food_size*0.175 if  sc2q3c== 2		
replace conversion = food_size*0.23 if  sc2q3c== 3
replace conversion = food_size*0.35 if  sc2q3c== 4	
replace conversion = food_size*0.70 if  sc2q3c== 5
replace conversion = food_size*1.50 if  sc2q3c== 6
replace conversion = food_size*3.00 if  sc2q3c== 7
replace conversion = food_size*20.0 if  sc2q3c== 11	
replace conversion = food_size*50.0 if  sc2q3c== 12
replace conversion = food_size*100 if   sc2q3c== 13	
replace conversion = food_size*120 if   sc2q3c== 14
replace conversion = food_size*30.0 if  sc2q3c== 22		
replace conversion = food_size*10.0 if  sc2q3c== 31
replace conversion = food_size*25 if   sc2q3c== 32	
replace conversion = food_size*40 if   sc2q3c== 33
replace conversion = food_size*3.0 if  sc2q3c== 51					
tab conversion, missing	



gen food_price_maize = sc2q3b* conversion if item_cd==12

gen maize_price = sc2q3a/food_price_maize if item_cd==12  

*br  sc2q3b conversion sc2q3c sc2q3a  food_price_maize maize_price item_cd if item_cd<=17

tab maize_price,missing
sum maize_price,detail
tab maize_price

replace maize_price = 270 if maize_price >270 & maize_price<.  //bottom 1%
replace maize_price = 1 if maize_price< 1       ////top 1%



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



*********Getting the price for rice only**************
//   Unit           Conversion Factor for maize






gen food_price_rice = sc2q3b* conversion if item_cd==14

gen rice_price = sc2q3a/food_price_rice if item_cd==14

*br  sc2q3b conversion sc2q3c sc2q3a  food_price_rice rice_price item_cd if item_cd==14

sum rice_price,detail
tab rice_price

replace rice_price = 300 if rice_price >300 & rice_price<.   //bottom 3%
replace rice_price = 25 if rice_price< 25   //top 3%
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


save "${Nigeria_GHS_W1_created_data}\food_prices.dta", replace



**************
*Net Buyers and Sellers
***************
use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect7b_plantingw1.dta", clear
merge m:1 zone state lga sector ea using "${Nigeria_GHS_W1_created_data}\food_prices.dta", keepusing (median_pr_ea median_pr_lga median_pr_state median_pr_zone maize_price_mr rice_price_mr)
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1

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





*s7bq3a from purchases
*s7bq5a from own production

tab s7bq5a
tab s7bq3a

replace s7bq5a = 0 if s7bq5a<=0 |s7bq5a==.
tab s7bq5a,missing
replace s7bq3a = 0 if s7bq3a<=0 |s7bq3a==.
tab s7bq3a,missing

gen net_seller = 1 if s7bq5a > s7bq3a
tab net_seller,missing
replace net_seller=0 if net_seller==.
tab net_seller,missing

gen net_buyer = 1 if s7bq5a < s7bq3a
tab net_buyer,missing
replace net_buyer=0 if net_buyer==.
tab net_buyer,missing


collapse  (max) maize_price_mr rice_price_mr net_seller net_buyer, by(hhid)



gen rea_maize_price_mr = maize_price_mr  /0.190511
gen real_maize_price_mr = rea_maize_price_mr
tab real_maize_price_mr
sum real_maize_price_mr, detail
gen rea_rice_price_mr = rice_price_mr   /0.190511
gen real_rice_price_mr = rea_rice_price_mr
tab real_rice_price_mr
sum real_rice_price_mr, detail


label var real_maize_price_mr "commercial price of maize in naira"
label var real_rice_price_mr "commercial price of rice in naira"
la var net_seller "1= if respondent is a net seller"
la var net_buyer "1= if respondent is a net buyer"
sort hhid
save "${Nigeria_GHS_W1_created_data}\net_buyer_seller.dta", replace



/*
************************************
*cpi
********************************
  wbopendata, language(en - English) country() topics() indicator(fp.cpi.totl) clear
*save a copy for use off-line
  *save "wbopendata_cpi_timeseries.dta", replace

*use "wbopendata_cpi_timeseries.dta", clear

*keep SSA
keep if inlist(region,"SSF")
	*does the same thing: keep if regioncode=="SSF"

*keep our study countries
keep if inlist(countrycode,"NGA")
	* does the same thing: drop if !(inlist(countrycode,"TZA"))


*drop very old years
drop yr1960-yr1989

*take a look at recent values (note these all use 2010 as base year)
l countrycode yr2004-yr2017

*rebase to 2015
gen baseyear = yr2023
forvalues i=1990(1)2023 {
	replace yr`i' = yr`i'/baseyear
}
forvalues i=1990(1)2023 {
	di "year is: `i'" 
}


*reformat to match panel structure 
reshape long yr, i(countrycode) j(year)
rename yr cpi
keep countrycode countryname year cpi
order countrycode countryname year cpi
la var year "Year"
la var cpi "CPI (base=2023)"


*save for use in analysis
*save "tza_cpi_b2019.dta", replace


*/

















*****************************
*Household Assests
****************************


use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect5_plantingw1.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
sort hhid item_cd

collapse (sum) s5q1, by (zone state lga ea hhid item_cd)
tab item_cd
save "${Nigeria_GHS_W1_created_data}\assest_qty.dta", replace

use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Household\sect5b_plantingw1.dta", clear

collapse (mean) s5q4, by (zone state lga ea hhid item_cd)
tab item_cd
save "${Nigeria_GHS_W1_created_data}\assest_cost.dta", replace

*******************Merging assest***********************
sort hhid item_cd
merge 1:1 hhid item_cd using "${Nigeria_GHS_W1_created_data}\assest_qty.dta", keepusing(zone state lga ea s5q1)

drop _merge

merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
gen hhasset_value = s5q4*s5q1


tab hhasset_value
/*
replace hhasset_value=. if hhasset_value==0
replace hhasset_value= 5700000 if hhasset_value> 5700000 & hhasset_value<.
tab hhasset_value, missing
*/
sum hhasset_value, detail







collapse (sum) hhasset_value, by (hhid)

merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1


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

gen rea_hhvalue = hhasset_value_w   /0.190511
gen real_hhvalue = rea_hhvalue/1000
sum hhasset_value_w real_hhvalue, detail


keep  hhid real_hhvalue
la var real_hhvalue "total value of household asset"
save "${Nigeria_GHS_W1_created_data}\assest_value.dta", replace





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
save "${Nigeria_GHS_W1_created_data}\land_cf.dta", replace

 
 
 
 
 
 
*********************
*Plot Size 
**********************

use "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Agriculture\sect11a1_plantingw1.dta", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using  "${Nigeria_GHS_W1_raw_data}\Post Planting Wave 1\Agriculture\sect11b_plantingw1.dta"
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W1_raw_data}\Post Harvest Wave 1\Agriculture\secta1_harvestw1.dta", gen(plot_merge)
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1
 
ren s11aq4a area_size
ren s11aq4b area_unit
ren sa1q9a area_size2
ren sa1q9b area_unit2
ren s11aq4d area_meas_sqm
ren sa1q9d area_meas_sqm2

*If land was cultivated by household, then cultivate is equal to 1
gen cultivate = s11bq16 ==1 
tab cultivate
*assuming new plots are cultivated
replace cultivate = 1 if sa1q3==1
tab cultivate


******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W1_created_data}\land_cf.dta", nogen keep(1 3) 


 
 *farmer reported field size for post-planting
gen field_size= area_size*conversion
 sum field_size, detail
*replacing farmer reported with GPS if
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.  
 sum field_size, detail 
 
 gen gps_meas = (area_meas_sqm!=. | area_meas_sqm2!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
tab gps_meas
 
 
 
 ***************Measurement in hectares for the additional plots from post-harvest************
 *farmer reported field size for post-harvest added fields
drop area_unit conversion
ren area_unit2 area_unit
******Merging data with the conversion factor
merge m:1 zone area_unit using "${Nigeria_GHS_W1_created_data}\land_cf.dta", nogen keep(1 3) 

replace field_size= area_size2*conversion if field_size==.
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm2*0.0001 if area_meas_sqm2!=.               
la var field_size "Area of plot (ha)"
ren plotid plot_id
sum field_size, detail
*Total land holding including cultivated and rented out
collapse (sum) field_size, by (hhid)


merge 1:1 hhid using  "${Nigeria_GHS_W1_created_data}/weight.dta", gen (wgt)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)

keep if ag_rainy_10==1


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
save "${Nigeria_GHS_W1_created_data}\land_holdings.dta", replace

 


 
********************************************************************************
*OFF-FARM HOURS
********************************************************************************
use "${Nigeria_GHS_W1_raw_data}/sect3a_harvestw1.dta", clear
gen  hrs_main_wage_off_farm=s3aq15 if (s3aq11>1 & s3aq11!=.) 	// s3q14 1   is agriculture (exclude mining). 
gen  hrs_sec_wage_off_farm= s3aq27 if (s3aq23>1 & s3aq23!=.) 
egen hrs_wage_off_farm= rowtotal(hrs_main_wage_off_farm hrs_sec_wage_off_farm) 
gen  hrs_main_wage_on_farm=s3aq15 if (s3aq11<=1 & s3aq11!=.)  
gen  hrs_sec_wage_on_farm= s3aq27 if (s3aq23<=1 & s3aq23!=.)  
egen hrs_wage_on_farm= rowtotal(hrs_main_wage_on_farm hrs_sec_wage_on_farm)
egen hrs_unpaid_off_farm= rowtotal(s3aq38)
drop *main* *sec*  
recode s3aq39a s3aq39b s3aq40a s3aq40b (.=0) 
gen hrs_domest_fire_fuel=(s3aq39a+ s3aq39b/60+s3aq40a+s3aq40b/60)*7  // hours worked just yesterday
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
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_off_farm_hours.dta", replace


********************************************************************************
* WAGE INCOME *
********************************************************************************
use "${Nigeria_GHS_W1_raw_data}/sect3a_harvestw1.dta", clear
ren s3aq10 activity_code
ren s3aq11 sector_code
ren s3aq4 mainwage_yesno
ren s3aq13 mainwage_number_months
ren s3aq14 mainwage_number_weeks
ren s3aq15 mainwage_number_hours
ren s3aq18a mainwage_recent_payment
gen ag_activity = (sector_code==1)
replace mainwage_recent_payment = . if ag_activity==1 // exclude ag wages 
ren s3aq18b mainwage_payment_period
ren s3aq20a mainwage_recent_payment_other
replace mainwage_recent_payment_other = . if ag_activity==1
ren s3aq20b mainwage_payment_period_other
ren s3aq23 sec_sector_code
ren s3aq21 secwage_yesno
ren s3aq25 secwage_number_months
ren s3aq26 secwage_number_weeks
ren s3aq27 secwage_number_hours
ren s3aq30a secwage_recent_payment
gen sec_ag_activity = (sec_sector_code==1)
replace secwage_recent_payment = . if sec_ag_activity==1 // exclude ag wages 
ren s3aq30b secwage_payment_period
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
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_wage_income.dta", replace


*Ag wage income
use "${Nigeria_GHS_W1_raw_data}/sect3a_harvestw1.dta", clear
ren s3aq10 activity_code
ren s3aq11 sector_code
ren s3aq4 mainwage_yesno
ren s3aq13 mainwage_number_months
ren s3aq14 mainwage_number_weeks
ren s3aq15 mainwage_number_hours
ren s3aq18a mainwage_recent_payment
gen ag_activity = (sector_code==1)
replace mainwage_recent_payment = . if ag_activity!=1 // include only ag wages
ren s3aq18b mainwage_payment_period
ren s3aq20a mainwage_recent_payment_other
replace mainwage_recent_payment_other = . if ag_activity!=1 // include only ag wages
ren s3aq20b mainwage_payment_period_other
ren s3aq23 sec_sector_code
ren s3aq21 secwage_yesno
ren s3aq25 secwage_number_months
ren s3aq26 secwage_number_weeks
ren s3aq27 secwage_number_hours
ren s3aq30a secwage_recent_payment
gen sec_ag_activity = (sec_sector_code==1)
replace secwage_recent_payment = . if sec_ag_activity!=1
ren s3aq30b secwage_payment_period
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
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_agwage_income.dta", replace 


 
 
 
 

global climate "C:\Users\obine\Music\Documents\food_secure\dofile\original\pp_only\CHIRPS"
*--------------------------------------------------------------*
* 1. Load household rainfall dataset
*--------------------------------------------------------------*
use "$climate\Nigeria_y4_hh_coordinates_rainfall_TS_monthly.dta", clear

* Rename rainfall variables to avoid name conflicts after merge
foreach var of varlist rain_2007_01 - rain_2011_12 {
    rename `var' hh_`var'
}

* Save temporary file of household rainfall
tempfile hh_rain
save `hh_rain', replace

*--------------------------------------------------------------*
* 2. Load plot-level dataset and merge rainfall by hhid
*--------------------------------------------------------------*
use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_all_plots.dta", clear

merge m:1 hhid using `hh_rain'
drop _merge

*--------------------------------------------------------------*
* 3. Transfer household rainfall into plot rainfall variables
*--------------------------------------------------------------*
foreach var of varlist hh_rain_2007_01 - hh_rain_2011_12 {
    local new = subinstr("`var'", "hh_", "", .)   // remove hh_ prefix
    gen `new' = `var'
}

*--------------------------------------------------------------*
* 4. Remove household-prefixed rainfall variables
*--------------------------------------------------------------*
drop hh_rain_2007_01 - hh_rain_2011_12

		

egen total_rain_18_June = rowtotal(rain_2011_03 rain_2011_04 rain_2011_05 rain_2011_06)
egen total_rain_18_July = rowtotal(rain_2011_03 rain_2011_04 rain_2011_05 rain_2011_06 rain_2011_07)

egen mean_rain_18_June  = rowmean(rain_2011_03 rain_2011_04 rain_2011_05 rain_2011_06)
egen mean_rain_18_July  = rowmean(rain_2011_03 rain_2011_04 rain_2011_05 rain_2011_06 rain_2011_07)

*--------------------------------------------------------------*
* 1. Remove rainfall for years you don't want (example: drop 2018)
*--------------------------------------------------------------*
drop rain_2011_*


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
egen mean_rain_2010_Mar = rowmean(rain_2010_03 rain_2010_04 rain_2010_05 rain_2010_06)
gen  dev_rain_2010_Mar  = mean_rain_2010_Mar - mean_rain_Mar_June

egen mean_rain_2010_Aug = rowmean(rain_2010_08 rain_2010_09 rain_2010_10 rain_2010_11 rain_2010_12)
gen  dev_rain_2010_Aug  = mean_rain_2010_Aug - mean_rain_Aug_Dec

*----------------------------------------------------------------------
* 5. Annual mean rainfall (for all years)
*----------------------------------------------------------------------
egen mean_annual_rainfall = rowmean(rain_*_01 rain_*_02 rain_*_03 rain_*_04 rain_*_05 rain_*_06 rain_*_07 rain_*_08 rain_*_09 rain_*_10 rain_*_11 rain_*_12)

*----------------------------------------------------------------------
* 6. Annual shortfall (corrected code using loops)
*----------------------------------------------------------------------
forvalues yr = 2007/2010 {
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
forvalues yr = 2007/2010 {
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
     mean_rain_2010_Mar dev_rain_2010_Mar dev_rain_2010_Aug ///
     shortfall_Mar_June shortfall_Mar_July shortfall_Aug_Dec ///
     sd_shortfall_* *_18_June, by (hhid)

save "${Nigeria_GHS_W1_created_data}/rainfall_10.dta", replace 


 
 
 
 
 
 
 
 
 
 
 
 

*******************************
*Merging Household Level Dataset
*******************************
use  "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_all_plots.dta",clear

sort hhid plot_id
count
*count if cropcode==1080
*keep if cropcode==1080
*keep if purestand ==1
order hhid plot_id  quant_harv_kg value_harvest ha_harvest percent_inputs field_size purestand

collapse (sum) quant_harv_kg value_harvest ha_planted field_size (max) percent_inputs  purestand, by (hhid)


sum ha_planted, detail

replace ha_planted = 9.5 if ha_planted >= 9.5 
replace field_size = 20 if field_size >= 20
ren value_harvest real_value_harvest
gen value_harvest  = real_value_harvest/0.236945
sum value_harvest, detail
tab value_harvest
replace value_harvest=  4695385 if value_harvest>= 4695385




merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/purchasefert.dta", gen(fert)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/net_buyer_seller.dta", gen (food)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/assest_value.dta", gen (asset)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/weight.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/ag_rainy_10.dta", gen(filter)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/extension_visit.dta", gen(diet)
*merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W2_consumption2.dta", gen(exp)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_group2.dta", gen (exp2)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_weights.dta", gen(hh)
merge 1:1 hhid using "C:\Users\obine\Music\Documents\Smallholder lsms STATA\analyzed_data\nga_wave2012\soil_quality_2012.dta"
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/demographics.dta", gen(house)
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/land_holdings.dta", gen(work)
*merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W4_shannon_diversity_index.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_off_farm_hours.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_wage_income.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_agwage_income.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/rainfall_10.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/subsidized_fert.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/shock.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W1_created_data}/haz.dta", nogen



*keep if ag_rainy_10==1
***********************Dealing with outliers*************************


gen year = 2010
sort hhid

drop if hhid == 310100 //didnt report price****
drop if hhid == 340089 //didnt report price****


tabstat ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty  real_tpricefert_cens_mrk real_hhvalue mean_annual_rainfall [w=weight], statistics( mean median sd min max ) columns(statistics)
count
misstable summarize ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty  real_tpricefert_cens_mrk real_hhvalue mean_annual_rainfall mrk_dist_w num_mem hh_headage femhead attend_sch zone state lga ea



replace total_qty = 0 if total_qty==.

egen median_maize = median(real_maize_price_mr)
replace real_maize_price_mr = median_maize if real_maize_price_mr==.

egen median_rice = median (real_rice_price_mr)
replace real_rice_price_mr = median_rice if real_rice_price_mr==.

*egen median_dist = median (mrk_dist_w)
*replace mrk_dist_w = median_dist if mrk_dist_w==.

egen median_real_tpricefert_cens_mrk = median(real_tpricefert_cens_mrk)
replace real_tpricefert_cens_mrk = median_real_tpricefert_cens_mrk if real_tpricefert_cens_mrk==.




egen medianfert_dist_ea = median(mrk_dist_w), by (ea)
egen medianfert_dist_lga = median(mrk_dist_w), by (lga)
egen medianfert_dist_state = median(mrk_dist_w), by (state)
egen medianfert_dist_zone = median(mrk_dist_w), by (zone)


replace mrk_dist_w = medianfert_dist_ea if mrk_dist_w ==. 
replace mrk_dist_w = medianfert_dist_lga if mrk_dist_w ==. 
replace mrk_dist_w = medianfert_dist_state if mrk_dist_w ==.

replace mrk_dist_w = medianfert_dist_zone if mrk_dist_w ==. 

misstable summarize ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk   real_hhvalu mrk_dist_w num_mem hh_headage femhead attend_sch  peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg mean_annual_rainfall  dev_rain_2010_Mar dev_rain_2010_Aug 

egen mean1 = mean (dev_rain_2010_Mar)
egen mean2 = mean (dev_rain_2010_Aug)


tabstat haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk   real_hhvalue mrk_dist_w num_mem hh_headage femhead attend_sch peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg mean_annual_rainfall dev_rain_2010_Mar dev_rain_2010_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)

misstable summarize haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk   real_hhvalue mrk_dist_w num_mem hh_headage femhead attend_sch peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg mean_annual_rainfall dev_rain_2010_Mar dev_rain_2010_Aug

ren dev_rain_2010_Mar dev_rain_Mar
ren  dev_rain_2010_Aug dev_rain_Aug


egen med = median(haz)
tab med
replace haz = med if haz ==.


tabstat haz ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty real_tpricefert_cens_mrk   real_hhvalue mrk_dist_w num_mem hh_headage femhead attend_sch peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg mean_annual_rainfall dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)


save "${Nigeria_GHS_W1_created_data}/final_10.dta", replace

