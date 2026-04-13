/*********************************************************************************
* LSMS-ISA Harmonised Panel Analysis Code                                        *
* Description: Extract data for GHS4          *
* Date: December 2023                                                            *
* -------------------------------------------------------------------------------*
*/

***************************************************
*starting
***************************************************


global Nigeria_GHS_W5_raw_data 		"C:\Users\obine\Music\Documents\Smallholder lsms STATA\NGA_2023_GHSP-W5_v01_M_Stata (1)"
global Nigeria_GHS_W5_created_data  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_five"




/*
use "${Nigeria_GHS_W5_raw_data}\sect4b_harvestw5.dta", clear

merge 1:1 hhid indiv using "${Nigeria_GHS_W5_raw_data}/sect1_harvestw5.dta", nogen


/********************************************************************
FINAL: HAZ using zanthro (correct age handling)
********************************************************************/

* Keep children under 5
keep if s4bq1 == 1

* Age in months → years
gen age_months = s4bq5
replace age_months = . if age_months < 0 | age_months > 59
gen age_years = age_months/12

* Sex
gen sex = s1q2
replace sex = . if sex != 1 & sex != 2

* Height (cm)
egen height_cm = rowmean(s4bq12a s4bq12b s4bq12c)
replace height_cm = . if height_cm < 45 | height_cm > 120

* Install zanthro if needed
capture which zanthro
if _rc {
    net install dm0004, from("https://www.stata-journal.com/software/sj4-1") replace
}

* Compute HAZ (UK90 height-for-age)
egen haz = zanthro(height_cm, ha, UK), ///
    xvar(age_years) ///
    gender(sex) ///
    gencode(male=1, female=2)

* Stunting indicators
gen stunted        = haz < -2 if haz < .
gen severe_stunted = haz < -3 if haz < .

* Validate
sum haz, detail
collapse (max) haz, by (hhid)
tab shock
tab shock1
save  "${Nigeria_GHS_W5_created_data}/shock.dta", replace
*/


***************
*2 WHO
*************

/********************************************************************
WHO 2006 Height-for-Age Z-score (HAZ)
Based on zscore06 (WHO Child Growth Standards)
********************************************************************/
use "${Nigeria_GHS_W5_raw_data}\sect4b_harvestw5.dta", clear

merge 1:1 hhid indiv using "${Nigeria_GHS_W5_raw_data}/sect1_harvestw5.dta", nogen

/********************************************************************
WHO 2006 Height-for-Age Z-score (HAZ)
Correct age source: s1q6 (age in completed years → months)
********************************************************************/

*--------------------------------------------------------------*
* 0. Keep children under 5 years
*--------------------------------------------------------------*
keep if s4bq1 == 1

gen child = (s4bq1 == 1)
tab child

*--------------------------------------------------------------*
* 1. Age in months (CORRECT: convert years → months)
*--------------------------------------------------------------*
gen age_months = s1q6 * 12
replace age_months = . if age_months < 0 | age_months > 59

*--------------------------------------------------------------*
* 2. Sex (WHO default: 1 = boy, 2 = girl)
*--------------------------------------------------------------*
gen sex = s1q2
replace sex = . if sex != 1 & sex != 2

*--------------------------------------------------------------*
* 3. Height in centimeters (average of up to 3 measures)
*--------------------------------------------------------------*
egen height_cm = rowmean(s4bq12a s4bq12b s4bq12c)

* Drop biologically impossible heights for 0–59 months
replace height_cm = . if height_cm < 45 | height_cm > 120

*--------------------------------------------------------------*
* 4. Measurement position (WHO requirement)
*    WHO coding:
*      1 = recumbent length
*      2 = standing height
*
*    Your data (confirmed):
*      s4bq13 == 1 → standing up
*      s4bq13 == 2 → laying down
*--------------------------------------------------------------*
gen meas = .
replace meas = 2 if s4bq13 == 1   // standing height
replace meas = 1 if s4bq13 == 2   // recumbent length

*--------------------------------------------------------------*
* 5. Install zscore06 if needed
*--------------------------------------------------------------*
capture which zscore06
if _rc ssc install zscore06, replace

*--------------------------------------------------------------*
* 6. Run WHO 2006 z-score calculation
*--------------------------------------------------------------*
capture drop haz06 waz06 whz06 bmiz06
zscore06, a(age_months) s(sex) h(height_cm) ///
          measure(meas) recum(1) stand(2)

*--------------------------------------------------------------*
* 7. Clean WHO outputs
*    zscore06 uses large numeric flags for invalid cases
*--------------------------------------------------------------*
gen haz = haz06

* Drop flag values
replace haz = . if haz > 1000

* WHO biological plausibility bounds
replace haz = . if haz < -6 | haz > 6

*--------------------------------------------------------------*
* 8. Optional: stunting indicators
*--------------------------------------------------------------*
gen stunted        = haz < -2 if haz < .
gen severe_stunted = haz < -3 if haz < .

*--------------------------------------------------------------*
* 9. Validation check (this should now look right)
*--------------------------------------------------------------*
sum haz, detail
tab stunted if haz < ., missing

collapse (mean) haz (sum) child1 = child (max) child s4bq1, by(hhid)

egen med = median(haz)

gen haz2 = haz
replace haz2 = med if haz ==.
tab haz, missing
tab haz2, missing
sum haz, detail
sum haz2, detail

tab child1, missing
save  "${Nigeria_GHS_W5_created_data}/haz.dta", replace





use "${Nigeria_GHS_W5_raw_data}\sect12_harvestw5.dta", clear

keep if  s12q1==1
gen nonag_shock = 1 if shock_cd ==4 | shock_cd ==9 | shock_cd ==10 | shock_cd ==11 | shock_cd ==12 | shock_cd ==13 | shock_cd == 14 | shock_cd == 15 | shock_cd == 17 | shock_cd ==18 | shock_cd == 20 | shock_cd == 21 | shock_cd == 25

replace nonag_shock = 0 if nonag_shock==.

gen ag_shock = 1 if shock_cd ==1 | shock_cd ==2 | shock_cd ==3 | shock_cd ==6 | shock_cd ==7 | shock_cd ==8 | shock_cd == 16 | shock_cd == 22 | shock_cd == 23 | shock_cd == 24 | shock_cd == 28

replace ag_shock = 0 if ag_shock==.

tab ag_shock, missing 
tab nonag_shock, missing

gen shock =1 if (s12q1==1)
replace shock = 0 if shock==.
collapse (max) shock ag_shock nonag_shock, by (hhid)
tab shock, missing
tab ag_shock, missing
tab nonag_shock, missing
count
save  "${Nigeria_GHS_W5_created_data}/shock.dta", replace









//demographics, labor age, distance
use "${Nigeria_GHS_W5_raw_data}/sect11f_plantingw5.dta", clear
*use "${Nigeria_GHS_W5_raw_data}/sect11e1_plantingw5.dta", clear
*br s11fq5a s11fq5b if s11fq5a!=.

********************************************************************************
* AG FILTER *
********************************************************************************

use  "${Nigeria_GHS_W5_raw_data}/secta_plantingw5.dta", clear

keep hhid ag1
rename (ag1) (ag_rainy_23)
save  "${Nigeria_GHS_W5_created_data}/ag_rainy_18.dta", replace


********************************************************************************
* WEIGHTS *
********************************************************************************

use "${Nigeria_GHS_W5_raw_data}/secta_plantingw5.dta" , clear

gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave5 rural
ren wt_wave5 weight
duplicates report hhid

save  "${Nigeria_GHS_W5_created_data}/hhids.dta", replace



*******************************************************************************
*HOUSEHOLD'S DIET DIVERSITY SCORE * PA Done
********************************************************************************
* since the diet variable is available in both PP and PH datasets, we first append the two together
use "${Nigeria_GHS_W5_raw_data}/sect6b_plantingw5.dta" , clear // PA 12.31, recall period for consumption changed from 7 days in pr
keep zone state lga sector ea hhid item_cd s6bq1
gen survey="PP"
preserve
use "${Nigeria_GHS_W5_raw_data}/sect5b_harvestw5.dta" , clear
keep zone state lga sector ea hhid item_cd s5bq1
ren  s5bq1  s6bq1 // ren the variable indicating household consumption of food items to harminize accross data set
gen survey="PH"
tempfile diet_ph
save `diet_ph'
restore 
append using `diet_ph'
* We recode food items to map to India food groups used as reference

recode item_cd 	    (10 11 13 14 16 19 20/23 25 28   		=1	"CEREALS")  ///
					(17 18 30/38    						=2	"WHITE ROOTS,TUBERS AND OTHER STARCHES")  ///
					(78  70/77 79	 						=3	"VEGETABLES")  ///
					( 60/69 145/147 601						=4	"FRUITS")  ///
					(80/82 90/96 29 						=5	"MEAT")  ///
					(83/85									=6	"EGGS")  ///
					(100/107  								=7  "FISH") ///
					(43/48 40/42   							=8  "LEGUMES, NUTS AND SEEDS") ///
					(110/115								=9	"MILK AND MILK PRODUCTS")  ///
					(50/56   								=10	"OILS AND FATS")  ///
					(26 27 130/133 121 152/155				=11	"SWEETS")  ///
					(76 77 140/144 120 122 150 151 160/164	=12	"SPICES, CONDIMENTS, BEVERAGES"	) ///
					(150 151 								=. ) ///
					,generate(Diet_ID)	
gen adiet_yes=(s6bq1==1)
ta Diet_ID   
** Now, we collapse to food group level assuming that if an a household consumes at least one food item in a food group,
* then he has consumed that food group. That is equivalent to taking the MAX of adiet_yes
collapse (max) adiet_yes, by(hhid survey Diet_ID) 
label define YesNo 1 "Yes" 0 "No"
label val adiet_yes YesNo
* Now, estimate the number of food groups eaten by each individual
collapse (sum) adiet_yes, by(hhid survey )
collapse (mean) adiet_yes, by(hhid )
/*
There are no established cut-off points in terms of number of food groups to indicate
adequate or inadequate dietary diversity for the HDDS. 
Can use either cut-off or 6 (=12/2) or cut-off=mean(socore) 
*/
ren adiet_yes number_foodgroup 
local cut_off1=6
sum number_foodgroup
local cut_off2=round(r(mean))
gen household_diet_cut_off1=(number_foodgroup>=`cut_off1')
gen household_diet_cut_off2=(number_foodgroup>=`cut_off2') 
lab var household_diet_cut_off1 "1= houseold consumed at least `cut_off1' of the 12 food groups last week - average PP and PH"
lab var household_diet_cut_off2 "1= houseold consumed at least `cut_off2PP' of the 12 food groups last week - average PP and PH"
label var number_foodgroup "Number of food groups individual consumed last week HDDS="
save "${Nigeria_GHS_W5_created_data}/dieatary_diversity.dta", replace



















********************************************************************************
*CONSUMPTION PA Done 
********************************************************************************

********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Nigeria_GHS_W5_raw_data}/secta_plantingw5.dta", clear
keep if interview_result==1
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave5 wt_longpanel_wave5 wt_cross_wave5 rural
ren wt_wave5 weight // 
ren wt_longpanel_wave5 weight_longpanel
ren wt_cross_wave5 weight_crosssection
drop if weight==. & weight_longpanel==. & weight_crosssection==.
duplicates report hhid
save  "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhids.dta", replace



********************************************************************************
* INDIVIDUAL IDS *
********************************************************************************
use "${Nigeria_GHS_W5_raw_data}/sect1_plantingw5.dta", clear
gen season="plan"
append using "${Nigeria_GHS_W5_raw_data}/sect1_harvestw5.dta"
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
merge m:1 hhid using `fhh'
merge m:1 hhid using  "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhids.dta", keep(2 3) nogen  // keeping hh surveyed
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_person_ids.dta", replace
*first get adult equivalent
use "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_person_ids.dta", clear
gen gender = female+1 //This should get fixed.
gen adulteq=.
replace adulteq=0.4 if (age<3 & age>=0)
replace adulteq=0.48 if (age<5 & age>2)
replace adulteq=0.56 if (age<7 & age>4)
replace adulteq=0.64 if (age<9 & age>6)
replace adulteq=0.76 if (age<11 & age>8)
replace adulteq=0.80 if (age<=12 & age>10) & gender==1		//1=male, 2=female
replace adulteq=0.88 if (age<=12 & age>10) & gender==2      //ALT 01.07.21: Updated this to be inclusive, otherwise 12-year-olds get left out
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
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hh_adulteq.dta", replace




********************************************************************************
* HOUSEHOLD SIZE *
********************************************************************************
use "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_person_ids.dta", clear
gen member=1
collapse (max) fhh (sum) hh_members=member, by (hhid)
lab var hh_members "Number of household members"
lab var fhh "1= Female-headed household"
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhsize.dta", replace



	***********
	* Visit 2

use "${Nigeria_GHS_W5_raw_data}/sect6a_harvestw5.dta", clear
append using "${Nigeria_GHS_W5_raw_data}/sect6b_harvestw5.dta"
append using "${Nigeria_GHS_W5_raw_data}/sect6c_harvestw5.dta"


gen nfd_ = s6q2/7 //Per day
replace nfd_ = s6q4/30 if nfd_==.
*replace nfd_ = s11cq6/182.5 if nfd_==. // PA 1.8 6-month consumption not captured in W5
replace nfd_ = s6q6/365 if nfd_==.
recode nfd_ (.=0)

keep hhid nfd_ item_cd 
reshape wide nfd_, i(hhid) j(item_cd)
gen nfdtbac = nfd_101+nfd_102 //Tobacco and matches

gen nfdrecre = nfd_103+nfd_105+nfd_229+nfd_232+nfd_235+nfd_237+nfd_238 //"Recreation and culture", here including gambling/lotto and newspapers/magazines
gen nfdfares = nfd_104+nfd_358+nfd_359 //Public transportation
gen nfdwater = nfd_214
gen nfdelec = nfd_205+nfd_213
gen nfdgas = nfd_203
gen nfdkero = nfd_201+nfd_206
gen nfdliqd = nfd_204+nfd_202+nfd_212
gen nfdutil = 0 // not reported in W5?
egen nfdcloth = rowtotal(nfd_301-nfd_326 nfd_236)
egen nfdfmtn = rowtotal(nfd_328-nfd_349)
gen nfdrepar = nfd_327+nfd_328+nfd_248+nfd_249
gen nfddome = nfd_220+nfd_221+nfd_244
gen nfdpetro = nfd_209
gen nfddiesl = nfd_210
gen nfdcomm = nfd_318+nfd_319+nfd_320+nfd_321+nfd_350+nfd_351+nfd_352+nfd_224+nfd_225+nfd_226+nfd_227+nfd_233+nfd_234
gen nfdinsur = nfd_362+nfd_365
egen nfdfoth =rowtotal(nfd_206 nfd_211 nfd_247 nfd_308 nfd_313-nfd_317 nfd_354 nfd_361 nfd_215-nfd_219 nfd_327 nfd_360 nfd_364) //Added dowry, wedding, and funeral expenses/fines and legal fees
gen nfdfwood = nfd_207+nfd_208
gen nfdchar = nfd_307
egen nfdtrans = rowtotal(nfd_239-nfd_243)
gen nfdrnthh = nfd_245+nfd_246+nfd_353
gen nfdhealth = nfd_355+nfd_363+nfd_222+nfd_223+nfd_356+nfd_357 //Health insurance and non-insurance healthcare expenses
drop nfd_*

*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean) // PA W5 consumption data not published yet, check back later
unab vars : nfd*
foreach i in `vars' {
	gen `i'_def = `i' /*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
}

//There are a couple of big-ticket repair bills that likely aren't recurring monthly expenses even though they ask for 30-day recall on those questions. I'm assuming that they should probably be reported as annual expenses rather than monthly ones and rescale to fit.
*replace nfdrepar = nfdrepar*30/365 if hhid == 320056 | hhid == 199048
*replace nfdrepar_def = nfdrepar*30/365 if hhid == 320056 | hhid == 199048

la var nfdtbac "Tobacco & narcotics"
la var nfdrecre "Recreation and culture"
la var nfdfares "Fares"
la var nfdwater "Water, excluding packaged water"
la var nfdelec "Electricity"
la var nfdgas "Gas"
la var nfdkero "Kerosene"
la var nfdliqd "Other liquid fuels"
la var nfdutil "Refuse, sewage collection, disposal, and other services"
la var nfdcloth "Clothing and footwear"
la var nfdfmtn "Furnishings and routine household maintenance"
la var nfdrepar "Maintenance and repairs to dwelling"
la var nfddome "Domestic household services"
la var nfdpetro "Petrol"
la var nfddiesl "Diesel"
la var nfdtrans "Other transportation (n/a)"
la var nfdcomm "Communication (post, telephone, and computing/internet)"
la var nfdinsur "Other insurance excluding education and health"
la var nfdfoth "Expenditures on frequent non-food not mentioned elsewhere"
la var nfdfwood "Firewood"
la var nfdchar "Charcoal"
la var nfdrnthh "Mortgage and Rent"
la var nfdhealth "Healthcare expenses"

tempfile hhexp
save `hhexp', replace


//Getting prepared foods out of the way
use "${Nigeria_GHS_W5_raw_data}/sect5a_harvestw5.dta", clear
keep if s5aq1==1
gen item_ = s5aq2/7 //Total consumption per day (avg) of prepared foods/beverages
keep hhid item_cd item_ 
reshape wide item_, i(hhid) j(item_cd)
recode item_* (.=0)
gen fdbevby1 = item_6+item_8 
gen fdalcby1 = item_9
gen fdrestby = item_1+item_2+item_3+item_4
gen fdothby1=item_5+item_7
*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean) // PA Update when WB consumption data becomes available
gen fdbevby1_def = fdbevby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdalcby1_def = fdalcby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdothby1_def = fdothby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdrestby_def = fdrestby/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
drop item*
tempfile prepfoods
save `prepfoods', replace


use "${Nigeria_GHS_W5_raw_data}/sect5b_harvestw5.dta", clear
//gen obs=1 if s5bq1 != .
//keep if s5bq3!= . | s5bq4!= . | s5bq5!= . 
ren s5bq7a qty_bought 
gen kg_bought = qty_bought*s5bq7_cvn
gen price_kg = s5bq8/kg_bought
keep if price_kg !=. & price_kg!=0
//ALT 01.25.21: I've tested this with weighted/unweighted and kg vs unit-based pricing.
//It seems like weighted average per-kgs are producing the most reasonable results, but it is a value judgment.
*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keep(1 3) keepusing(reg_def_mean)
gen price_kg_def = price_kg/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
merge m:1 hhid using "${Nigeria_GHS_W5_created_data}/hhids.dta", nogen keep(3) keepusing(weight)
gen obs=1
foreach i in ea lga state zone {
	preserve
	collapse (median) price_`i' = price_kg price_def_`i' = price_kg_def (rawsum) obs_`i'=obs [aw=weight], by(item_cd `i')
	tempfile food_`i'
	save `food_`i''
	restore
}

collapse (median) price_kg price_kg_def (rawsum) obs_country=obs [aw=weight], by(item_cd)
keep item_cd price_kg price_kg_def obs_country
ren price_kg price_country
ren price_kg_def price_def_country
tempfile food_country
save `food_country'

use "${Nigeria_GHS_W5_raw_data}/sect5b_harvestw5.dta", clear
keep if s5bq3!= . | s5bq4!= . | s5bq5!= . 
ren s5bq7a qty_bought 
gen kg_bought = qty_bought*s5bq7_cvn
gen price_kg = s5bq8/kg_bought
recode price_kg (0=.)
gen price_kg_def = price_kg/*/reg_def_mean*/
foreach i in ea lga state zone { 
	merge m:1 item_cd `i' using `food_`i'', nogen
}
merge m:1 item_cd using `food_country', nogen

foreach i in lga state zone country {
	replace price_kg = price_`i' if price_kg ==. & obs_`i' > 9
	replace price_kg_def = price_def_`i' if price_kg_def == . & obs_`i' > 9
}

gen qty_purch = s5bq2_cvn * s5bq3
gen qty_own = s5bq2_cvn * (s5bq4+s5bq5)
//Getting per-day consumption
gen purch_ = qty_purch*price_kg/7
gen own_ = qty_own*price_kg/7
gen purch_def_ = qty_purch*price_kg_def/7
gen own_def_ = qty_own*price_kg_def/7
keep hhid item_cd purch* own*
reshape wide purch_ own_ purch_def_ own_def_, i(hhid) j(item_cd)
recode purch_* own_* (.=0)
ren purch_def_* purch_*_def 
ren own_def_* own_*_def

//Needed for water section
preserve
//ALT 4/1/22: Using deflated values now
gen purch_water_ph = purch_151_def + purch_150_def
gen own_water_ph = own_151_def + own_150_def
keep hhid purch_water_ph own_water_ph 
tempfile water_ph
save `water_ph'
restore
ren purch_10 fdsorby
ren purch_10_def fdorsby_def
ren purch_11 fdmilby
ren purch_11_def fdmilby_def
gen fdmaizby = purch_16+purch_20+purch_22
gen fdmaizby_def = purch_16_def + purch_20_def + purch_22_def
gen fdriceby = purch_13+purch_14
gen fdriceby_def = purch_13_def + purch_14_def
gen fdyamby = purch_17+purch_31 
gen fdyamby_def = purch_17_def + purch_31_def
gen fdcasby = purch_18+purch_30+purch_32+purch_33 
gen fdcasby_def = purch_18_def + purch_30_def + purch_32_def + purch_33_def
gen fdcereby = purch_23+purch_19
gen fdcereby_def = purch_23_def + purch_19_def
gen fdbrdby = purch_25+purch_26+purch_27+purch_28
gen fdbrdby_def = purch_25_def + purch_26_def + purch_27_def + purch_28_def
gen fdtubby = purch_34+purch_35+purch_36+purch_37+purch_38+purch_60 
gen fdtubby_def = purch_34_def + purch_35_def + purch_36_def + purch_37_def + purch_38_def + purch_60_def
gen fdpoulby = purch_80+purch_81+purch_82
gen fdpoulby_def = purch_80_def + purch_81_def + purch_82_def 
gen fdmeatby = purch_29+purch_90+purch_91+purch_92+purch_93+purch_94+purch_96
gen fdmeatby_def = purch_29_def + purch_90_def + purch_91_def + purch_92_def + purch_93_def + purch_94_def + purch_96_def
gen fdfishby = purch_100+purch_101+purch_102+purch_103+purch_104+purch_105+purch_106+purch_107
gen fdfishby_def = purch_100_def + purch_101_def + purch_102_def + purch_103_def + purch_104_def + purch_105_def + purch_106_def + purch_107_def
gen fddairby = purch_83+purch_84+purch_110+purch_111+purch_112+purch_113+purch_114
gen fddairby_def = purch_83_def + purch_84_def + purch_110_def + purch_111_def + purch_112_def + purch_113_def + purch_114_def 
gen fdfatsby = purch_46+purch_47+purch_48+purch_50+purch_51+purch_52+purch_53+purch_56+purch_63+purch_43+purch_44
gen fdfatsby_def = purch_46_def + purch_47_def + purch_48_def + purch_50_def + purch_51_def + purch_52_def + purch_53_def + purch_56_def + purch_63_def + purch_43_def + purch_44_def
gen fdfrutby = purch_61+purch_62+purch_64+purch_66+purch_67+purch_68+purch_69+purch_70+purch_71+purch_601
gen fdfrutby_def = purch_61_def + purch_62_def + purch_64_def + purch_66_def + purch_67_def + purch_68_def + purch_69_def + purch_70_def + purch_71_def + purch_601_def
gen fdvegby = purch_72+purch_73+purch_74+purch_75+purch_76+purch_77+purch_78+purch_79
gen fdvegby_def = purch_72_def + purch_73_def + purch_74_def + purch_75_def + purch_76_def + purch_77_def +  purch_78_def + purch_79_def
gen fdbeanby = purch_40+purch_41+purch_42+purch_45
gen fdbeanby_def = purch_40_def + purch_41_def + purch_42_def + purch_45_def
gen fdswtby = purch_130+purch_132
gen fdswtby_def = purch_130_def + purch_132_def 
gen fdbevby2 = purch_120+purch_121+purch_122+purch_150+purch_151+purch_152+purch_153+purch_154+purch_155
gen fdbevby2_def = purch_120_def + purch_121_def + purch_122_def + purch_150_def + purch_151_def + purch_152_def + purch_153_def + purch_154_def + purch_155_def
gen fdalcby2 = purch_160+purch_161+purch_162+purch_163+purch_164
gen fdalcby2_def = purch_160_def + purch_161_def + purch_162_def + purch_163_def + purch_164
gen fdothby2 = purch_142+purch_143
gen fdothby2_def = purch_142_def + purch_143_def
gen fdspiceby = purch_141+purch_144+purch_148+purch_145+purch_146+purch_147
gen fdspiceby_def = purch_141_def + purch_144_def + purch_148_def + purch_145_def + purch_146_def + purch_147_def

ren own_10 fdsorpr
ren own_10_def fdorspr_def
ren own_11 fdmilpr
ren own_11_def fdmilpr_def
gen fdmaizpr = own_16+own_20+own_22
gen fdmaizpr_def = own_16_def + own_20_def + own_22_def
gen fdricepr = own_13+own_14
gen fdricepr_def = own_13_def + own_14_def
gen fdyampr = own_17+own_31 
gen fdyampr_def = own_17_def + own_31_def
gen fdcaspr = own_18+own_30+own_32+own_33 
gen fdcaspr_def = own_18_def + own_30_def + own_32_def + own_33_def
gen fdcerepr = own_23+own_19
gen fdcerepr_def = own_23_def + own_19_def
gen fdbrdpr = own_25+own_26+own_27+own_28
gen fdbrdpr_def = own_25_def + own_26_def + own_27_def + own_28_def
gen fdtubpr = own_34+own_35+own_36+own_37+own_38+own_60 
gen fdtubpr_def = own_34_def + own_35_def + own_36_def + own_37_def + own_38_def + own_60_def
gen fdpoulpr = own_80+own_81+own_82
gen fdpoulpr_def = own_80_def + own_81_def + own_82_def 
gen fdmeatpr = own_29+own_90+own_91+own_92+own_93+own_94+own_96
gen fdmeatpr_def = own_29_def + own_90_def + own_91_def + own_92_def + own_93_def + own_94_def + own_96_def
gen fdfishpr = own_100+own_101+own_102+own_103+own_104+own_105+own_106+own_107
gen fdfishpr_def = own_100_def + own_101_def + own_102_def + own_103_def + own_104_def + own_105_def + own_106_def + own_107_def
gen fddairpr = own_83+own_84+own_110+own_111+own_112+own_113+own_114
gen fddairpr_def = own_83_def + own_84_def + own_110_def + own_111_def + own_112_def + own_113_def + own_114_def
gen fdfatspr = own_46+own_47+own_48+own_50+own_51+own_52+own_53+own_56+own_63+own_43+own_44
gen fdfatspr_def = own_46_def + own_47_def + own_48_def + own_50_def + own_51_def + own_52_def + own_53_def + own_56_def + own_63_def + own_43_def + own_44_def
gen fdfrutpr = own_61+own_62+own_64+own_66+own_67+own_68+own_69+own_70+own_71+own_601
gen fdfrutpr_def = own_61_def + own_62_def + own_64_def + own_66_def + own_67_def + own_68_def + own_69_def + own_70_def + own_71_def + own_601_def
gen fdvegpr = own_72+own_73+own_74+own_75+own_76+own_77+own_78+own_79
gen fdvegpr_def = own_72_def + own_73_def + own_74_def + own_75_def + own_76_def + own_77_def +  own_78_def + own_79_def
gen fdbeanpr = own_40+own_41+own_42+own_45
gen fdbeanpr_def = own_40_def + own_41_def + own_42_def + own_45_def
gen fdswtpr = own_130+own_132
gen fdswtpr_def = own_130_def + own_132_def 
gen fdbevpr = own_120+own_121+own_122+own_150+own_151+own_152+own_153+own_154+own_155
gen fdbevpr_def = own_120_def + own_121_def + own_122_def + own_150_def + own_151_def + own_152_def + own_153_def + own_154_def + own_155_def
gen fdalcpr = own_160+own_161+own_162+own_163+own_164
gen fdalcpr_def = own_160_def + own_161_def + own_162_def + own_163_def + own_164
gen fdothpr = own_142+own_143
gen fdothpr_def = own_142_def + own_143_def
gen fdspicepr = own_141+own_144+own_148+own_145+own_146+own_147
gen fdspicepr_def = own_141_def + own_144_def + own_148_def + own_145_def + own_146_def + own_147_def

drop purch_* own_*

merge 1:1 hhid using `prepfoods', nogen
gen fdothby = fdothby1+fdothby2
gen fdbevby = fdbevby1+fdbevby2 
gen fdalcby = fdalcby1+fdalcby2 
gen fdothby_def = fdothby1_def + fdothby2_def 
gen fdbevby_def = fdbevby1_def+ fdbevby2_def
gen fdalcby_def = fdalcby1_def+fdalcby2_def
drop fdothby1* fdothby2* fdbevby1* fdbevby2* fdalcby1* fdalcby2* 

