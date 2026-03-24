



*******************************************************************************
*Wave 4
*******************************************************************************




***************************************************
*starting
***************************************************


global Nigeria_GHS_W4_raw_data 		"C:\Users\obine\Music\Documents\Smallholder lsms STATA\NGA_2018_GHSP-W4_v03_M_Stata12 (1)"
global Nigeria_GHS_W4_created_data  "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\wave_four"


/********************************************************************
WHO 2006 Height-for-Age Z-score (HAZ)
Based on zscore06 (WHO Child Growth Standards)
********************************************************************/
use "${Nigeria_GHS_W4_raw_data}\sect4a_harvestw4.dta", clear

merge 1:1 hhid indiv using "${Nigeria_GHS_W4_raw_data}/sect1_harvestw4.dta", nogen

/********************************************************************
WHO 2006 Height-for-Age Z-score (HAZ)
Correct age source: s1q6 (age in completed years → months)
********************************************************************/

*--------------------------------------------------------------*
* 0. Keep children under 5 years
*--------------------------------------------------------------*
keep if s4aq51 == 1

*--------------------------------------------------------------*
* 1. Age in months (CORRECT: convert years → months)
*--------------------------------------------------------------*
gen age_months = s1q4 * 12
replace age_months = . if age_months < 0 | age_months > 59

*--------------------------------------------------------------*
* 2. Sex (WHO default: 1 = boy, 2 = girl)
*--------------------------------------------------------------*
gen sex = s1q2
replace sex = . if sex != 1 & sex != 2

*--------------------------------------------------------------*
* 3. Height in centimeters (average of up to 3 measures)
*--------------------------------------------------------------*
egen height_cm = rowmean(s4aq53_1 s4aq53_2  s4aq53_3)

* Drop biologically impossible heights for 0–59 months
*replace height_cm = . if height_cm < 45 | height_cm > 120

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
replace meas = 2 if s4aq53b == 1   // standing height
replace meas = 1 if s4aq53b == 2   // recumbent length

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

collapse (mean) haz (max) s4aq51, by(hhid)

gen haz2 = haz
replace haz2 = 3.06 if haz > 3.06 
sum haz, detail
sum haz2, detail
save  "${Nigeria_GHS_W4_created_data}/haz.dta", replace


********************************************************************************
* AG FILTER *
********************************************************************************

use "${Nigeria_GHS_W4_raw_data}\sect15a_harvestw4.dta", clear

*gen shock = 1 if s15aq1==1 & shock_cd ==12 | shock_cd ==13 | shock_cd ==14
gen ag = 1 if shock_cd ==12 | shock_cd ==13 | shock_cd ==14
gen shock1 if ag = 1 & s15aq1==1
replace shock1 = 0 if shock1==.

gen shock =1 if (s15aq1==1)
replace shock = 0 if shock==.
collapse (max) shock shock1, by (hhid)
tab shock
tab shock1
save  "${Nigeria_GHS_W4_created_data}/shock.dta", replace







********************************************************************************
* AG FILTER *
********************************************************************************

use "${Nigeria_GHS_W4_raw_data}\nga_householdgeovars_y4.dta", clear






save  "${Nigeria_GHS_W4_created_data}/geovariables.dta", replace




********************************************************************************
* AG FILTER *
********************************************************************************

use "${Nigeria_GHS_W4_raw_data}/sect11a_plantingw4.dta" , clear

keep hhid ag1
rename (ag1) (ag_rainy_18)
save  "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", replace


********************************************************************************
* WEIGHTS *
********************************************************************************

use "${Nigeria_GHS_W4_raw_data}/secta_plantingw4.dta" , clear
*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave4 rural
ren wt_wave4 weight
duplicates report hhid
save  "${Nigeria_GHS_W4_created_data}/weight.dta", replace



********************************************************************************
* HHIDS *
********************************************************************************

use "${Nigeria_GHS_W4_raw_data}/secta_plantingw4.dta" , clear

gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave4 rural
ren wt_wave4 weight
duplicates report hhid
save  "${Nigeria_GHS_W4_created_data}/hhid.dta", replace



*******************************************************************************
*GPS COORDINATES *
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}\nga_householdgeovars_y4.dta", clear
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/hhid.dta", nogen keep(3) 
ren lat_dd_mod latitude
ren lon_dd_mod longitude
keep lga ea latitude longitude
duplicates drop lga ea latitude longitude, force //ea+lga necessary to uniquely identify ea
gen GPS_level = "ea"
save "${Nigeria_GHS_W4_created_data}/ea_coords.dta", replace



********************************************************************************
*HOUSEHOLD'S DIET DIVERSITY SCORE
********************************************************************************
* since the diet variable is available in both PP and PH datasets, we first append the two together
use "${Nigeria_GHS_W4_raw_data}/sect7b_plantingw4.dta" , clear
keep zone state lga sector ea hhid item_cd s7bq1
gen survey="PP"
preserve
use "${Nigeria_GHS_W4_raw_data}/sect10b_harvestw4.dta" , clear
keep zone state lga sector ea hhid item_cd s10bq1
ren  s10bq1  s7bq1 // ren the variable indicating household consumption of food items to harminize accross data set
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
gen adiet_yes=(s7bq1==1)
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
save "${Nigeria_GHS_W4_created_data}/dieatary_diversity.dta", replace






********************************************************************************
*CONSUMPTION
********************************************************************************

********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}/secta_plantingw4.dta", clear
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave4 rural
ren wt_wave4 weight
drop if weight == . 
*DYA.11.21.2020 from the the BID
*"The final sample consisted of 4,976 households of which 1,425 were from the long panel sample and 3,551 from the refresh sample."
*Now sure why we have 5,263 obs in this file.
*It seems that Overall, 34 refresh EAs were inaccessible during the listing period or post-planting visit. 
*The EAs were highly concentrated in the North East and North Central Zones where conflict (insurgency and farmer-herder attacks) were prevalent during this period.
*But these likely show up this this file explaing why with have 287 a additional households.
duplicates report hhid
//merge 1:1 hhid using  "${Nigeria_GHS_W4_created_data}\Nigeria_GHS_W4_weights.dta", keep(2 3) nogen  // keeping hh surveyed
save  "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", replace



********************************************************************************
* INDIVIDUAL IDS *
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}/sect1_plantingw4.dta", clear
gen season="plan"
append using "${Nigeria_GHS_W4_raw_data}/sect1_harvestw4.dta"
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
merge m:1 hhid using  "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", keep(2 3) nogen  // keeping hh surveyed
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_person_ids.dta", replace






********************************************************************************
* HOUSEHOLD SIZE *
********************************************************************************
use "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_person_ids.dta", clear
gen member=1
collapse (max) fhh (sum) hh_members=member, by (hhid)
lab var hh_members "Number of household members"
lab var fhh "1= Female-headed household"
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhsize.dta", replace







*first get adult equivalent
use "${Nigeria_GHS_W4_created_data}\Nigeria_GHS_W4_person_ids.dta", clear
gen adulteq=.
gen gender=female+1
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
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_adulteq.dta", replace











***********
	* Visit 2

use "${Nigeria_GHS_W4_raw_data}/sect11a_harvestw4.dta", clear
append using "${Nigeria_GHS_W4_raw_data}/sect11b_harvestw4.dta"
append using "${Nigeria_GHS_W4_raw_data}/sect11c_harvestw4.dta"
append using "${Nigeria_GHS_W4_raw_data}/sect11d_harvestw4.dta"

gen nfd_ = s11aq2/7 //Per day
replace nfd_ = s11bq4/30 if nfd_==.
replace nfd_ = s11cq6/182.5 if nfd_==.
replace nfd_ = s11dq8/365 if nfd_==.
recode nfd_ (.=0)

keep hhid nfd_ item_cd 
reshape wide nfd_, i(hhid) j(item_cd)
gen nfdtbac = nfd_101+nfd_102 //Tobacco and matches
gen nfdrecre = nfd_103+nfd_105+nfd_322+nfd_506+nfd_507 //"Recreation and culture", here including gambling/lotto and newspapers/magazines
gen nfdfares = nfd_104 //Public transportation
gen nfdwater = nfd_312
gen nfdelec = nfd_305
gen nfdgas = nfd_303
gen nfdkero = nfd_301
gen nfdliqd = nfd_304+nfd_302
gen nfdutil = nfd_509 //Council rates?
egen nfdcloth = rowtotal(nfd_401-nfd_418 nfd_431 nfd_432)
egen nfdfmtn = rowtotal(nfd_311 nfd_323 nfd_324 nfd_325 nfd_330 nfd_419-nfd_427 nfd_433-nfd_439 nfd_501-nfd_505 nfd_508)
gen nfdrepar = nfd_327+nfd_328
gen nfddome = nfd_325
gen nfdpetro = nfd_309
gen nfddiesl = nfd_310
gen nfdcomm = nfd_318+nfd_319+nfd_320+nfd_321+nfd_440+nfd_441
gen nfdinsur = nfd_511+nfd_512+nfd_513
egen nfdfoth =rowtotal(nfd_308 nfd_313-nfd_317 nfd_428 nfd_429 nfd_514 nfd_515 nfd_516 nfd_517) //Added dowry, wedding, and funeral expenses/fines and legal fees
gen nfdfwood = nfd_306
gen nfdchar = nfd_307
gen nfdtrans = 0 //Other transportation. Doesn't appear to have an associated question in W4
gen nfdrnthh = nfd_326+nfd_329
gen nfdhealth = nfd_430 + nfd_510 //Health insurance and non-insurance healthcare expenses
drop nfd_*

merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean)
unab vars : nfd*
foreach i in `vars' {
	gen `i'_def = `i' //reg_def_mean
}
//There are a couple of big-ticket repair bills that likely aren't recurring monthly expenses even though they ask for 30-day recall on those questions. I'm assuming that they should probably be reported as annual expenses rather than monthly ones and rescale to fit.
replace nfdrepar = nfdrepar*30/365 if hhid == 320056 | hhid == 199048
replace nfdrepar_def = nfdrepar*30/365 if hhid == 320056 | hhid == 199048
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
use "${Nigeria_GHS_W4_raw_data}/sect10a_harvestw4.dta", clear
keep if s10aq1==1
gen item_ = s10aq2/7 //Total consumption per day (avg) of prepared foods/beverages
keep hhid item_cd item_ 
reshape wide item_, i(hhid) j(item_cd)
recode item_* (.=0)
gen fdbevby1 = item_6+item_8 
gen fdalcby1 = item_9
gen fdrestby = item_1+item_2+item_3+item_4
gen fdothby1=item_5+item_7
merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean)
gen fdbevby1_def = fdbevby1 //reg_def_mean
gen fdalcby1_def = fdalcby1 //reg_def_mean 
gen fdothby1_def = fdothby1 //reg_def_mean
gen fdrestby_def = fdrestby //reg_def_mean
drop item*
tempfile prepfoods
save `prepfoods', replace


use "${Nigeria_GHS_W4_raw_data}/sect10b_harvestw4.dta", clear
gen obs=1 if s10bq9a != .
keep if s10bq5a!= . | s10bq6a != . | s10bq7a != . 
ren s10bq9a qty_bought 
gen kg_bought = qty_bought*s10bq9_cvn
gen price_kg = s10bq10/kg_bought
//ALT 01.25.21: I've tested this with weighted/unweighted and kg vs unit-based pricing.
//It seems like weighted average per-kgs are producing the most reasonable results, but it is a value judgment.
merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keep(1 3) keepusing(reg_def_mean)
gen price_kg_def = price_kg //reg_def_mean 
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/weight.dta", nogen keep(3) keepusing(weight)

foreach i in ea lga state zone {
	preserve
	bys `i' item_cd : egen obs_`i' = total(obs)
	collapse (median) price_`i' = price_kg price_def_`i' = price_kg_def [aw=weight], by(item_cd `i' obs_`i')
	tempfile food_`i'
	save `food_`i''
	restore
	merge m:1 item_cd `i' using `food_`i'', nogen
}

preserve
bys item_cd : egen obs_country=total(obs)
collapse (median) price_kg price_kg_def [aw=weight], by(item_cd obs_country)
keep item_cd price_kg price_kg_def obs_country
ren price_kg price_country
ren price_kg_def price_def_country
tempfile food_country
save `food_country'
restore

