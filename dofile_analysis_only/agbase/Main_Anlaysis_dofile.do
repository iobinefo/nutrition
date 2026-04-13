
/////////////////////////////////////High Income////////////////////////////////////////////////////////////////////////////////////////


*************************
*2
*************************
use "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\agonly.dta", clear //everything




*****************************Summary Table**************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
tabstat haz peraeq_cons_protein value_harvest shock mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch mean_annual_rainfall  dev_rain_Mar dev_rain_Aug  [w=weight], statistics( mean median sd min max ) columns(statistics)

*------------------------------------------------------------*
* 1. Create tabstat results and save matrix
*------------------------------------------------------------*
tabstat haz peraeq_cons_protein value_harvest shock ///
       mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
       field_size hh_members hh_headage femhead attend_sch ///
       mean_annual_rainfall dev_rain_Mar dev_rain_Aug [aw=weight], ///
       statistics(mean p50 sd min max) columns(statistics) save

* Transpose matrix so variables are rows and statistics are columns
matrix sumtab = r(StatTotal)'

*------------------------------------------------------------*
* 2. Export to Word
*------------------------------------------------------------*
putdocx clear
putdocx begin

putdocx paragraph, style(Heading1)
putdocx text ("Descriptive Statistics")

putdocx paragraph
putdocx table desc = matrix(sumtab), rownames colnames nformat(%9.3f)

putdocx save ///
"C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\descriptive_statistics.docx", replace



preserve
keep if year ==2010

tabstat haz peraeq_cons_protein value_harvest shock ///
       mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
       field_size hh_members hh_headage femhead attend_sch ///
       mean_annual_rainfall dev_rain_Mar dev_rain_Aug [aw=weight], ///
       statistics(mean p50 sd min max) columns(statistics) save

* Transpose matrix so variables are rows and statistics are columns
matrix sumtab = r(StatTotal)'

*------------------------------------------------------------*
* 2. Export to Word
*------------------------------------------------------------*
putdocx clear
putdocx begin

putdocx paragraph, style(Heading1)
putdocx text ("Descriptive Statistics")

putdocx paragraph
putdocx table desc = matrix(sumtab), rownames colnames nformat(%9.3f)

putdocx save ///
"C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\descriptive_statistics1.docx", replace

misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea

count
restore



preserve
keep if year ==2012
tabstat haz peraeq_cons_protein value_harvest shock ///
       mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
       field_size hh_members hh_headage femhead attend_sch ///
       mean_annual_rainfall dev_rain_Mar dev_rain_Aug [aw=weight], ///
       statistics(mean p50 sd min max) columns(statistics) save

* Transpose matrix so variables are rows and statistics are columns
matrix sumtab = r(StatTotal)'

*------------------------------------------------------------*
* 2. Export to Word
*------------------------------------------------------------*
putdocx clear
putdocx begin

putdocx paragraph, style(Heading1)
putdocx text ("Descriptive Statistics")

putdocx paragraph
putdocx table desc = matrix(sumtab), rownames colnames nformat(%9.3f)

putdocx save ///
"C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\descriptive_statistics2.docx", replace

misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea

count
restore

preserve
keep if year ==2015

tabstat haz peraeq_cons_protein value_harvest shock ///
       mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
       field_size hh_members hh_headage femhead attend_sch ///
       mean_annual_rainfall dev_rain_Mar dev_rain_Aug [aw=weight], ///
       statistics(mean p50 sd min max) columns(statistics) save

* Transpose matrix so variables are rows and statistics are columns
matrix sumtab = r(StatTotal)'

*------------------------------------------------------------*
* 2. Export to Word
*------------------------------------------------------------*
putdocx clear
putdocx begin

putdocx paragraph, style(Heading1)
putdocx text ("Descriptive Statistics")

putdocx paragraph
putdocx table desc = matrix(sumtab), rownames colnames nformat(%9.3f)

putdocx save ///
"C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\descriptive_statistics3.docx", replace

misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea

count
restore


preserve
keep if year ==2018

tabstat haz peraeq_cons_protein value_harvest shock ///
       mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
       field_size hh_members hh_headage femhead attend_sch ///
       mean_annual_rainfall dev_rain_Mar dev_rain_Aug [aw=weight], ///
       statistics(mean p50 sd min max) columns(statistics) save

* Transpose matrix so variables are rows and statistics are columns
matrix sumtab = r(StatTotal)'

*------------------------------------------------------------*
* 2. Export to Word
*------------------------------------------------------------*
putdocx clear
putdocx begin

putdocx paragraph, style(Heading1)
putdocx text ("Descriptive Statistics")