la var fdsorby "Sorghum purchased"
la var fdmilby "Millet purchased"
la var fdmaizby "Maize grain and flours purchased"
la var fdriceby "Rice in all forms purchased"
la var fdyamby "Yam roots and flour purchased"
la var fdcasby "Cassava-gari, roots, and flour purchased"
la var fdcereby "Other cereals purchased"
la var fdbrdby "Bread and the like purchased"
la var fdtubby "Bananas & tubers purchased"
la var fdpoulby "Poultry purchased"
la var fdmeatby "Meat purchased"
la var fdfishby "Fish & seafood purchased"
la var fddairby "Milk, cheese, and eggs purchased"
la var fdfatsby "Oils, fats, & oil-rich nuts purchased"
la var fdfrutby "Fruits purchased"
la var fdvegby "Vegetables excluding pulses purchased"
la var fdbeanby "Pulses (beans, peas, and groundnuts) purchased"
la var fdswtby "Sugar, jam, honey, chocolate & confectionary purchased"
la var fdbevby "Non-alcoholic purchased"
la var fdalcby "Alcoholic beverages purchased"
la var fdrestby "Food consumed in restaurants & canteens purchased"
la var fdspiceby "Spices and condiments purchased"
la var fdothby "Food items not mentioned above purchased"

la var fdsorpr "Sorghum auto-consumption"
la var fdmilpr "Millet auto-consumption"
la var fdmaizpr "Maize grain and flours auto-consumption"
la var fdricepr "Rice in all forms auto-consumption"
la var fdyampr "Yam roots and flour auto-consumption"
la var fdcaspr "Cassava-gari, roots, and flour auto-consumption"
la var fdcerepr "Other cereals auto-consumption"
la var fdbrdpr "Bread and the like auto-consumption"
la var fdtubpr "Bananas & tubers auto-consumption"
la var fdpoulpr "Poultry auto-consumption"
la var fdmeatpr "Meat auto-consumption"
la var fdfishpr "Fish & seafood auto-consumption"
la var fddairpr "Milk, cheese, and eggs auto-consumption"
la var fdfatspr "Oils, fats, & oil-rich nuts auto-consumption"
la var fdfrutpr "Fruits auto-consumption"
la var fdvegpr "Vegetables excluding pulses auto-consumption"
la var fdbeanpr "Pulses (beans, peas, and groundnuts) auto-consumption"
la var fdswtpr "Sugar, jam, honey, chocolate & confectionary auto-consumption"
la var fdbevpr "Non-alcoholic auto-consumption"
la var fdalcpr "Alcoholic beverages auto-consumption"
la var fdspiceby "Spices and condiments auto-consumption"
la var fdothpr "Food items not mentioned above auto-consumption"


















//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*merge 1:1 hhid using `hhexp', nogen
unab varlist : *_def 
local vars_nom : subinstr local varlist "_def" "", all 
egen totcons = rowtotal(`vars_nom')
egen totcons_def = rowtotal(`varlist')
drop if totcons_def == 0 // Dropping 3 households for which we have extremely partial consumption statistics 
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhsize.dta", nogen keepusing(hh_members)
//Convert to annual to get these aligned with the WB files
gen totcons_pc = totcons/hh_members * 365
gen totcons_adj = totcons_def/hh_members * 365
la var totcons "Total daily consumption per hh, nominal"
la var totcons_def "Total daily consumption per hh, regionally deflated"
la var totcons_pc "Total percap cons exp, annual, nominal, postharverst vals only"
la var totcons_adj "Total percap cons exp, annual, regionally deflated, postharvest vals only"
save "${Nigeria_GHS_W5_created_data}/cons_agg_wave5_visit2.dta", replace



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



















	*****************
	*Visit 1

use "${Nigeria_GHS_W5_raw_data}/sect7a_plantingw5.dta", clear
append using "${Nigeria_GHS_W5_raw_data}/sect7b_plantingw5.dta"
append using "${Nigeria_GHS_W5_raw_data}/sect7c_plantingw5.dta"

gen nfd_ = s7q2/7 //Per day
replace nfd_ = s7q4/30 if nfd_==.
* replace nfd_ = s8q6/182.5 if nfd_==. PA 1.9 6 month consumption not asked in W5
replace nfd_ = s7q6/365 if nfd_==.
recode nfd_ (.=0)

keep hhid nfd_ item_cd 
reshape wide nfd_, i(hhid) j(item_cd)
gen nfdtbac = nfd_101+nfd_102 //Tobacco and matches

gen nfdrecre = nfd_103+nfd_105+nfd_229+nfd_232+nfd_235+nfd_237+nfd_238 //"Recreation and culture", here including gambling/lotto and newspapers/magazines
gen nfdfares = nfd_104+nfd_358+nfd_359 //Public transportation
gen nfdwater = nfd_214
gen nfdelec = nfd_205+nfd_213
gen nfdgas = nfd_203
gen nfdkero = nfd_201+nfd_206
gen nfdliqd = nfd_204+nfd_202+nfd_212
gen nfdutil = 0 // not reported in W5?
egen nfdcloth = rowtotal(nfd_301-nfd_326 nfd_236)
egen nfdfmtn = rowtotal(nfd_328-nfd_349)
gen nfdrepar = nfd_327+nfd_328+nfd_248+nfd_249
gen nfddome = nfd_220+nfd_221+nfd_244
gen nfdpetro = nfd_209
gen nfddiesl = nfd_210
gen nfdcomm = nfd_318+nfd_319+nfd_320+nfd_321+nfd_350+nfd_351+nfd_352+nfd_224+nfd_225+nfd_226+nfd_227+nfd_233+nfd_234
gen nfdinsur = nfd_362+nfd_365
egen nfdfoth =rowtotal(nfd_206 nfd_211 nfd_247 nfd_308 nfd_313-nfd_317 nfd_354 nfd_361 nfd_215-nfd_219 nfd_327 nfd_360 nfd_364) //Added dowry, wedding, and funeral expenses/fines and legal fees
gen nfdfwood = nfd_207+nfd_208
gen nfdchar = nfd_307
egen nfdtrans = rowtotal(nfd_239-nfd_243)
gen nfdrnthh = nfd_245+nfd_246+nfd_353
gen nfdhealth = nfd_355+nfd_363+nfd_222+nfd_223+nfd_356+nfd_357 //Health insurance and non-insurance healthcare expenses
drop nfd_*


*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean) // PA 1.9 to update when WB consumption data is available
unab vars : nfd*
foreach i in `vars' {
	gen `i'_def = `i'/*/reg_def_mean*/
}

//See visit 2 notes.
*replace nfdrepar = nfdrepar*30/365 if hhid == 320056 | hhid == 199048
*replace nfdrepar_def = nfdrepar*30/365 if hhid == 320056 | hhid == 199048


la var nfdtbac "Tobacco & narcotics"
la var nfdrecre "Recreation and culture"
la var nfdfares "Fares"
la var nfdwater "Water, excluding packaged water"
la var nfdelec "Electricity"
la var nfdgas "Gas"
la var nfdkero "Kerosene"
la var nfdliqd "Other liquid fuels"
la var nfdutil "Refuse, sewage collection, disposal, and other services"
la var nfdcloth "Clothing and footwear"
la var nfdfmtn "Furnishings and routine household maintenance"
la var nfdrepar "Maintenance and repairs to dwelling"
la var nfddome "Domestic household services"
la var nfdpetro "Petrol"
la var nfddiesl "Diesel"
la var nfdtrans "Other transportation (n/a)"
la var nfdcomm "Communication (post, telephone, and computing/internet)"
la var nfdinsur "Other insurance excluding education and health"
la var nfdfoth "Expenditures on frequent non-food not mentioned elsewhere"
la var nfdfwood "Firewood"
la var nfdchar "Charcoal"
la var nfdrnthh "Mortgage and Rent"
la var nfdhealth "Healthcare expenses"

tempfile hhexp
save `hhexp', replace

//Getting prepared foods out of the way
use "${Nigeria_GHS_W5_raw_data}/sect6a_plantingw5.dta", clear
keep if s6aq1==1
gen item_ = s6aq2/7 //Total consumption per day (avg) of prepared foods/beverages
keep hhid item_cd item_ 
reshape wide item_, i(hhid) j(item_cd)
recode item_* (.=0)
gen fdbevby1 = item_6+item_8 
gen fdalcby1 = item_9
gen fdrestby = item_1+item_2+item_3+item_4
gen fdothby1=item_5+item_7
*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean) // PA Update when WB consumption data becomes available
gen fdbevby1_def = fdbevby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdalcby1_def = fdalcby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdothby1_def = fdothby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdrestby_def = fdrestby/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
drop item*
tempfile prepfoods
save `prepfoods', replace



use "${Nigeria_GHS_W5_raw_data}/sect6b_plantingw5.dta", clear
//gen obs=1 if s6bq7a != .
//keep if s6bq3!= . | s6bq4!= . | s6bq5!= . 
ren s6bq7a qty_bought 
gen kg_bought = qty_bought*s6bq7_cvn
gen price_kg = s6bq8/kg_bought
keep if price_kg != 0 & price_kg != .
gen obs=1
*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keep(1 3) keepusing(reg_def_mean)
gen price_kg_def = price_kg /*/reg_def_mean */
merge m:1 hhid using "${Nigeria_GHS_W5_created_data}/hhids.dta", nogen keep(3) keepusing(weight)
foreach i in ea lga state zone {
	preserve
	collapse (median) price_`i' = price_kg price_def_`i' = price_kg_def (rawsum) obs_`i'=obs [aw=weight], by(item_cd `i')
	tempfile food_`i'
	save `food_`i''
	restore
}


collapse (median) price_kg price_kg_def (rawsum) obs_country=obs [aw=weight], by(item_cd)
keep item_cd price_kg price_kg_def obs_country
ren price_kg price_country
ren price_kg_def price_def_country
tempfile food_country
save `food_country'


use "${Nigeria_GHS_W5_raw_data}/sect6b_plantingw5.dta", clear
ren s6bq7a qty_bought 
gen kg_bought = qty_bought*s6bq7_cvn
gen price_kg = s6bq8/kg_bought
recode price_kg (0=.)
gen price_kg_def = price_kg/*/reg_def_mean*/ 
keep if s6bq3!= . | s6bq4!= . | s6bq5!= . 
foreach i in ea lga state zone {
merge m:1 item_cd `i' using `food_`i'', nogen
}
merge m:1 item_cd using `food_country', nogen

foreach i in lga state zone country {
	replace price_kg = price_`i' if price_kg ==. & obs_`i' > 9
	replace price_kg_def = price_def_`i' if price_kg_def == . & obs_`i' > 9
}

gen qty_purch = s6bq2_cvn * s6bq3 
gen qty_own = s6bq2_cvn * (s6bq4+s6bq5)
//Getting per-day consumption
gen purch_ = qty_purch*price_kg/7
gen own_ = qty_own*price_kg/7
gen purch_def_ = qty_purch*price_kg_def/7
gen own_def_ = qty_own*price_kg_def/7
keep hhid item_cd purch* own*
reshape wide purch_ own_ purch_def_ own_def_, i(hhid) j(item_cd)
recode purch_* own_* (.=0)
ren purch_def_* purch_*_def 
ren own_def_* own_*_def

//Water section
preserve
gen purch_water_pp = purch_151 + purch_150
gen own_water_pp = own_151 + own_150
keep hhid purch_water_pp own_water_pp 
merge 1:1 hhid using `water_ph', nogen
recode *water* (.=0)
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_water_cons.dta", replace

restore

ren purch_10 fdsorby
ren purch_10_def fdorsby_def
ren purch_11 fdmilby
ren purch_11_def fdmilby_def
gen fdmaizby = purch_16+purch_20+purch_22
gen fdmaizby_def = purch_16_def + purch_20_def + purch_22_def
gen fdriceby = purch_13+purch_14
gen fdriceby_def = purch_13_def + purch_14_def
gen fdyamby = purch_17+purch_31 
gen fdyamby_def = purch_17_def + purch_31_def
gen fdcasby = purch_18+purch_30+purch_32+purch_33 
gen fdcasby_def = purch_18_def + purch_30_def + purch_32_def + purch_33_def
gen fdcereby = purch_23+purch_19
gen fdcereby_def = purch_23_def + purch_19_def
gen fdbrdby = purch_25+purch_26+purch_27+purch_28
gen fdbrdby_def = purch_25_def + purch_26_def + purch_27_def + purch_28_def
gen fdtubby = purch_34+purch_35+purch_36+purch_37+purch_38+purch_60 
gen fdtubby_def = purch_34_def + purch_35_def + purch_36_def + purch_37_def + purch_38_def + purch_60_def
gen fdpoulby = purch_80+purch_81+purch_82
gen fdpoulby_def = purch_80_def + purch_81_def + purch_82_def 
gen fdmeatby = purch_29+purch_90+purch_91+purch_92+purch_93+purch_94+purch_96
gen fdmeatby_def = purch_29_def + purch_90_def + purch_91_def + purch_92_def + purch_93_def + purch_94_def + purch_96_def
gen fdfishby = purch_100+purch_101+purch_102+purch_103+purch_104+purch_105+purch_106+purch_107
gen fdfishby_def = purch_100_def + purch_101_def + purch_102_def + purch_103_def + purch_104_def + purch_105_def + purch_106_def + purch_107_def
gen fddairby = purch_83+purch_84+purch_110+purch_111+purch_112+purch_113+purch_114+purch_115
gen fddairby_def = purch_83_def + purch_84_def + purch_110_def + purch_111_def + purch_112_def + purch_113_def + purch_114_def + purch_115_def
gen fdfatsby = purch_46+purch_47+purch_48+purch_50+purch_51+purch_52+purch_53+purch_56+purch_63+purch_43+purch_44
gen fdfatsby_def = purch_46_def + purch_47_def + purch_48_def + purch_50_def + purch_51_def + purch_52_def + purch_53_def + purch_56_def + purch_63_def + purch_43_def + purch_44_def
gen fdfrutby = purch_61+purch_62+purch_64+/*purch_65+*/purch_66+purch_67+purch_68+purch_69+purch_70+purch_71+purch_601 //65 is only in postharvest questionnaire for some reason
gen fdfrutby_def = purch_61_def + purch_62_def + purch_64_def + /*purch_65_def +*/ purch_66_def + purch_67_def + purch_68_def + purch_69_def + purch_70_def + purch_71_def + purch_601_def
gen fdvegby = purch_72+purch_73+purch_74+purch_75+purch_76+purch_77+purch_78+purch_79
gen fdvegby_def = purch_72_def + purch_73_def + purch_74_def + purch_75_def + purch_76_def + purch_77_def +  purch_78_def + purch_79_def
gen fdbeanby = purch_40+purch_41+purch_42+purch_45
gen fdbeanby_def = purch_40_def + purch_41_def + purch_42_def + purch_45_def
gen fdswtby = purch_130+purch_132+purch_133
gen fdswtby_def = purch_130_def + purch_132_def + purch_133_def
gen fdbevby2 = purch_120+purch_121+purch_122+purch_150+purch_151+purch_152+purch_153+purch_154+purch_155
gen fdbevby2_def = purch_120_def + purch_121_def + purch_122_def + purch_150_def + purch_151_def + purch_152_def + purch_153_def + purch_154_def + purch_155_def
gen fdalcby2 = purch_160+purch_161+purch_162+purch_163+purch_164
gen fdalcby2_def = purch_160_def + purch_161_def + purch_162_def + purch_163_def + purch_164
gen fdothby2 = purch_142+purch_143
gen fdothby2_def = purch_142_def + purch_143_def
gen fdspiceby = purch_141+purch_144+purch_148+purch_145+purch_146+purch_147
gen fdspiceby_def = purch_141_def + purch_144_def + purch_148_def + purch_145_def + purch_146_def + purch_147_def

ren own_10 fdsorpr
ren own_10_def fdorspr_def
ren own_11 fdmilpr
ren own_11_def fdmilpr_def
gen fdmaizpr = own_16+own_20+own_22
gen fdmaizpr_def = own_16_def + own_20_def + own_22_def
gen fdricepr = own_13+own_14
gen fdricepr_def = own_13_def + own_14_def
gen fdyampr = own_17+own_31 
gen fdyampr_def = own_17_def + own_31_def
gen fdcaspr = own_18+own_30+own_32+own_33 
gen fdcaspr_def = own_18_def + own_30_def + own_32_def + own_33_def
gen fdcerepr = own_23+own_19
gen fdcerepr_def = own_23_def + own_19_def
gen fdbrdpr = own_25+own_26+own_27+own_28
gen fdbrdpr_def = own_25_def + own_26_def + own_27_def + own_28_def
gen fdtubpr = own_34+own_35+own_36+own_37+own_38+own_60 
gen fdtubpr_def = own_34_def + own_35_def + own_36_def + own_37_def + own_38_def + own_60_def
gen fdpoulpr = own_80+own_81+own_82
gen fdpoulpr_def = own_80_def + own_81_def + own_82_def 
gen fdmeatpr = own_29+own_90+own_91+own_92+own_93+own_94+own_96
gen fdmeatpr_def = own_29_def + own_90_def + own_91_def + own_92_def + own_93_def + own_94_def + own_96_def
gen fdfishpr = own_100+own_101+own_102+own_103+own_104+own_105+own_106+own_107
gen fdfishpr_def = own_100_def + own_101_def + own_102_def + own_103_def + own_104_def + own_105_def + own_106_def + own_107_def
gen fddairpr = own_83+own_84+own_110+own_111+own_112+own_113+own_114+own_115
gen fddairpr_def = own_83_def + own_84_def + own_110_def + own_111_def + own_112_def + own_113_def + own_114_def + own_115_def
gen fdfatspr = own_46+own_47+own_48+own_50+own_51+own_52+own_53+own_56+own_63+own_43+own_44
gen fdfatspr_def = own_46_def + own_47_def + own_48_def + own_50_def + own_51_def + own_52_def + own_53_def + own_56_def + own_63_def + own_43_def + own_44_def
gen fdfrutpr = own_61+own_62+own_64+/*own_65+*/own_66+own_67+own_68+own_69+own_70+own_71+own_601
gen fdfrutpr_def = own_61_def + own_62_def + own_64_def + /*own_65_def +*/ own_66_def + own_67_def + own_68_def + own_69_def + own_70_def + own_71_def + own_601_def
gen fdvegpr = own_72+own_73+own_74+own_75+own_76+own_77+own_78+own_79
gen fdvegpr_def = own_72_def + own_73_def + own_74_def + own_75_def + own_76_def + own_77_def +  own_78_def + own_79_def
gen fdbeanpr = own_40+own_41+own_42+own_45
gen fdbeanpr_def = own_40_def + own_41_def + own_42_def + own_45_def
gen fdswtpr = own_130+own_132+own_133
gen fdswtpr_def = own_130_def + own_132_def + own_133_def
gen fdbevpr = own_120+own_121+own_122+own_150+own_151+own_152+own_153+own_154+own_155
gen fdbevpr_def = own_120_def + own_121_def + own_122_def + own_150_def + own_151_def + own_152_def + own_153_def + own_154_def + own_155_def
gen fdalcpr = own_160+own_161+own_162+own_163+own_164
gen fdalcpr_def = own_160_def + own_161_def + own_162_def + own_163_def + own_164
gen fdothpr = own_142+own_143
gen fdothpr_def = own_142_def + own_143_def
gen fdspicepr = own_141+own_144+own_148+own_145+own_146+own_147
gen fdspicepr_def = own_141_def + own_144_def + own_148_def + own_145_def + own_146_def + own_147_def

drop purch_* own_*

merge 1:1 hhid using `prepfoods', nogen
gen fdothby = fdothby1+fdothby2
gen fdbevby = fdbevby1+fdbevby2 
gen fdalcby = fdalcby1+fdalcby2 
gen fdothby_def = fdothby1_def + fdothby2_def 
gen fdbevby_def = fdbevby1_def+ fdbevby2_def
gen fdalcby_def = fdalcby1_def+fdalcby2_def
drop fdothby1* fdothby2* fdbevby1* fdbevby2* fdalcby1* fdalcby2* 

la var fdsorby "Sorghum purchased"
la var fdmilby "Millet purchased"
la var fdmaizby "Maize grain and flours purchased"
la var fdriceby "Rice in all forms purchased"
la var fdyamby "Yam roots and flour purchased"
la var fdcasby "Cassava-gari, roots, and flour purchased"
la var fdcereby "Other cereals purchased"
la var fdbrdby "Bread and the like purchased"
la var fdtubby "Bananas & tubers purchased"
la var fdpoulby "Poultry purchased"
la var fdmeatby "Meat purchased"
la var fdfishby "Fish & seafood purchased"
la var fddairby "Milk, cheese, and eggs purchased"
la var fdfatsby "Oils, fats, & oil-rich nuts purchased"
la var fdfrutby "Fruits purchased"
la var fdvegby "Vegetables excluding pulses purchased"
la var fdbeanby "Pulses (beans, peas, and groundnuts) purchased"
la var fdswtby "Sugar, jam, honey, chocolate & confectionary purchased"
la var fdbevby "Non-alcoholic purchased"
la var fdalcby "Alcoholic beverages purchased"
la var fdrestby "Food consumed in restaurants & canteens purchased"
la var fdspiceby "Spices and condiments purchased"
la var fdothby "Food items not mentioned above purchased"

la var fdsorpr "Sorghum auto-consumption"
la var fdmilpr "Millet auto-consumption"
la var fdmaizpr "Maize grain and flours auto-consumption"
la var fdricepr "Rice in all forms auto-consumption"
la var fdyampr "Yam roots and flour auto-consumption"
la var fdcaspr "Cassava-gari, roots, and flour auto-consumption"
la var fdcerepr "Other cereals auto-consumption"
la var fdbrdpr "Bread and the like auto-consumption"
la var fdtubpr "Bananas & tubers auto-consumption"
la var fdpoulpr "Poultry auto-consumption"
la var fdmeatpr "Meat auto-consumption"
la var fdfishpr "Fish & seafood auto-consumption"
la var fddairpr "Milk, cheese, and eggs auto-consumption"
la var fdfatspr "Oils, fats, & oil-rich nuts auto-consumption"
la var fdfrutpr "Fruits auto-consumption"
la var fdvegpr "Vegetables excluding pulses auto-consumption"
la var fdbeanpr "Pulses (beans, peas, and groundnuts) auto-consumption"
la var fdswtpr "Sugar, jam, honey, chocolate & confectionary auto-consumption"
la var fdbevpr "Non-alcoholic auto-consumption"
la var fdalcpr "Alcoholic beverages auto-consumption"
la var fdspiceby "Spices and condiments auto-consumption"
la var fdothpr "Food items not mentioned above auto-consumption"