merge m:1 item_cd using `food_country', nogen


foreach i in lga state zone country {
	replace price_kg = price_`i' if price_kg ==. & obs_`i' > 9
	replace price_kg_def = price_def_`i' if price_kg_def == . & obs_`i' > 9
}

gen qty_purch = s10bq2_cvn * s10bq5a 
gen qty_own = s10bq2_cvn * (s10bq6a+s10bq7a)
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
gen fddairby = purch_83+purch_84+purch_110+purch_111+purch_112+purch_113+purch_114+purch_115
gen fddairby_def = purch_83_def + purch_84_def + purch_110_def + purch_111_def + purch_112_def + purch_113_def + purch_114_def + purch_115_def
gen fdfatsby = purch_46+purch_47+purch_48+purch_50+purch_51+purch_52+purch_53+purch_56+purch_63+purch_43+purch_44
gen fdfatsby_def = purch_46_def + purch_47_def + purch_48_def + purch_50_def + purch_51_def + purch_52_def + purch_53_def + purch_56_def + purch_63_def + purch_43_def + purch_44_def
gen fdfrutby = purch_61+purch_62+purch_64+purch_65+purch_66+purch_67+purch_68+purch_69+purch_70+purch_71+purch_601
gen fdfrutby_def = purch_61_def + purch_62_def + purch_64_def + purch_65_def + purch_66_def + purch_67_def + purch_68_def + purch_69_def + purch_70_def + purch_71_def + purch_601_def
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
gen fdfrutpr = own_61+own_62+own_64+own_65+own_66+own_67+own_68+own_69+own_70+own_71+own_601
gen fdfrutpr_def = own_61_def + own_62_def + own_64_def + own_65_def + own_66_def + own_67_def + own_68_def + own_69_def + own_70_def + own_71_def + own_601_def
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
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhsize.dta", nogen keepusing(hh_members)
//Convert to annual to get these aligned with the WB files
gen totcons_pc = totcons/hh_members * 365
gen totcons_adj = totcons_def/hh_members * 365
la var totcons "Total daily consumption per hh, nominal"
la var totcons_def "Total daily consumption per hh, regionally deflated"
la var totcons_pc "Total percap cons exp, annual, nominal, postharverst vals only"
la var totcons_adj "Total percap cons exp, annual, regionally deflated, postharvest vals only"
save "${Nigeria_GHS_W4_created_data}/cons_agg_wave4_visit2.dta", replace





*****************
	*Visit 1

use "${Nigeria_GHS_W4_raw_data}/sect8a_plantingw4.dta", clear
append using "${Nigeria_GHS_W4_raw_data}/sect8b_plantingw4.dta"
append using "${Nigeria_GHS_W4_raw_data}/sect8c_plantingw4.dta"
append using "${Nigeria_GHS_W4_raw_data}/sect11d_harvestw4.dta" //They didn't ask about annual purchases in the post-planting survey; I borrow from the harvest survey to keep everything balanced. These terms will essentially drop out when we take the average for estimated consumption

gen nfd_ = s8q2/7 //Per day
replace nfd_ = s8q4/30 if nfd_==.
replace nfd_ = s8q6/182.5 if nfd_==.
replace nfd_ = s11dq8/365 if nfd_==.
recode nfd_ (.=0)

keep hhid nfd_ item_cd 
reshape wide nfd_, i(hhid) j(item_cd)
gen nfdtbac = nfd_101+nfd_102 //Tobacco and matches
gen nfdrecre = nfd_103+nfd_105+nfd_322+nfd_506+nfd_507 //"Recreation and culture", here including gambling/lotto and newspapers/magazines
gen nfdfares = nfd_104 //Public transportation
gen nfdwater = nfd_312
gen nfdelec = nfd_305
gen nfdgas = nfd_303
gen nfdkero = nfd_301
gen nfdliqd = nfd_304+nfd_302
gen nfdutil = nfd_509 //Council rates?
egen nfdcloth = rowtotal(nfd_401-nfd_418 nfd_431 nfd_432)
egen nfdfmtn = rowtotal(nfd_311 nfd_323 nfd_324 nfd_325 nfd_330 nfd_419-nfd_427 nfd_433-nfd_439 nfd_501-nfd_505 nfd_508)
gen nfdrepar = nfd_327+nfd_328
gen nfddome = nfd_325
gen nfdpetro = nfd_309
gen nfddiesl = nfd_310
gen nfdcomm = nfd_318+nfd_319+nfd_320+nfd_321+nfd_440+nfd_441
gen nfdinsur = nfd_511+nfd_512+nfd_513
egen nfdfoth =rowtotal(nfd_308 nfd_313-nfd_317 nfd_428 nfd_429 nfd_514 nfd_515 nfd_516 nfd_517) //Added dowry, wedding, and funeral expenses
gen nfdfwood = nfd_306
gen nfdchar = nfd_307
gen nfdtrans = 0 //Other transportation. Doesn't appear to have an associated question in W4
gen nfdrnthh = nfd_326+nfd_329
gen nfdhealth = nfd_430 + nfd_510 //Health insurance and non-insurance healthcare expenses
drop nfd_*


merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean)
unab vars : nfd*
foreach i in `vars' {
	gen `i'_def = `i' //reg_def_mean
}

//See visit 2 notes.
replace nfdrepar = nfdrepar*30/365 if hhid == 320056 | hhid == 199048
replace nfdrepar_def = nfdrepar*30/365 if hhid == 320056 | hhid == 199048


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
use "${Nigeria_GHS_W4_raw_data}/sect7a_plantingw4.dta", clear
keep if s7aq1==1
gen item_ = s7aq2/7 //Total consumption per day (avg) of prepared foods/beverages
keep hhid item_cd item_ 
reshape wide item_, i(hhid) j(item_cd)
recode item_* (.=0)
gen fdbevby1 = item_6+item_8 
gen fdalcby1 = item_9
gen fdrestby = item_1+item_2+item_3+item_4
gen fdothby1=item_5+item_7
merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean)
gen fdbevby1_def = fdbevby1 //reg_def_mean
gen fdalcby1_def = fdalcby1 //reg_def_mean 
gen fdothby1_def = fdothby1 //reg_def_mean
gen fdrestby_def = fdrestby //reg_def_mean
drop item*
replace fdrestby = . if hhid == 40172 // ~ N 170k of restaurant purchases
replace fdrestby_def = . if hhid==40172
tempfile prepfoods
save `prepfoods', replace


use "${Nigeria_GHS_W4_raw_data}/sect7b_plantingw4.dta", clear
gen obs = s7bq9a != .
keep if s7bq5a!= . | s7bq6a != . | s7bq7a != . 
ren s7bq9a qty_bought 
gen kg_bought = qty_bought*s7bq9_cvn
gen price_kg = s7bq10/kg_bought

//ALT 01.25.21: I've tested this with weighted/unweighted and kg vs unit-based pricing.
//It seems like weighted average per-kgs are producing the most reasonable results, but it is a value judgment.
//ALT 07.23.21: Quicker version of the geographic medians code.
merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keep(1 3) keepusing(reg_def_mean)
gen price_kg_def = price_kg //reg_def_mean 
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/weight.dta", nogen keep(3) keepusing(weight)
foreach i in ea lga state zone {
	preserve
	bys `i' item_cd : egen obs_`i' = total(obs)
	collapse (median) price_`i' = price_kg price_def_`i' = price_kg_def [aw=weight], by(item_cd `i' obs_`i')
	tempfile food_`i'
	save `food_`i''
	restore
	merge m:1 item_cd `i' using `food_`i'', nogen
}

preserve
bys item_cd : egen obs_country=total(obs)
collapse (median) price_kg price_kg_def [aw=weight], by(item_cd obs_country)
keep item_cd price_kg price_kg_def obs_country
ren price_kg price_country
ren price_kg_def price_def_country
tempfile food_country
save `food_country'
restore

merge m:1 item_cd using `food_country', nogen

foreach i in lga state zone country {
	replace price_kg = price_`i' if price_kg ==. & obs_`i' > 9
	replace price_kg_def = price_def_`i' if price_kg_def == . & obs_`i' > 9
}

gen qty_purch = s7bq2_cvn * s7bq5a 
gen qty_own = s7bq2_cvn * (s7bq6a+s7bq7a)
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
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_water_cons.dta", replace

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
replace fdfishby=0 if hhid == 39004 //One hh reporting consuming N 228k of fish per day.
replace fdfishby_def = 0 if hhid == 39004

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
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhsize.dta", nogen keepusing(hh_members)
//Convert to annual to get these aligned with the WB files
gen totcons_pc = totcons/hh_members * 365
gen totcons_adj = totcons_def/hh_members * 365
la var totcons "Total daily consumption per hh, nominal"
la var totcons_def "Total daily consumption per hh, regionally deflated"
la var totcons_pc "Total percap cons exp, annual, nominal, postplanting vals only"
la var totcons_adj "Total percap cons exp, annual, regionally deflated, postplanting vals only"
save "${Nigeria_GHS_W4_created_data}/cons_agg_wave4_visit1.dta", replace

ren totcons totcons_pp
ren totcons_def totcons_def_pp 
ren totcons_pc totcons_pc_pp
ren totcons_adj totcons_adj_pp
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/cons_agg_wave4_visit2.dta", nogen keepusing(totcons*)
ren totcons totcons_ph
ren totcons_def totcons_def_ph
ren totcons_pc totcons_pc_ph 
ren totcons_adj totcons_adj_ph 
*gen totcons = (totcons_pp+totcons_ph)/2
gen totcons = totcons_pp
gen totcons_def = (totcons_def_pp+totcons_def_ph)/2
gen totcons_pc = (totcons_pc_pp+totcons_pc_ph)/2
gen totcons_adj = (totcons_adj_ph+totcons_pc_pp)/2

merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_adulteq.dta", nogen keep(1 3) keepusing(adulteq)
//merge 1:1 hhid using  "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhsize.dta", nogen keep(1 3)
 
gen daily_peraeq_cons = totcons/adulteq 
gen peraeq_cons = daily_peraeq_cons*365
gen daily_percap_cons = totcons/hh_members
gen percapita_cons = daily_percap_cons*365
gen total_cons = totcons*365

ren totcons_pc totcons_pc_n
ren peraeq_cons peraeq_cons_n
ren total_cons total_cons_n

gen totcons_pc = totcons_pc_n /0.4574889
gen peraeq_cons = peraeq_cons_n /0.4574889
gen total_cons = total_cons_n /0.4574889
  

la var totcons "Total daily consumption per hh, nominal"
la var totcons_def "Total daily consumption per hh, regionally deflated"
la var totcons_pc "Total percap cons exp, annual, nominal"
la var totcons_adj "Total percap cons exp, annual, regionally deflated"