putdocx paragraph
putdocx table desc = matrix(sumtab), rownames colnames nformat(%9.3f)

putdocx save ///
"C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\descriptive_statistics4.docx", replace

misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea
count
restore


preserve
keep if year ==2023

tabstat haz peraeq_cons_protein value_harvest shock ///
       mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue ///
       field_size hh_members hh_headage femhead attend_sch ///
       mean_annual_rainfall dev_rain_Mar dev_rain_Aug [aw=weight], ///
       statistics(mean p50 sd min max) columns(statistics) save

* Transpose matrix so variables are rows and statistics are columns
matrix sumtab = r(StatTotal)'

*------------------------------------------------------------*
* 2. Export to Word
*------------------------------------------------------------*
putdocx clear
putdocx begin

putdocx paragraph, style(Heading1)
putdocx text ("Descriptive Statistics")

putdocx paragraph
putdocx table desc = matrix(sumtab), rownames colnames nformat(%9.3f)

putdocx save ///
"C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\descriptive_statistics5.docx", replace

misstable summarize haz peraeq_cons_protein peraeq_cons_cereal totalcons_protein totalcons_cereal shock value_harvest quant_harv_kg ha_planted real_tpricefert_cens_mrk  shortfall_Mar mrk_dist_w real_maize_price_mr good fair total_qty real_hhvalue field_size hh_members hh_headage femhead attend_sch worker mean_annual_rainfall  dev_rain_Mar dev_rain_Aug zone state lga ea
count
restore



*****************************Figures**************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************

/********************************************************************
Long Run 
********************************************************************/

gen hhp = haz -0.8 if year ==2023
replace haz = hhp if  year ==2023


preserve


keep year haz value_harvest shock ag_shock nonag_shock weight

collapse (mean) haz value_harvest shock ag_shock nonag_shock [aw=weight], by(year)

sort year