*merge 1:1 hhid using `hhexp', nogen
unab varlist : *_def 
local vars_nom : subinstr local varlist "_def" "", all 
egen totcons = rowtotal(`vars_nom')
egen totcons_def = rowtotal(`varlist')
drop if totcons_def == 0 // Dropping 3 households for which we have extremely partial consumption statistics 
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhsize.dta", nogen keepusing(hh_members)
//Convert to annual to get these aligned with the WB files
gen totcons_pc = totcons/hh_members * 365
gen totcons_adj = totcons_def/hh_members * 365
la var totcons "Total daily consumption per hh, nominal"
la var totcons_def "Total daily consumption per hh, regionally deflated"
la var totcons_pc "Total percap cons exp, annual, nominal, postplanting vals only"
la var totcons_adj "Total percap cons exp, annual, regionally deflated, postplanting vals only"
save "${Nigeria_GHS_W5_created_data}/cons_agg_wave5_visit1.dta", replace

ren totcons totcons_pp
ren totcons_def totcons_def_pp 
ren totcons_pc totcons_pc_pp
ren totcons_adj totcons_adj_pp
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/cons_agg_wave5_visit2.dta", nogen keepusing(totcons*)
ren totcons totcons_ph
ren totcons_def totcons_def_ph
ren totcons_pc totcons_pc_ph 
ren totcons_adj totcons_adj_ph 
*gen totcons = (totcons_pp+totcons_ph)/2
gen totcons = totcons_pp
gen totcons_def = (totcons_def_pp+totcons_def_ph)/2
gen totcons_pc = (totcons_pc_pp+totcons_pc_ph)/2
gen totcons_adj = (totcons_adj_ph+totcons_pc_pp)/2

merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hh_adulteq.dta", nogen keep(1 3) keepusing(adulteq)
//merge 1:1 hhid using  "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhsize.dta", nogen keep(1 3)
 
gen daily_peraeq_cons = totcons/adulteq 
gen peraeq_cons = daily_peraeq_cons*365
gen daily_percap_cons = totcons/hh_members
gen percapita_cons = daily_percap_cons*365
gen total_cons = totcons*365

la var totcons "Total daily consumption per hh, nominal"
la var totcons_def "Total daily consumption per hh, regionally deflated"
la var totcons_pc "Total percap cons exp, annual, nominal"
la var totcons_adj "Total percap cons exp, annual, regionally deflated"

la var percapita_cons "Yearly HH consumption per person"	
la var total_cons "Total yearly HH consumption - harvest"								
la var peraeq_cons "Yearly HH consumption per adult equivalent"				
la var daily_peraeq_cons "Daily HH consumption per adult equivalent"		
la var daily_percap_cons "Daily HH consumption per person" 		
keep hhid adulteq totcons totcons_def totcons_pc totcons_adj percapita_cons daily_percap_cons total_cons peraeq_cons daily_peraeq_cons fd*
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_consumption2.dta", replace 




********************************************************************************
*HOUSEHOLD FOOD PROVISION* PA Done
********************************************************************************
use "${Nigeria_GHS_W5_raw_data}/sect7_harvestw5.dta", clear
reshape long s7q4__, i(hhid) j(j)
ren s7q4__ months_food_insec
keep hhid months_food_insec
collapse (sum) months_food_insec, by(hhid)
gen months_food_insec2 = months_food_insec //ALT 02.01.21: The questionnaire asks up to 25 months, but the max is 12 - I think the way the q's were administered was to ask "over the last year" and the greater time range accounts for different survey times
replace months_food_insec=(months_food_insec/12)*6 //Rescale to 6 months as this is the extent of previous waves
la var months_food_insec "Food insecurity, rescaled to 6 months max"
la var months_food_insec2 "Food insecurity over last 12 months"
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_food_insecurity.dta", replace














*******************************
*Soil Quality
*******************************
*starting with planting
//ALT IMPORTANT NOTE: As of w5, the implied area conversions for farmer estimated units (including hectares) are markedly different from previous waves. I recommend excluding plots that do not have GPS measured areas from any area-based productivity estimates.
use "${Nigeria_GHS_W5_raw_data}/sect11a1_plantingw5.dta", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using "${Nigeria_GHS_W5_raw_data}/sect11b1_plantingw5.dta", nogen
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W5_raw_data}/secta1_harvestw5.dta", gen(plot_merge)
ren s11aq3_number area_size
ren s11aq3_unit area_unit
ren sa1q1c area_size2 //GPS measurement, no units in file
//ren sa1q9b area_unit2 //Not in file
ren s11mq3 area_meas_sqm
//ren sa1q9c area_meas_sqm2
gen cultivate = sa1q1a ==1 

gen field_size= area_size if area_unit==6
replace field_size = area_size*0.0667 if area_unit==4									//reported in plots
replace field_size = area_size*0.404686 if area_unit==5		    						//reported in acres
replace field_size = area_size*0.0001 if area_unit==7									//reported in square meters
replace field_size = area_size*0.09290304 if area_unit==8
replace field_size = area_size*0.04645152 if area_unit==9
replace field_size = area_size*0.721159848 if area_unit==10

replace field_size = area_size*0.00012 if area_unit==1 & zone==1						//reported in heaps
replace field_size = area_size*0.00016 if area_unit==1 & zone==2
replace field_size = area_size*0.00011 if area_unit==1 & zone==3
replace field_size = area_size*0.00019 if area_unit==1 & zone==4
replace field_size = area_size*0.00021 if area_unit==1 & zone==5
replace field_size = area_size*0.00012 if area_unit==1 & zone==6

replace field_size = area_size*0.0027 if area_unit==2 & zone==1							//reported in ridges
replace field_size = area_size*0.004 if area_unit==2 & zone==2
replace field_size = area_size*0.00494 if area_unit==2 & zone==3
replace field_size = area_size*0.0023 if area_unit==2 & zone==4
replace field_size = area_size*0.0023 if area_unit==2 & zone==5
replace field_size = area_size*0.00001 if area_unit==2 & zone==6

replace field_size = area_size*0.00006 if area_unit==3 & zone==1						//reported in stands
replace field_size = area_size*0.00016 if area_unit==3 & zone==2
replace field_size = area_size*0.00004 if area_unit==3 & zone==3
replace field_size = area_size*0.00004 if area_unit==3 & zone==4
replace field_size = area_size*0.00013 if area_unit==3 & zone==5
replace field_size = area_size*0.00041 if area_unit==3 & zone==6

/*ALT 02.23.23*/ gen area_est = field_size
*replacing farmer reported with GPS if available
replace field_size =  area_meas_sqm*0.0001 if area_meas_sqm!=.
        				
gen gps_meas = (area_meas_sqm!=. & area_meas_sqm !=0)
la var gps_meas "Plot was measured with GPS, 1=Yes"
keep zone state lga sector ea hhid plotid field_size

merge 1:1 hhid plotid using "${Nigeria_GHS_W5_raw_data}\sect11b1_plantingw5.dta"
*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1

ren s11b1q62 soil_quality
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
gen soil_qty_rev2 = soil_quality

replace soil_qty_rev2 = soil_qty_rev if dup>0

list hhid plotid  field_size soil_quality soil_qty_rev soil_qty_rev2 dup if dup>0



egen med_soil_ea = median(soil_qty_rev2), by (ea)
egen med_soil_lga = median(soil_qty_rev2), by (lga)
egen med_soil_state = median(soil_qty_rev2), by (state)
egen med_soil_zone = median(soil_qty_rev2), by (zone)

replace soil_qty_rev2= med_soil_ea if soil_qty_rev2==.
tab soil_qty_rev2, missing
replace soil_qty_rev2= med_soil_lga if soil_qty_rev2==.
tab soil_qty_rev2, missing
replace soil_qty_rev2= med_soil_state if soil_qty_rev2==.
tab soil_qty_rev2, missing
replace soil_qty_rev2= med_soil_zone if soil_qty_rev2==.
tab soil_qty_rev2, missing

replace soil_qty_rev2= 2 if soil_qty_rev2==1.5
tab soil_qty_rev2, missing

la define soil 1 "Good" 2 "fair" 3 "poor"

*la value soil soil_qty_rev2

collapse (mean) soil_qty_rev2 , by (hhid)
la var soil_qty_rev2 "1=Good 2= fair 3=Bad "
save "${Nigeria_GHS_W5_created_data}\soil_quality_2023.dta", replace








*******************************
*Soil Quality Plot
*******************************
*starting with planting
//ALT IMPORTANT NOTE: As of w5, the implied area conversions for farmer estimated units (including hectares) are markedly different from previous waves. I recommend excluding plots that do not have GPS measured areas from any area-based productivity estimates.
use "${Nigeria_GHS_W5_raw_data}/sect11a1_plantingw5.dta", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using "${Nigeria_GHS_W5_raw_data}/sect11b1_plantingw5.dta", nogen
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W5_raw_data}/secta1_harvestw5.dta", gen(plot_merge)
ren s11aq3_number area_size
ren s11aq3_unit area_unit
ren sa1q1c area_size2 //GPS measurement, no units in file
//ren sa1q9b area_unit2 //Not in file
ren s11mq3 area_meas_sqm
//ren sa1q9c area_meas_sqm2
gen cultivate = sa1q1a ==1 

gen field_size= area_size if area_unit==6
replace field_size = area_size*0.0667 if area_unit==4									//reported in plots
replace field_size = area_size*0.404686 if area_unit==5		    						//reported in acres
replace field_size = area_size*0.0001 if area_unit==7									//reported in square meters
replace field_size = area_size*0.09290304 if area_unit==8
replace field_size = area_size*0.04645152 if area_unit==9
replace field_size = area_size*0.721159848 if area_unit==10

replace field_size = area_size*0.00012 if area_unit==1 & zone==1						//reported in heaps
replace field_size = area_size*0.00016 if area_unit==1 & zone==2
replace field_size = area_size*0.00011 if area_unit==1 & zone==3
replace field_size = area_size*0.00019 if area_unit==1 & zone==4
replace field_size = area_size*0.00021 if area_unit==1 & zone==5
replace field_size = area_size*0.00012 if area_unit==1 & zone==6

replace field_size = area_size*0.0027 if area_unit==2 & zone==1							//reported in ridges
replace field_size = area_size*0.004 if area_unit==2 & zone==2
replace field_size = area_size*0.00494 if area_unit==2 & zone==3
replace field_size = area_size*0.0023 if area_unit==2 & zone==4
replace field_size = area_size*0.0023 if area_unit==2 & zone==5
replace field_size = area_size*0.00001 if area_unit==2 & zone==6

replace field_size = area_size*0.00006 if area_unit==3 & zone==1						//reported in stands
replace field_size = area_size*0.00016 if area_unit==3 & zone==2
replace field_size = area_size*0.00004 if area_unit==3 & zone==3
replace field_size = area_size*0.00004 if area_unit==3 & zone==4
replace field_size = area_size*0.00013 if area_unit==3 & zone==5
replace field_size = area_size*0.00041 if area_unit==3 & zone==6

/*ALT 02.23.23*/ gen area_est = field_size
*replacing farmer reported with GPS if available
replace field_size =  area_meas_sqm*0.0001 if area_meas_sqm!=.
        				
gen gps_meas = (area_meas_sqm!=. & area_meas_sqm !=0)
la var gps_meas "Plot was measured with GPS, 1=Yes"
keep zone state lga sector ea hhid plotid field_size

merge 1:1 hhid plotid using "${Nigeria_GHS_W5_raw_data}\sect11b1_plantingw5.dta"
*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1

ren s11b1q62 soil_quality
tab soil_quality , missing
order field_size soil_quality hhid 
sort hhid

tab field_size, missing
tab soil_quality if field_size!=., missing

gen good = (soil_quality==1)
gen fair = (soil_quality==2)
gen poor = (soil_quality==3)


gen irrigation = (s11b1q56==1)
gen tractors = (s11b1q69==1)
gen flat_slope = (s11b1q63==1)
gen steep_slope = (s11b1q63==4)
gen slope_slope = (s11b1q63==2 | s11b1q63==3 )

ren plotid plot_id
collapse (max) good fair poor irrigation tractors flat_slope steep_slope slope_slope , by (hhid plot_id)
tab good, missing
tab fair, missing
tab poor, missing
save "${Nigeria_GHS_W5_created_data}\soil_quality_2023_plot.dta", replace








********************************************************************************
*crop unit conversion factors
********************************************************************************
/*ALT: Theoretically this should be unnecessary because conversion factors are now
included in their respective files. However, in practice there is a lot of missing info
and so we need to construct a central conversion factors file like the one provided in W3.
Issues this section is used to address:
	*Known but missing conversion factors
	*Calculating conversion factors for seed (see seed section for why we need this)
	*Units that had conversion factors in previous waves that were not used in w5
	*Conversion factors for units that weren't included but which can be inferred from the literature
*/
use "${Nigeria_GHS_W5_raw_data}/secta3i_harvestw5.dta", clear
append using "${Nigeria_GHS_W5_raw_data}/secta3ii_harvestw5.dta"
append using "${Nigeria_GHS_W5_raw_data}/secta3iii_harvestw5.dta"
replace cropcode=1120 if inrange(cropcode, 1121,1124)
label define CROPCODE 1120 "1120. YAM" , add //all yam cfs are the same
//recode cropcode (2170=2030) //Bananas=plaintains ALT 06.23.2020: Bad idea, because the conversion factors vary a bunch (har har)

ren sa3iq9b unit
ren sa3iq9c size
ren sa3iq9d condition
ren sa3iq9_conv conv_fact

replace unit=sa3iq15b if unit==.
replace size=sa3iq15c if size==.
replace condition=sa3iq15d if condition==.  //ALT 02.01.21 Typo; fixed //DYA.11.21.2020  I am not sure why this? sa3iiq1d is "What was the total harvest of [CROP] from all HH's plots? (Size)". Should be sa3iiq1b but this is used below
replace conv_fact=sa3iq15_conv if conv_fact==.

replace unit=sa3iiiq23b if unit==.
replace size=sa3iiiq23c if size==.
replace condition=sa3iiiq23d if condition==.
replace conv_fact=sa3iiiq23_conv if conv_fact==.

/*
replace unit=sa3iq6d2 if unit==.
replace size=sa3iq6d4 if size==.
//ALT 09.25.20: something weird is happening here
replace condition=sa3iq6d2a if condition==.
replace conv_fact=sa3iq6d_conv if conv_fact==.
//drop if sa3iq3==2 | sa3iq3==. //drop if no harvest //ALT 02.03.21: I was mistakenly dropping things needed for conversion factors here
drop if unit==.  //DYA.11.21.2020 So all the missing units are instances where there was no harvest during the season
//At this point we have all cropcode/size/unit/condition combinations that show up in the survey.
//Ordinarily, we'd collapse by state/zone/country to get median values most representative of a hh's area.
//However, here the values are the same across geographies so we don't need to do it - we just need to add in our imputed values.
*/
//ALT 06.23.2020: Code added for bananas/plantains, oil palm, other missing conversions. Turns out conversions are missing from the tree crop harvest in the next section, and so tree crops are being underreported in the final data.
replace conv_fact=1 if unit==1 //kg
replace conv_fact=0.001 if unit==2 //g

replace conv_fact=25 if size==10 & conv_fact==. //25kg bag
replace conv_fact=50 if size==11 & conv_fact==. //50kg bag
replace conv_fact=100 if size==12 & conv_fact==. //100kg bag

replace conv_fact = 21.3 if unit==160 & cropcode==2230 & conv_fact==. //Conversion factors for sugar cane, because they are not in the files or basic info doc
replace conv_fact = 2.13 if unit==80 & cropcode==2230 & conv_fact==.
replace conv_fact = 53.905 if unit==170 & cropcode==2230 & conv_fact==.
replace conv_fact = 1957.58 if unit==180 & conv_fact==. //Estimated weight for a pick-up 
//Banana/Plantain & oil palm conversions from W3
replace conv_fact=0.5 if unit==80 & size==0 & cropcode==2030 & conv_fact==.
replace conv_fact=0.6 if unit==80 & (size==1 | size==.) & cropcode==2030 & conv_fact==.
replace conv_fact=0.7 if unit==80 & size==2 & cropcode==2030 & conv_fact==.
replace conv_fact=0.445 if unit==100 & size==0 & cropcode==2030 & conv_fact==.
replace conv_fact=1.345 if unit==100 & (size==1 | size==.) & cropcode==2030 & conv_fact==.
replace conv_fact=2.12 if unit==100 & size==2 & cropcode==2030 & conv_fact==.
replace conv_fact=5.07 if unit==110 & size==0 & cropcode==2030 & conv_fact==.
replace conv_fact=7.14 if unit==110 & (size==1 | size==.) & cropcode==2030 & conv_fact==.
replace conv_fact=21.62 if unit==110 & size==2 & cropcode==2030 & conv_fact==.

replace conv_fact=0.135 if unit==80 & size==0 & cropcode==2170 & conv_fact==.
replace conv_fact=0.23 if unit==80 & (size==1 | size==.) & cropcode==2170 & conv_fact==.
replace conv_fact=0.34 if unit==80 & size==2 & cropcode==2170 & conv_fact==.
replace conv_fact=0.615 if unit==100 & size==0 & cropcode==2170 & conv_fact==.
replace conv_fact=1.06 if unit==100 & (size==1 | size==.) & cropcode==2170 & conv_fact==.
replace conv_fact=2.1 if unit==100 & size==2 & cropcode==2170 & conv_fact==.
replace conv_fact=3.51 if unit==110 & size==0 & cropcode==2170 & conv_fact==.
replace conv_fact=5.14 if unit==110 & (size==1 | size==.) & cropcode==2170 & conv_fact==.
replace conv_fact=7.965 if unit==110 & size==2 & cropcode==2170 & conv_fact==.

replace conv_fact=5.235 if unit==140 & size==0 & cropcode==2170 & conv_fact==.
replace conv_fact=13.285 if unit==140 & (size==1 | size==.) & cropcode==2170 & conv_fact==.
replace conv_fact=15.972 if unit==140 & size==2 & cropcode==2170 & conv_fact==.
replace conv_fact=3.001 if unit==150 & size==0 & cropcode==2170 & conv_fact==.
replace conv_fact=6.959 if unit==150 & (size==1 | size==.) & cropcode==2170 & conv_fact==.
replace conv_fact=16.11 if unit==150 & size==2 & cropcode==2170 & conv_fact==.

//Oil palm bunch data. Lots of papers report weights, but none report variances, so asessing small/med/large is difficult.
//The lit cites bunch weights anywhere from 15-40 kg, but Nigeria-specific research exclusively cites lower values. Here,
//I use the range from Genotype and genotype by environment (GGE) biplot analysis of fresh fruit bunch yield and yield components of oil palm (Elaeis guineensis Jacq.).
//by Okoye et al (2008) to approximate the field variation.

replace conv_fact=9.5 if unit==100 & size==0 & cropcode==3180
replace conv_fact=14.5 if unit==100 & size==2 & cropcode==3180
replace conv_fact=12 if unit==100 & (size==1 | size==.) & cropcode==3180
replace conv_fact = 20*0.9/0.26 if cropcode==3180 & unit==190 & size==5
replace conv_fact = 25*0.9/0.26 if cropcode==3180 & size==6  //Crude estimate of raw fruit based on oil yield for jerry cans, some also flagged in liters/bunches, assuming this is oil.
replace conv_fact = 0.9/0.26 if cropcode==3180 & unit==3 & size==.


//borrowing conversion factors for beans/cowpeas if 

//Now one-size-fits-all estimates from WB and external sources to get stragglers 
//These from Local weights and measures in Nigeria: a handbook of conversion factors by Kormawa and Ogundapo
//paint rubber - 2.49 //LSMS says about 2.9
replace conv_fact=2.49 if unit==11 & conv_fact==.
replace conv_fact = 1.36 if (unit==20 | unit==30) & size==0 & conv_fact==. //Lower estimate given by Kormawa and Ogundapo
replace conv_fact = 1.5 if (unit==20 | unit==30) & (size==1 | size==.) & conv_fact==. //congo/mudu value from LSMS W1, assuming medium if left blank
replace conv_fact = 1.74 if (unit==20 | unit==30) & size==2 & conv_fact==. //Upper estimate by K&O
replace conv_fact = 2.72 if unit==50 & size==0 & conv_fact==. //1 tiya=2 mudu
replace conv_fact = 3 if unit==50 & (size==1 | size==.) & conv_fact==. //2x med mudu
replace conv_fact = 3.48 if unit==50 & size==2 & conv_fact==. //2x lg mudu
replace conv_fact = 0.35 if unit==40 & size==0  & conv_fact==. //Small derica from W1
replace conv_fact = 0.525 if unit==40 & (size==1 | size==.) & conv_fact==. //central value
replace conv_fact = 0.7 if unit==40 & size==2 & conv_fact==. & conv_fact==. //large derica from W1
replace conv_fact = 15 if unit==140 & size==0 & conv_fact==. //Small basket from W1
replace conv_fact = 30 if unit==140 & (size==1 | size==.) & conv_fact==. //Med basket W1
replace conv_fact = 50 if unit==140 & size==2 & conv_fact==. //Lg basket W1
replace conv_fact = 85 if unit==170 & size==. & conv_fact==. //Med wheelbarrow w1 

drop if conv_fact==.

collapse (median) conv_fact, by(unit size cropcode condition)
ren conv_fact conv_fact_median
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_cf.dta", replace










********************************************************************************
* PLOT AREAS *
********************************************************************************
*starting with planting
//ALT IMPORTANT NOTE: As of w5, the implied area conversions for farmer estimated units (including hectares) are markedly different from previous waves. I recommend excluding plots that do not have GPS measured areas from any area-based productivity estimates.
use "${Nigeria_GHS_W5_raw_data}/sect11a1_plantingw5.dta", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using "${Nigeria_GHS_W5_raw_data}/sect11b1_plantingw5.dta", nogen
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W5_raw_data}/secta1_harvestw5.dta", gen(plot_merge)
ren s11aq3_number area_size
ren s11aq3_unit area_unit
ren sa1q1c area_size2 //GPS measurement, no units in file
//ren sa1q9b area_unit2 //Not in file
ren s11mq3 area_meas_sqm
//ren sa1q9c area_meas_sqm2
gen cultivate = sa1q1a ==1 

gen field_size= area_size if area_unit==6
replace field_size = area_size*0.0667 if area_unit==4									//reported in plots
replace field_size = area_size*0.404686 if area_unit==5		    						//reported in acres
replace field_size = area_size*0.0001 if area_unit==7									//reported in square meters
replace field_size = area_size*0.09290304 if area_unit==8
replace field_size = area_size*0.04645152 if area_unit==9
replace field_size = area_size*0.721159848 if area_unit==10

replace field_size = area_size*0.00012 if area_unit==1 & zone==1						//reported in heaps
replace field_size = area_size*0.00016 if area_unit==1 & zone==2
replace field_size = area_size*0.00011 if area_unit==1 & zone==3
replace field_size = area_size*0.00019 if area_unit==1 & zone==4
replace field_size = area_size*0.00021 if area_unit==1 & zone==5
replace field_size = area_size*0.00012 if area_unit==1 & zone==6

replace field_size = area_size*0.0027 if area_unit==2 & zone==1							//reported in ridges
replace field_size = area_size*0.004 if area_unit==2 & zone==2
replace field_size = area_size*0.00494 if area_unit==2 & zone==3
replace field_size = area_size*0.0023 if area_unit==2 & zone==4
replace field_size = area_size*0.0023 if area_unit==2 & zone==5
replace field_size = area_size*0.00001 if area_unit==2 & zone==6

replace field_size = area_size*0.00006 if area_unit==3 & zone==1						//reported in stands
replace field_size = area_size*0.00016 if area_unit==3 & zone==2
replace field_size = area_size*0.00004 if area_unit==3 & zone==3
replace field_size = area_size*0.00004 if area_unit==3 & zone==4
replace field_size = area_size*0.00013 if area_unit==3 & zone==5
replace field_size = area_size*0.00041 if area_unit==3 & zone==6

/*ALT 02.23.23*/ gen area_est = field_size
*replacing farmer reported with GPS if available
replace field_size =  area_meas_sqm*0.0001 if area_meas_sqm!=.
        				
gen gps_meas = (area_meas_sqm!=. & area_meas_sqm !=0)
la var gps_meas "Plot was measured with GPS, 1=Yes"
ren plotid plot_id
replace field_size = 22 if field_size >= 22
ren s11aq5a indiv1
ren s11aq5b indiv2
ren s11aq5c indiv3
ren s11aq5d indiv4

replace indiv1 = sa1q11_1 if indiv1==. //Post-Harvest (only reported for "new" plot)
replace indiv2 = sa1q11_2 if indiv2==.
replace indiv3 = sa1q11_3 if indiv3==. //The ph questionnaire goes up to six for ph but we'll stick to the first four for consistency with the pp questionnaire 
replace indiv4 = sa1q11_4 if indiv4==.
replace indiv1 = s11b1q7_1 if indiv1==. & indiv2==. & indiv3==. & indiv4==. //plot owner if dm is empty


keep hhid plot_id field_size indiv* cultivate
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_plot_areas.dta", replace





***************************
	*Crop Values
	***************************
	//Nonstandard unit values
use "${Nigeria_GHS_W5_raw_data}/secta3ii_harvestw5.dta", clear
	//Fstat highly insignificant for yam on price, so we'll lump here.
	replace cropcode=1120 if inrange(cropcode, 1121,1124)
	label define CROPCODE 1120 "1120. YAM", add
	keep if sa3iiq4==1
	ren sa3iiq6 qty
	ren sa3iiq3d condition
	ren sa3iiq3b unit
	ren sa3iiq3c size
	ren sa3iiq7 value
	merge m:1 hhid using "${Nigeria_GHS_W5_created_data}/hhids.dta", nogen keepusing(weight) keep(3)
	//ren cropcode crop_code
	gen price_unit = value/qty
	gen obs=price_unit!=.
	keep if obs==1
	foreach i in zone state lga ea hhid {
		preserve
		bys `i' cropcode unit size condition : egen obs_`i'_price = sum(obs)
		collapse (median) price_unit_`i'=price_unit [aw=weight], by (`i' unit size condition cropcode obs_`i'_price)
		tempfile price_unit_`i'_median
		save `price_unit_`i'_median'
		restore
	}
	bys cropcode unit size condition : egen obs_country_price = sum(obs)
	collapse (median) price_unit_country = price_unit [aw=weight], by(cropcode unit size condition obs_country_price)
	
	save "${Nigeria_GHS_W5_created_data}/price_unit_country_median.dta", replace

	//Because we have several qualifiers now (size and condition), using kg as an alternative for pricing. Results from experimentation suggests that the kg method is less accurate than using original units, so original units should be preferred.
	
use "${Nigeria_GHS_W5_raw_data}/secta3ii_harvestw5.dta", clear
	keep if sa3iiq4==1
	replace cropcode=1120 if inrange(cropcode, 1121,1124)
	label define CROPCODE 1120 "1120. YAM", add
	ren sa3iiq6 qty
	ren sa3iiq3d condition
	ren sa3iiq3b unit
	ren sa3iiq3c size
	ren sa3iiq7 value
	merge m:1 hhid using "${Nigeria_GHS_W5_created_data}/hhids.dta", nogen keepusing(weight) keep(1 3)
	merge m:1 cropcode unit size condition using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_cf.dta", nogen keep(1 3)
	//ren cropcode crop_code
	gen qty_kg = qty*conv_fact 
	drop if qty_kg==. //34 dropped; largely basin and bowl.
	gen price_kg = value/qty_kg
	gen obs=price_kg !=.
	keep if obs == 1
	foreach i in zone state lga ea hhid {
		preserve
		bys `i' cropcode : egen obs_`i'_pkg = sum(obs)
		collapse (median) price_kg_`i'=price_kg [aw=weight], by (`i' cropcode obs_`i'_pkg)
		tempfile price_kg_`i'_median
		save `price_kg_`i'_median'
		restore
	}
	bys cropcode : egen obs_country_pkg = sum(obs)
	collapse (median) price_kg_country = price_kg [aw=weight], by(cropcode obs_country_pkg)
	save "${Nigeria_GHS_W5_created_data}/price_kg_country_median.dta" , replace







***************************
	*Plot variables
	***************************
use "${Nigeria_GHS_W5_raw_data}/sect11f_plantingw5.dta", clear
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W5_raw_data}/secta3i_harvestw5.dta", nogen
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W5_raw_data}/secta3iii_harvestw5.dta", nogen
	gen use_imprv_seed=s11fq7==1
	replace use_imprv_seed = s11fq18==1 if s11fq7==.
	gen crop_code_long = cropcode
	//ren cropcode crop_code_a3i 
	ren plotid plot_id
	ren s11fq15 number_trees_planted
	//replace crop_code_11f=crop_code_a3i if crop_code_11f==.
	//replace crop_code_a3i = crop_code_11f if crop_code_a3i==.
	//gen cropcode =crop_code_11f //Generic level
	//replace cropcode = crop_code_11f if cropcode==.
	drop if strpos(sa3iq4_os, "WRONGLY") | strpos(sa3iq4_os, "MISTAKEN") | strpos(sa3iq4_os, "DIDN'T") | strpos(sa3iq4_os, "did not") | strpos(sa3iq4_os, "DID NOT") //Reported as mistaken entries in sa3iq4_os
	recode cropcode (2170=2030) (2142 = 2141) (1121 1122 1123=1120) //Only things that carry over from W3 are bananas/plantains, yams, and peppers. The generic pepper category 2040 in W3 is missing from this wave. //Okay to lump yams for price and unit conversions, not for other things. 
	//replace cropcode = 4010 if strpos(sa3iq4_os, "FEED") | regexm(sa3iq4_os, "CONSUMP*TION") | regexm(sa3iq4_os, "ONLY.+LEAVES") //no one reported fodder in this question for w5.
	label def Sec11f_crops__id 1120 "1120. YAM" 4010 "4010. FODDER", modify
	la values cropcode Sec11f_crops__id
	merge m:1 hhid plot_id using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_plot_areas.dta", nogen keep(3) //ALT 05.03.23
	gen percent_field = s11fq3/100
	replace percent_field = s11fq14/100 if percent_field==. 
	recode percent_field field_size (0=.)

	//for tree crops not part of an orchard, the area planted is not recorded; this divides the missing area by the number of tree crops on the plot 
	bys hhid plot_id : egen tot_pct_planted = sum(percent_field)
	gen miss_pct = percent_field==. 
	bys hhid plot_id : egen tot_miss = sum(miss_pct)
	gen underplant_pct = 1-tot_pct_planted 
	replace percent_field = underplant_pct/tot_miss if miss_pct & underplant_pct > 0 //175/241 fixed, remainder are overplanted. 
	replace percent_field=percent_field/tot_pct_planted if tot_pct_planted > 1
	gen ha_planted = percent_field*field_size
	
	gen pct_harvest=1 if sa3iq6 ==2 | sa3iiiq17==1 //Was area planted less than area harvested? 2=No / In the last 12 months, has your household harvested any <Tree Crop>? They don't ask for area harvested, so I assume that the whole area is harvested (not true for some crops)
	replace pct_harvest = sa3iq8/100 if sa3iq8!=. //1075 obs
	replace pct_harvest = 0 if pct_harvest==. & sa3iq4_1 <= 18  
	replace pct_harvest = . if pct_harvest==0 & sa3iq4_1 > 18 & sa3iq4_1 < 96
	gen ha_harvest=pct_harvest*ha_planted
	//replace pct_harvest = 1 if cropcode==4010 //Assuming fodder crops were fully "harvested"
	preserve
		gen obs=1
		//replace obs=0 if inrange(sa3iq3,1,5) & sa3iq3==1// Question changed to sa3iq4_1/2, no entries for either. Only 1 hh reports harvesting 0% of the plot.
		collapse (sum) obs, by(hhid plot_id cropcode)
		replace obs = 1 if obs > 1
		collapse (sum) crops_plot=obs, by(hhid plot_id)
		save "${Nigeria_GHS_W5_created_data}/ncrops.dta", replace
	restore //14 plots have >1 crop but list monocropping; meanwhile 289 list intercropping or mixed cropping but only report one crop
	merge m:1 hhid plot_id using "${Nigeria_GHS_W5_created_data}/ncrops.dta", nogen
	
	/*
	gen lost_crop=inrange(sa3iq3,1,5) & s11fq2==1
	bys hhid plot_id : egen max_lost = max(lost_crop)
	gen replanted = (max_lost==1 & crops_plot>0)
	drop if replanted==1 & lost_crop==1 //Crop expenses should count toward the crop that was kept, probably.
	*/
	//bys hhid plot_id : egen crops_avg = mean(cropcode) //Checks for different versions of the same crop in the same plot
	gen purestand = crops_plot==1 //This includes replanted crops 
	
	gen perm_crop=(s11fq2==2)
	replace perm_crop = 1 if cropcode==1020 //I don't see any indication that cassava is grown as a seasonal crop in Nigeria
	bys hhid plot_id : egen permax = max(perm_crop)
	
	//bys hhid plot_id s11fq3a s11fq3b : gen plant_date_unique=_n
	gen planting_year = s11fq11_year
	gen planting_month = s11fq11_month
	gen harvest_month_begin = sa3iq5a
	gen harvest_year_begin = s11fq20b
	replace harvest_year_begin = planting_year if sa3iq3==1 & harvest_year_begin==.
	replace harvest_year_begin = harvest_year_begin+1 if harvest_year_begin==planting_year & harvest_month_begin <= planting_month
	gen harvest_year_end = s11fq20d
	replace harvest_year_end = harvest_year_begin if harvest_year_end==.
	gen harvest_month_end = s11fq20c
	replace harvest_month_end =harvest_month_begin if harvest_month_end==.
	replace harvest_year_end = harvest_year_begin if harvest_year_end < harvest_year_begin
	replace harvest_year_end = harvest_year_end+1 if harvest_year_end == planting_year & harvest_month_end <= planting_month
	
    ren sa3iq9b unit
	replace unit = s11fq24c if unit==.
	replace unit = s11fq23c if unit==. & s11fq20b==2018 
	ren sa3iq9c size
	replace size = sa3iiiq23c if size==.
	replace size = s11fq23d if size==. & s11fq20b==2018
	ren sa3iq9d condition
	replace condition = sa3iiiq23b if condition==.
	replace condition = s11fq23a if condition==. & s11fq20b==2018
	ren sa3iq9a quantity_harvested
	replace quantity_harvested = sa3iiiq23a if quantity_harvested==.
	*replace quantity_harvested = s11fq23a if quantity_harvested==. & s11fq20b==2018
	*merging in conversion factors
	merge m:1 cropcode unit size condition using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_cf.dta", keep(1 3) nogen 
	replace conv_fact=1 if conv_fact==. & unit==1
	gen quant_harv_kg = quantity_harvested * sa3iq9_conv
	replace quant_harv_kg = quantity_harvested * sa3iq15_conv if quant_harv_kg == .
	replace quant_harv_kg = quantity_harvested * sa3iiiq23_conv if quant_harv_kg == .
	replace quant_harv_kg = quantity_harvested * conv_fact if quant_harv_kg == .
	replace quant_harv_kg = . if harvest_year_end < 2023 //Tracking only the most recent production period. 
	replace ha_harvest = . if harvest_year_end < 2023
	//gen quant_harv_kg= quantity_harvested*conv_fact
	ren sa3iq10 val_harvest_est
	replace val_harvest_est = sa3iiiq24 if val_harvest_est==.
	//ALT 09.28.22: I'm going to keep the grower-estimated valuation in here even though it's likely inaccurate for comparison purposes.
	gen val_unit_est = val_harvest_est/quantity_harvested
	gen val_kg_est = val_harvest_est/quant_harv_kg
	merge m:1 hhid using "${Nigeria_GHS_W5_created_data}/hhids.dta", nogen keep(1 3)
	gen plotweight = ha_planted*weight
	//IMPLAUSIBLE ENTRIES - at least 100x the typical yield
	gen obs=quantity_harvested>0 & quantity_harvested!=.

foreach i in zone state lga ea hhid {
	merge m:1 `i' unit size condition cropcode using `price_unit_`i'_median', nogen keep(1 3)
	merge m:1 `i' cropcode using `price_kg_`i'_median', nogen keep(1 3)
}
merge m:1 unit size condition cropcode using "${Nigeria_GHS_W5_created_data}/price_unit_country_median.dta", nogen keep(1 3)
*merge m:1 unit size condition cropcode using `val_unit_country_median', nogen keep(1 3)
merge m:1 cropcode using "${Nigeria_GHS_W5_created_data}/price_kg_country_median.dta", nogen keep(1 3)
*merge m:1 cropcode using `val_kg_country_median', nogen keep(1 3)

//We're going to prefer observed prices first
gen price_unit = . 
gen price_kg = .
recode obs_* (.=0)
foreach i in country zone state lga ea {
	replace price_unit = price_unit_`i' if obs_`i'_price>9 & price_unit_`i'!=.
	replace price_kg = price_kg_`i' if obs_`i'_pkg>9 & price_kg_`i'!=. 
}
	ren price_unit_hhid price_unit_hh 
	ren price_kg_hhid price_kg_hh 
	
	gen value_harvest = price_unit * quantity_harvested	 
	replace value_harvest = price_kg * quant_harv_kg if value_harvest == .
	replace value_harvest = val_harvest_est if value_harvest == .
	
	gen value_harvest_hh=price_unit_hh*quantity_harvested 
	replace value_harvest=price_kg_hh * quant_harv_kg if value_harvest_hh==.
	replace value_harvest_hh = value_harvest if value_harvest_hh==.

	//Replacing conversions for unknown units
	replace val_unit_est = value_harvest/quantity_harvested if val_unit_est==.
	replace val_kg_est = value_harvest/quant_harv_kg if val_kg_est == .

preserve
//ALT note to double check and see if the changes to valuation mess this up.
	replace val_kg = val_kg_est if val_kg==.
	collapse (mean) val_kg=price_kg conv_fact, by(hhid cropcode)
	save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hh_crop_prices_kg.dta", replace //Backup for s-e income.
restore
preserve
	//ALT 02.10.22: NOTE: This should be changed to ensure we get all household values rather than just ones with recorded harvests (although I imagine the number of households that paid in a crop they did not harvest is small)
	replace val_unit = val_unit_est if val_unit==.
	collapse (mean) val_unit=price_unit, by (hhid cropcode unit size condition)
	drop if unit == .
	ren val_unit hh_price_mean
	lab var hh_price_mean "Average price reported for this crop-unit in the household"
	save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hh_crop_prices_for_wages.dta", replace //This gets used for self-employment income
restore
	//still-to-harvest value
	gen same_unit=unit==sa3iq15b & size==sa3iq15c & condition==sa3iq15d & unit!=.
	replace price_unit = value_harvest/quantity_harvested if same_unit==1 & price_unit==.
	//ALT 05.12.21: I feel like we should include the expected harvest.
	//Addendum 10.14: Unfortunately we can only reliably do this for annual crops because the question for tree crops was asked in the planting survey; estimates are probably not reliable.
	//Addendum to addendum 9.28.22: The plant survey also asks about temporary crops, not just tree crops. This was causing estimated harvests to be far too high.
	//Addendum to addendum 9.30.24: Adding an additional criterion to only include harvests that had been started, some long-haul crops like cassava and yam were probably not intended for harvest this year.
	replace sa3iq15a = . if sa3iq15a > 19000 //Retaining this threshold from W4; two plots are affected, one 
	drop unit size condition quantity_harvested
	ren sa3iq15b unit
	ren sa3iq15c size
	ren sa3iq15d condition
	ren sa3iq15a quantity_harvested
	//replace quantity_harvested = . if hhid == 220016 & plot_id==2 & cropcode==1121 //One obs of 2000 pickups on a quarter of a hectare. Planting estimate was 1 pickup; likely a unit typo. //ALT: Excluded by the 9.30.24 update
	gen quant_harv_kg2 = quantity_harvested * sa3iq9_conv 
	replace quant_harv_kg2 = quantity_harvested * conv_fact if same_unit == 1
	drop conv_fact
	merge m:1 cropcode unit size condition using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_cf.dta", nogen keep(1 3)
	replace quant_harv_kg2= quantity_harvested*conv_fact if quant_harv_kg2 == .
	gen val_harv2 = 0
	gen val_harv2_hh=0
	recode quant_harv_kg2 quantity_harvested value_harvest (.=0) //ALT 02.10.22: This is causing people with "still to harvest" values getting missing where they should have something.
	replace val_harv2=quantity_harvested*price_kg if unit==1 
	replace val_harv2=quantity_harvested*price_unit if val_harv2==0 & same_unit==1  //Use household price for consistency. (see line 959)

//The few that don't have the same units are in somewhat suspicious units. (I'm pretty sure you can't measure bananas in liters)
	replace quant_harv_kg = quant_harv_kg+quant_harv_kg2 if sa3iq3==1   //Counting only crops that have begun harvest; only 44 obs 
	replace quant_harv_kg = quant_harv_kg2 if sa3iq3==1 & quant_harv_kg==. //this annoying two-step here to deal with how stata processes missing values and the desire to avoid introducing spurious 0s.
	replace value_harvest = value_harvest+val_harv2 if sa3iq3==1 
	replace value_harvest = val_harv2 if sa3iq3==1 & value_harvest==.
	replace ha_harvest = ha_planted if sa3iq3==1 & !inlist(quant_harv_kg2,0,.) & !inlist(sa3iq7_1, 1, .)
	gen lost_drought = sa3iq4_1==6 | sa3iq4_2==6 | s11fq22==1 | sa3iq7_1==6 | sa3iq7_2==6 
	gen lost_flood = sa3iq4_1==5 | sa3iq4_2==5 | s11fq22==2 | sa3iq7_1==5 | sa3iq7_2==5
	gen lost_pest = sa3iq4_1==12 | sa3iq4_2==12 | s11fq22==5 | sa3iq7_1==12 | sa3iq7_2==12
	replace cropcode = 1124 if crop_code_long==1124 //Removing three-leaved yams from yams. 
	//ren cropcode crop_code 
	replace ha_harvest = . if ha_harvest==0 & (quant_harv_kg !=. & quant_harv_kg !=0)
	gen no_harvest = ha_harvest==. 
	collapse (sum) quant_harv_kg value_harvest* /*val_harvest_est*/ ha_planted ha_harvest number_trees_planted percent_field (max) no_harvest lost_pest lost_flood lost_drought use_imprv_seed, by(zone state lga sector ea hhid plot_id cropcode purestand field_size)
	recode ha_planted (0=.)
replace ha_harvest=. if (ha_harvest==0 & no_harvest==1) | (ha_harvest==0 & quant_harv_kg>0 & quant_harv_kg!=.)
   replace quant_harv_kg = . if quant_harv_kg==0 & no_harvest==1
   drop no_harvest
	bys hhid plot_id : gen count_crops = _N
	replace purestand = 0 if count_crops > 1 & purestand==1 //Three plots no longer considered monocropped after the disaggregation.
	bys hhid plot_id : egen percent_area = sum(percent_field)
	bys hhid plot_id : gen percent_inputs = percent_field/percent_area
	drop percent_area //Assumes that inputs are +/- distributed by the area planted. Probably not true for mixed tree/field crops, but reasonable for plots that are all field crops
	//Labor should be weighted by growing season length, though. 
	//Small gardens may distort yield by being undermeasured/under-reported given the quantities harvested. We exclude them from the yield analysis.
	gen ha_harv_yld = ha_harvest if ha_planted >=0.05
	gen ha_plan_yld = ha_planted if ha_planted >=0.05
	*merge m:1 hhid plot_id using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_plot_decision_makers.dta", nogen keep(1 3) keepusing(dm_gender)
	save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_all_plots.dta",replace



*********************************************** 
*Purchased Fertilizer
***********************************************

use "${Nigeria_GHS_W5_raw_data}/secta11c3_harvestw5.dta", clear  

******conversion to kg

gen input_kg = s11c3q4a*s11c3q4_conv if inputid >=2 & inputid <=4

*br s11c3q4a s11c3q4b s11c3q4_conv input_kg

***getting the qty for inorg fertilizer

gen inorg_fert = input_kg if inputid >=2 & inputid <=4


gen npk = input_kg if inputid ==2  & s11c3q7 == 6
gen urea = input_kg if inputid ==3  & s11c3q7 == 6
gen others = input_kg if inputid ==4  & s11c3q7 == 6

gen total_qty = input_kg if inputid >=2 & inputid <=4 & s11c3q7 == 6

gen npk_adj   = npk * 0.18
gen urea_adj  = urea * 0.46
egen n_kg     = rowtotal(npk_adj urea_adj)

gen p_kg = npk*0.12
gen k_kg = npk*0.11

gen cost_fert = s11c3q5 if inputid >=2 & inputid <=4
gen cost_fert_real = cost_fert if s11c3q7 == 6
*br s11c3q5 inputid cost_fert

gen tpricefert = cost_fert_real/total_qty
tab tpricefert

gen tpricefert_cens = tpricefert 
replace tpricefert_cens = 4000 if tpricefert_cens > 4000 & tpricefert_cens < .   //winzonrizing bottom 1% figures look too much beyond this
replace tpricefert_cens = 60 if tpricefert_cens < 60
tab tpricefert_cens, missing //winzonrizing top 1%


egen medianfert_pr_ea = median(tpricefert_cens), by (ea)
egen medianfert_pr_lga = median(tpricefert_cens), by (lga)
egen medianfert_pr_state = median(tpricefert_cens), by (state)
egen medianfert_pr_zone = median(tpricefert_cens), by (zone)



egen num_fert_pr_ea = count(tpricefert_cens), by (ea)
egen num_fert_pr_lga = count(tpricefert_cens), by (lga)
egen num_fert_pr_state = count(tpricefert_cens), by (state)
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



********Distance to institute of purchased fertilizer
gen distance = s11c3q8 if inputid >=2 & inputid <=4
tab distance
replace distance = . if distance== 0
tab distance

egen medianfert_dist_ea = median(distance), by (ea)
egen medianfert_dist_lga = median(distance), by (lga)
egen medianfert_dist_state = median(distance), by (state)
egen medianfert_dist_zone = median(distance), by (zone)
egen medianfert_dist_sector = median(distance), by (sector)


egen num_fert_dist_ea = count(distance), by (ea)
egen num_fert_dist_lga = count(distance), by (lga)
egen num_fert_dist_state = count(distance), by (state)
egen num_fert_dist_zone = count(distance), by (zone)
egen num_fert_dist_sector = count(distance), by (sector)


tab medianfert_dist_ea
tab medianfert_dist_lga
tab medianfert_dist_state
tab medianfert_dist_zone



tab num_fert_dist_ea
tab num_fert_dist_lga
tab num_fert_dist_state
tab num_fert_dist_zone

gen mrk_dist = distance

replace mrk_dist = medianfert_dist_ea if mrk_dist ==. & num_fert_dist_ea >= 20

tab mrk_dist,missing


replace mrk_dist = medianfert_dist_lga if mrk_dist ==. & num_fert_dist_lga >= 20

tab mrk_dist,missing



replace mrk_dist = medianfert_dist_state if mrk_dist ==. & num_fert_dist_state >= 20

tab mrk_dist,missing


replace mrk_dist = medianfert_dist_zone if mrk_dist ==. & num_fert_dist_zone >= 20

tab mrk_dist,missing
replace mrk_dist = medianfert_dist_sector if mrk_dist ==. & num_fert_dist_sector >= 20

tab mrk_dist,missing



collapse (sum) total_qty n_kg p_kg (max) mrk_dist tpricefert_cens_mrk, by( hhid)
 
replace  total_qty = 3000 if total_qty >= 3000
replace n_kg = 621 if n_kg >=621

tab total_qty
gen real_tpricefert_cens_mrk = tpricefert_cens_mrk /1

sum tpricefert_cens_mrk real_tpricefert_cens_mrk, detail



************winzonrizing fertilizer distance
foreach v of varlist  mrk_dist  {
	_pctile `v'  , p(1 99) //[aw=weight]
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 1%"
}