la var percapita_cons "Yearly HH consumption per person"	
la var total_cons "Total yearly HH consumption - harvest"								
la var peraeq_cons "Yearly HH consumption per adult equivalent"				
la var daily_peraeq_cons "Daily HH consumption per adult equivalent"		
la var daily_percap_cons "Daily HH consumption per person" 		
keep hhid adulteq totcons totcons_def totcons_pc totcons_adj percapita_cons daily_percap_cons total_cons peraeq_cons daily_peraeq_cons 
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_consumption2.dta", replace









********************************************************************************
*HOUSEHOLD FOOD PROVISION*
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}/sect12_harvestw4.dta", clear
reshape long s12q6__, i(hhid) j(j)
ren s12q6__ months_food_insec
keep hhid months_food_insec
collapse (sum) months_food_insec, by(hhid)
gen months_food_insec2 = months_food_insec //ALT 02.01.21: The questionnaire asks up to 15 months, but the max is 12 - I think the way the q's were administered was to ask "over the last year" and the greater time range accounts for different survey times
replace months_food_insec=(months_food_insec/12)*6 //Rescale to 6 months as this is the extent of previous waves
la var months_food_insec "Food insecurity, rescaled to 6 months max"
la var months_food_insec2 "Food insecurity over last 12 months"
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_food_insecurity.dta", replace








 ********************************************************************************
* PLOT AREAS *
********************************************************************************
clear
 
 
 
 *************** Plot Size **********************

//ALT IMPORTANT NOTE: As of W4, the implied area conversions for farmer estimated units (including hectares) are markedly different from previous waves. I recommend excluding plots that do not have GPS measured areas from any area-based productivity estimates.
use "${Nigeria_GHS_W4_raw_data}/sect11a1_plantingw4.dta", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using "${Nigeria_GHS_W4_raw_data}/sect11b1_plantingw4.dta", nogen
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W4_raw_data}/secta1_harvestw4.dta", gen(plot_merge)
 *merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1

ren s11aq4aa area_size
ren s11aq4b area_unit
ren sa1q11 area_size2 //GPS measurement, no units in file
//ren sa1q9b area_unit2 //Not in file
ren s11aq4c area_meas_sqm
//ren sa1q9c area_meas_sqm2
gen cultivate = s11b1q27 ==1 


gen field_size= area_size if area_unit==6
replace field_size = area_size*0.0667 if area_unit==4									//reported in plots
replace field_size = area_size*0.404686 if area_unit==5		    						//reported in acres
replace field_size = area_size*0.0001 if area_unit==7									//reported in square meters

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
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"
ren plotid plot_id
replace field_size = 20 if field_size >= 20
*Total land holding including cultivated and rented out
*collapse (sum) field_size, by (hhid plot_id)

*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/weight.dta", gen(wgt)

*merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1
/*
foreach v of varlist  field_size  {
	_pctile `v' [aw=weight] , p(5 99) 
	gen `v'_w=`v'
	replace  `v'_w = r(r1) if  `v'_w < r(r1) &  `v'_w!=.
	replace  `v'_w = r(r2) if  `v'_w > r(r2) &  `v'_w!=.
	local l`v' : var lab `v'
	lab var  `v'_w  "`l`v'' - Winzorized top 5% & bottom 1%"
}
*/
*tab field_size
*tab field_size_w, missing
*sum field_size field_size_w, detail

keep hhid plot_id field_size
*label var land_holding "land holding in hectares"
save "${Nigeria_GHS_W4_created_data}\land_holding_2018.dta", replace






********************************************************************************
*crop unit conversion factors
********************************************************************************
/*ALT: Theoretically this should be unnecessary because conversion factors are now
included in their respective files. However, in practice there is a lot of missing info
and so we need to construct a central conversion factors file like the one provided in W3.
Issues this section is used to address:
	*Known but missing conversion factors
	*Calculating conversion factors for seed (see seed section for why we need this)
	*Units that had conversion factors in previous waves that were not used in W4
	*Conversion factors for units that weren't included but which can be inferred from the literature
*/
use "${Nigeria_GHS_W4_raw_data}/secta3i_harvestw4.dta", clear
append using "${Nigeria_GHS_W4_raw_data}/secta3ii_harvestw4.dta"
append using "${Nigeria_GHS_W4_raw_data}/secta3iii_harvestw4.dta"
replace cropcode=1120 if inrange(cropcode, 1121,1124)
label define CROPCODE 1120 "1120. YAM" , add //all yam cfs are the same
//recode cropcode (2170=2030) //Bananas=plaintains ALT 06.23.2020: Bad idea, because the conversion factors vary a bunch (har har)
ren sa3iq6ii unit
ren sa3iq6_4 size
ren sa3iq6_2 condition
ren sa3iq6_conv conv_fact

replace unit=sa3iiq1c if unit==.
replace size=sa3iiq1d if size==.
replace condition=sa3iiq1b if condition==.  //ALT 02.01.21 Typo; fixed //DYA.11.21.2020  I am not sure why this? sa3iiq1d is "What was the total harvest of [CROP] from all HH's plots? (Size)". Should be sa3iiq1b but this is used below
replace conv_fact=sa3iiq1_conv if conv_fact==.

replace unit=sa3iiiq13c if unit==.
replace size=sa3iiiq13d if size==.
replace condition=sa3iiiq13b if condition==.
replace conv_fact=sa3iiiq13_conv if conv_fact==.


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

//ALT 06.23.2020: Code added for bananas/plantains, oil palm, other missing conversions. Turns out conversions are missing from the tree crop harvest in the next section, and so tree crops are being underreported in the final data.
replace conv_fact=1 if unit==1 //kg
replace conv_fact=0.001 if unit==2 //g

replace conv_fact=25 if size==10 //25kg bag
replace conv_fact=50 if size==11 //50kg bag
replace conv_fact=100 if size==12 //100kg bag

replace conv_fact = 21.3 if unit==160 & cropcode==2230 //Conversion factors for sugar cane, because they are not in the files or basic info doc
replace conv_fact = 2.13 if unit==80 & cropcode==2230
replace conv_fact = 53.905 if unit==170 & cropcode==2230
replace conv_fact = 1957.58 if unit==180 //Estimated weight for a pick-up 
//Banana/Plantain & oil palm conversions from W3
replace conv_fact=0.5 if unit==80 & size==0 & cropcode==2030
replace conv_fact=0.6 if unit==80 & (size==1 | size==.) & cropcode==2030
replace conv_fact=0.7 if unit==80 & size==2 & cropcode==2030
replace conv_fact=0.445 if unit==100 & size==0 & cropcode==2030
replace conv_fact=1.345 if unit==100 & (size==1 | size==.) & cropcode==2030
replace conv_fact=2.12 if unit==100 & size==2 & cropcode==2030
replace conv_fact=5.07 if unit==110 & size==0 & cropcode==2030
replace conv_fact=7.14 if unit==110 & (size==1 | size==.) & cropcode==2030
replace conv_fact=21.62 if unit==110 & size==2 & cropcode==2030

replace conv_fact=0.135 if unit==80 & size==0 & cropcode==2170
replace conv_fact=0.23 if unit==80 & (size==1 | size==.) & cropcode==2170
replace conv_fact=0.34 if unit==80 & size==2 & cropcode==2170
replace conv_fact=0.615 if unit==100 & size==0 & cropcode==2170
replace conv_fact=1.06 if unit==100 & (size==1 | size==.) & cropcode==2170
replace conv_fact=2.1 if unit==100 & size==2 & cropcode==2170
replace conv_fact=3.51 if unit==110 & size==0 & cropcode==2170
replace conv_fact=5.14 if unit==110 & (size==1 | size==.) & cropcode==2170
replace conv_fact=7.965 if unit==110 & size==2 & cropcode==2170

replace conv_fact=5.235 if unit==140 & size==0 & cropcode==2170
replace conv_fact=13.285 if unit==140 & (size==1 | size==.) & cropcode==2170
replace conv_fact=15.972 if unit==140 & size==2 & cropcode==2170
replace conv_fact=3.001 if unit==150 & size==0 & cropcode==2170
replace conv_fact=6.959 if unit==150 & (size==1 | size==.) & cropcode==2170
replace conv_fact=16.11 if unit==150 & size==2 & cropcode==2170

//Oil palm bunch data. Lots of papers report weights, but none report variances, so asessing small/med/large is difficult.
//The lit cites bunch weights anywhere from 15-40 kg, but Nigeria-specific research exclusively cites lower values. Here,
//I use the range from Genotype and genotype by environment (GGE) biplot analysis of fresh fruit bunch yield and yield components of oil palm (Elaeis guineensis Jacq.).
//by Okoye et al (2008) to approximate the field variation.

replace conv_fact=9.5 if unit==100 & size==0 & cropcode==3180
replace conv_fact=14.5 if unit==100 & size==2 & cropcode==3180
replace conv_fact=12 if unit==100 & (size==1 | size==.) & cropcode==3180

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
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_cf.dta", replace



********************************************************************************
*ALL PLOTS
********************************************************************************
/*ALT 08.16.21: Imported the W3 code for this section 
This code is part of a project to create database-style files for use in AgQuery. At the same time,
it simplifies and reduces the ag indicator construction code. Most files generated by the old code
are still constructed (marked as "legacy" files); some files are eliminated where data were consolidated.
*/
	***************************
	*Crop Values
	***************************
	//Nonstandard unit values
use "${Nigeria_GHS_W4_raw_data}/secta3ii_harvestW4.dta", clear
	//Fstat highly insignificant for yam on price, so we'll lump here.
	replace cropcode=1120 if inrange(cropcode, 1121,1124)
	label define CROPCODE 1120 "1120. YAM", add
	keep if sa3iiq3==1
	ren sa3iiq5a qty
	ren sa3iiq1b condition
	ren sa3iiq1c unit
	ren sa3iiq1d size
	ren sa3iiq6 value
	merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", nogen keepusing(weight) keep(3)
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
	tempfile price_unit_country_median
	save `price_unit_country_median'
//Because we have several qualifiers now (size and condition), using kg as an alternative for pricing. Results from experimentation suggests that the kg method is less accurate than using original units, so original units should be preferred.
use "${Nigeria_GHS_W4_raw_data}/secta3ii_harvestW4.dta", clear
	keep if sa3iiq3==1
	replace cropcode=1120 if inrange(cropcode, 1121,1124)
	label define CROPCODE 1120 "1120. YAM", add
	ren sa3iiq5a qty
	ren sa3iiq1b condition
	ren sa3iiq1c unit
	ren sa3iiq1d size
	ren sa3iiq6 value
	merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", nogen keepusing(weight) keep(1 3)
	merge m:1 cropcode unit size condition using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_cf.dta", nogen keep(1 3)
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
	tempfile price_kg_country_median
	save `price_kg_country_median'
 
***************************
	*Plot variables
	***************************