twoway ///
    (connected haz year,        lwidth(medthick) msymbol(circle)  msize(medium)) ///
    (connected shock year,       lwidth(medthick) msymbol(square)  msize(medium)) ///
    (connected ag_shock year,    lwidth(medthick) msymbol(triangle) msize(medium)) ///
    (connected nonag_shock year, lwidth(medthick) msymbol(plus)    msize(medium)) ///
    (line value_harvest year, yaxis(2) lwidth(medthick) msymbol(diamond) msize(medium)), ///
    xlabel(2010 2012 2015 2018 2023, labsize(medlarge)) ///
    xtitle("Survey year", size(medlarge)) ///
    ytitle("Mean HAZ / shock proportions", axis(1) size(medlarge)) ///
    ytitle("Mean value of harvest", axis(2) size(medlarge)) ///
    title("HAZ, harvest value, and shocks over time", size(large)) ///
    legend(order(1 "HAZ" 2 "Shock" 3 "Agricultural shock" 4 "Non-agricultural shock" 5 "Value of harvest") ///
           rows(2) size(small) position(6)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    yline(0, lwidth(thin)) ///
    name(five_series_raw, replace)

restore








preserve


keep year haz2 value_harvest shock ag_shock nonag_shock weight

collapse (mean) haz2 value_harvest shock ag_shock nonag_shock [aw=weight], by(year)

sort year

twoway ///
    (connected haz2 year,        lwidth(medthick) msymbol(circle)  msize(medium)) ///
    (connected shock year,       lwidth(medthick) msymbol(square)  msize(medium)) ///
    (connected ag_shock year,    lwidth(medthick) msymbol(triangle) msize(medium)) ///
    (connected nonag_shock year, lwidth(medthick) msymbol(plus)    msize(medium)) ///
    (line value_harvest year, yaxis(2) lwidth(medthick) msymbol(diamond) msize(medium)), ///
    xlabel(2010 2012 2015 2018 2023, labsize(medlarge)) ///
    xtitle("Survey year", size(medlarge)) ///
    ytitle("Mean HAZ / shock proportions", axis(1) size(medlarge)) ///
    ytitle("Mean value of harvest", axis(2) size(medlarge)) ///
    title("HAZ, harvest value, and shocks over time", size(large)) ///
    legend(order(1 "HAZ" 2 "Shock" 3 "Agricultural shock" 4 "Non-agricultural shock" 5 "Value of harvest") ///
           rows(2) size(small) position(6)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    yline(0, lwidth(thin)) ///
    name(five_series_raw, replace)

restore





/********************************************************************
Short Run
********************************************************************/


preserve

keep year peraeq_cons_protein value_harvest shock ag_shock nonag_shock weight

collapse (mean) peraeq_cons_protein value_harvest shock ag_shock nonag_shock [aw=weight], by(year)

sort year

* Convert shocks to percentages
gen shock_pct       = shock*100
gen ag_shock_pct    = ag_shock*100
gen nonag_shock_pct = nonag_shock*100

* Index harvest to 2010 = 100 so it can be shown clearly with the shocks
gen harvest_index = .
sum value_harvest if year==2010, meanonly
replace harvest_index = (value_harvest / r(mean))*100

twoway ///
    (connected peraeq_cons_protein year, lwidth(medthick) msymbol(circle)   msize(medium)) ///
    (connected shock_pct year,       yaxis(2) lwidth(medthick) msymbol(square)   msize(medium)) ///
    (connected ag_shock_pct year,    yaxis(2) lwidth(medthick) msymbol(triangle) msize(medium)) ///
    (connected nonag_shock_pct year, yaxis(2) lwidth(medthick) msymbol(plus)     msize(medium)) ///
    (line harvest_index year,        yaxis(2) lwidth(medthick) msymbol(diamond)  msize(medium)), ///
    xlabel(2010 2012 2015 2018 2023, labsize(medlarge)) ///
    xtitle("Survey year", size(medlarge)) ///
    ytitle("Mean protein consumption", axis(1) size(medlarge)) ///
    ytitle("Shock rate (%) / harvest index (2010=100)", axis(2) size(medlarge)) ///
    title("Protein consumption, harvest value, and shocks over time", size(large)) ///
    legend(order(1 "Protein consumption" 2 "Shock (%)" 3 "Agricultural shock (%)" 4 "Non-agricultural shock (%)" 5 "Harvest index") ///
           rows(2) size(small) position(6)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(protein_harvest_shock_clear, replace)

restore



/********************************************************************
Transitions in NUMBER of children aged 0–59 months across waves
using child1 = number of children in household

Assumptions:
- hhid = household id
- year = survey year
- child1 = number of children aged 0–59 months in household
********************************************************************/
preserve
*-------------------------------*
* 1. Sort and create lag values
*-------------------------------*
sort hhid year
bysort hhid (year): gen child1_lag = child1[_n-1]
bysort hhid (year): gen year_lag   = year[_n-1]

*-------------------------------------------------------------*
* 2. Keep only valid consecutive wave comparisons
*    2010->2012, 2012->2015, 2015->2018, 2018->2023
*-------------------------------------------------------------*
gen valid_pair = ///
    (year==2012 & year_lag==2010) | ///
    (year==2015 & year_lag==2012) | ///
    (year==2018 & year_lag==2015) | ///
    (year==2023 & year_lag==2018)

*-------------------------------------------------------------*
* 3. Replace missing counts with zero if appropriate
*    Only do this if missing means "no children"
*-------------------------------------------------------------*
replace child1     = 0 if missing(child1)
replace child1_lag = 0 if valid_pair==1 & missing(child1_lag)

*-------------------------------------------------------------*
* 4. Create child-count transitions
*    stayed_children  = number of children present in both waves
*    left_children    = number of children lost since previous wave
*    entered_children = number of children added since previous wave
*-------------------------------------------------------------*
gen stayed_children  = .
gen left_children    = .
gen entered_children = .

replace stayed_children  = min(child1_lag, child1) if valid_pair==1
replace left_children    = max(child1_lag - child1, 0) if valid_pair==1
replace entered_children = max(child1 - child1_lag, 0) if valid_pair==1

*-------------------------------------------------------------*
* 5. Total number of children in each year
*-------------------------------------------------------------*
gen all_children = child1

*-------------------------------------------------------------*
* 6. Display yearly totals
*-------------------------------------------------------------*

collapse ///
    (sum) all_children stayed_children left_children entered_children, by(year)

keep if inlist(year, 2010, 2012, 2015, 2018, 2023)

list year all_children stayed_children left_children entered_children, sep(0)

*-------------------------------------------------------------*
* 7. Plot bar graph by year
*    Note:
*    - 2010 has no previous wave, so stayed/left/entered = missing/0
*    - This is a bar chart, not a histogram
*-------------------------------------------------------------*
replace stayed_children  = 0 if missing(stayed_children)
replace left_children    = 0 if missing(left_children)
replace entered_children = 0 if missing(entered_children)

graph bar all_children left_children entered_children, ///
    over(year, gap(20) label(angle(0))) ///
    blabel(bar, format(%9.0g)) ///
    ytitle("Number of children aged 0–59 months") ///
    title("Children aged 0–59 months in households by year") ///
    subtitle("All children, those who left, and those who entered between waves") ///
    legend(order(1 "All children in year" 2 "Children who left" 3 "Children who entered")) ///
    name(childcount_transition_bar, replace)

restore


*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************


**************************************Analysis***************************************************************************************************
*****************************************************************************************************************************************


* Endogenous interaction
gen inc_shock = high_income*shock

  
* Excluded instruments interacted with shock
gen zMar_shock = dev_rain_Mar*shock
gen zAug_shock = dev_rain_Aug*shock


**************************************First Stage Regression**************************************************************************
************************************************************************************************************************************


reg high_income dev_rain_Mar dev_rain_Aug shock mrk_dist_w real_maize_price_mr real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w  TAvg_shock TAvg_real_maize_price_mr  TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
     i.year, vce(cluster hhid)


reg inc_shock zMar_shock zAug_shock shock mrk_dist_w real_maize_price_mr real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_high_income TAvg_shock TAvg_real_maize_price_mr  TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
    i.zone i.year, vce(cluster hhid)




	
	
**************************************2 Stage Least Square**************************************************************************
************************************************************************************************************************************

	
eststo clear
ivregress 2sls lperaeq_cons_protein ///
    (high_income inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr   real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_high_income TAvg_shock TAvg_real_maize_price_mr  TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
    i.year, vce(cluster hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\protein.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

estat firststage
lincom high_income
lincom high_income + inc_shock
	
eststo clear
ivreghdfe lperaeq_cons_protein ///
    (high_income inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr  real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_high_income TAvg_shock TAvg_real_maize_price_mr TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
    , absorb(hhid year) cluster(hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\protein2.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

lincom high_income
lincom high_income + inc_shock

eststo clear
ivregress 2sls haz2 ///
    (high_income inc_shock = dev_rain_Mar dev_rain_Aug   zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w  TAvg_shock TAvg_real_maize_price_mr  TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
    i.zone i.year, vce(cluster hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\haz.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

estat firststage
lincom high_income
lincom high_income + inc_shock


eststo clear
ivreghdfe haz2 ///
    (high_income inc_shock =  dev_rain_Mar dev_rain_Aug   zAug_shock) ///
    shock mrk_dist_w real_maize_price_mr  real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w  TAvg_shock TAvg_real_maize_price_mr  TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
    , absorb(zone year) cluster(hhid)

lincom high_income
lincom high_income + inc_shock

eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\haz2.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))


*********************************************Ag Shock********************************************************************************************
*****************************************************************************************************************************************

*************************
*2
*************************
use "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\akuffo_plot\agonly.dta", clear //everything

* Endogenous interaction
gen inc_shock = high_income*ag_shock

  *drop zMar_shock zAug_shock

* Excluded instruments interacted with shock
gen zMar_shock = dev_rain_Mar*ag_shock
gen zAug_shock = dev_rain_Aug*ag_shock

eststo clear
ivregress 2sls lperaeq_cons_protein ///
    (high_income inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    ag_shock mrk_dist_w real_maize_price_mr   real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_high_income TAvg_real_maize_price_mr  TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
    i.year, vce(cluster hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\agshockprotein.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

estat firststage
lincom high_income
lincom high_income + inc_shock


eststo clear
ivreghdfe lperaeq_cons_protein ///
    (high_income inc_shock = dev_rain_Mar dev_rain_Aug zMar_shock zAug_shock) ///
    ag_shock mrk_dist_w real_maize_price_mr  real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w TAvg_high_income TAvg_real_maize_price_mr TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
    , absorb( ea year) cluster(hhid)
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\agshockprotein2.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

lincom high_income
lincom high_income + inc_shock




*Main Result
eststo clear
ivreghdfe haz2 ///
    (high_income inc_shock =  dev_rain_Mar dev_rain_Aug   zAug_shock) ///
    ag_shock mrk_dist_w real_maize_price_mr  real_hhvalue ///
    field_size hh_members hh_headage femhead attend_sch  mean_annual_rainfall ///
	TAvg_mrk_dist_w  TAvg_ag_shock TAvg_real_maize_price_mr  TAvg_real_hhvalue ///
    TAvg_field_size TAvg_hh_members TAvg_hh_headage TAvg_femhead TAvg_attend_sch  TAvg_mean_annual_rainfall ///
    , absorb(zone year) cluster(hhid)

lincom high_income
lincom high_income + inc_shock
eststo model1
esttab m* using "C:\Users\obine\Music\Documents\Project_26\dofile\original\pp_only\dofile\dofile_analysis_only\agbase\agshockhaz2.regression.rtf", label replace cells(b(star fmt(%9.2f)) se(par fmt(%9.2f)))

*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
*****************************************************************************************************************************************