tab mrk_dist
tab mrk_dist_w, missing
sum mrk_dist mrk_dist_w, detail
la var mrk_dist_w "distance to the nearest market in km"


save "${Nigeria_GHS_W5_created_data}/fert_units.dta", replace









*********************************************** 
*Used Purchased Fertilizer plot variable
***********************************************

use "${Nigeria_GHS_W5_raw_data}/secta11c2_harvestw5.dta", clear

gen qtynpk_fert=s11c2q7a*s11c2q7a_conv 

gen qtyurea = s11c2q11a*s11c2q11a_conv
gen qtyorgfert = s11c2q16a*s11c2q16_conv //This looks wrong but it isn't
gen qtyother_fert=s11c2q9a*s11c2q9a_conv 

ren plotid plot_id 
replace qtyurea = 1000 if qtyurea >= 1000 & qtyurea < .
replace qtynpk_fert = 1000 if qtynpk_fert > 1000 & qtynpk_fert < .
replace qtyother_fert = 250 if qtyother_fert > 250 & qtynpk_fert < .

//We can estimate how many nutrient units were applied for most fertilizers; dry urea is 46% N and NPK can have several formulations; we go with a weighted average of 18-12-11 based on https://africafertilizer.org/#/en/vizualizations-by-topic/consumption-data/

egen inorg_fert_kg = rowtotal(qtynpk_fert qtyurea qtyother_fert)
gen nitrogen_npk = qtynpk_fert*0.18
gen nitrogen_urea = qtyurea*0.46

egen n_kg_plot = rowtotal(nitrogen_npk nitrogen_urea)







gen  herbicide = (s11c2q1 ==1)
gen  pesticide = (s11c2q3 ==1)
gen  org_fert = (s11c2q11 ==1)
gen  animal_tract = (s11c2q14 ==1)
gen  mechanization = (s11c2q20 ==1)

collapse (sum) inorg_fert_kg n_kg_plot (max) herbicide pesticide org_fert animal_tract mechanization, by( hhid plot_id)

save "${Nigeria_GHS_W5_created_data}/fert_used.dta", replace



***********************************
*Food Prices from Community
*********************************
use "${Nigeria_GHS_W5_raw_data}\sectc2_plantingw5.dta", clear
*rice is 13, maize is 16

*br if item_cd == 20
*br if item_cd ==20 & c2q2==1
tab c2q2b if item_cd==20
tab c2q3 if item_cd ==20
tab c2q3 if item_cd ==13





gen conversion =1
tab conversion, missing
gen food_size=1 //This makes it easy for me to copy-paste existing code rather than having to write a new block
replace conversion = food_size*2.696 if c2q2b == 11
replace conversion = food_size*0.001 if  c2q2b == 2
replace conversion = food_size*0.175 if  c2q2b == 12		
replace conversion = food_size*0.23 if  c2q2b == 13
replace conversion = food_size*1.5 if  c2q2b == 20 |c2q2b == 21  |c2q2b == 30  |c2q2b == 31 	
replace conversion = food_size*0.35 if  c2q2b == 40 
replace conversion = food_size*0.70 if  c2q2b == 41
replace conversion = food_size*3.00 if  c2q2b == 51  |c2q2b == 52 
replace conversion = food_size*0.718 if  c2q2b == 70	 |c2q2b == 71  |c2q2b == 72
replace conversion = food_size*1.615 if  c2q2b == 80  |c2q2b == 81  |c2q2b == 82
replace conversion = food_size*1.135 if   c2q2b == 90  |c2q2b == 91  |c2q2b == 92
				
tab conversion, missing	



gen maize_price= c2q3* conversion if item_cd==20
tab maize_price

sum maize_price, detail


tab maize_price,missing
sum maize_price,detail
tab maize_price

replace maize_price = 681 if maize_price >681 & maize_price<.  //bottom 5%
*replace maize_price = 50 if maize_price< 50       ////top 5%



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

sort zone state ea
collapse (max) maize_price_mr   median_pr_lga median_pr_state median_pr_zone median_pr_ea , by (zone state lga sector ea)
save "${Nigeria_GHS_W5_created_data}\food_prices.dta", replace


use "${Nigeria_GHS_W5_raw_data}\sect7b_plantingw5.dta", clear
merge m:1 zone state lga sector ea using "${Nigeria_GHS_W5_created_data}\food_prices.dta", keepusing (median_pr_ea median_pr_lga median_pr_state median_pr_zone maize_price_mr)
*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1

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

collapse zone (max) maize_price_mr, by(hhid)
gen rea_maize_price_mr = maize_price_mr 
gen real_maize_price_mr = rea_maize_price_mr
tab real_maize_price_mr
sum real_maize_price_mr, detail