use "${Nigeria_GHS_W4_raw_data}/sect11f_plantingW4.dta", clear
	gen crop_code_11f = cropcode
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W4_raw_data}/secta3i_harvestw4.dta", nogen
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W4_raw_data}/secta3iii_harvestw4.dta", nogen
	//ren cropcode crop_code_a3i 
	ren plotid plot_id
	ren s11fq5 number_trees_planted
	gen use_imprv_seed=s11fq3b==1
	
	gen perm_crop = s11fq0==2
	replace perm_crop = 1 if cropcode==1020 //I don't see any indication that cassava is grown as a seasonal crop in Nigeria
	//replace crop_code_11f=crop_code_a3i if crop_code_11f==.
	//replace crop_code_a3i = crop_code_11f if crop_code_a3i==.
	//gen cropcode =crop_code_11f //Generic level
	replace cropcode = crop_code_11f if cropcode==.
	drop if cropcode == 1010 & ((hhid==50053 & plot_id==2) | (hhid==209107 & plot_id==1)) //Reported as mistaken entries in sa3iq4_os
	recode cropcode (2170=2030) (2142 = 2141) (1121 1122 1123 1124=1120) //Only things that carry over from W3 are bananas/plantains, yams, and peppers. The generic pepper category 2040 in W3 is missing from this wave. //Okay to lump yams for price and unit conversions, not for other things. 
	replace cropcode = 4010 if strpos(sa3iq4_os, "FEED") | regexm(sa3iq4_os, "CONSUMP*TION") | regexm(sa3iq4_os, "ONLY.+LEAVES")
	drop if strpos(sa3iq4_os, "FALLOW") | regexm(sa3iq4_os, "NO.+PLANT") | strpos(sa3iq4_os, "MISTAK")
	label define CROPCODE 1120 "1120. YAM" 4010 "4010. FODDER", add
	la values cropcode CROPCODE
	merge m:1 hhid plot_id using "${Nigeria_GHS_W4_created_data}/land_holding_2018.dta", nogen keep(3) //ALT 05.03.23
	gen percent_field = s11fq1/100
	replace percent_field = s11fq4/100 if percent_field==. 
	recode percent_field field_size (0=.)
	
	bys hhid plot_id : egen tot_pct_planted = sum(percent_field)
	gen miss_pct = percent_field==. 
	bys hhid plot_id : egen tot_miss = sum(miss_pct)
	gen underplant_pct = 1-tot_pct_planted 
	replace percent_field = underplant_pct/tot_miss if miss_pct & underplant_pct > 0 
	replace percent_field = percent_field/tot_pct_planted if tot_pct_planted > 1
	gen ha_planted = percent_field*field_size
	
	gen pct_harvest=1 if sa3iq4b ==2 | sa3iiiq7==1 //Was area planted less than area harvested? 2=No / In the last 12 months, has your household harvested any <Tree Crop>? They don't ask for area harvested, so I assume that the whole area is harvested (not true for some crops)
	replace pct_harvest = sa3iq5/100 if sa3iq5!=. //1075 obs
	replace pct_harvest = 0 if pct_harvest==. & sa3iq4 < 6
	replace pct_harvest = 1 if cropcode==4010 //Assuming fodder crops were fully "harvested"
	gen ha_harvest=ha_planted*pct_harvest
	
	preserve
		gen obs=1
		replace obs=0 if inrange(sa3iq4,1,5) & s11fq0==1
		collapse (sum) obs, by(hhid plot_id cropcode)
		replace obs = 1 if obs > 1
		collapse (sum) crops_plot=obs, by(hhid plot_id)
		tempfile ncrops 
		save `ncrops'
	restore //14 plots have >1 crop but list monocropping; meanwhile 289 list intercropping or mixed cropping but only report one crop
	merge m:1 hhid plot_id using `ncrops', nogen

	
	gen purestand= crops_plot==1 //This includes replanted crops
	bys hhid plot_id : egen permax = max(perm_crop)
	
	gen planting_year = s11fq3_2
	gen planting_month = s11fq3_1
	gen harvest_month_begin = sa3iq4a1
	gen harvest_year_begin = sa3iq4a2
	gen harvest_year_end = sa3iq6c2
	gen harvest_month_end = sa3iq6c1

	
	*renaming unit code for merge
	//ALT 10.14.21: Tree crop harvests are recorded in both s11f (planting) and sa3iii (harvest); thus, it's likely that s11f has a lot of old harvests (range 2010-2018; mean 2017.365) that we wouldn't want to consider here. However, 465 obs note 2018 (vs 300 in harvest questionnaire), so I replace with sa3iii except when sa3iii is empty and the harvest year is 2018
	ren sa3iq6ii unit
	replace unit = sa3iiiq13c if unit==.
	replace unit = s11fq11b if unit==. & s11fq8b==2018 
	ren sa3iq6_4 size
	replace size = sa3iiiq13d if size==.
	replace size = s11fq11c if size==. & s11fq8b==2018
	ren sa3iq6_2 condition
	replace condition = sa3iiiq13b if condition==.
	replace condition = s11fq11d if condition==. & s11fq8b==2018
	ren sa3iq6i quantity_harvested
	replace quantity_harvested = sa3iiiq13a if quantity_harvested==.
	replace quantity_harvested = s11fq11a if quantity_harvested==. & s11fq8b==2018
	*merging in conversion factors
	merge m:1 cropcode unit size condition using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_cf.dta", keep(1 3) nogen //Only 169 obs of units unmerged. 
	replace conv_fact=1 if conv_fact==. & unit==1
	gen quant_harv_kg = quantity_harvested * sa3iq6_conv
	replace quant_harv_kg = quantity_harvested * sa3iiiq13_conv if quant_harv_kg == .
	replace quant_harv_kg = quantity_harvested * conv_fact if quant_harv_kg == .
	//gen quant_harv_kg= quantity_harvested*conv_fact
	ren sa3iq6a val_harvest_est
	replace val_harvest_est = sa3iiiq14 if val_harvest_est==.
	//ALT 09.28.22: I'm going to keep the grower-estimated valuation in here even though it's likely inaccurate for comparison purposes.
	gen val_unit_est = val_harvest_est/quantity_harvested
	gen val_kg_est = val_harvest_est/quant_harv_kg
	merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", nogen keep(1 3)
	gen plotweight = ha_planted*weight
	//IMPLAUSIBLE ENTRIES - at least 100x the typical yield
	foreach var in quantity_harvested quant_harv_kg val_harvest_est val_unit_est val_kg_est {
	replace `var' = . if (hhid == 299005 & plot_id == 2 & cropcode == 1020) | /* 2000 heaps of cassava on 0.003 ha 
	*/ (hhid == 339038 & plot_id == 2 & cropcode == 2190) | /* 5 tons of pumpkins on 0.0075 ha, an area smaller than my apartment
	*/ (hhid == 229068 & plot_id == 2 & cropcode == 1121) | /* 17 tons of yams on 0.144 ha
	*/ (hhid == 120058 & plot_id == 3 & cropcode == 1121) //14 tons of yams on 0.1 ha.
	}
	gen obs=quantity_harvested>0 & quantity_harvested!=.

foreach i in zone state lga ea hhid {
	merge m:1 `i' unit size condition cropcode using `price_unit_`i'_median', nogen keep(1 3)
	merge m:1 `i' cropcode using `price_kg_`i'_median', nogen keep(1 3)
}

merge m:1 unit size condition cropcode using `price_unit_country_median', nogen keep(1 3)
*merge m:1 unit size condition cropcode using `val_unit_country_median', nogen keep(1 3)
merge m:1 cropcode using `price_kg_country_median', nogen keep(1 3)
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
	
	replace price_unit_hh = price_unit if price_unit_hh==.
	replace price_kg_hh = price_kg if price_kg_hh==.
	gen value_harvest = price_unit * quantity_harvested
	replace value_harvest = price_kg * quant_harv_kg if value_harvest == .
	replace value_harvest = val_harvest_est if value_harvest == .
	gen value_harvest_hh= price_unit_hh*quantity_harvested 
	replace value_harvest_hh=price_kg_hh*quant_harv_kg if value_harvest_hh==.
	replace value_harvest_hh=value_harvest if value_harvest==.
	
//A few situations (mainly cocoa) where the grower estimated price is substantially below the area median.	

	//Replacing conversions for unknown units
	replace val_unit_est = value_harvest/quantity_harvested if val_unit_est==.
	replace val_kg_est = value_harvest/quant_harv_kg if val_kg_est == .

preserve
//ALT note to double check and see if the changes to valuation mess this up.
	replace val_kg = val_kg_est if val_kg==.
	collapse (mean) val_kg=price_kg conv_fact, by(hhid cropcode)
	save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_crop_prices_kg.dta", replace //Backup for s-e income.
restore
preserve
	//ALT 02.10.22: NOTE: This should be changed to ensure we get all household values rather than just ones with recorded harvests (although I imagine the number of households that paid in a crop they did not harvest is small)
	replace val_unit = val_unit_est if val_unit==.
	collapse (mean) val_unit=price_unit, by (hhid cropcode unit size condition)
	drop if unit == .
	ren val_unit hh_price_mean
	lab var hh_price_mean "Average price reported for this crop-unit in the household"
	save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_crop_prices_for_wages.dta", replace //This gets used for self-employment income
restore
	//still-to-harvest value
	gen same_unit=unit==sa3iq6d2 & size==sa3iq6d4 & condition==sa3iq6d2a & unit!=.
	replace price_unit = value_harvest/quantity_harvested if same_unit==1 & price_unit==.
	//ALT 05.12.21: I feel like we should include the expected harvest.
	//Addendum 10.14: Unfortunately we can only reliably do this for annual crops because the question for tree crops was asked in the planting survey; estimates are probably not reliable.
	//Addendum to addendum 9.28.22: The plant survey also asks about temporary crops, not just tree crops. This was causing estimated harvests to be far too high.
	//Addendum to addendum 9.30.24: Adding an additional criterion to only include harvests that had been started, some long-haul crops like cassava and yam were probably not intended for harvest this year.
	replace sa3iq6d1 = . if sa3iq6d1 > 19000 //This corrects two plots, one where the household anticipates harvesting 20,000 paint rubbers of peppers (2000x current harvest) and another that anticipates 722,500 bags of rice.
	drop unit size condition quantity_harvested
	ren sa3iq6d2 unit
	ren sa3iq6d4 size
	ren sa3iq6d2a condition
	ren sa3iq6d1 quantity_harvested
	//replace quantity_harvested = . if hhid == 220016 & plot_id==2 & cropcode==1121 //One obs of 2000 pickups on a quarter of a hectare. Planting estimate was 1 pickup; likely a unit typo. //ALT: Excluded by the 9.30.24 update
	gen quant_harv_kg2 = quantity_harvested * sa3iq6d_conv
	replace quant_harv_kg2 = quantity_harvested * conv_fact if same_unit == 1
	drop conv_fact
	merge m:1 cropcode unit size condition using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_cf.dta", nogen keep(1 3)
	replace quant_harv_kg2= quantity_harvested*conv_fact if quant_harv_kg2 == .
	gen val_harv2 = 0
	gen val_harv2_hh=0
	recode quant_harv_kg2 quantity_harvested value_harvest (.=0) //ALT 02.10.22: This is causing people with "still to harvest" values getting missing where they should have something.
	replace val_harv2=quantity_harvested*price_unit if val_harv2==0 & same_unit==1  //Use household price for consistency. (see line 959)
	replace val_harv2=quant_harv_kg*price_kg if val_harv2==0 
	replace val_harv2_hh = quantity_harvested*price_unit_hh 
	replace val_harv2_hh = quant_harv_kg * price_kg_hh if val_harv2_hh==0
	gen missing_unit =val_harv2 == 0

	replace quant_harv_kg = quant_harv_kg+quant_harv_kg2 if sa3iq3==1
	replace quant_harv_kg = quant_harv_kg2 if sa3iq3==1 & quant_harv_kg==. //this annoying two-step here to deal with how stata processes missing values and the desire to avoid introducing spurious 0s.
	replace value_harvest = value_harvest+val_harv2 if sa3iq3==1 
	replace value_harvest = val_harv2 if sa3iq3==1 & value_harvest==.
	replace value_harvest_hh = value_harvest_hh + val_harv2_hh if sa3iq3==1
	replace value_harvest_hh = val_harv2_hh if sa3iq3==1 & value_harvest==.
	replace ha_harvest = ha_planted if sa3iq3==1 & !inlist(quant_harv_kg2,0,.) & !inlist(sa3iq4c, 1, .)
	replace cropcode = 1124 if crop_code_11f==1124 //Removing three-leaved yams from yams. 
	gen lost_crop=inrange(sa3iq4,1,5) & s11fq0==1
	gen lost_drought = sa3iq4==1 | sa3iq4c==2
	gen lost_flood = sa3iq4==2 | sa3iq4c==3
	gen lost_pest = sa3iq4==3 | sa3iq4c==4
	gen no_harvest = sa3iq4 >= 6 & sa3iq4 <=10
	collapse (sum) quant_harv_kg value_harvest* /*val_harvest_est*/ ha_planted ha_harvest number_trees_planted percent_field (max) lost_pest lost_flood lost_drought no_harvest use_imprv_seed, by(zone state lga sector ea hhid plot_id cropcode purestand field_size)
	bys hhid plot_id : gen count_crops = _N
	recode ha_planted (0=.)
	replace purestand = 0 if count_crops > 1 & purestand==1 //Three plots no longer considered monocropped after the disaggregation.
	bys hhid plot_id : egen percent_area = sum(percent_field)
	bys hhid plot_id : gen percent_inputs = percent_field/percent_area
	drop percent_area //Assumes that inputs are +/- distributed by the area planted. Probably not true for mixed tree/field crops, but reasonable for plots that are all field crops
	//Labor should be weighted by growing season length, though. 
	replace ha_harvest=. if (ha_harvest==0 & no_harvest==1) | (ha_harvest==0 & quant_harv_kg>0 & quant_harv_kg!=.)
	replace quant_harv_kg = . if quant_harv_kg==0 & no_harvest==1
	drop no_harvest
	drop if (ha_planted==0 | ha_planted==.) & (ha_harvest==0 | ha_harvest==.) & (quant_harv_kg==0 | quant_harv_kg==.)
	*merge m:1 hhid plot_id using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_decision_makers.dta", nogen keep(1 3) keepusing(dm*)
		//We remove small planted areas from the sample for yield, as these areas are likely undermeasured/underestimated and cause substantial outliers. The harvest quantities are retained for farm income and production estimates. 
	gen ha_harv_yld = ha_harvest if ha_planted >=0.05
	gen ha_plan_yld = ha_planted if ha_planted >=0.05
	
	save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_all_plots.dta",replace




	
	
	


	
*********************************************** 
*Purchased Fertilizer
***********************************************

use "${Nigeria_GHS_W4_raw_data}\secta11c3_harvestw4.dta",clear   
*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1
 //household level variables......... distance to purchase was also asked

*inputid  1= org fert| 2-4 inorg fert
*s11c3q2  1= hhold purchased inputs
*s11c3q4a qty of purchased inputs
*s11c3q4b units of purchased inputs
*s11c3q4_conv conversion factor
*s11c3q5  cost of inputs
*s11c3q6b institute of purchased
*s11c3q7  distance to institute (km)


******conversion to kg


gen input_kg = s11c3q4a*s11c3q4_conv if inputid >=2 & inputid <=4

*br s11c3q4a s11c3q4b s11c3q4_conv input_kg

***getting the qty for inorg fertilizer

gen inorg_fert = input_kg if inputid >=2 & inputid <=4


gen npk = input_kg if inputid ==2  & s11c3q6b== 6
gen urea = input_kg if inputid ==3  & s11c3q6b== 6
gen others = input_kg if inputid ==4  & s11c3q6b== 6

gen total_qty = input_kg if inputid >=2 & inputid <=4 & s11c3q6b== 6

gen npk_adj   = npk * 0.18
gen urea_adj  = urea * 0.46
egen n_kg     = rowtotal(npk_adj urea_adj)

gen p_kg = npk*0.12
gen k_kg = npk*0.11

gen cost_fert = s11c3q5 if inputid >=2 & inputid <=4
gen cost_fert_real = cost_fert if s11c3q6b== 6
*br s11c3q5 inputid cost_fert

gen tpricefert = cost_fert_real/total_qty
tab tpricefert

gen tpricefert_cens = tpricefert 
replace tpricefert_cens = 900 if tpricefert_cens > 900 & tpricefert_cens < .   //winzonrizing bottom 1% figures look too much beyond this
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
gen distance = s11c3q7 if inputid >=2 & inputid <=4
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
replace  total_qty = 3525 if total_qty >= 3525
replace n_kg = 800 if n_kg >=800

gen real_tpricefert_cens_mrk = tpricefert_cens_mrk /0.4574889

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

save "${Nigeria_GHS_W4_created_data}/fert_units.dta", replace






*********************************************** 
*Used Purchased Fertilizer plot variable
***********************************************

use "${Nigeria_GHS_W4_raw_data}/secta11c2_harvestw4.dta", clear

gen qtynpk_fert=s11c2q37a*s11c2q37a_conv 

gen qtyurea = s11c2q38a*s11c2q38a_conv


gen qtyorgfert = s11dq37a*s11c2q37_conv //This looks wrong but it isn't
gen qtyother_fert=s11c2q39a*s11c2q39a_conv 

ren plotid plot_id 
replace qtyurea = 1000 if qtyurea >= 1000 & qtyurea < .
replace qtynpk_fert = 1000 if qtynpk_fert > 1000 & qtynpk_fert < .

//We can estimate how many nutrient units were applied for most fertilizers; dry urea is 46% N and NPK can have several formulations; we go with a weighted average of 18-12-11 based on https://africafertilizer.org/#/en/vizualizations-by-topic/consumption-data/

egen inorg_fert_kg = rowtotal(qtynpk_fert qtyurea qtyother_fert)
gen nitrogen_npk = qtynpk_fert*0.18
gen nitrogen_urea = qtyurea*0.46

egen n_kg_plot = rowtotal(nitrogen_npk nitrogen_urea)




gen  herbicide = (s11c2q10 ==1)
gen  pesticide = (s11c2q1 ==1)
gen  org_fert = (s11dq36 ==1)
gen  animal_tract = (s11c2q19 ==1)
gen  mechanization = (s11c2q27 ==1)



collapse (sum) inorg_fert_kg n_kg_plot  (max) herbicide pesticide org_fert animal_tract mechanization, by( hhid plot_id)

save "${Nigeria_GHS_W4_created_data}/fert_used.dta", replace




***********************************
*Food Prices from Community
*********************************
use "${Nigeria_GHS_W4_raw_data}\sectc2_plantingw4.dta", clear
*rice is 13, maize is 16

*br if item_cd == 20
*br if item_cd ==20 & c2q2==1
tab c2q3 if item_cd ==20 & c2q2==1
tab c2q2 if item_cd==20
tab c2q3 if item_cd ==20
tab c2q3 if item_cd ==13





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

replace maize_price = 500 if maize_price >500 & maize_price<.  //bottom 5%
replace maize_price = 50 if maize_price< 50       ////top 5%



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
save "${Nigeria_GHS_W4_created_data}\food_prices.dta", replace

save "${Nigeria_GHS_W4_created_data}\food_prices.dta", replace

use "${Nigeria_GHS_W4_raw_data}\sect7b_plantingw4.dta", clear
merge m:1 zone state lga sector ea using "${Nigeria_GHS_W4_created_data}\food_prices.dta", keepusing (median_pr_ea median_pr_lga median_pr_state median_pr_zone maize_price_mr)
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
gen rea_maize_price_mr = maize_price_mr  /0.4574889
gen real_maize_price_mr = rea_maize_price_mr
tab real_maize_price_mr
replace real_maize_price_mr = 758 if real_maize_price_mr>=758
sum real_maize_price_mr, detail

sort hhid
save "${Nigeria_GHS_W4_created_data}\food_prices_2018.dta", replace




*****************************
*Household Assests
****************************


use "${Nigeria_GHS_W4_raw_data}\sect5_plantingw4.dta",clear 
*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1
sort hhid item_cd

*s5q1 qty of item
*s5q4 value of item

gen hhasset_value  = s5q4*s5q1
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

gen rea_hhvalue = hhasset_value_w /0.4574889
gen real_hhvalue= rea_hhvalue/1000
sum hhasset_value_w real_hhvalue, detail


keep  hhid real_hhvalue hhasset_value_w

la var real_hhvalue "total value of household asset"
save "${Nigeria_GHS_W4_created_data}\household_asset_2018.dta", replace









*********************************
*Demographics 
*********************************



use "${Nigeria_GHS_W4_raw_data}\sect1_plantingw4.dta",clear 


merge 1:1 hhid indiv using "${Nigeria_GHS_W4_raw_data}\sect2_harvestw4.dta" //, gen(household)

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

 label list S2AQ9

gen pry_edu  = 1 if s2aq9 >= 1 & s2aq9 < 16 & s1q3==1
gen finish_pry = 1 if s2aq9 >= 16 & s2aq9 < 26 & s1q3==1
gen finish_sec  = 1 if s2aq9 >= 26 & s2aq9 & s1q3==1
replace finish_sec  =0 if s2aq9==51 | s2aq9==52 & s1q3==1

replace pry_edu =0 if pry_edu==. & s1q3==1
replace finish_pry  =0 if finish_pry==. & s1q3==1
replace finish_sec =0 if finish_sec==. & s1q3==1
tab pry_edu if s1q3==1 , missing
tab finish_pry if s1q3==1 , missing 
tab finish_sec if s1q3==1 , missing

collapse (sum) num_mem (max)  hh_headage femhead attend_sch  pry_edu finish_pry finish_sec, by (hhid)

merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/weight.dta", gen(wgt)

*merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1



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
save "${Nigeria_GHS_W4_created_data}\demographics_2018.dta", replace

*/


********************************* 
*Labor Age 
*********************************
use "${Nigeria_GHS_W4_raw_data}\sect1_plantingw4.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

keep if ag_rainy_18==1
ren s1q6 hh_age

gen worker = 1
replace worker = 0 if hh_age < 15 | hh_age > 65

tab worker,missing
sort hhid
collapse (sum) worker, by (hhid)
la var worker "number of members age 15 and older and less than 65"
sort hhid

save "${Nigeria_GHS_W4_created_data}\laborage_2018.dta", replace




********************************* 
*Labor Age 
*********************************
use "${Nigeria_GHS_W4_raw_data}\sect1_plantingw4.dta",clear 
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

keep if ag_rainy_18==1
ren s1q6 hh_age

gen child = 1
replace child = 0 if hh_age > 8

tab child,missing
sort hhid
collapse (max) child, by (hhid)
la var child "number of children"
sort hhid
tab child,missing
save "${Nigeria_GHS_W4_created_data}\child18.dta", replace



*******************************
*Soil Quality
*******************************

//ALT IMPORTANT NOTE: As of W4, the implied area conversions for farmer estimated units (including hectares) are markedly different from previous waves. I recommend excluding plots that do not have GPS measured areas from any area-based productivity estimates.
use "${Nigeria_GHS_W4_raw_data}/sect11a1_plantingw4.dta", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using "${Nigeria_GHS_W4_raw_data}/sect11b1_plantingw4.dta", nogen
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W4_raw_data}/secta1_harvestw4.dta", gen(plot_merge)
 