sort hhid
save "${Nigeria_GHS_W5_created_data}\food_prices_2023.dta", replace
	



*****************************
*Household Assests
****************************


use "${Nigeria_GHS_W5_raw_data}\sect10_plantingw5.dta",clear 
*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1
sort hhid item_cd

*s5q1 qty of item
*s5q4 value of item

gen hhasset_value  = s10q6*s10q2
tab hhasset_value,missing
sum hhasset_value,detail

/*
replace hhasset_value = 1000000 if hhasset_value > 2000000 & hhasset_value <.
replace hhasset_value = 200 if hhasset_value <200
replace hhasset_value = 0 if hhasset_value ==.
*/
sum hhasset_value, detail



collapse (sum) hhasset_value, by (hhid)
*merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/weight.dta", gen(wgt)

*merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1 [aw=weight] 


foreach v of varlist  hhasset_value  {
	_pctile `v' , p(1 99) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 5%"
}


tab hhasset_value
tab hhasset_value_w, missing
sum hhasset_value hhasset_value_w, detail

gen rea_hhvalue = hhasset_value_w 
gen real_hhvalue= rea_hhvalue/1000
sum hhasset_value_w real_hhvalue, detail


keep  hhid real_hhvalue hhasset_value_w

la var real_hhvalue "total value of household asset"
save "${Nigeria_GHS_W5_created_data}\household_asset_2023.dta", replace






*********************************
*Demographics 
*********************************



use "${Nigeria_GHS_W5_raw_data}\sect1_plantingw5.dta",clear 


merge 1:1 hhid indiv using "${Nigeria_GHS_W5_raw_data}\sect2_harvestw5.dta" //, gen(household)

*merge m:1 zone state lga sector ea using "${Nigeria_GHS_W4_created_data}\market_distance.dta", keepusing (median_lga median_state median_zone mrk_dist1)

*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1
**************
*market distance
*************






*s1q2 sex
*s1q3 relationship with hhead (1= head)
*s1q6 age (in years)
sort hhid indiv 
 
gen num_mem  = 1


******** female head****

gen femhead  = 0
replace femhead = 1 if s1q2== 2 & s1q3==1
tab femhead,missing

********Age of HHead***********
ren s1q6 hh_age
gen hh_headage  = hh_age if s1q3==1

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
*s2aq6 attend school
*s2aq9 highest level of edu completed
*s1q3 relationship with hhead (1= head)

ren  s2q6 attend_sch 
tab attend_sch
replace attend_sch = 0 if attend_sch ==2
tab attend_sch, nolabel
*tab s1q4 if s2q7==.

replace s2q9= 0 if attend_sch==0
tab s2q9
tab s1q3 if _merge==1

tab s2q9 if s1q3==1
replace s2q9 = 16 if s2q9==. &  s1q3==1

*** Education Dummy Variable*****

 label list s2q9

gen pry_edu  = 1 if s2q9 >= 1 & s2q9 < 16 & s1q3==1
gen finish_pry = 1 if s2q9 >= 16 & s2q9 < 26 & s1q3==1
gen finish_sec  = 1 if s2q9 >= 26 & s2q9 & s1q3==1
replace finish_sec  =0 if s2q9==51 | s2q9==52 & s1q3==1

replace pry_edu =0 if pry_edu==. & s1q3==1
replace finish_pry  =0 if finish_pry==. & s1q3==1
replace finish_sec =0 if finish_sec==. & s1q3==1
tab pry_edu if s1q3==1 , missing
tab finish_pry if s1q3==1 , missing 
tab finish_sec if s1q3==1 , missing

collapse (sum) num_mem (max)  hh_headage femhead attend_sch  pry_edu finish_pry finish_sec, by (hhid)




keep hhid  num_mem femhead hh_headage attend_sch pry_edu finish_pry finish_sec

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

la var femhead  "=1 if head is female"
la var hh_headage "age of household head in years"
la var attend_sch"=1 if respondent attended school"
la var pry_edu  "=1 if household head attended pry school"
la var finish_pry "=1 if household head finished pry school"
la var finish_sec "=1 if household head finished sec school"
save "${Nigeria_GHS_W5_created_data}\demographics_2023.dta", replace

*/


********************************* 
*Labor Age 
*********************************
use "${Nigeria_GHS_W5_raw_data}\sect1_plantingw5.dta",clear 
*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1
ren s1q6 hh_age

gen worker = 1
replace worker = 0 if hh_age < 15 | hh_age > 65

tab worker,missing
sort hhid
collapse (sum) worker, by (hhid)
la var worker "number of members age 15 and older and less than 65"
sort hhid

save "${Nigeria_GHS_W5_created_data}\laborage_2023.dta", replace


/*
********************************* 
*Labor Age 
*********************************
use "${Nigeria_GHS_W5_raw_data}\sect1_plantingw5.dta",clear 
*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1
ren s1q6 hh_age

gen child = 1
replace child = 0 if hh_age > 8

tab child,missing
sort hhid
collapse (max) child, by (hhid)
la var child "number of children"
sort hhid
tab child,missing
save "${Nigeria_GHS_W5_created_data}\child_23.dta", replace

*/

*****************************************
*Consumption Grouped
*****************************************


	***********
	* Visit 2

use "${Nigeria_GHS_W5_raw_data}/sect6a_harvestw5.dta", clear
append using "${Nigeria_GHS_W5_raw_data}/sect6b_harvestw5.dta"
append using "${Nigeria_GHS_W5_raw_data}/sect6c_harvestw5.dta"


gen nfd_ = s6q2/7 //Per day
replace nfd_ = s6q4/30 if nfd_==.
*replace nfd_ = s11cq6/182.5 if nfd_==. // PA 1.8 6-month consumption not captured in W5
replace nfd_ = s6q6/365 if nfd_==.
recode nfd_ (.=0)

keep hhid nfd_ item_cd 
reshape wide nfd_, i(hhid) j(item_cd)
gen nfdtbac = nfd_101+nfd_102 //Tobacco and matches

gen nfdrecre = nfd_103+nfd_105+nfd_229+nfd_232+nfd_235+nfd_237+nfd_238 //"Recreation and culture", here including gambling/lotto and newspapers/magazines
gen nfdfares = nfd_104+nfd_358+nfd_359 //Public transportation
gen nfdwater = nfd_214
gen nfdelec = nfd_205+nfd_213
gen nfdgas = nfd_203
gen nfdkero = nfd_201+nfd_206
gen nfdliqd = nfd_204+nfd_202+nfd_212
gen nfdutil = 0 // not reported in W5?
egen nfdcloth = rowtotal(nfd_301-nfd_326 nfd_236)
egen nfdfmtn = rowtotal(nfd_328-nfd_349)
gen nfdrepar = nfd_327+nfd_328+nfd_248+nfd_249
gen nfddome = nfd_220+nfd_221+nfd_244
gen nfdpetro = nfd_209
gen nfddiesl = nfd_210
gen nfdcomm = nfd_318+nfd_319+nfd_320+nfd_321+nfd_350+nfd_351+nfd_352+nfd_224+nfd_225+nfd_226+nfd_227+nfd_233+nfd_234
gen nfdinsur = nfd_362+nfd_365
egen nfdfoth =rowtotal(nfd_206 nfd_211 nfd_247 nfd_308 nfd_313-nfd_317 nfd_354 nfd_361 nfd_215-nfd_219 nfd_327 nfd_360 nfd_364) //Added dowry, wedding, and funeral expenses/fines and legal fees
gen nfdfwood = nfd_207+nfd_208
gen nfdchar = nfd_307
egen nfdtrans = rowtotal(nfd_239-nfd_243)
gen nfdrnthh = nfd_245+nfd_246+nfd_353
gen nfdhealth = nfd_355+nfd_363+nfd_222+nfd_223+nfd_356+nfd_357 //Health insurance and non-insurance healthcare expenses
drop nfd_*

*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean) // PA W5 consumption data not published yet, check back later
unab vars : nfd*
foreach i in `vars' {
	gen `i'_def = `i' /*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
}

//There are a couple of big-ticket repair bills that likely aren't recurring monthly expenses even though they ask for 30-day recall on those questions. I'm assuming that they should probably be reported as annual expenses rather than monthly ones and rescale to fit.
*replace nfdrepar = nfdrepar*30/365 if hhid == 320056 | hhid == 199048
*replace nfdrepar_def = nfdrepar*30/365 if hhid == 320056 | hhid == 199048

la var nfdtbac "Tobacco & narcotics"
la var nfdrecre "Recreation and culture"
la var nfdfares "Fares"
la var nfdwater "Water, excluding packaged water"
la var nfdelec "Electricity"
la var nfdgas "Gas"
la var nfdkero "Kerosene"
la var nfdliqd "Other liquid fuels"
la var nfdutil "Refuse, sewage collection, disposal, and other services"
la var nfdcloth "Clothing and footwear"
la var nfdfmtn "Furnishings and routine household maintenance"
la var nfdrepar "Maintenance and repairs to dwelling"
la var nfddome "Domestic household services"
la var nfdpetro "Petrol"
la var nfddiesl "Diesel"
la var nfdtrans "Other transportation (n/a)"
la var nfdcomm "Communication (post, telephone, and computing/internet)"
la var nfdinsur "Other insurance excluding education and health"
la var nfdfoth "Expenditures on frequent non-food not mentioned elsewhere"
la var nfdfwood "Firewood"
la var nfdchar "Charcoal"
la var nfdrnthh "Mortgage and Rent"
la var nfdhealth "Healthcare expenses"

tempfile hhexp
save `hhexp', replace


//Getting prepared foods out of the way
use "${Nigeria_GHS_W5_raw_data}/sect5a_harvestw5.dta", clear
keep if s5aq1==1
gen item_ = s5aq2/7 //Total consumption per day (avg) of prepared foods/beverages
keep hhid item_cd item_ 
reshape wide item_, i(hhid) j(item_cd)
recode item_* (.=0)
gen fdbevby1 = item_6+item_8 
gen fdalcby1 = item_9
gen fdrestby = item_1+item_2+item_3+item_4
gen fdothby1=item_5+item_7
*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean) // PA Update when WB consumption data becomes available
gen fdbevby1_def = fdbevby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdalcby1_def = fdalcby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdothby1_def = fdothby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdrestby_def = fdrestby/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
drop item*
tempfile prepfoods
save `prepfoods', replace


use "${Nigeria_GHS_W5_raw_data}/sect5b_harvestw5.dta", clear
//gen obs=1 if s5bq1 != .
//keep if s5bq3!= . | s5bq4!= . | s5bq5!= . 
ren s5bq7a qty_bought 
gen kg_bought = qty_bought*s5bq7_cvn
gen price_kg = s5bq8/kg_bought
keep if price_kg !=. & price_kg!=0
//ALT 01.25.21: I've tested this with weighted/unweighted and kg vs unit-based pricing.
//It seems like weighted average per-kgs are producing the most reasonable results, but it is a value judgment.
*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keep(1 3) keepusing(reg_def_mean)
gen price_kg_def = price_kg/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
merge m:1 hhid using "${Nigeria_GHS_W5_created_data}/hhids.dta", nogen keep(3) keepusing(weight)
gen obs=1
foreach i in ea lga state zone {
	preserve
	collapse (median) price_`i' = price_kg price_def_`i' = price_kg_def (rawsum) obs_`i'=obs [aw=weight], by(item_cd `i')
	tempfile food_`i'
	save `food_`i''
	restore
}

collapse (median) price_kg price_kg_def (rawsum) obs_country=obs [aw=weight], by(item_cd)
keep item_cd price_kg price_kg_def obs_country
ren price_kg price_country
ren price_kg_def price_def_country
tempfile food_country
save `food_country'

use "${Nigeria_GHS_W5_raw_data}/sect5b_harvestw5.dta", clear
keep if s5bq3!= . | s5bq4!= . | s5bq5!= . 
ren s5bq7a qty_bought 
gen kg_bought = qty_bought*s5bq7_cvn
gen price_kg = s5bq8/kg_bought
recode price_kg (0=.)
gen price_kg_def = price_kg/*/reg_def_mean*/
foreach i in ea lga state zone { 
	merge m:1 item_cd `i' using `food_`i'', nogen
}
merge m:1 item_cd using `food_country', nogen

foreach i in lga state zone country {
	replace price_kg = price_`i' if price_kg ==. & obs_`i' > 9
	replace price_kg_def = price_def_`i' if price_kg_def == . & obs_`i' > 9
}

gen qty_purch = s5bq2_cvn * s5bq3
gen qty_own = s5bq2_cvn * (s5bq4+s5bq5)
//Getting per-day consumption
gen purch_ = qty_purch*price_kg/7
gen own_ = qty_own*price_kg/7
gen purch_def_ = qty_purch*price_kg_def/7
gen own_def_ = qty_own*price_kg_def/7
keep hhid item_cd purch* own*
reshape wide purch_ own_ purch_def_ own_def_, i(hhid) j(item_cd)
recode purch_* own_* (.=0)
ren purch_def_* purch_*_def 
ren own_def_* own_*_def

//Needed for water section
preserve
//ALT 4/1/22: Using deflated values now
gen purch_water_ph = purch_151_def + purch_150_def
gen own_water_ph = own_151_def + own_150_def
keep hhid purch_water_ph own_water_ph 
tempfile water_ph
save `water_ph'
restore
ren purch_10 fdsorby
ren purch_10_def fdorsby_def
ren purch_11 fdmilby
ren purch_11_def fdmilby_def
gen fdmaizby = purch_16+purch_20+purch_22
gen fdmaizby_def = purch_16_def + purch_20_def + purch_22_def
gen fdriceby = purch_13+purch_14
gen fdriceby_def = purch_13_def + purch_14_def
gen fdyamby = purch_17+purch_31 
gen fdyamby_def = purch_17_def + purch_31_def
gen fdcasby = purch_18+purch_30+purch_32+purch_33 
gen fdcasby_def = purch_18_def + purch_30_def + purch_32_def + purch_33_def
gen fdcereby = purch_23+purch_19
gen fdcereby_def = purch_23_def + purch_19_def
gen fdbrdby = purch_25+purch_26+purch_27+purch_28
gen fdbrdby_def = purch_25_def + purch_26_def + purch_27_def + purch_28_def
gen fdtubby = purch_34+purch_35+purch_36+purch_37+purch_38+purch_60 
gen fdtubby_def = purch_34_def + purch_35_def + purch_36_def + purch_37_def + purch_38_def + purch_60_def
gen fdpoulby = purch_80+purch_81+purch_82
gen fdpoulby_def = purch_80_def + purch_81_def + purch_82_def 
gen fdmeatby = purch_29+purch_90+purch_91+purch_92+purch_93+purch_94+purch_96
gen fdmeatby_def = purch_29_def + purch_90_def + purch_91_def + purch_92_def + purch_93_def + purch_94_def + purch_96_def
gen fdfishby = purch_100+purch_101+purch_102+purch_103+purch_104+purch_105+purch_106+purch_107
gen fdfishby_def = purch_100_def + purch_101_def + purch_102_def + purch_103_def + purch_104_def + purch_105_def + purch_106_def + purch_107_def
gen fddairby = purch_83+purch_84+purch_110+purch_111+purch_112+purch_113+purch_114
gen fddairby_def = purch_83_def + purch_84_def + purch_110_def + purch_111_def + purch_112_def + purch_113_def + purch_114_def 
gen fdfatsby = purch_46+purch_47+purch_48+purch_50+purch_51+purch_52+purch_53+purch_56+purch_63+purch_43+purch_44
gen fdfatsby_def = purch_46_def + purch_47_def + purch_48_def + purch_50_def + purch_51_def + purch_52_def + purch_53_def + purch_56_def + purch_63_def + purch_43_def + purch_44_def
gen fdfrutby = purch_61+purch_62+purch_64+purch_66+purch_67+purch_68+purch_69+purch_70+purch_71+purch_601
gen fdfrutby_def = purch_61_def + purch_62_def + purch_64_def + purch_66_def + purch_67_def + purch_68_def + purch_69_def + purch_70_def + purch_71_def + purch_601_def
gen fdvegby = purch_72+purch_73+purch_74+purch_75+purch_76+purch_77+purch_78+purch_79
gen fdvegby_def = purch_72_def + purch_73_def + purch_74_def + purch_75_def + purch_76_def + purch_77_def +  purch_78_def + purch_79_def
gen fdbeanby = purch_40+purch_41+purch_42+purch_45
gen fdbeanby_def = purch_40_def + purch_41_def + purch_42_def + purch_45_def
gen fdswtby = purch_130+purch_132
gen fdswtby_def = purch_130_def + purch_132_def 
gen fdbevby2 = purch_120+purch_121+purch_122+purch_150+purch_151+purch_152+purch_153+purch_154+purch_155
gen fdbevby2_def = purch_120_def + purch_121_def + purch_122_def + purch_150_def + purch_151_def + purch_152_def + purch_153_def + purch_154_def + purch_155_def
gen fdalcby2 = purch_160+purch_161+purch_162+purch_163+purch_164
gen fdalcby2_def = purch_160_def + purch_161_def + purch_162_def + purch_163_def + purch_164
gen fdothby2 = purch_142+purch_143
gen fdothby2_def = purch_142_def + purch_143_def
gen fdspiceby = purch_141+purch_144+purch_148+purch_145+purch_146+purch_147
gen fdspiceby_def = purch_141_def + purch_144_def + purch_148_def + purch_145_def + purch_146_def + purch_147_def

ren own_10 fdsorpr
ren own_10_def fdorspr_def
ren own_11 fdmilpr
ren own_11_def fdmilpr_def
gen fdmaizpr = own_16+own_20+own_22
gen fdmaizpr_def = own_16_def + own_20_def + own_22_def
gen fdricepr = own_13+own_14
gen fdricepr_def = own_13_def + own_14_def
gen fdyampr = own_17+own_31 
gen fdyampr_def = own_17_def + own_31_def
gen fdcaspr = own_18+own_30+own_32+own_33 
gen fdcaspr_def = own_18_def + own_30_def + own_32_def + own_33_def
gen fdcerepr = own_23+own_19
gen fdcerepr_def = own_23_def + own_19_def
gen fdbrdpr = own_25+own_26+own_27+own_28
gen fdbrdpr_def = own_25_def + own_26_def + own_27_def + own_28_def
gen fdtubpr = own_34+own_35+own_36+own_37+own_38+own_60 
gen fdtubpr_def = own_34_def + own_35_def + own_36_def + own_37_def + own_38_def + own_60_def
gen fdpoulpr = own_80+own_81+own_82
gen fdpoulpr_def = own_80_def + own_81_def + own_82_def 
gen fdmeatpr = own_29+own_90+own_91+own_92+own_93+own_94+own_96
gen fdmeatpr_def = own_29_def + own_90_def + own_91_def + own_92_def + own_93_def + own_94_def + own_96_def
gen fdfishpr = own_100+own_101+own_102+own_103+own_104+own_105+own_106+own_107
gen fdfishpr_def = own_100_def + own_101_def + own_102_def + own_103_def + own_104_def + own_105_def + own_106_def + own_107_def
gen fddairpr = own_83+own_84+own_110+own_111+own_112+own_113+own_114
gen fddairpr_def = own_83_def + own_84_def + own_110_def + own_111_def + own_112_def + own_113_def + own_114_def
gen fdfatspr = own_46+own_47+own_48+own_50+own_51+own_52+own_53+own_56+own_63+own_43+own_44
gen fdfatspr_def = own_46_def + own_47_def + own_48_def + own_50_def + own_51_def + own_52_def + own_53_def + own_56_def + own_63_def + own_43_def + own_44_def
gen fdfrutpr = own_61+own_62+own_64+own_66+own_67+own_68+own_69+own_70+own_71+own_601
gen fdfrutpr_def = own_61_def + own_62_def + own_64_def + own_66_def + own_67_def + own_68_def + own_69_def + own_70_def + own_71_def + own_601_def
gen fdvegpr = own_72+own_73+own_74+own_75+own_76+own_77+own_78+own_79
gen fdvegpr_def = own_72_def + own_73_def + own_74_def + own_75_def + own_76_def + own_77_def +  own_78_def + own_79_def
gen fdbeanpr = own_40+own_41+own_42+own_45
gen fdbeanpr_def = own_40_def + own_41_def + own_42_def + own_45_def
gen fdswtpr = own_130+own_132
gen fdswtpr_def = own_130_def + own_132_def 
gen fdbevpr = own_120+own_121+own_122+own_150+own_151+own_152+own_153+own_154+own_155
gen fdbevpr_def = own_120_def + own_121_def + own_122_def + own_150_def + own_151_def + own_152_def + own_153_def + own_154_def + own_155_def
gen fdalcpr = own_160+own_161+own_162+own_163+own_164
gen fdalcpr_def = own_160_def + own_161_def + own_162_def + own_163_def + own_164
gen fdothpr = own_142+own_143
gen fdothpr_def = own_142_def + own_143_def
gen fdspicepr = own_141+own_144+own_148+own_145+own_146+own_147
gen fdspicepr_def = own_141_def + own_144_def + own_148_def + own_145_def + own_146_def + own_147_def

drop purch_* own_*

merge 1:1 hhid using `prepfoods', nogen
gen fdothby = fdothby1+fdothby2
gen fdbevby = fdbevby1+fdbevby2 
gen fdalcby = fdalcby1+fdalcby2 
gen fdothby_def = fdothby1_def + fdothby2_def 
gen fdbevby_def = fdbevby1_def+ fdbevby2_def
gen fdalcby_def = fdalcby1_def+fdalcby2_def
drop fdothby1* fdothby2* fdbevby1* fdbevby2* fdalcby1* fdalcby2* 

la var fdsorby "Sorghum purchased"
la var fdmilby "Millet purchased"
la var fdmaizby "Maize grain and flours purchased"
la var fdriceby "Rice in all forms purchased"
la var fdyamby "Yam roots and flour purchased"
la var fdcasby "Cassava-gari, roots, and flour purchased"
la var fdcereby "Other cereals purchased"
la var fdbrdby "Bread and the like purchased"
la var fdtubby "Bananas & tubers purchased"
la var fdpoulby "Poultry purchased"
la var fdmeatby "Meat purchased"
la var fdfishby "Fish & seafood purchased"
la var fddairby "Milk, cheese, and eggs purchased"
la var fdfatsby "Oils, fats, & oil-rich nuts purchased"
la var fdfrutby "Fruits purchased"
la var fdvegby "Vegetables excluding pulses purchased"
la var fdbeanby "Pulses (beans, peas, and groundnuts) purchased"
la var fdswtby "Sugar, jam, honey, chocolate & confectionary purchased"
la var fdbevby "Non-alcoholic purchased"
la var fdalcby "Alcoholic beverages purchased"
la var fdrestby "Food consumed in restaurants & canteens purchased"
la var fdspiceby "Spices and condiments purchased"
la var fdothby "Food items not mentioned above purchased"

la var fdsorpr "Sorghum auto-consumption"
la var fdmilpr "Millet auto-consumption"
la var fdmaizpr "Maize grain and flours auto-consumption"
la var fdricepr "Rice in all forms auto-consumption"
la var fdyampr "Yam roots and flour auto-consumption"
la var fdcaspr "Cassava-gari, roots, and flour auto-consumption"
la var fdcerepr "Other cereals auto-consumption"
la var fdbrdpr "Bread and the like auto-consumption"
la var fdtubpr "Bananas & tubers auto-consumption"
la var fdpoulpr "Poultry auto-consumption"
la var fdmeatpr "Meat auto-consumption"
la var fdfishpr "Fish & seafood auto-consumption"
la var fddairpr "Milk, cheese, and eggs auto-consumption"
la var fdfatspr "Oils, fats, & oil-rich nuts auto-consumption"
la var fdfrutpr "Fruits auto-consumption"
la var fdvegpr "Vegetables excluding pulses auto-consumption"
la var fdbeanpr "Pulses (beans, peas, and groundnuts) auto-consumption"
la var fdswtpr "Sugar, jam, honey, chocolate & confectionary auto-consumption"
la var fdbevpr "Non-alcoholic auto-consumption"
la var fdalcpr "Alcoholic beverages auto-consumption"
la var fdspiceby "Spices and condiments auto-consumption"
la var fdothpr "Food items not mentioned above auto-consumption"


















//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*merge 1:1 hhid using `hhexp', nogen
drop *_def

egen cereals_only = rowtotal (fdsorby fdmilby fdmaizby fdriceby fdyamby fdcasby fdcereby fdbrdby fdsorpr fdmilpr fdmaizpr fdricepr fdyampr fdcaspr fdcerepr fdbrdpr)
egen protein_only = rowtotal (fdpoulby fdmeatby fdfishby fddairby fdfatsby fdbeanby  fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdbeanpr )
egen fruits_vegetables = rowtotal (fdtubby fdfrutby fdvegby fdtubpr fdfrutpr fdvegpr)

save "${Nigeria_GHS_W5_created_data}/cons_agg_wave5_visit2group.dta", replace



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



















	*****************
	*Visit 1

use "${Nigeria_GHS_W5_raw_data}/sect7a_plantingw5.dta", clear
append using "${Nigeria_GHS_W5_raw_data}/sect7b_plantingw5.dta"
append using "${Nigeria_GHS_W5_raw_data}/sect7c_plantingw5.dta"

gen nfd_ = s7q2/7 //Per day
replace nfd_ = s7q4/30 if nfd_==.
* replace nfd_ = s8q6/182.5 if nfd_==. PA 1.9 6 month consumption not asked in W5
replace nfd_ = s7q6/365 if nfd_==.
recode nfd_ (.=0)

keep hhid nfd_ item_cd 
reshape wide nfd_, i(hhid) j(item_cd)
gen nfdtbac = nfd_101+nfd_102 //Tobacco and matches

gen nfdrecre = nfd_103+nfd_105+nfd_229+nfd_232+nfd_235+nfd_237+nfd_238 //"Recreation and culture", here including gambling/lotto and newspapers/magazines
gen nfdfares = nfd_104+nfd_358+nfd_359 //Public transportation
gen nfdwater = nfd_214
gen nfdelec = nfd_205+nfd_213
gen nfdgas = nfd_203
gen nfdkero = nfd_201+nfd_206
gen nfdliqd = nfd_204+nfd_202+nfd_212
gen nfdutil = 0 // not reported in W5?
egen nfdcloth = rowtotal(nfd_301-nfd_326 nfd_236)
egen nfdfmtn = rowtotal(nfd_328-nfd_349)
gen nfdrepar = nfd_327+nfd_328+nfd_248+nfd_249
gen nfddome = nfd_220+nfd_221+nfd_244
gen nfdpetro = nfd_209
gen nfddiesl = nfd_210
gen nfdcomm = nfd_318+nfd_319+nfd_320+nfd_321+nfd_350+nfd_351+nfd_352+nfd_224+nfd_225+nfd_226+nfd_227+nfd_233+nfd_234
gen nfdinsur = nfd_362+nfd_365
egen nfdfoth =rowtotal(nfd_206 nfd_211 nfd_247 nfd_308 nfd_313-nfd_317 nfd_354 nfd_361 nfd_215-nfd_219 nfd_327 nfd_360 nfd_364) //Added dowry, wedding, and funeral expenses/fines and legal fees
gen nfdfwood = nfd_207+nfd_208
gen nfdchar = nfd_307
egen nfdtrans = rowtotal(nfd_239-nfd_243)
gen nfdrnthh = nfd_245+nfd_246+nfd_353
gen nfdhealth = nfd_355+nfd_363+nfd_222+nfd_223+nfd_356+nfd_357 //Health insurance and non-insurance healthcare expenses
drop nfd_*


*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean) // PA 1.9 to update when WB consumption data is available
unab vars : nfd*
foreach i in `vars' {
	gen `i'_def = `i'/*/reg_def_mean*/
}

//See visit 2 notes.
*replace nfdrepar = nfdrepar*30/365 if hhid == 320056 | hhid == 199048
*replace nfdrepar_def = nfdrepar*30/365 if hhid == 320056 | hhid == 199048


la var nfdtbac "Tobacco & narcotics"
la var nfdrecre "Recreation and culture"
la var nfdfares "Fares"
la var nfdwater "Water, excluding packaged water"
la var nfdelec "Electricity"
la var nfdgas "Gas"
la var nfdkero "Kerosene"
la var nfdliqd "Other liquid fuels"
la var nfdutil "Refuse, sewage collection, disposal, and other services"
la var nfdcloth "Clothing and footwear"
la var nfdfmtn "Furnishings and routine household maintenance"
la var nfdrepar "Maintenance and repairs to dwelling"
la var nfddome "Domestic household services"
la var nfdpetro "Petrol"
la var nfddiesl "Diesel"
la var nfdtrans "Other transportation (n/a)"
la var nfdcomm "Communication (post, telephone, and computing/internet)"
la var nfdinsur "Other insurance excluding education and health"
la var nfdfoth "Expenditures on frequent non-food not mentioned elsewhere"
la var nfdfwood "Firewood"
la var nfdchar "Charcoal"
la var nfdrnthh "Mortgage and Rent"
la var nfdhealth "Healthcare expenses"

tempfile hhexp
save `hhexp', replace

//Getting prepared foods out of the way
use "${Nigeria_GHS_W5_raw_data}/sect6a_plantingw5.dta", clear
keep if s6aq1==1
gen item_ = s6aq2/7 //Total consumption per day (avg) of prepared foods/beverages
keep hhid item_cd item_ 
reshape wide item_, i(hhid) j(item_cd)
recode item_* (.=0)
gen fdbevby1 = item_6+item_8 
gen fdalcby1 = item_9
gen fdrestby = item_1+item_2+item_3+item_4
gen fdothby1=item_5+item_7
*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean) // PA Update when WB consumption data becomes available
gen fdbevby1_def = fdbevby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdalcby1_def = fdalcby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdothby1_def = fdothby1/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
gen fdrestby_def = fdrestby/*/reg_def_mean*/ // PA 1.9 Need to revisit once WB published consumption data is available
drop item*
tempfile prepfoods
save `prepfoods', replace



use "${Nigeria_GHS_W5_raw_data}/sect6b_plantingw5.dta", clear
//gen obs=1 if s6bq7a != .
//keep if s6bq3!= . | s6bq4!= . | s6bq5!= . 
ren s6bq7a qty_bought 
gen kg_bought = qty_bought*s6bq7_cvn
gen price_kg = s6bq8/kg_bought
keep if price_kg != 0 & price_kg != .
gen obs=1
*merge m:1 hhid using "${Nigeria_GHS_W5_raw_data}/totcons_final.dta", nogen keep(1 3) keepusing(reg_def_mean)
gen price_kg_def = price_kg /*/reg_def_mean */
merge m:1 hhid using "${Nigeria_GHS_W5_created_data}/hhids.dta", nogen keep(3) keepusing(weight)
foreach i in ea lga state zone {
	preserve
	collapse (median) price_`i' = price_kg price_def_`i' = price_kg_def (rawsum) obs_`i'=obs [aw=weight], by(item_cd `i')
	tempfile food_`i'
	save `food_`i''
	restore
}


collapse (median) price_kg price_kg_def (rawsum) obs_country=obs [aw=weight], by(item_cd)
keep item_cd price_kg price_kg_def obs_country
ren price_kg price_country
ren price_kg_def price_def_country
tempfile food_country
save `food_country'


use "${Nigeria_GHS_W5_raw_data}/sect6b_plantingw5.dta", clear

ren s6bq7a qty_bought 
gen kg_bought = qty_bought*s6bq7_cvn
gen price_kg = s6bq8/kg_bought
recode price_kg (0=.)
gen price_kg_def = price_kg/*/reg_def_mean*/ 
keep if s6bq3!= . | s6bq4!= . | s6bq5!= . 
foreach i in ea lga state zone {
merge m:1 item_cd `i' using `food_`i'', nogen
}
merge m:1 item_cd using `food_country', nogen

foreach i in lga state zone country {
	replace price_kg = price_`i' if price_kg ==. & obs_`i' > 9
	replace price_kg_def = price_def_`i' if price_kg_def == . & obs_`i' > 9
}

gen qty_purch = s6bq2_cvn * s6bq3 
gen qty_own = s6bq2_cvn * (s6bq4+s6bq5)
//Getting per-day consumption
gen purch_ = qty_purch*price_kg/7
gen own_ = qty_own*price_kg/7
gen purch_def_ = qty_purch*price_kg_def/7
gen own_def_ = qty_own*price_kg_def/7
keep hhid item_cd purch* own*
reshape wide purch_ own_ purch_def_ own_def_, i(hhid) j(item_cd)
recode purch_* own_* (.=0)
ren purch_def_* purch_*_def 
ren own_def_* own_*_def

//Water section
preserve
gen purch_water_pp = purch_151 + purch_150
gen own_water_pp = own_151 + own_150
keep hhid purch_water_pp own_water_pp 
merge 1:1 hhid using `water_ph', nogen
recode *water* (.=0)
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_water_cons.dta", replace

restore

ren purch_10 fdsorby
ren purch_10_def fdorsby_def
ren purch_11 fdmilby
ren purch_11_def fdmilby_def
gen fdmaizby = purch_16+purch_20+purch_22
gen fdmaizby_def = purch_16_def + purch_20_def + purch_22_def
gen fdriceby = purch_13+purch_14
gen fdriceby_def = purch_13_def + purch_14_def
gen fdyamby = purch_17+purch_31 
gen fdyamby_def = purch_17_def + purch_31_def
gen fdcasby = purch_18+purch_30+purch_32+purch_33 
gen fdcasby_def = purch_18_def + purch_30_def + purch_32_def + purch_33_def
gen fdcereby = purch_23+purch_19
gen fdcereby_def = purch_23_def + purch_19_def
gen fdbrdby = purch_25+purch_26+purch_27+purch_28
gen fdbrdby_def = purch_25_def + purch_26_def + purch_27_def + purch_28_def
gen fdtubby = purch_34+purch_35+purch_36+purch_37+purch_38+purch_60 
gen fdtubby_def = purch_34_def + purch_35_def + purch_36_def + purch_37_def + purch_38_def + purch_60_def
gen fdpoulby = purch_80+purch_81+purch_82
gen fdpoulby_def = purch_80_def + purch_81_def + purch_82_def 
gen fdmeatby = purch_29+purch_90+purch_91+purch_92+purch_93+purch_94+purch_96
gen fdmeatby_def = purch_29_def + purch_90_def + purch_91_def + purch_92_def + purch_93_def + purch_94_def + purch_96_def
gen fdfishby = purch_100+purch_101+purch_102+purch_103+purch_104+purch_105+purch_106+purch_107
gen fdfishby_def = purch_100_def + purch_101_def + purch_102_def + purch_103_def + purch_104_def + purch_105_def + purch_106_def + purch_107_def
gen fddairby = purch_83+purch_84+purch_110+purch_111+purch_112+purch_113+purch_114+purch_115
gen fddairby_def = purch_83_def + purch_84_def + purch_110_def + purch_111_def + purch_112_def + purch_113_def + purch_114_def + purch_115_def
gen fdfatsby = purch_46+purch_47+purch_48+purch_50+purch_51+purch_52+purch_53+purch_56+purch_63+purch_43+purch_44
gen fdfatsby_def = purch_46_def + purch_47_def + purch_48_def + purch_50_def + purch_51_def + purch_52_def + purch_53_def + purch_56_def + purch_63_def + purch_43_def + purch_44_def
gen fdfrutby = purch_61+purch_62+purch_64+/*purch_65+*/purch_66+purch_67+purch_68+purch_69+purch_70+purch_71+purch_601 //65 is only in postharvest questionnaire for some reason
gen fdfrutby_def = purch_61_def + purch_62_def + purch_64_def + /*purch_65_def +*/ purch_66_def + purch_67_def + purch_68_def + purch_69_def + purch_70_def + purch_71_def + purch_601_def
gen fdvegby = purch_72+purch_73+purch_74+purch_75+purch_76+purch_77+purch_78+purch_79
gen fdvegby_def = purch_72_def + purch_73_def + purch_74_def + purch_75_def + purch_76_def + purch_77_def +  purch_78_def + purch_79_def
gen fdbeanby = purch_40+purch_41+purch_42+purch_45
gen fdbeanby_def = purch_40_def + purch_41_def + purch_42_def + purch_45_def
gen fdswtby = purch_130+purch_132+purch_133
gen fdswtby_def = purch_130_def + purch_132_def + purch_133_def
gen fdbevby2 = purch_120+purch_121+purch_122+purch_150+purch_151+purch_152+purch_153+purch_154+purch_155
gen fdbevby2_def = purch_120_def + purch_121_def + purch_122_def + purch_150_def + purch_151_def + purch_152_def + purch_153_def + purch_154_def + purch_155_def
gen fdalcby2 = purch_160+purch_161+purch_162+purch_163+purch_164
gen fdalcby2_def = purch_160_def + purch_161_def + purch_162_def + purch_163_def + purch_164
gen fdothby2 = purch_142+purch_143
gen fdothby2_def = purch_142_def + purch_143_def
gen fdspiceby = purch_141+purch_144+purch_148+purch_145+purch_146+purch_147
gen fdspiceby_def = purch_141_def + purch_144_def + purch_148_def + purch_145_def + purch_146_def + purch_147_def

ren own_10 fdsorpr
ren own_10_def fdorspr_def
ren own_11 fdmilpr
ren own_11_def fdmilpr_def
gen fdmaizpr = own_16+own_20+own_22
gen fdmaizpr_def = own_16_def + own_20_def + own_22_def
gen fdricepr = own_13+own_14
gen fdricepr_def = own_13_def + own_14_def
gen fdyampr = own_17+own_31 
gen fdyampr_def = own_17_def + own_31_def
gen fdcaspr = own_18+own_30+own_32+own_33 
gen fdcaspr_def = own_18_def + own_30_def + own_32_def + own_33_def
gen fdcerepr = own_23+own_19
gen fdcerepr_def = own_23_def + own_19_def
gen fdbrdpr = own_25+own_26+own_27+own_28
gen fdbrdpr_def = own_25_def + own_26_def + own_27_def + own_28_def
gen fdtubpr = own_34+own_35+own_36+own_37+own_38+own_60 
gen fdtubpr_def = own_34_def + own_35_def + own_36_def + own_37_def + own_38_def + own_60_def
gen fdpoulpr = own_80+own_81+own_82
gen fdpoulpr_def = own_80_def + own_81_def + own_82_def 
gen fdmeatpr = own_29+own_90+own_91+own_92+own_93+own_94+own_96
gen fdmeatpr_def = own_29_def + own_90_def + own_91_def + own_92_def + own_93_def + own_94_def + own_96_def
gen fdfishpr = own_100+own_101+own_102+own_103+own_104+own_105+own_106+own_107
gen fdfishpr_def = own_100_def + own_101_def + own_102_def + own_103_def + own_104_def + own_105_def + own_106_def + own_107_def
gen fddairpr = own_83+own_84+own_110+own_111+own_112+own_113+own_114+own_115
gen fddairpr_def = own_83_def + own_84_def + own_110_def + own_111_def + own_112_def + own_113_def + own_114_def + own_115_def
gen fdfatspr = own_46+own_47+own_48+own_50+own_51+own_52+own_53+own_56+own_63+own_43+own_44
gen fdfatspr_def = own_46_def + own_47_def + own_48_def + own_50_def + own_51_def + own_52_def + own_53_def + own_56_def + own_63_def + own_43_def + own_44_def
gen fdfrutpr = own_61+own_62+own_64+/*own_65+*/own_66+own_67+own_68+own_69+own_70+own_71+own_601
gen fdfrutpr_def = own_61_def + own_62_def + own_64_def + /*own_65_def +*/ own_66_def + own_67_def + own_68_def + own_69_def + own_70_def + own_71_def + own_601_def
gen fdvegpr = own_72+own_73+own_74+own_75+own_76+own_77+own_78+own_79
gen fdvegpr_def = own_72_def + own_73_def + own_74_def + own_75_def + own_76_def + own_77_def +  own_78_def + own_79_def
gen fdbeanpr = own_40+own_41+own_42+own_45
gen fdbeanpr_def = own_40_def + own_41_def + own_42_def + own_45_def
gen fdswtpr = own_130+own_132+own_133
gen fdswtpr_def = own_130_def + own_132_def + own_133_def
gen fdbevpr = own_120+own_121+own_122+own_150+own_151+own_152+own_153+own_154+own_155
gen fdbevpr_def = own_120_def + own_121_def + own_122_def + own_150_def + own_151_def + own_152_def + own_153_def + own_154_def + own_155_def
gen fdalcpr = own_160+own_161+own_162+own_163+own_164
gen fdalcpr_def = own_160_def + own_161_def + own_162_def + own_163_def + own_164
gen fdothpr = own_142+own_143
gen fdothpr_def = own_142_def + own_143_def
gen fdspicepr = own_141+own_144+own_148+own_145+own_146+own_147
gen fdspicepr_def = own_141_def + own_144_def + own_148_def + own_145_def + own_146_def + own_147_def

drop purch_* own_*

merge 1:1 hhid using `prepfoods', nogen
gen fdothby = fdothby1+fdothby2
gen fdbevby = fdbevby1+fdbevby2 
gen fdalcby = fdalcby1+fdalcby2 
gen fdothby_def = fdothby1_def + fdothby2_def 
gen fdbevby_def = fdbevby1_def+ fdbevby2_def
gen fdalcby_def = fdalcby1_def+fdalcby2_def
drop fdothby1* fdothby2* fdbevby1* fdbevby2* fdalcby1* fdalcby2* 

la var fdsorby "Sorghum purchased"
la var fdmilby "Millet purchased"
la var fdmaizby "Maize grain and flours purchased"
la var fdriceby "Rice in all forms purchased"
la var fdyamby "Yam roots and flour purchased"
la var fdcasby "Cassava-gari, roots, and flour purchased"
la var fdcereby "Other cereals purchased"
la var fdbrdby "Bread and the like purchased"
la var fdtubby "Bananas & tubers purchased"
la var fdpoulby "Poultry purchased"
la var fdmeatby "Meat purchased"
la var fdfishby "Fish & seafood purchased"
la var fddairby "Milk, cheese, and eggs purchased"
la var fdfatsby "Oils, fats, & oil-rich nuts purchased"
la var fdfrutby "Fruits purchased"
la var fdvegby "Vegetables excluding pulses purchased"
la var fdbeanby "Pulses (beans, peas, and groundnuts) purchased"
la var fdswtby "Sugar, jam, honey, chocolate & confectionary purchased"
la var fdbevby "Non-alcoholic purchased"
la var fdalcby "Alcoholic beverages purchased"
la var fdrestby "Food consumed in restaurants & canteens purchased"
la var fdspiceby "Spices and condiments purchased"
la var fdothby "Food items not mentioned above purchased"

la var fdsorpr "Sorghum auto-consumption"
la var fdmilpr "Millet auto-consumption"
la var fdmaizpr "Maize grain and flours auto-consumption"
la var fdricepr "Rice in all forms auto-consumption"
la var fdyampr "Yam roots and flour auto-consumption"
la var fdcaspr "Cassava-gari, roots, and flour auto-consumption"
la var fdcerepr "Other cereals auto-consumption"
la var fdbrdpr "Bread and the like auto-consumption"
la var fdtubpr "Bananas & tubers auto-consumption"
la var fdpoulpr "Poultry auto-consumption"
la var fdmeatpr "Meat auto-consumption"
la var fdfishpr "Fish & seafood auto-consumption"
la var fddairpr "Milk, cheese, and eggs auto-consumption"
la var fdfatspr "Oils, fats, & oil-rich nuts auto-consumption"
la var fdfrutpr "Fruits auto-consumption"
la var fdvegpr "Vegetables excluding pulses auto-consumption"
la var fdbeanpr "Pulses (beans, peas, and groundnuts) auto-consumption"
la var fdswtpr "Sugar, jam, honey, chocolate & confectionary auto-consumption"
la var fdbevpr "Non-alcoholic auto-consumption"
la var fdalcpr "Alcoholic beverages auto-consumption"
la var fdspiceby "Spices and condiments auto-consumption"
la var fdothpr "Food items not mentioned above auto-consumption"


*merge 1:1 hhid using `hhexp', nogen
drop *_def

egen cereals_only = rowtotal (fdsorby fdmilby fdmaizby fdriceby fdyamby fdcasby fdcereby fdbrdby fdsorpr fdmilpr fdmaizpr fdricepr fdyampr fdcaspr fdcerepr fdbrdpr)
egen protein_only = rowtotal (fdpoulby fdmeatby fdfishby fddairby fdfatsby fdbeanby  fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdbeanpr )
egen fruits_vegetables = rowtotal (fdtubby fdfrutby fdvegby fdtubpr fdfrutpr fdvegpr)


save "${Nigeria_GHS_W5_created_data}/cons_agg_wave5_visit1group.dta", replace
ren cereals_only totcons_cereal_pp
ren protein_only totcons_protein_pp 
ren fruits_vegetables totcons_veg_pp


merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/cons_agg_wave5_visit2group.dta", nogen keepusing(cereals_only protein_only fruits_vegetables)
ren cereals_only totcons_cereal_ph
ren protein_only totcons_protein_ph 
ren fruits_vegetables totcons_veg_ph

*gen totcons_cereal = (totcons_cereal_pp+totcons_cereal_ph)/2
gen totcons_cereal = totcons_cereal_pp
*gen totcons_protein = (totcons_protein_pp+totcons_protein_ph)/2
gen totcons_protein = totcons_protein_pp
*gen totcons_fruit_veg = (totcons_veg_pp+totcons_veg_ph)/2
gen totcons_fruit_veg = totcons_veg_pp


merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hh_adulteq.dta", nogen keep(1 3) keepusing(adulteq)
//merge 1:1 hhid using  "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhsize.dta", nogen keep(1 3)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/hhids.dta", nogen


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


gen totcons_cereal = totcons_cereal_n /1
gen totcons_protein = totcons_protein_n /1
gen totcons_fruit_veg = totcons_fruit_veg_n /1

gen peraeq_cons_cereal = peraeq_cons_cereal_n /1
gen peraeq_cons_protein = peraeq_cons_protein_n /1
gen peraeq_cons_veg = peraeq_cons_veg_n /1


gen totalcons_cereal = totalcons_cereal_n /1
gen totalcons_protein = totalcons_protein_n /1
gen totalcons_veg = totalcons_veg_n /1
  
  
  
  
keep hhid adulteq totcons_cereal totcons_protein  totcons_fruit_veg peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg

save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_consumptiongroup2.dta", replace 

use "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_consumptiongroup2.dta", clear 

merge 1:1 hhid using   "${Nigeria_GHS_W5_created_data}/haz.dta", nogen

keep if s4bq1 ==1
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_consumptiongroup2.dta", replace 



*******************************************************************************
*OFF-FARM HOURS PA: Done but verify which hours are daily, weekly, monthly, annual 
********************************************************************************
use "${Nigeria_GHS_W5_raw_data}/sect4a_harvestw5.dta", clear
gen  hrs_main_wage_off_farm=s4aq46 if (s4aq41c>1 & s4aq41c!=.)	& s4aq53!=1
*gen  hrs_sec_wage_off_farm= hh_e50 if (hh_e39_2>3 & hh_e39_2!=.)		// s3q14 1 to 2 is agriculture  
egen hrs_wage_off_farm= rowtotal(hrs_main_wage_off_farm /*hrs_sec_wage_off_farm*/) 

gen  hrs_main_wage_on_farm=s4aq46 if (s4aq41c<=1 & s4aq41c!=.) & s4aq53!=1		 
*gen  hrs_sec_wage_on_farm= hh_e50 if (hh_e39_2<3 & hh_e39_2!=.)	 
egen hrs_wage_on_farm= rowtotal(hrs_main_wage_on_farm /*hrs_sec_wage_on_farm*/) 

drop *main* /*sec*/
gen hrs_unpaid_off_farm=s4aq46 if (s4aq41c>1 & s4aq41c!=.)	& s4aq53==1 // Hours on apprenticeship
*recode hh_e70 hh_e71 (.=0) 
gen  hrs_domest_fire_fuel=s4aq61a 
ren  s4aq12 hrs_ag_activ 
ren s4aq7 hrs_self_off_farm

egen hrs_off_farm=rowtotal(hrs_wage_off_farm hrs_self_off_farm)
egen hrs_on_farm=rowtotal(hrs_ag_activ hrs_wage_on_farm)
gen hrs_domest_all=.
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

save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_off_farm_hours.dta", replace

//hrs_unpaid_off_farm  hrs_ag_activ 



********************************************************************************
* WAGE INCOME * PA done
********************************************************************************
use "${Nigeria_GHS_W5_raw_data}/sect4a_harvestw5.dta", clear
*ren  activity_code
ren s4aq41c sector_code
//ren s3q12b1 mainwage_yesno //ALT: Because this section only covers one job, it's assumed that we're asking about the main wage
egen mainwage_number_months = rowtotal(s4aq58__2 - s4aq58__13) //ALT: Questionnaire goes from June '17 to April '19. I'm doing Feb 18-Jan 19 to keep it consistent with W3
replace mainwage_number_months = 12 if s4aq58__0==1 //ALT: "All 12 months" would mean either Jan-Dec 18 or Feb 18 - Jan 19 depending on when HH was surveyed. Not sure why the questionnaire goes out to April.
//ren s3q16 mainwage_number_months
ren s4aq44 mainwage_number_weeks
ren s4aq46 mainwage_number_hours
ren s4aq47 mainwage_recent_payment
gen ag_activity = (sector_code==1)
replace mainwage_recent_payment = . if ag_activity==1 // exclude ag wages 
ren s4aq47_tunit mainwage_payment_period 
ren s4aq49a mainwage_recent_payment_other
replace mainwage_recent_payment_other = . if ag_activity==1
ren s4aq49b mainwage_payment_period_other

gen worked_as_employee=(s4aq4==1) if s4aq4!=.

recode  mainwage_number_months (12/max=12)
recode  mainwage_number_weeks (52/max=52)
recode  mainwage_number_hours (84/max=84)
local vars main //sec oth
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
gen annual_salary = mainwage_annual_salary
collapse (sum) annual_salary, by (hhid)
lab var annual_salary "Estimated annual earnings from non-agricultural wage employment over previous 12 months"
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_wage_income.dta", replace


*Ag wage income
use "${Nigeria_GHS_W5_raw_data}/sect4a_harvestw5.dta", clear

*ren s3q13b activity_code
ren s4aq41c sector_code
*ren s3q12b1 mainwage_yesno
egen mainwage_number_months = rowtotal(s4aq58__2 - s4aq58__13)
replace mainwage_number_months = 12 if s4aq58__0==1
//ren s3q16 mainwage_number_months
ren s4aq44 mainwage_number_weeks
ren s4aq46 mainwage_number_hours
ren s4aq47 mainwage_recent_payment
gen ag_activity = (sector_code==1)

replace mainwage_recent_payment = . if ag_activity!=1 // include only ag wages
ren s4aq47_tunit mainwage_payment_period
ren s4aq49a mainwage_recent_payment_other
replace mainwage_recent_payment_other = . if ag_activity!=1 // include only ag wages
ren s4aq49b mainwage_payment_period_other

gen worked_as_employee=(s4aq4==1) if s4aq4!=.
recode  mainwage_number_months (12/max=12)
recode  mainwage_number_weeks (52/max=52)
recode  mainwage_number_hours (84/max=84)
local vars main //sec oth
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
gen annual_salary_agwage = mainwage_annual_salary //+ secwage_annual_salary + othwage_annual_salary
collapse (sum) annual_salary_agwage, by (hhid)
lab var annual_salary_agwage "Estimated annual earnings from agricultural wage employment over previous 12 months"
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_agwage_income.dta", replace 












********************************************************************************
* PLOT DECISION MAKERS *
********************************************************************************
use "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_plot_areas.dta", clear
keep hhid plot_id indiv* cultivate //ALT: Based on crop reporting numbers I would take the cultivate response with a grain of salt. 
reshape long indiv, i(hhid plot_id cultivate) j(indivno)
collapse (min) indivno, by(hhid plot_id indiv cultivate) //Removing excess observations to accurately estimate the number of decisionmakers in mixed-managed plots. Taking the highest rank
//At this point, we have the decisionmakers and their relative priority level, as the questionnaire asks to go in descending order of importance. This may be relevant for some applications (e.g., you want only the primary decisionmaker; keep if indivno==1), but we don't use it here.
drop if indiv==.
merge m:1 hhid indiv using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_person_ids.dta", nogen keep(1 3) keepusing(female)
preserve 
keep hhid plot_id indiv female
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_dm_ids.dta", replace
restore
gen dm1_gender = female+1 if indivno==1
gen dm1_id = indiv if indivno==1
collapse (mean) female (firstnm) dm1_gender dm1_id, by(hhid plot_id)
*Constructing three-part gendered decision-maker variable; male only (=1) female only (=2) or mixed (=3)
gen dm_gender = 3 if female !=1 & female!=0 & female!=.
replace dm_gender = 1 if female == 0
replace dm_gender = 2 if female == 1
la def dm_gender 1 "Male only" 2 "Female only" 3 "Mixed gender"
*replacing observations without gender of plot manager with gender of HOH
merge m:1 hhid using "${Nigeria_GHS_W5_created_data}\demographics_2023.dta", nogen keep(1 3)
replace dm1_gender=femhead+1 if dm_gender==.
gen dm_male = dm_gender==1
gen dm_female = dm_gender==2
gen dm_mixed = dm_gender==3
keep plot_id hhid dm* //fhh 
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_plot_decision_makers", replace




********************************************************************************
*SHANNON DIVERSITY INDEX * PA Done
********************************************************************************

use "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_all_plots.dta", clear
merge m:1 hhid plot_id using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_plot_decision_makers.dta", nogen keep(1 3) keepusing(dm*)
ren cropcode crop_code
gen no_harvest=ha_harvest==.
ren quant_harv_kg harvest 
ren ha_plan_yld area_plan
ren ha_harv_yld area_harv 
gen mixed = "inter"  //Note to adjust this for lost crops 
replace mixed="pure" if purestand==1
gen dm_gender2="unknown"
replace dm_gender2="male" if dm_gender==1
replace dm_gender2="female" if dm_gender==2
replace dm_gender2="mixed" if dm_gender==3

foreach i in harvest area_plan area_harv {	
	foreach j in inter pure {
		gen `i'_`j'=`i' if mixed == "`j'"
		foreach k in male female mixed {
			gen `i'_`j'_`k' = `i' if mixed=="`j'" & dm_gender2=="`k'"
			capture confirm var `i'_`k'
			if _rc {
				gen `i'_`k'=`i' if dm_gender2=="`k'"
			}
		}
	}
}