ren s11aq4aa area_size
ren s11aq4b area_unit
ren sa1q11 area_size2 //GPS measurement, no units in file
//ren sa1q9b area_unit2 //Not in file
ren s11aq4c area_meas_sqm
//ren sa1q9c area_meas_sqm2
gen cultivate = s11b1q27 ==1 


gen field_size= area_size if area_unit==6
replace field_size = area_size*0.0667 if area_unit==4									//reported in plots
replace field_size = area_size*0.404686 if area_unit==5		    						//reported in acres
replace field_size = area_size*0.0001 if area_unit==7									//reported in square meters

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
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"

keep zone state lga sector ea hhid plotid field_size

merge 1:1 hhid plotid using "${Nigeria_GHS_W4_raw_data}\sect11b1_plantingw4.dta"
*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1

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
save "${Nigeria_GHS_W4_created_data}\soil_quality_2018.dta", replace









*******************************
*Soil Quality plot
*******************************

//ALT IMPORTANT NOTE: As of W4, the implied area conversions for farmer estimated units (including hectares) are markedly different from previous waves. I recommend excluding plots that do not have GPS measured areas from any area-based productivity estimates.
use "${Nigeria_GHS_W4_raw_data}/sect11a1_plantingw4.dta", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using "${Nigeria_GHS_W4_raw_data}/sect11b1_plantingw4.dta", nogen
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W4_raw_data}/secta1_harvestw4.dta", gen(plot_merge)
 