collapse (sum) harvest* area* (max) no_harvest, by(hhid crop_code)
unab vars : harvest* area*
foreach var in `vars' {
	replace `var' = . if `var'==0 & no_harvest==1
}

replace area_plan = . if area_plan==0
replace area_harv = . if area_plan==. | (area_harv==0 & no_harvest==1)
unab vars2 : area_plan_*
local suffix : subinstr local vars2 "area_plan_" "", all
foreach var in `suffix' {
	replace area_plan_`var' = . if area_plan_`var'==0
	replace harvest_`var'=. if area_plan_`var'==. | (harvest_`var'==0 & no_harvest==1)
	replace area_harv_`var'=. if area_plan_`var'==. | (area_harv_`var'==0 & no_harvest==1)
}
drop no_harvest

save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hh_crop_area_plan.dta", replace




********************************************************************************
*SHANNON DIVERSITY INDEX * PA Done
********************************************************************************
*Area planted
*Bringing in area planted for LRS
//ALT: Wave 3 code seems to run okay without modification
use "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hh_crop_area_plan.dta", clear
*Some households have crop observations, but the area planted=0. These are permanent crops. Right now they are not included in the SDI unless they are the only crop on the plot, but we could include them by estimating an area based on the number of trees planted
drop if area_plan==0
*generating area planted of each crop as a proportion of the total area
preserve 
collapse (sum) area_plan_hh=area_plan area_plan_female_hh=area_plan_female area_plan_male_hh=area_plan_male area_plan_mixed_hh=area_plan_mixed, by(hhid)
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hh_crop_area_plan_shannon.dta", replace
restore
merge m:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hh_crop_area_plan_shannon.dta", nogen		//all matched
recode area_plan_female area_plan_male area_plan_female_hh area_plan_male_hh area_plan_mixed area_plan_mixed_hh (0=.)
gen prop_plan = area_plan/area_plan_hh
gen prop_plan_female=area_plan_female/area_plan_female_hh
gen prop_plan_male=area_plan_male/area_plan_male_hh
gen prop_plan_mixed=area_plan_mixed/area_plan_mixed_hh
gen sdi_crop = prop_plan*ln(prop_plan)
gen sdi_crop_female = prop_plan_female*ln(prop_plan_female)
gen sdi_crop_male = prop_plan_male*ln(prop_plan_male)
gen sdi_crop_mixed = prop_plan_mixed*ln(prop_plan_mixed)
*tagging those that are missing all values
bysort hhid (sdi_crop_female) : gen allmissing_female = mi(sdi_crop_female[1])
bysort hhid (sdi_crop_male) : gen allmissing_male = mi(sdi_crop_male[1])
bysort hhid (sdi_crop_mixed) : gen allmissing_mixed = mi(sdi_crop_mixed[1])
*Generating number of crops per household
bysort hhid crop_code : gen nvals_tot = _n==1
gen nvals_female = nvals_tot if area_plan_female!=0 & area_plan_female!=.
gen nvals_male = nvals_tot if area_plan_male!=0 & area_plan_male!=. 
gen nvals_mixed = nvals_tot if area_plan_mixed!=0 & area_plan_mixed!=.
collapse (sum) sdi=sdi_crop sdi_female=sdi_crop_female sdi_male=sdi_crop_male sdi_mixed=sdi_crop_mixed num_crops_hh=nvals_tot num_crops_female=nvals_female ///
num_crops_male=nvals_male num_crops_mixed=nvals_mixed (max) allmissing_female allmissing_male allmissing_mixed, by(hhid)
la var sdi "Shannon diversity index"
la var sdi_female "Shannon diversity index on female managed plots"
la var sdi_male "Shannon diversity index on male managed plots"
la var sdi_mixed "Shannon diversity index on mixed managed plots"
replace sdi_female=. if allmissing_female==1
replace sdi_male=. if allmissing_male==1
replace sdi_mixed=. if allmissing_mixed==1
gen encs = exp(-sdi)
gen encs_female = exp(-sdi_female)
gen encs_male = exp(-sdi_male)
gen encs_mixed = exp(-sdi_mixed)
gen sdi1 = -1 * sdi
la var encs "Effective number of crop species per household"
la var encs_female "Effective number of crop species on female managed plots per household"
la var encs_male "Effective number of crop species on male managed plots per household"
la var encs_mixed "Effective number of crop species on mixed managed plots per household"
la var num_crops_hh "Number of crops grown by the household"
la var num_crops_female "Number of crops grown on female managed plots" 
la var num_crops_male "Number of crops grown on male managed plots"
la var num_crops_mixed "Number of crops grown on mixed managed plots"
gen multiple_crops = (num_crops_hh>1 & num_crops_hh!=.)
la var multiple_crops "Household grows more than one crop"
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_shannon_diversity_index.dta", replace





global climate "C:\Users\obine\Music\Documents\food_secure\dofile\original\pp_only\CHIRPS\spatial"
*--------------------------------------------------------------*
* 1. Load household rainfall dataset
*--------------------------------------------------------------*
use "$climate\Nigeria_y4_hh_coordinates_rainfall_TS_monthly.dta", clear

* Rename rainfall variables to avoid name conflicts after merge
foreach var of varlist rain_1987_01 - rain_2023_12 {
    rename `var' hh_`var'
}

* Save temporary file of household rainfall
tempfile hh_rain
save `hh_rain', replace

*--------------------------------------------------------------*
* 2. Load plot-level dataset and merge rainfall by hhid
*--------------------------------------------------------------*
use "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_all_plots.dta", clear

merge m:1 hhid using `hh_rain'
drop _merge

*--------------------------------------------------------------*
* 3. Transfer household rainfall into plot rainfall variables
*--------------------------------------------------------------*
foreach var of varlist hh_rain_1987_01 - hh_rain_2023_12 {
    local new = subinstr("`var'", "hh_", "", .)   // remove hh_ prefix
    gen `new' = `var'
}

*--------------------------------------------------------------*
* 4. Remove household-prefixed rainfall variables
*--------------------------------------------------------------*
drop hh_rain_1987_01 - hh_rain_2023_12

		

egen total_rain_18_June = rowtotal(rain_2023_03 rain_2023_04 rain_2023_05 rain_2023_06)
egen total_rain_18_July = rowtotal(rain_2023_03 rain_2023_04 rain_2023_05 rain_2023_06 rain_2023_07)

egen mean_rain_18_June  = rowmean(rain_2023_03 rain_2023_04 rain_2023_05 rain_2023_06)
egen mean_rain_18_July  = rowmean(rain_2023_03 rain_2023_04 rain_2023_05 rain_2023_06 rain_2023_07)

*--------------------------------------------------------------*
* 1. Remove rainfall for years you don't want (example: drop 2018)
*--------------------------------------------------------------*
drop rain_2023_*


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
egen mean_rain_2022_Mar = rowmean(rain_2022_03 rain_2022_04 rain_2022_05 rain_2022_06)
gen  dev_rain_2022_Mar  = mean_rain_2022_Mar - mean_rain_Mar_June

egen mean_rain_2022_Aug = rowmean(rain_2022_08 rain_2022_09 rain_2022_10 rain_2022_11 rain_2022_12)
gen  dev_rain_2022_Aug  = mean_rain_2022_Aug - mean_rain_Aug_Dec

*----------------------------------------------------------------------
* 5. Annual mean rainfall (for all years)
*----------------------------------------------------------------------
egen mean_annual_rainfall = rowmean(rain_*_01 rain_*_02 rain_*_03 rain_*_04 rain_*_05 rain_*_06 rain_*_07 rain_*_08 rain_*_09 rain_*_10 rain_*_11 rain_*_12)

*----------------------------------------------------------------------
* 6. Annual shortfall (corrected code using loops)
*----------------------------------------------------------------------
forvalues yr = 1987/2022 {
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
forvalues yr = 1987/2022 {
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
     mean_rain_2022_Mar dev_rain_2022_Mar dev_rain_2022_Aug ///
     shortfall_Mar_June shortfall_Mar_July shortfall_Aug_Dec ///
     sd_shortfall_* *_18_June, by (hhid)

save "${Nigeria_GHS_W5_created_data}/rainfall_23.dta", replace 





* Example: if your analysis year is 2022 and you want Apr–Jun deviation
* ivregress 2sls outcome controls (ln_income = dev_R2_2022 dev_R2_sq_2022), vce(cluster `locid')




***********************************************************************************************************************************************
*Merging Dataset
***********************************************************************************************************************************************


use "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_all_plots.dta",clear

sort hhid 
count
*count if crop_code==1080
*keep if cropcode==1080
*keep if purestand ==1
order hhid plot_id cropcode quant_harv_kg value_harvest ha_harvest percent_inputs field_size purestand

collapse (sum) quant_harv_kg value_harvest ha_planted field_size (max) percent_inputs  purestand, by (hhid)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/hhids.dta", nogen

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
gen value_harvest  = real_value_harvest_w/1
sum value_harvest, detail


merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/fert_units.dta", gen(fert)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/food_prices_2023.dta", gen(food)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}\household_asset_2023.dta", gen(asset)
merge 1:1 hhid using  "${Nigeria_GHS_W5_created_data}/hhids.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/ag_rainy_18.dta", gen(filter)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/dieatary_diversity.dta", gen(diet)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_consumption2.dta", gen(exp)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_consumptiongroup2.dta", gen(exp2)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhsize.dta", gen(hh)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/soil_quality_2023.dta", gen(soil)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/demographics_2023.dta", gen(house)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/laborage_2023.dta", gen(work)
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_shannon_diversity_index.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_off_farm_hours.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_wage_income.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_agwage_income.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/rainfall_23.dta", nogen
*merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/child_23.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/shock.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/haz.dta", nogen




gen year =2023
***********************Dealing with outliers*************************

sort hhid
misstable summarize haz haz2 peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr  total_qty real_hhvalue field_size hh_members num_mem hh_headage femhead attend_sch  mean_annual_rainfall   zone state lga ea ag_shock nonag_shock  


replace total_qty = 0 if total_qty==.
replace shock = 0 if shock ==.
replace ag_shock = 0 if ag_shock ==.
replace nonag_shock = 0 if nonag_shock ==.


egen median_maize = median(real_maize_price_mr)
replace real_maize_price_mr = median_maize if real_maize_price_mr==.


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

egen mean1 = mean (dev_rain_2022_Mar)
egen mean2 = mean (dev_rain_2022_Aug)
egen mean3 = mean (shortfall_Mar)
egen mean4 = mean (mean_annual_rainfall)



ren dev_rain_2022_Mar dev_rain_Mar
ren dev_rain_2022_Aug dev_rain_Aug


replace dev_rain_Mar = mean1 if dev_rain_Mar ==. 
replace dev_rain_Aug = mean2 if dev_rain_Aug ==. 
replace shortfall_Mar = mean3 if shortfall_Mar ==. 
replace mean_annual_rainfall = mean4 if mean_annual_rainfall ==. 


tabstat haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea  [w=weight], statistics( mean median sd min max ) columns(statistics)


misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr  total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea

misstable summarize hhid haz haz2 peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr  total_qty real_hhvalue field_size hh_members num_mem hh_headage femhead attend_sch  mean_annual_rainfall   zone state lga ea ag_shock nonag_shock  

save "${Nigeria_GHS_W5_created_data}/final_23.dta", replace













/*



append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_two\final_12.dta" 
append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_three\final_15.dta"


append using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_four\final_19.dta"


save "${Nigeria_GHS_W5_created_data}/apppend.dta", replace


use "${Nigeria_GHS_W5_created_data}/apppend.dta", clear

order year


gen dummy = 1

collapse (sum) dummy, by (hhid)
tab dummy
keep if dummy==4


merge 1:m hhid  using "${Nigeria_GHS_W5_created_data}/apppend.dta", gen(fil)

drop if fil==2

order year

sort hhid  year

misstable summarize ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty n_kg  tpricefert_cens_mrk real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue totcons_pc peraeq_cons total_cons hh_members number_foodgroup soil_qty_rev2 mrk_dist_w num_mem hh_headage femhead attend_sch worker zone state lga ea peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg sdi


*tab if ha_planted == 0 | ha_planted == .
drop if ha_planted == 0 | ha_planted == .

gen yield_plot =  quant_harv_kg/ ha_planted
gen fert_rate = total_qty/ ha_planted
gen n_rate = n_kg/ field_size
gen productivity = value_harvest/ ha_planted
foreach v of varlist  productivity  {
	_pctile `v' , p(5 95) 
	gen `v'_w=`v'
	*replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top & bottom 1%"
}




/////real variables

gen input_ratio =  real_tpricefert_cens_mrk/real_maize_price_mr
gen output_ratio =  real_maize_price_mr/ real_tpricefert_cens_mrk
gen good = (soil_qty_rev2 ==1)
gen fair = (soil_qty_rev2==2)
gen poor = (soil_qty_rev2==3)
gen good_soil_plant = ha_planted if ha_planted !=. & good==1
gen fair_soil_plant = ha_planted if ha_planted !=. & fair==1
gen poor_soil_plant = ha_planted if ha_planted !=. & poor==1



misstable summarize ha_planted field_size quant_harv_kg yield_plot value_harvest maize_price_mr real_maize_price_mr total_qty n_kg n_rate tpricefert_cens_mrk real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue productivity productivity_w household_diet_cut_off1 household_diet_cut_off2 totcons_pc peraeq_cons total_cons hh_members number_foodgroup input_ratio output_ratio soil_qty_rev2 good fair poor mrk_dist_w num_mem hh_headage femhead attend_sch worker peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg sdi mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug 





//// annual_salary annual_salary_agwage
preserve
keep if year ==2018
sum hrs_wage_off_farm, detail
tabstat nworker_wage_off_farm  nworker_wage_on_farm  hrs_wage_off_farm hrs_wage_on_farm sdi1 peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg ha_planted field_size quant_harv_kg yield_plot value_harvest maize_price_mr real_maize_price_mr total_qty n_kg n_rate tpricefert_cens_mrk real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue productivity productivity_w household_diet_cut_off1 household_diet_cut_off2 totcons_pc peraeq_cons total_cons hh_members number_foodgroup input_ratio output_ratio soil_qty_rev2 good fair poor good_soil_plant fair_soil_plant poor_soil_plant mrk_dist_w num_mem hh_headage femhead attend_sch worker hrs_ag_activ mean_annual_rainfall [w=weight], statistics( mean median sd min max ) columns(statistics)
count
restore


preserve
keep if year ==2023
sum hrs_wage_off_farm, detail
tabstat nworker_wage_off_farm  nworker_wage_on_farm  hrs_wage_off_farm hrs_wage_on_farm  sdi1 peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg ha_planted field_size quant_harv_kg yield_plot value_harvest maize_price_mr real_maize_price_mr total_qty n_kg n_rate tpricefert_cens_mrk real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue productivity productivity_w household_diet_cut_off1 household_diet_cut_off2 totcons_pc peraeq_cons total_cons hh_members number_foodgroup input_ratio output_ratio soil_qty_rev2 good fair poor good_soil_plant fair_soil_plant poor_soil_plant mrk_dist_w num_mem hh_headage femhead attend_sch worker hrs_ag_activ mean_annual_rainfall [w=weight], statistics( mean median sd min max ) columns(statistics)
count
restore

gen commercial_dummy = (total_qty >0)
//% of HHs that bought commercial fertilizer by each survey wave
bysort year : tabstat commercial_dummy [w=weight], stat(mean sem) //

// By HH, sum the binary variable of commerical fert market particapation for all waves
bysort hhid : egen sum_4waves_com_fer_bin = sum(commercial_dummy) 


**********************************
ttest household_diet_cut_off2, by(year) unequal
ttest number_foodgroup, by(year) unequal
ttest totcons_pc, by(year) unequal
ttest peraeq_cons, by(year) unequal
ttest ha_planted, by(year) unequal
ttest field_size, by(year) unequal
ttest quant_harv_kg, by(year) unequal
ttest yield_plot, by(year) unequal
ttest value_harvest, by(year) unequal
ttest productivity_w, by(year) unequal
ttest maize_price_mr, by(year) unequal
ttest real_maize_price_mr, by(year) unequal
ttest input_ratio, by(year) unequal
ttest total_qty, by(year) unequal
ttest n_kg, by(year) unequal
ttest n_rate, by(year) unequal
ttest tpricefert_cens_mrk, by(year) unequal
ttest real_tpricefert_cens_mrk, by(year) unequal
ttest good, by(year) unequal
ttest fair, by(year) unequal
ttest poor, by(year) unequal
ttest good_soil_plant, by(year) unequal
ttest fair_soil_plant, by(year) unequal
ttest poor_soil_plant, by(year) unequal
ttest hh_members, by(year) unequal
ttest hhasset_value_w, by(year) unequal
ttest peraeq_cons_cereal, by(year) unequal
ttest peraeq_cons_protein, by(year) unequal
ttest peraeq_cons_veg, by(year) unequal
ttest hrs_wage_off_farm, by(year) unequal
ttest hrs_wage_on_farm, by(year) unequal
ttest nworker_wage_off_farm, by(year) unequal
ttest nworker_wage_on_farm, by(year) unequal
ttest hrs_off_farm, by(year) unequal
ttest hrs_on_farm, by(year) unequal
ttest nworker_off_farm, by(year) unequal
ttest nworker_on_farm, by(year) unequal
ttest  mrk_dist_w, by(year) unequal
           
//yield_plot productivity_w household_diet_cut_off2 peraeq_cons number_foodgroup
 
//sdi1 hrs_wage_off_farm hrs_wage_on_farm nworker_wage_off_farm nworker_wage_on_farm

* Generate interaction term
gen year2023 = (real_tpricefert_cens_mrk !=. & year == 2023)
gen price2023 = real_tpricefert_cens_mrk * year2023
gen mrk_dist_w23 = mrk_dist_w *year2023
gen real_hhvalue_23 = real_hhvalue * year2023
gen fert_mrk_23 = mrk_dist_w *real_tpricefert_cens_mrk
gen t23 = real_tpricefert_cens_mrk * mrk_dist_w * year2023


//////////////////////////////////////Regression//////////////////////////////
*save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\child.dta", replace

save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\child2.dta", replace ///everything


*save "C:\Users\obine\Music\Documents\food_secure\dofile\original\pp_only\pure_maize_farm_pp.dta", replace




*****************************************************
*
*****************************************************
* (A) Weighted median:
* weighted median classification into poor / non-poor
/*
xtile poors = peraeq_cons [pw = weight], nq(2)
recode poors (2 = 0)
label define poorlbl 1 "Poor (<= median)" 0 "Non-poor (> median)"
label values poors poorlbl
keep if poors==1
*/



* Assumes:
*   peraeq_cons = (per adult-equivalent or per capita) expenditure
*   weight      = survey pweight for the household
/*
drop if missing(peraeq_cons, weight) | weight<=0

* 1) Get the weighted median (p50) using pweights (no svy: prefix)
quietly _pctile peraeq_cons [pweight = weight], p(50)
scalar med_pc = r(r1)

* 2) Classify poor vs non-poor using that cutoff
gen byte poors = peraeq_cons <= med_pc
label define poorlbl 1 "Poor (<= weighted median)" 0 "Non-poor (> weighted median)"
label values poors poorlbl

* 3) Quick sanity checks
display "Weighted median used = " med_pc
tab poors
sum peraeq_cons if poors==1
sum peraeq_cons if poors==0
*/

/*
local time_avg " n_rate_w good fair  ha_planted herbicide pesticide org_fert irrigation flat_slope slope_slope"

foreach x in `time_avg' {

	bysort hhid : egen TAvg_`x' = mean(`x')

}
*/




*use "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\child.dta", clear

use "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\child.dta", clear //everything


gen lperaeq_cons_cereal = log(peraeq_cons_cereal)

*gen lperaeq_cons_protein = log(peraeq_cons_protein + 1)
gen value_harvest1 = -value_harvest
gen shockk = (shock==0)
misstable summarize haz peraeq_cons_protein
replace peraeq_cons_protein = 0 if peraeq_cons_protein ==.
gen inc__shock = value_harvest1*shockk

gen lperaeq_cons_veg = log(peraeq_cons_veg)
gen lperaeq_cons = log(peraeq_cons)

gen lproductivity_w = log(productivity_w + 1)

save "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\testingresult.dta", replace ///everything



local time_avg "mrk_dist_w23  year2023  mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker real_tpricefert_cens_mrk value_harvest annual_salary_agwage annual_salary mean_annual_rainfall shock shock1"

foreach x in `time_avg' {

	bysort hhid : egen TAvg_`x' = mean(`x')

}


*******************************************************
*ivreg2
*******************************************************

count
*keep if child ==1
count


preserve
keep if year ==2018
tabstat haz shock shock1 peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)
count
restore


preserve
keep if year ==2023
tabstat haz shock shock1  peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug [w=weight], statistics( mean median sd min max ) columns(statistics)
count
restore


* ln_cv_rain_Mar_June ln_cv_gdd_Mar_June ln_cv_hot_Mar_June ln_cv_temp_Mar shortfall_Mar dev_rain_2017_Mar dev_gdd_2017_Mar dev_hot_2017_Mar ln_cv_rain_Aug_Dec ln_cv_gdd_Aug_Dec ln_cv_hot_Aug_Dec dev_rain_2017_Aug dev_hot_2017_Aug dev_gdd_2017_Aug




gen inc_shock  = value_harvest*shock
gen rain_shock = shortfall_Mar*shock

ivregress 2sls peraeq_cons_protein ///
    (value_harvest inc_shock = shortfall_Mar rain_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
    i.year, vce(cluster hhid)

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock




ivreghdfe peraeq_cons_protein ///
    (value_harvest inc_shock = shortfall_Mar rain_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
    , absorb(hhid year) cluster(hhid)

lincom value_harvest
lincom value_harvest + inc_shock



misstable summarize haz peraeq_cons_protein
replace peraeq_cons_protein = 0 if peraeq_cons_protein ==.

gen lperaeq_cons_protein = log(peraeq_cons_protein + 1)

************************************
*Child height for age**************
***********************************

* Endogenous variables: value_harvest and its interaction with shock
* Instruments: dev_rain_Mar, dev_rain_Aug and their interactions with shock


ivregress 2sls haz ///
    (c.value_harvest c.value_harvest#c.shock = ///
     c.dev_rain_Mar  c.dev_rain_Aug ///
     c.dev_rain_Mar#c.shock c.dev_rain_Aug#c.shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
    i.year, vce(cluster hhid)

estat firststage

* Marginal effect of value_harvest when shock=0
lincom value_harvest

* Marginal effect of value_harvest when shock=1  (if shock is binary)
lincom value_harvest + c.value_harvest#c.shock



ivreghdfe haz ///
    (c.value_harvest c.value_harvest#c.shock = ///
     c.dev_rain_Mar  c.dev_rain_Aug ///
     c.dev_rain_Mar#c.shock c.dev_rain_Aug#c.shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall, ///
    absorb(hhid year) cluster(hhid)

lincom value_harvest
lincom value_harvest + c.value_harvest#c.shock


*************************
*2
*************************


* Endogenous interaction
gen inc_shock = value_harvest*shock

  
* Excluded instruments interacted with shock
gen zMar_shock = dev_rain_Mar*shock
gen zAug_shock = dev_rain_Aug*shock

eststo clear
ivregress 2sls lperaeq_cons_protein ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr TAvg_good TAvg_fair TAvg_total_qty TAvg_real_hhvalue ///
    TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker TAvg_mean_annual_rainfall ///
    i.year, vce(cluster hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\result\protein.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock


eststo clear
ivreghdfe lperaeq_cons_protein ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr TAvg_good TAvg_fair TAvg_total_qty TAvg_real_hhvalue ///
    TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker TAvg_mean_annual_rainfall ///
    , absorb(hhid year) cluster(hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\result\protein.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

lincom value_harvest
lincom value_harvest + inc_shock





*************************
*2 HAZ
*************************


eststo clear
ivregress 2sls haz ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr TAvg_good TAvg_fair TAvg_total_qty TAvg_real_hhvalue ///
    TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker TAvg_mean_annual_rainfall ///
    i.year, vce(cluster hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\result\haz.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock



ivreghdfe haz ///
    (value_harvest inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr TAvg_good TAvg_fair TAvg_total_qty TAvg_real_hhvalue ///
    TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker TAvg_mean_annual_rainfall ///
    , absorb(hhid year) cluster(hhid)

lincom value_harvest
lincom value_harvest + inc_shock







************************************************************************************************************************
/************************************************************
*Interpretation 
************************************************************
Following Duflo (2003), we measure child nutritional status using height-for-age z-scores constructed from WHO growth standards, which capture long-term nutritional deprivation accumulated during early childhood.
Child nutritional status is measured using height-for-age z-scores (HAZ) constructed from the WHO (2006) Child Growth Standards. Height measurements are averaged across repeated measures, age is expressed in months, and observations outside WHO biological plausibility bounds are excluded.
Mean HAZ = −0.26

Median ≈ −0.30

SD ≈ 2.15

Min ≈ −5.9

Max ≈ +6 (after WHO bounds)

Obs ≈ 1,988

Average child height-for-age improved by about 0.25 standard deviations between 2019 and 2023.

Harvest value is positively associated with child height-for-age in non-shock years (β₁ = 0.318). However, this association is significantly weaker during shock years, as indicated by the negative interaction term (β₃ = −0.118). The implied marginal effect of harvest value during shocks is β₁ + β₃ = 0.200, suggesting that adverse shocks reduce the nutritional returns to household resources by roughly 37%



Descriptive statistics indicate an improvement in average child nutritional status over time. Mean height-for-age z-scores increased from −0.55 in 2019 to −0.30 in 2023, corresponding to an average gain of approximately 0.25 standard deviations. While this suggests improved nutritional outcomes, children in the sample remain below the WHO reference standard on average.

b1 When shock = 0, higher harvest value (higher income/resources) should improve long-term child nutrition → higher HAZ.

b2 Holding harvest value at its baseline (formally at 0; practically at "low"), a shock should reduce HAZ through lower food/protein intake, worse health environment, stress, etc.

b3 

A one-standard-deviation increase in harvest value improves child height-for-age by approximately 0.32 standard deviations in non-shock years. Experiencing an adverse shock reduces height-for-age by about 0.31 standard deviations, and the nutritional returns to income are significantly attenuated during shock periods. During shock years, the nutritional "return" to harvest value is smaller by 0.118 HAZ standard deviations (per unit of harvest value), compared with non-shock years. Shocks weaken the ability of income/harvest resources to translate into improved long-run child nutrition.
In shock periods, a one-unit increase in harvest value is associated with a 0.200 SD increase in child HAZ (holding other controls constant).

Compare to the non-shock years:

No shock: 
0.318
0.318 SD gain in HAZ per unit harvest value

Shock: 
0.200
0.200 SD gain in HAZ per unit harvest value
Households' resources matter for child nutrition, but shocks substantially erode the protective role of those resources
************************************************************************************************************************
(iii) B3
Core interpretation (this is the sentence you want)

value of harvest = 0.0387
inc_shock = −0.0264
shock = 0.02

The negative and statistically significant coefficient on the interaction between income and shock indicates that adverse harvest shocks substantially weaken the ability of additional agricultural income to translate into higher child protein consumption.

The income–protein gradient is significantly flatter among households that experienced harvest losses due to floods, pests, drought, or poor rains in the previous year.

This is exactly consistent with standard coping behavior:

households smooth calories first,

protein (animal-source foods) is adjusted last,

liquidity constraints and competing needs dominate.

Agricultural income significantly increases child protein expenditure, but this relationship is substantially weaker among households that suffered harvest losses from flood/pest/drought/poor rainfall in the previous year. The negative interaction implies that adverse shocks impair households' ability to translate additional income into improved child diet quality.
*************
overall
************
Plugging in your estimates:

No shock (shock = 0) ie ∂Income
                        ∂Protein
Income=0.0387


Shock household (shock = 1)  ie ∂Income
								∂Protein

Income= 0.0387 − 0.0264 = 0.0123

Income still increases child protein expenditure under shock, but the effect is much smaller.

Extension will be to check for household below poverty line and household that have only children
************************************************************************************************************************


************************************************************************************************************************
How to interpret all three coefficients together (important)

(i) value_harvest (β₁ > 0, significant)   Among households that did not experience a prior harvest shock, increases in agricultural income lead to significant increases in child protein expenditure.
This confirms:

income is a key driver of diet quality,

protein is a normal good for children in these households.

************************************************************************************************************************




************************************************************************************************************************
How to interpret all three coefficients together (important)

(i) value_harvest (β2 < 0, significant)   


At very low (near-zero) levels of agricultural income, experiencing a harvest shock reduces child protein expenditure.

This is perfectly plausible and often expected.

************************************************************************************************************************





*/
************************************************************************************************************************





************************************************************************************************************************
*Model Specification Using Children Protein Consumption 

*Currently, what we have is for households that have children. You need to merge child data with protein consumption and only calculate those that are less than 8 years old. that is the dependent variable.

*For health Outcomes, you merge child data with health data and obtain a binary for age below 8 or for observations that have child==1. replace missing otherwise. that is also the dependent variable.

* For the independent variables. we use multiple income proxy. 1. value of crop harvest  2. annual_salary_agwage 3. value of harvest + annual_salary_agwage

*For IV estimation . we use RD for four seasons and their squared term. The result agrees. The first equation shows a negative relationship between income and rainfall deviation. We use Hausman test. 

*************
*Robustness
*************
*Only restrict our sample to only households that have children between 0 and 8 years. The results largely confirms what we have previously.
************************************************************************************************************************
gen shockk = (shock==0)



ivregress 2sls hazz ///
    (c.value_harvest1 c.value_harvest#c.shock = ///
     c.dev_rain_Mar  c.dev_rain_Aug ///
     c.dev_rain_Mar#c.shock c.dev_rain_Aug#c.shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
    i.year, vce(cluster hhid)

estat firststage

* Marginal effect of value_harvest when shock=0
lincom value_harvest

* Marginal effect of value_harvest when shock=1  (if shock is binary)
lincom value_harvest + c.value_harvest#c.shock



ivreghdfe haz ///
    (c.value_harvest1 c.value_harvest#c.shock = ///
     c.dev_rain_Mar  c.dev_rain_Aug ///
     c.dev_rain_Mar#c.shock c.dev_rain_Aug#c.shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall, ///
    absorb(hhid year) cluster(hhid)

lincom value_harvest
lincom value_harvest + c.value_harvest#c.shock



gen inc_shock = value_harvest * shock
gen rain_shock = shortfall_Mar * shock

estat firststage

ivregress 2sls peraeq_cons_protein (value_harvest inc_shock = shortfall_Mar rain_shock)  shock i.year, vce(cluster hhid)


ivregress 2sls peraeq_cons_protein (value_harvest inc_shock = shortfall_Mar rain_shock)  shock mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall i.year, vce(cluster hhid)

ivregress 2sls peraeq_cons_protein (value_harvest inc_shock = shortfall_Mar rain_shock)  shock mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall TAvg_mrk_dist_w  TAvg_real_maize_price_mr TAvg_good TAvg_fair  TAvg_total_qty TAvg_real_hhvalue TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker TAvg_value_harvest TAvg_shock TAvg_mean_annual_rainfall i.year, vce(cluster hhid)


xtset hhid year

xtivreg peraeq_cons_protein (value_harvest inc_shock = shortfall_Mar rain_shock)  shock  i.year, fe 


xtivreg peraeq_cons_protein (value_harvest inc_shock = shortfall_Mar rain_shock)  shock mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall i.year, fe vce(robust)

xtivreg peraeq_cons_protein ///
    (value_harvest inc_shock = shortfall_Mar rain_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
    i.year, fe vce(robust)


*************
*Interpretation
*************
/*
*b3​<0: income increases protein spending less among shock households. shock is more damaging at higher income levels in expenditure terms (because the gap grows with income). That doesn't mean richer households suffer more in welfare—just that the protein spending difference is larger. 

*instrument affects protein primarily through harvest income, and you control for channels like prices/market access, and the rainfall measure used as instrument is timed so it predicts harvest income but is not just proxying food scarcity at consumption time.


*b3>0: income increases protein spending more among shock households.

Justification for using 2sls
"Harvest value is subject to substantial measurement error due to recall bias, crop loss misreporting, and price imputation. Classical measurement error attenuates OLS and FE estimates. We therefore instrument harvest value using rainfall deviations during the planting season, which strongly predict true agricultural income but are orthogonal to measurement error."



*/
*annual_salary_agwage TAvg_annual_salary_agwage annual_salary TAvg_annual_salary value_harvest TAvg_value_harvest
************************************************************************************************************************
*Model Specification Using Distance 
************************************************************************************************************************
*-----------------------------
* DID regression without controls
*-----------------------------

gen interaction = value_harvest*shock

eststo clear
areg peraeq_cons_protein interaction shock  value_harvest TAvg_value_harvest TAvg_shock, absorb(ea) cluster(hhid)
eststo model1
*no controls
areg peraeq_cons_protein  interaction shock  value_harvest   mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall, absorb(ea) cluster(hhid)
eststo model2

areg peraeq_cons_protein  interaction shock  value_harvest TAvg_shock  mean_annual_rainfall TAvg_value_harvest TAvg_mean_annual_rainfall    mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker TAvg_mrk_dist_w  TAvg_real_maize_price_mr TAvg_good TAvg_fair  TAvg_total_qty TAvg_real_hhvalue TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker, absorb(ea) cluster(hhid)
eststo model3
*-----------------------------
* Export all results into one DOCX file
*-----------------------------
esttab m* using "C:\Users\obine\Music\Documents\Project_25\market\Marketcereal02.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))





///look at it by post planting and post harvest
areg  value_harvest  shortfall_Mar   mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker, absorb(ea) cluster(hhid)
 predict value, xb
 sum value, detail
local time_avg "value"

foreach x in `time_avg' {

	bysort hhid : egen TAvg_`x' = mean(`x')

}
 gen interact = value*shock
*-----------------------------
* Second Stage
*-----------------------------

eststo clear
areg peraeq_cons_protein interact shock  value TAvg_value TAvg_shock, absorb(ea) cluster(hhid)
eststo model1
*no controls
areg peraeq_cons_protein  interact shock  value   mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall, absorb(ea) cluster(hhid)
eststo model2

areg peraeq_cons_protein  interact shock  value TAvg_value TAvg_shock  mean_annual_rainfall TAvg_value_harvest TAvg_mean_annual_rainfall    mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker TAvg_mrk_dist_w  TAvg_real_maize_price_mr TAvg_good TAvg_fair  TAvg_total_qty TAvg_real_hhvalue TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker, absorb(ea) cluster(hhid)
eststo model3


*-----------------------------
* 2 stage least square
*-----------------------------
ivregress 2sls lperaeq_cons_protein mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker  i.zone  (value_harvest = shortfall_Mar ), vce(cluster hhid)

ivregress 2sls lperaeq_cons_protein mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker  i.ea  (value_harvest = shortfall_Mar ), vce(robust)

**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************************************************************************************************







/*
preserve
keep if year ==2018
sum hrs_wage_off_farm, detail
tabstat nworker_wage_off_farm  nworker_wage_on_farm  hrs_wage_off_farm hrs_wage_on_farm sdi1 peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg ha_planted field_size quant_harv_kg yield_plot value_harvest maize_price_mr real_maize_price_mr total_qty n_kg n_rate tpricefert_cens_mrk real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue productivity productivity_w household_diet_cut_off1 household_diet_cut_off2 totcons_pc peraeq_cons total_cons hh_members number_foodgroup input_ratio output_ratio soil_qty_rev2 good fair poor good_soil_plant fair_soil_plant poor_soil_plant mrk_dist_w num_mem hh_headage femhead attend_sch worker hrs_ag_activ mean_annual_rainfall [w=weight], statistics( mean median sd min max ) columns(statistics)
count
restore


preserve
keep if year ==2023
sum hrs_wage_off_farm, detail
tabstat nworker_wage_off_farm  nworker_wage_on_farm  hrs_wage_off_farm hrs_wage_on_farm  sdi1 peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg ha_planted field_size quant_harv_kg yield_plot value_harvest maize_price_mr real_maize_price_mr total_qty n_kg n_rate tpricefert_cens_mrk real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue productivity productivity_w household_diet_cut_off1 household_diet_cut_off2 totcons_pc peraeq_cons total_cons hh_members number_foodgroup input_ratio output_ratio soil_qty_rev2 good fair poor good_soil_plant fair_soil_plant poor_soil_plant mrk_dist_w num_mem hh_headage femhead attend_sch worker hrs_ag_activ mean_annual_rainfall [w=weight], statistics( mean median sd min max ) columns(statistics)
count
restore
***********************************
*Rainfall Deviation
***********************************
/********************************************************************
A) Merge rainfall (hhid + rain_YYYY_MM) into household dataset
   then compute Paxson-style rainfall deviations at HH level.
********************************************************************/

global climate "C:\Users\obine\Music\Documents\food_secure\dofile\original\pp_only\CHIRPS"

*--------------------------------------------------------------*
* 1. Load household rainfall dataset (HH level rainfall TS)
*--------------------------------------------------------------*
use "$climate\Nigeria_y4_hh_coordinates_rainfall_TS_monthly.dta", clear

* Rename rainfall variables to avoid name conflicts after merge
foreach var of varlist rain_2007_01 - rain_2023_12 {
    rename `var' hh_`var'
}

* Keep only what you need to merge (safer)
keep hhid ea hh_rain_2007_01-hh_rain_2023_12

* Save temporary file of household rainfall
tempfile hh_rain
save `hh_rain', replace


*--------------------------------------------------------------*
* 2. Load plot-level dataset and merge HH rainfall by hhid
*--------------------------------------------------------------*
use "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_all_plots.dta", clear

merge m:1 hhid using `hh_rain'
drop _merge

*--------------------------------------------------------------*
* 3. Transfer household rainfall into plot rainfall variables
*--------------------------------------------------------------*
foreach var of varlist hh_rain_2007_01 - hh_rain_2023_12 {
    local new = subinstr("`var'", "hh_", "", .)   // remove hh_ prefix
    gen `new' = `var'
}

*--------------------------------------------------------------*
* 4. Remove household-prefixed rainfall variables
*--------------------------------------------------------------*
drop hh_rain_2007_01 - hh_rain_2023_12


/********************************************************************
PAXSON-STYLE RAINFALL DEVIATIONS (HOUSEHOLD/LOCATION MEAN OVER YEARS)
- Build seasonal rainfall totals per year (by plot obs but identical
  within household since rainfall was merged at HH level).
- Compute long-run LOCATION mean across years.
- Deviation = seasonal rainfall - long-run location mean for that season.
********************************************************************/

*--------------------------------------------------------------*
* 5. Define location id for "regional" mean (Paxson)
*    Use ea (recommended). If you prefer state/LGA, change it here.
*--------------------------------------------------------------*
local locid ea

*--------------------------------------------------------------*
* 6. OPTIONAL: drop the extra year if you don't want it
*    You said you drop 2023 later; we can do it now to match your loop.
*--------------------------------------------------------------*
drop rain_2023_*


*--------------------------------------------------------------*
* 7. Create SEASONAL TOTALS by year (2007–2022)
*    Seasons: Jan–Mar, Apr–Jun, Jul–Sep, Oct–Dec
*--------------------------------------------------------------*
forvalues yr = 2007/2022 {
    egen R1_`yr' = rowtotal(rain_`yr'_01 rain_`yr'_02 rain_`yr'_03)
    egen R2_`yr' = rowtotal(rain_`yr'_04 rain_`yr'_05 rain_`yr'_06)
    egen R3_`yr' = rowtotal(rain_`yr'_07 rain_`yr'_08 rain_`yr'_09)
    egen R4_`yr' = rowtotal(rain_`yr'_10 rain_`yr'_11 rain_`yr'_12)
}

*--------------------------------------------------------------*
* 8. Compute long-run LOCATION MEAN for each season across years
*    (requires reshape long)
*--------------------------------------------------------------*
preserve
keep hhid `locid' R1_* R2_* R3_* R4_*

* Reshape to long over year
reshape long R1_ R2_ R3_ R4_, i(hhid) j(year)

rename R1_ R1
rename R2_ R2
rename R3_ R3
rename R4_ R4

* Long-run location means across years (Paxson baseline)
bys `locid': egen mean_R1 = mean(R1)
bys `locid': egen mean_R2 = mean(R2)
bys `locid': egen mean_R3 = mean(R3)
bys `locid': egen mean_R4 = mean(R4)

* Paxson-style deviations and squared deviations
gen dev_R1 = R1 - mean_R1
gen dev_R2 = R2 - mean_R2
gen dev_R3 = R3 - mean_R3
gen dev_R4 = R4 - mean_R4

gen dev_R1_sq = dev_R1^2
gen dev_R2_sq = dev_R2^2
gen dev_R3_sq = dev_R3^2
gen dev_R4_sq = dev_R4^2

* Keep only instruments
keep hhid year dev_R1 dev_R2 dev_R3 dev_R4 dev_R1_sq dev_R2_sq dev_R3_sq dev_R4_sq

* Reshape wide so you get dev_R2_2022 etc.
reshape wide dev_R1 dev_R2 dev_R3 dev_R4 dev_R1_sq dev_R2_sq dev_R3_sq dev_R4_sq, i(hhid) j(year)

tempfile paxson_dev
save `paxson_dev', replace
restore

*--------------------------------------------------------------*
* 9. Merge Paxson deviations back onto the plot dataset by hhid
*--------------------------------------------------------------*
merge m:1 hhid using `paxson_dev'
drop if _merge==2
drop _merge


/********************************************************************
From here, you can KEEP your existing CV/shortfall code if you want.
The new Paxson instruments are now in your plot dataset:
  dev_R2_2022  dev_R2_sq_2022  etc.
You can use them as instruments for income in your plot regressions.
********************************************************************/
*/






















***********************************
*Regression
***********************************


use "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\testingresult.dta", clear //everything

local time_avg "mrk_dist_w23  year2023  mrk_dist_w  real_maize_price_mr good fair  total_qty real_hhvalue field_size num_mem hh_headage femhead attend_sch worker real_tpricefert_cens_mrk value_harvest annual_salary_agwage annual_salary mean_annual_rainfall shock shock1"

foreach x in `time_avg' {

	bysort hhid : egen TAvg_`x' = mean(`x')

}


*******************************************************
*ivreg2
*******************************************************

count
*keep if child ==1
count


preserve
keep if year ==2018
tabstat haz shock shock1 peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)
count
restore


preserve
keep if year ==2023
tabstat haz shock shock1  peraeq_cons_protein annual_salary_agwage annual_salary value_harvest field_size num_mem mean_annual_rainfall rainfall_shortfall shortfall_Mar shortfall_Aug  dev_rain_Mar dev_rain_Aug [w=weight], statistics( mean median sd min max ) columns(statistics)
count
restore



* Endogenous interaction
gen inc_shock = value_harvest1*shock

  
* Excluded instruments interacted with shock
gen zMar_shock = dev_rain_Mar*shock
gen zAug_shock = dev_rain_Aug*shock


eststo clear
ivregress 2sls haz ///
    (inc_shock value_harvest1  = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr TAvg_good TAvg_fair TAvg_total_qty TAvg_real_hhvalue ///
    TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker TAvg_mean_annual_rainfall ///
    i.year, vce(cluster hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\result\haz.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

estat firststage


gen lperaeq_cons_protein = log(peraeq_cons_protein + 1)


eststo clear
ivregress 2sls lperaeq_cons_protein ///
    (inc__shock value_harvest1  = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shockk mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_real_maize_price_mr TAvg_good TAvg_fair TAvg_total_qty TAvg_real_hhvalue ///
    TAvg_field_size TAvg_num_mem TAvg_hh_headage TAvg_femhead TAvg_attend_sch TAvg_worker TAvg_mean_annual_rainfall ///
    i.year, vce(cluster hhid)
eststo model1
*esttab m* using "C:\Users\obine\Music\Documents\Project_26\result\haz.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

estat firststage












************************************************************
* ROBUSTNESS IV: 2022 fertilizer price spike exposure design 03/26/2026
************************************************************

* 1. Construct pre-2022 fertilizer intensity
gen fert_intensity = fert_qty/field_size if field_size>0 & field_size<.

preserve
keep if inlist(year, 2012, 2015, 2019)
bysort hhid: egen exposure_fert_pre = mean(fert_intensity)
keep hhid exposure_fert_pre
bysort hhid: keep if _n==1
tempfile exposurefert
save `exposurefert'
restore

merge m:1 hhid using `exposurefert', nogen

* 2. Create post-shock IV
gen post2023 = (year==2023)
gen z_fertshock = post2023*exposure_fert_pre

* 3. Endogenous interaction and interaction IV
gen inc_shock = value_harvest*shock
gen z_fertshock_shock = z_fertshock*shock

* 4. IV regression: protein expenditure
ivreghdfe peraeq_cons_protein ///
    (value_harvest inc_shock = z_fertshock z_fertshock_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall, ///
    absorb(hhid year) cluster(hhid)

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock

* 5. IV regression: HAZ
ivreghdfe haz ///
    (value_harvest inc_shock = z_fertshock z_fertshock_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall, ///
    absorb(hhid year) cluster(hhid)

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock

* 6. Placebo pre-trend checks
gen y2015 = (year==2015)
gen y2019 = (year==2019)
gen placebo2015 = y2015*exposure_fert_pre
gen placebo2019 = y2019*exposure_fert_pre

reghdfe value_harvest placebo2015 placebo2019 ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall, ///
    absorb(hhid year) cluster(hhid)

	
	
	
	
************************************************************
* ROBUSTNESS IV: 2022 community fertilizer price spike exposure design 03/26/2026
************************************************************
	
	
gen fert_intensity = fert_qty/field_size if field_size>0 & field_size<.

preserve
keep if inlist(year,2012,2015,2019)
collapse (mean) comm_fert_pre=fert_intensity, by(clusterid year)
collapse (mean) exposure_comm_pre=comm_fert_pre, by(clusterid)
tempfile commexp
save `commexp'
restore

merge m:1 clusterid using `commexp', nogen

gen post2023 = (year==2023)
gen z_commshock = post2023*exposure_comm_pre
gen inc_shock = value_harvest*shock
gen z_commshock_shock = z_commshock*shock















************************************************************
* STEP 6: Placebo pre-trend interactions
************************************************************

gen y2015 = (year==2015)
gen y2019 = (year==2019)

gen placebo2015 = y2015*exposure_fert_pre
gen placebo2019 = y2019*exposure_fert_pre


reghdfe value_harvest placebo2015 placebo2019 ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall, ///
    absorb(hhid year) cluster(hhid)
	
	
	

/*
gen value_maize = qty_maize * price_maize if qty_maize<. & price_maize<.
gen value_rice  = qty_rice  * price_rice  if qty_rice<.  & price_rice<.
gen value_veg   = qty_veg   * price_veg   if qty_veg<.   & price_veg<.

gen value_marketcrop = value_maize + value_rice + value_veg
gen marketcrop_share = value_marketcrop/value_harvest if value_harvest>0 & value_harvest<.
gen value_harvest = value_maize + value_rice + value_veg + value_cassava + value_yam


gen value_marketcrop = sales_maize + sales_rice + sales_veg
gen marketcrop_share = value_marketcrop/value_harvest if value_harvest>0 & value_harvest<.



gen value_marketcrop_sales = sales_maize + sales_rice + sales_veg
gen marketcrop_sales_share = value_marketcrop_sales/value_harvest if value_harvest>0 & value_harvest<.





*/
	
	


************************************************************
* EXAMPLE: MARKET-CROP SHARE IV
************************************************************

* Example market crops: maize, rice, vegetables
* Replace these with your real variable names

gen value_maize = qty_maize*price_maize if qty_maize<. & price_maize<.
gen value_rice  = qty_rice*price_rice   if qty_rice<.  & price_rice<.
gen value_veg   = qty_veg*price_veg     if qty_veg<.   & price_veg<.

gen value_marketcrop = value_maize + value_rice + value_veg

* if value_harvest does not already exist, create total harvest value
* gen value_harvest = value_maize + value_rice + value_veg + value_cassava + value_yam

gen marketcrop_share = value_marketcrop/value_harvest if value_harvest>0 & value_harvest<.

* Pre-2022 exposure
preserve
keep if inlist(year, 2012, 2015, 2019)
bysort hhid: egen exposure_mkt_pre = mean(marketcrop_share)
keep hhid exposure_mkt_pre
bysort hhid: keep if _n==1
tempfile exposuremkt
save `exposuremkt'
restore

merge m:1 hhid using `exposuremkt', nogen

* Post-shock IV
gen post2023 = (year==2023)
gen z_mktshock = post2023*exposure_mkt_pre

* Endogenous interaction and interaction IV
gen inc_shock = value_harvest*shock
gen z_mktshock_shock = z_mktshock*shock

* IV regression: protein expenditure
ivreghdfe peraeq_cons_protein ///
    (value_harvest inc_shock = z_mktshock z_mktshock_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall, ///
    absorb(hhid year) cluster(hhid)

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock

* IV regression: HAZ
ivreghdfe haz ///
    (value_harvest inc_shock = z_mktshock z_mktshock_shock) ///
    shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
    field_size num_mem hh_headage femhead attend_sch worker mean_annual_rainfall, ///
    absorb(hhid year) cluster(hhid)

estat firststage
lincom value_harvest
lincom value_harvest + inc_shock