ren s11aq4aa area_size
ren s11aq4b area_unit
ren sa1q11 area_size2 //GPS measurement, no units in file
//ren sa1q9b area_unit2 //Not in file
ren s11aq4c area_meas_sqm
//ren sa1q9c area_meas_sqm2
gen cultivate = s11b1q27 ==1 


gen field_size= area_size if area_unit==6
replace field_size = area_size*0.0667 if area_unit==4									//reported in plots
replace field_size = area_size*0.404686 if area_unit==5		    						//reported in acres
replace field_size = area_size*0.0001 if area_unit==7									//reported in square meters

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
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.               				
gen gps_meas = (area_meas_sqm!=.)
la var gps_meas "Plot was measured with GPS, 1=Yes"

keep zone state lga sector ea hhid plotid field_size

merge 1:1 hhid plotid using "${Nigeria_GHS_W4_raw_data}\sect11b1_plantingw4.dta"
*merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)

*keep if ag_rainy_18==1

ren s11b1q45 soil_quality
tab soil_quality , missing
order field_size soil_quality hhid 
sort hhid

tab field_size, missing
tab soil_quality if field_size!=., missing

gen good = (soil_quality==1)
gen fair = (soil_quality==2)
gen poor = (soil_quality==3)


gen irrigation = (s11b1q39==1)
tab s11b1q39
gen tractors = (s11b1q11a==1)
tab s11b1q11a
gen flat_slope = (s11b1q46==1)
gen steep_slope = (s11b1q46==4)
gen slope_slope = (s11b1q46==2 | s11b1q46==3 )
tab s11b1q46
ren plotid plot_id
collapse (max) good fair poor irrigation tractors flat_slope steep_slope slope_slope , by (hhid plot_id)
tab good, missing
tab fair, missing
tab poor, missing
save "${Nigeria_GHS_W4_created_data}\soil_quality_2018_plot.dta", replace












/*
********************************************************************************
*SHANNON DIVERSITY INDEX
********************************************************************************




use "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_all_plots.dta", clear
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
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_crop_area_plan.dta", replace





********************************************************************************
*SHANNON DIVERSITY INDEX
********************************************************************************
*Area planted
*Bringing in area planted for LRS
//ALT: Wave 3 code seems to run okay without modification
use "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_crop_area_plan.dta", clear
*Some households have crop observations, but the area planted=0. These are permanent crops. Right now they are not included in the SDI unless they are the only crop on the plot, but we could include them by estimating an area based on the number of trees planted
drop if area_plan==0
*generating area planted of each crop as a proportion of the total area
preserve 
collapse (sum) area_plan_hh=area_plan area_plan_female_hh=area_plan_female area_plan_male_hh=area_plan_male area_plan_mixed_hh=area_plan_mixed, by(hhid)
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_crop_area_plan_shannon.dta", replace
restore
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_crop_area_plan_shannon.dta", nogen		//all matched
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
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_shannon_diversity_index.dta", replace

*/














*****************************************
*Consumption Grouped
*****************************************


***********
	* Visit 2

use "${Nigeria_GHS_W4_raw_data}/sect11a_harvestw4.dta", clear
append using "${Nigeria_GHS_W4_raw_data}/sect11b_harvestw4.dta"
append using "${Nigeria_GHS_W4_raw_data}/sect11c_harvestw4.dta"
append using "${Nigeria_GHS_W4_raw_data}/sect11d_harvestw4.dta"

gen nfd_ = s11aq2/7 //Per day
replace nfd_ = s11bq4/30 if nfd_==.
replace nfd_ = s11cq6/182.5 if nfd_==.
replace nfd_ = s11dq8/365 if nfd_==.
recode nfd_ (.=0)

keep hhid nfd_ item_cd 
reshape wide nfd_, i(hhid) j(item_cd)
gen nfdtbac = nfd_101+nfd_102 //Tobacco and matches
gen nfdrecre = nfd_103+nfd_105+nfd_322+nfd_506+nfd_507 //"Recreation and culture", here including gambling/lotto and newspapers/magazines
gen nfdfares = nfd_104 //Public transportation
gen nfdwater = nfd_312
gen nfdelec = nfd_305
gen nfdgas = nfd_303
gen nfdkero = nfd_301
gen nfdliqd = nfd_304+nfd_302
gen nfdutil = nfd_509 //Council rates?
egen nfdcloth = rowtotal(nfd_401-nfd_418 nfd_431 nfd_432)
egen nfdfmtn = rowtotal(nfd_311 nfd_323 nfd_324 nfd_325 nfd_330 nfd_419-nfd_427 nfd_433-nfd_439 nfd_501-nfd_505 nfd_508)
gen nfdrepar = nfd_327+nfd_328
gen nfddome = nfd_325
gen nfdpetro = nfd_309
gen nfddiesl = nfd_310
gen nfdcomm = nfd_318+nfd_319+nfd_320+nfd_321+nfd_440+nfd_441
gen nfdinsur = nfd_511+nfd_512+nfd_513
egen nfdfoth =rowtotal(nfd_308 nfd_313-nfd_317 nfd_428 nfd_429 nfd_514 nfd_515 nfd_516 nfd_517) //Added dowry, wedding, and funeral expenses/fines and legal fees
gen nfdfwood = nfd_306
gen nfdchar = nfd_307
gen nfdtrans = 0 //Other transportation. Doesn't appear to have an associated question in W4
gen nfdrnthh = nfd_326+nfd_329
gen nfdhealth = nfd_430 + nfd_510 //Health insurance and non-insurance healthcare expenses
drop nfd_*

merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean)
unab vars : nfd*
foreach i in `vars' {
	gen `i'_def = `i' //reg_def_mean
}
//There are a couple of big-ticket repair bills that likely aren't recurring monthly expenses even though they ask for 30-day recall on those questions. I'm assuming that they should probably be reported as annual expenses rather than monthly ones and rescale to fit.
replace nfdrepar = nfdrepar*30/365 if hhid == 320056 | hhid == 199048
replace nfdrepar_def = nfdrepar*30/365 if hhid == 320056 | hhid == 199048
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
use "${Nigeria_GHS_W4_raw_data}/sect10a_harvestw4.dta", clear
keep if s10aq1==1
gen item_ = s10aq2/7 //Total consumption per day (avg) of prepared foods/beverages
keep hhid item_cd item_ 
reshape wide item_, i(hhid) j(item_cd)
recode item_* (.=0)
gen fdbevby1 = item_6+item_8 
gen fdalcby1 = item_9
gen fdrestby = item_1+item_2+item_3+item_4
gen fdothby1=item_5+item_7
merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean)
gen fdbevby1_def = fdbevby1 //reg_def_mean
gen fdalcby1_def = fdalcby1 //reg_def_mean 
gen fdothby1_def = fdothby1 //reg_def_mean
gen fdrestby_def = fdrestby //reg_def_mean
drop item*
tempfile prepfoods
save `prepfoods', replace


use "${Nigeria_GHS_W4_raw_data}/sect10b_harvestw4.dta", clear
gen obs=1 if s10bq9a != .
keep if s10bq5a!= . | s10bq6a != . | s10bq7a != . 
ren s10bq9a qty_bought 
gen kg_bought = qty_bought*s10bq9_cvn
gen price_kg = s10bq10/kg_bought
//ALT 01.25.21: I've tested this with weighted/unweighted and kg vs unit-based pricing.
//It seems like weighted average per-kgs are producing the most reasonable results, but it is a value judgment.
merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keep(1 3) keepusing(reg_def_mean)
gen price_kg_def = price_kg //reg_def_mean 
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/weight.dta", nogen keep(3) keepusing(weight)

foreach i in ea lga state zone {
	preserve
	bys `i' item_cd : egen obs_`i' = total(obs)
	collapse (median) price_`i' = price_kg price_def_`i' = price_kg_def [aw=weight], by(item_cd `i' obs_`i')
	tempfile food_`i'
	save `food_`i''
	restore
	merge m:1 item_cd `i' using `food_`i'', nogen
}

preserve
bys item_cd : egen obs_country=total(obs)
collapse (median) price_kg price_kg_def [aw=weight], by(item_cd obs_country)
keep item_cd price_kg price_kg_def obs_country
ren price_kg price_country
ren price_kg_def price_def_country
tempfile food_country
save `food_country'
restore

merge m:1 item_cd using `food_country', nogen


foreach i in lga state zone country {
	replace price_kg = price_`i' if price_kg ==. & obs_`i' > 9
	replace price_kg_def = price_def_`i' if price_kg_def == . & obs_`i' > 9
}

gen qty_purch = s10bq2_cvn * s10bq5a 
gen qty_own = s10bq2_cvn * (s10bq6a+s10bq7a)
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
gen fddairby = purch_83+purch_84+purch_110+purch_111+purch_112+purch_113+purch_114+purch_115
gen fddairby_def = purch_83_def + purch_84_def + purch_110_def + purch_111_def + purch_112_def + purch_113_def + purch_114_def + purch_115_def
gen fdfatsby = purch_46+purch_47+purch_48+purch_50+purch_51+purch_52+purch_53+purch_56+purch_63+purch_43+purch_44
gen fdfatsby_def = purch_46_def + purch_47_def + purch_48_def + purch_50_def + purch_51_def + purch_52_def + purch_53_def + purch_56_def + purch_63_def + purch_43_def + purch_44_def
gen fdfrutby = purch_61+purch_62+purch_64+purch_65+purch_66+purch_67+purch_68+purch_69+purch_70+purch_71+purch_601
gen fdfrutby_def = purch_61_def + purch_62_def + purch_64_def + purch_65_def + purch_66_def + purch_67_def + purch_68_def + purch_69_def + purch_70_def + purch_71_def + purch_601_def
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
gen fdfrutpr = own_61+own_62+own_64+own_65+own_66+own_67+own_68+own_69+own_70+own_71+own_601
gen fdfrutpr_def = own_61_def + own_62_def + own_64_def + own_65_def + own_66_def + own_67_def + own_68_def + own_69_def + own_70_def + own_71_def + own_601_def
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
egen protein_only = rowtotal (fdpoulby fdmeatby fdfishby fddairby fdfatsby fdbeanby fdspiceby fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdbeanpr fdspiceby)
egen fruits_vegetables = rowtotal (fdtubby fdfrutby fdvegby fdtubpr fdfrutpr fdvegpr)


merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhsize.dta", nogen keepusing(hh_members)

save "${Nigeria_GHS_W4_created_data}/cons_agg_wave4_visit2group.dta", replace





*****************
	*Visit 1

use "${Nigeria_GHS_W4_raw_data}/sect8a_plantingw4.dta", clear
append using "${Nigeria_GHS_W4_raw_data}/sect8b_plantingw4.dta"
append using "${Nigeria_GHS_W4_raw_data}/sect8c_plantingw4.dta"
append using "${Nigeria_GHS_W4_raw_data}/sect11d_harvestw4.dta" //They didn't ask about annual purchases in the post-planting survey; I borrow from the harvest survey to keep everything balanced. These terms will essentially drop out when we take the average for estimated consumption

gen nfd_ = s8q2/7 //Per day
replace nfd_ = s8q4/30 if nfd_==.
replace nfd_ = s8q6/182.5 if nfd_==.
replace nfd_ = s11dq8/365 if nfd_==.
recode nfd_ (.=0)

keep hhid nfd_ item_cd 
reshape wide nfd_, i(hhid) j(item_cd)
gen nfdtbac = nfd_101+nfd_102 //Tobacco and matches
gen nfdrecre = nfd_103+nfd_105+nfd_322+nfd_506+nfd_507 //"Recreation and culture", here including gambling/lotto and newspapers/magazines
gen nfdfares = nfd_104 //Public transportation
gen nfdwater = nfd_312
gen nfdelec = nfd_305
gen nfdgas = nfd_303
gen nfdkero = nfd_301
gen nfdliqd = nfd_304+nfd_302
gen nfdutil = nfd_509 //Council rates?
egen nfdcloth = rowtotal(nfd_401-nfd_418 nfd_431 nfd_432)
egen nfdfmtn = rowtotal(nfd_311 nfd_323 nfd_324 nfd_325 nfd_330 nfd_419-nfd_427 nfd_433-nfd_439 nfd_501-nfd_505 nfd_508)
gen nfdrepar = nfd_327+nfd_328
gen nfddome = nfd_325
gen nfdpetro = nfd_309
gen nfddiesl = nfd_310
gen nfdcomm = nfd_318+nfd_319+nfd_320+nfd_321+nfd_440+nfd_441
gen nfdinsur = nfd_511+nfd_512+nfd_513
egen nfdfoth =rowtotal(nfd_308 nfd_313-nfd_317 nfd_428 nfd_429 nfd_514 nfd_515 nfd_516 nfd_517) //Added dowry, wedding, and funeral expenses
gen nfdfwood = nfd_306
gen nfdchar = nfd_307
gen nfdtrans = 0 //Other transportation. Doesn't appear to have an associated question in W4
gen nfdrnthh = nfd_326+nfd_329
gen nfdhealth = nfd_430 + nfd_510 //Health insurance and non-insurance healthcare expenses
drop nfd_*


merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean)
unab vars : nfd*
foreach i in `vars' {
	gen `i'_def = `i' //reg_def_mean
}

//See visit 2 notes.
replace nfdrepar = nfdrepar*30/365 if hhid == 320056 | hhid == 199048
replace nfdrepar_def = nfdrepar*30/365 if hhid == 320056 | hhid == 199048


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
use "${Nigeria_GHS_W4_raw_data}/sect7a_plantingw4.dta", clear
keep if s7aq1==1
gen item_ = s7aq2/7 //Total consumption per day (avg) of prepared foods/beverages
keep hhid item_cd item_ 
reshape wide item_, i(hhid) j(item_cd)
recode item_* (.=0)
gen fdbevby1 = item_6+item_8 
gen fdalcby1 = item_9
gen fdrestby = item_1+item_2+item_3+item_4
gen fdothby1=item_5+item_7
merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keepusing(reg_def_mean)
gen fdbevby1_def = fdbevby1 //reg_def_mean
gen fdalcby1_def = fdalcby1 //reg_def_mean 
gen fdothby1_def = fdothby1 //reg_def_mean
gen fdrestby_def = fdrestby //reg_def_mean
drop item*
replace fdrestby = . if hhid == 40172 // ~ N 170k of restaurant purchases
replace fdrestby_def = . if hhid==40172
tempfile prepfoods
save `prepfoods', replace


use "${Nigeria_GHS_W4_raw_data}/sect7b_plantingw4.dta", clear
gen obs = s7bq9a != .
keep if s7bq5a!= . | s7bq6a != . | s7bq7a != . 
ren s7bq9a qty_bought 
gen kg_bought = qty_bought*s7bq9_cvn
gen price_kg = s7bq10/kg_bought

//ALT 01.25.21: I've tested this with weighted/unweighted and kg vs unit-based pricing.
//It seems like weighted average per-kgs are producing the most reasonable results, but it is a value judgment.
//ALT 07.23.21: Quicker version of the geographic medians code.
merge m:1 hhid using "${Nigeria_GHS_W4_raw_data}/totcons_final.dta", nogen keep(1 3) keepusing(reg_def_mean)
gen price_kg_def = price_kg //reg_def_mean 
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/weight.dta", nogen keep(3) keepusing(weight)
foreach i in ea lga state zone {
	preserve
	bys `i' item_cd : egen obs_`i' = total(obs)
	collapse (median) price_`i' = price_kg price_def_`i' = price_kg_def [aw=weight], by(item_cd `i' obs_`i')
	tempfile food_`i'
	save `food_`i''
	restore
	merge m:1 item_cd `i' using `food_`i'', nogen
}

preserve
bys item_cd : egen obs_country=total(obs)
collapse (median) price_kg price_kg_def [aw=weight], by(item_cd obs_country)
keep item_cd price_kg price_kg_def obs_country
ren price_kg price_country
ren price_kg_def price_def_country
tempfile food_country
save `food_country'
restore

merge m:1 item_cd using `food_country', nogen

foreach i in lga state zone country {
	replace price_kg = price_`i' if price_kg ==. & obs_`i' > 9
	replace price_kg_def = price_def_`i' if price_kg_def == . & obs_`i' > 9
}

gen qty_purch = s7bq2_cvn * s7bq5a 
gen qty_own = s7bq2_cvn * (s7bq6a+s7bq7a)
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
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_water_cons.dta", replace

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
replace fdfishby=0 if hhid == 39004 //One hh reporting consuming N 228k of fish per day.
replace fdfishby_def = 0 if hhid == 39004

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
egen protein_only = rowtotal (fdpoulby fdmeatby fdfishby fddairby fdfatsby fdbeanby fdspiceby fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdbeanpr fdspiceby)
egen fruits_vegetables = rowtotal (fdtubby fdfrutby fdvegby fdtubpr fdfrutpr fdvegpr)


merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhsize.dta", nogen keepusing(hh_members)

save "${Nigeria_GHS_W4_created_data}/cons_agg_wave4_visit1group.dta", replace

ren cereals_only totcons_cereal_pp
ren protein_only totcons_protein_pp 
ren fruits_vegetables totcons_veg_pp


merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/cons_agg_wave4_visit2group.dta", nogen keepusing(cereals_only protein_only fruits_vegetables)
ren cereals_only totcons_cereal_ph
ren protein_only totcons_protein_ph 
ren fruits_vegetables totcons_veg_ph

*gen totcons_cereal = (totcons_cereal_pp+totcons_cereal_ph)/2
gen totcons_cereal = totcons_cereal_pp
*gen totcons_protein = (totcons_protein_pp+totcons_protein_ph)/2
gen totcons_protein = totcons_protein_pp
*gen totcons_fruit_veg = (totcons_veg_pp+totcons_veg_ph)/2
gen totcons_fruit_veg = totcons_veg_pp

merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_adulteq.dta", nogen keep(1 3) keepusing(adulteq)


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


gen totcons_cereal = totcons_cereal_n /0.4574889
gen totcons_protein = totcons_protein_n /0.4574889
gen totcons_fruit_veg = totcons_fruit_veg_n /0.4574889

gen peraeq_cons_cereal = peraeq_cons_cereal_n /0.4574889
gen peraeq_cons_protein = peraeq_cons_protein_n /0.4574889
gen peraeq_cons_veg = peraeq_cons_veg_n /0.4574889


gen totalcons_cereal = totalcons_cereal_n /0.4574889
gen totalcons_protein = totalcons_protein_n /0.4574889
gen totalcons_veg = totalcons_veg_n /0.4574889
    
		
keep hhid adulteq totcons_cereal totcons_protein  totcons_fruit_veg peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_consumption_group2.dta", replace




use "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_consumption_group2.dta", clear 

merge 1:1 hhid using   "${Nigeria_GHS_W4_created_data}/haz.dta", nogen

keep if s4aq51 ==1
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_consumption_group2.dta", replace 










********************************************************************************
*OFF-FARM HOURS
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}/sect3a_harvestw4.dta", clear
gen  hrs_main_wage_off_farm=s3q18 if (s3q14>1 & s3q14!=.)	& s3q15b1!=1	// s3q14 1 to 2 is agriculture  (exclude mining). Also exclude apprenticeship and considered this as unpaid work 
*gen  hrs_sec_wage_off_farm= hh_e50 if (hh_e39_2>3 & hh_e39_2!=.)		// s3q14 1 to 2 is agriculture  
egen hrs_wage_off_farm= rowtotal(hrs_main_wage_off_farm /*hrs_sec_wage_off_farm*/) 
gen  hrs_main_wage_on_farm=s3q18 if (s3q14<=1 & s3q14!=.) & s3q15b1!=1		 
*gen  hrs_sec_wage_on_farm= hh_e50 if (hh_e39_2<3 & hh_e39_2!=.)	 
egen hrs_wage_on_farm= rowtotal(hrs_main_wage_on_farm /*hrs_sec_wage_on_farm*/) 
drop *main* /*sec*/
gen hrs_unpaid_off_farm=s3q7b // Hours on apprenticeship
*recode hh_e70 hh_e71 (.=0) 
gen  hrs_domest_fire_fuel=. // hrs worked just yesterday
ren  s3q5b hrs_ag_activ 
ren s3q6b hrs_self_off_farm

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

replace hrs_wage_off_farm= 60 if hrs_wage_off_farm >=60 
sum hrs_wage_off_farm, detail

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

save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_off_farm_hours.dta", replace


********************************************************************************
* WAGE INCOME *
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}/sect3a_harvestw4.dta", clear
ren s3q13b activity_code
ren s3q14 sector_code
//ren s3q12b1 mainwage_yesno //ALT: Because this section only covers one job, it's assumed that we're asking about the main wage
egen mainwage_number_months = rowtotal(s3q16a__9 - s3q16a__20) //ALT: Questionnaire goes from June '17 to April '19. I'm doing Feb 18-Jan 19 to keep it consistent with W3
replace mainwage_number_months = 12 if s3q16a__0==1 //ALT: "All 12 months" would mean either Jan-Dec 18 or Feb 18 - Jan 19 depending on when HH was surveyed. Not sure why the questionnaire goes out to April.
//ren s3q16 mainwage_number_months
ren s3q17 mainwage_number_weeks
ren s3q18 mainwage_number_hours
ren s3q21a mainwage_recent_payment
gen ag_activity = (sector_code==1)
replace mainwage_recent_payment = . if ag_activity==1 // exclude ag wages 
ren s3q21b mainwage_payment_period
ren s3q24a mainwage_recent_payment_other
replace mainwage_recent_payment_other = . if ag_activity==1
ren s3q24b mainwage_payment_period_other
ren s3q4 worked_as_employee
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
gen annual_salary = mainwage_annual_salary /0.4574889
collapse (sum) annual_salary, by (hhid)
lab var annual_salary "Estimated annual earnings from non-agricultural wage employment over previous 12 months"
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_wage_income.dta", replace




*Ag wage income
use "${Nigeria_GHS_W4_raw_data}/sect3a_harvestw4.dta", clear
ren s3q13b activity_code
ren s3q14 sector_code
ren s3q12b1 mainwage_yesno
egen mainwage_number_months = rowtotal(s3q16a__9 - s3q16a__20)
replace mainwage_number_months = 12 if s3q16a__0==1
//ren s3q16 mainwage_number_months
ren s3q17 mainwage_number_weeks
ren s3q18 mainwage_number_hours
ren s3q21a mainwage_recent_payment
gen ag_activity = (sector_code==1)
replace mainwage_recent_payment = . if ag_activity!=1 // include only ag wages
ren s3q21b mainwage_payment_period
ren s3q24a mainwage_recent_payment_other
replace mainwage_recent_payment_other = . if ag_activity!=1 // include only ag wages
ren s3q24b mainwage_payment_period_other
ren s3q4 worked_as_employee
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
gen annual_salary_agwage = mainwage_annual_salary /0.4574889 //+ secwage_annual_salary + othwage_annual_salary
collapse (sum) annual_salary_agwage, by (hhid)
lab var annual_salary_agwage "Estimated annual earnings from agricultural wage employment over previous 12 months"
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_agwage_income.dta", replace 




global climate "C:\Users\obine\Music\Documents\food_secure\dofile\original\pp_only\CHIRPS"
*--------------------------------------------------------------*
* 1. Load household rainfall dataset
*--------------------------------------------------------------*
use "$climate\Nigeria_y4_hh_coordinates_rainfall_TS_monthly.dta", clear

* Rename rainfall variables to avoid name conflicts after merge
foreach var of varlist rain_2007_01 - rain_2019_12 {
    rename `var' hh_`var'
}

* Save temporary file of household rainfall
tempfile hh_rain
save `hh_rain', replace

*--------------------------------------------------------------*
* 2. Load plot-level dataset and merge rainfall by hhid
*--------------------------------------------------------------*
use "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_all_plots.dta", clear

merge m:1 hhid using `hh_rain'
drop _merge

*--------------------------------------------------------------*
* 3. Transfer household rainfall into plot rainfall variables
*--------------------------------------------------------------*
foreach var of varlist hh_rain_2007_01 - hh_rain_2019_12 {
    local new = subinstr("`var'", "hh_", "", .)   // remove hh_ prefix
    gen `new' = `var'
}

*--------------------------------------------------------------*
* 4. Remove household-prefixed rainfall variables
*--------------------------------------------------------------*
drop hh_rain_2007_01 - hh_rain_2019_12


/*
			use "$climate\rainfall_arc2_hh", clear
				foreach var of varlist rain_ann1983 - rain_mth2017_12 {
				rename `var' hh_`var'
				}
			mmerge hhid using "$climate\rainfall_arc2_plot"	, unmatch(master)
			drop _m

			foreach var of varlist rain_ann1983 - rain_mth2017_12 {
				replace `var' = hh_`var' if `var'==. & hh_`var' !=.
				}
			drop hh_rain_ann1983 - hh_rain_mth2017_12
			
			mmerge hhid plotid using `plot_level', unmatch(using) ukeep(lga ea) 
			keep if inlist(_m,2,3)	
			drop _m
			
		//	For those Missing Rainfall Information, Replace with EA Average
			foreach var of varlist rain_ann1983 - rain_mth2017_12 {
				bysort lga ea: egen `var'_ea = mean(`var')
				bysort lga: egen `var'_lga = mean(`var')				
				replace `var' = `var'_ea if `var'==. & `var'_ea != .
				replace `var' = `var'_lga if `var'==. & `var'_lga != .				
				}
			drop rain_ann*_ea rain_ann*_lga
*/		

egen total_rain_18_June = rowtotal(rain_2018_03 rain_2018_04 rain_2018_05 rain_2018_06)
egen total_rain_18_July = rowtotal(rain_2018_03 rain_2018_04 rain_2018_05 rain_2018_06 rain_2018_07)

egen mean_rain_18_June  = rowmean(rain_2018_03 rain_2018_04 rain_2018_05 rain_2018_06)
egen mean_rain_18_July  = rowmean(rain_2018_03 rain_2018_04 rain_2018_05 rain_2018_06 rain_2018_07)

*--------------------------------------------------------------*
* 1. Remove rainfall for years you don't want (example: drop 2018)
*--------------------------------------------------------------*
drop rain_2018_*


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
egen mean_rain_2017_Mar = rowmean(rain_2017_03 rain_2017_04 rain_2017_05 rain_2017_06)
gen  dev_rain_2017_Mar  = mean_rain_2017_Mar - mean_rain_Mar_June

egen mean_rain_2017_Aug = rowmean(rain_2017_08 rain_2017_09 rain_2017_10 rain_2017_11 rain_2017_12)
gen  dev_rain_2017_Aug  = mean_rain_2017_Aug - mean_rain_Aug_Dec

*----------------------------------------------------------------------
* 5. Annual mean rainfall (for all years)
*----------------------------------------------------------------------
egen mean_annual_rainfall = rowmean(rain_*_01 rain_*_02 rain_*_03 rain_*_04 rain_*_05 rain_*_06 rain_*_07 rain_*_08 rain_*_09 rain_*_10 rain_*_11 rain_*_12)

*----------------------------------------------------------------------
* 6. Annual shortfall (corrected code using loops)
*----------------------------------------------------------------------
forvalues yr = 2007/2017 {
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
forvalues yr = 2007/2017 {
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
collapse (sum) ln_cv_rain_Mar_June mean_rain sd_rain cv_rainfall cv_100_rainfall ln_cv_rain ln_cv_100_rain ///
     mean_rain_Mar_June sd_rain_Mar_June cv_rain_Mar_June cv_100_rain_Mar_June ///
     mean_annual_rainfall rainfall_shortfall ln_rain_shortfall shortfall shortfall_Mar shortfall_Aug ///
     mean_rain_Aug_Dec sd_rain_Aug_Dec cv_rain_Aug_Dec cv_100_rain_Aug_Dec ///
     ln_cv_rain_Aug_Dec ln_cv_100_rain_Aug_Dec ///
     mean_rain_2017_Mar dev_rain_2017_Mar dev_rain_2017_Aug ///
     shortfall_Mar_June shortfall_Mar_July shortfall_Aug_Dec ///
     sd_shortfall_* *_18_June, by ( hhid)

save "${Nigeria_GHS_W4_created_data}/rainfall_19.dta", replace 













*******************************
*Merging Household Level Dataset
*******************************
use  "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_all_plots.dta",clear

sort hhid plot_id
count
count if cropcode==1080
*keep if cropcode==1080
*keep if purestand ==1
order hhid plot_id cropcode quant_harv_kg value_harvest ha_harvest percent_inputs field_size purestand

collapse (sum) quant_harv_kg value_harvest ha_planted field_size (max) percent_inputs  purestand, by (hhid)
replace ha_planted = 9.5 if ha_planted >= 9.5 
replace field_size = 20 if field_size >= 20
ren value_harvest real_value_harvest
gen value_harvest  = real_value_harvest/0.4574889
tab value_harvest
replace value_harvest=  4695385 if value_harvest>= 4695385


merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/fert_units.dta", gen(fert)
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/food_prices_2018.dta", gen (food)
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/household_asset_2018.dta", gen (asset)
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/weight.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/ag_rainy_18.dta", gen(filter)
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/dieatary_diversity.dta", gen(diet)
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_consumption2.dta", gen(exp)
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_consumption_group2.dta", gen (exp2)
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhsize.dta", gen(hh)
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/soil_quality_2018.dta", gen(soil)
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/demographics_2018.dta", gen(house)
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/laborage_2018.dta", gen(work)
*merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_shannon_diversity_index.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_off_farm_hours.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_wage_income.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_agwage_income.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/rainfall_19.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/child18.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/shock.dta", nogen
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/haz.dta", nogen



*keep if ag_rainy_18==1
***********************Dealing with outliers*************************


gen year = 2018
tabstat ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty n_kg  tpricefert_cens_mrk real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue mean_annual_rainfall [w=weight], statistics( mean median sd min max ) columns(statistics)
count
misstable summarize ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty n_kg  tpricefert_cens_mrk real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue totcons_pc peraeq_cons total_cons mrk_dist_w num_mem hh_headage femhead attend_sch worker zone state lga ea



replace total_qty = 0 if total_qty==.
replace n_kg = 0 if n_kg ==.

/*
replace ha_planted = 0 if ha_planted==.
replace field_size = 0 if field_size ==.
replace value_harvest = 0 if value_harvest==.
replace quant_harv_kg = 0 if quant_harv_kg ==.
*/
egen medianfert_pr = median(real_tpricefert_cens_mrk)
egen medianfert_ = median(tpricefert_cens_mrk)
replace real_tpricefert_cens_mrk = medianfert_pr if real_tpricefert_cens_mrk ==. 

replace tpricefert_cens_mrk = medianfert_ if tpricefert_cens_mrk ==. 


egen medianmaize_pr = median(real_maize_price_mr)
egen medianmaize_ = median(maize_price_mr)

replace real_maize_price_mr = medianmaize_pr if real_maize_price_mr ==. 

replace maize_price_mr = medianmaize_ if maize_price_mr ==. 



egen medianfert_dist_ea = median(mrk_dist_w), by (ea)
egen medianfert_dist_lga = median(mrk_dist_w), by (lga)
egen medianfert_dist_state = median(mrk_dist_w), by (state)
egen medianfert_dist_zone = median(mrk_dist_w), by (zone)


replace mrk_dist_w = medianfert_dist_ea if mrk_dist_w ==. 
replace mrk_dist_w = medianfert_dist_lga if mrk_dist_w ==. 
replace mrk_dist_w = medianfert_dist_state if mrk_dist_w ==.

replace mrk_dist_w = medianfert_dist_zone if mrk_dist_w ==. 

misstable summarize ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty n_kg  tpricefert_cens_mrk real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue totcons_pc peraeq_cons total_cons number_foodgroup mrk_dist_w num_mem hh_headage femhead attend_sch worker peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg mean_annual_rainfall child dev_rain_2017_Mar dev_rain_2017_Aug 

egen mean1 = mean (dev_rain_2017_Mar)
egen mean2 = mean (dev_rain_2017_Aug)

ren dev_rain_2017_Mar dev_rain_Mar
ren  dev_rain_2017_Aug dev_rain_Aug

misstable summarize ha_planted field_size quant_harv_kg value_harvest maize_price_mr real_maize_price_mr total_qty n_kg  tpricefert_cens_mrk real_tpricefert_cens_mrk  hhasset_value_w real_hhvalue totcons_pc peraeq_cons total_cons number_foodgroup mrk_dist_w num_mem hh_headage femhead attend_sch worker peraeq_cons_cereal peraeq_cons_protein peraeq_cons_veg totalcons_cereal totalcons_protein totalcons_veg mean_annual_rainfall child  dev_rain_Mar dev_rain_Aug haz peraeq_cons_protein

egen med = median(haz)
replace haz = med if haz ==.
save "${Nigeria_GHS_W4_created_data}/final_19.dta", replace


















