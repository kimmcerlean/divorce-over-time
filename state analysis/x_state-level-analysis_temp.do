********************************************************************************
* Adding in state-level data
* state-level-analysis.do
* Kim McErlean
********************************************************************************

********************************************************************************
* First just get data and do all the restrictions that are in file 3
********************************************************************************

use "$data_keep\PSID_marriage_recoded_sample.dta", clear // created in 1a

gen cohort=.
replace cohort=1 if inrange(rel_start_all,1969,1979)
replace cohort=2 if inrange(rel_start_all,1980,1989)
replace cohort=3 if inrange(rel_start_all,1990,2010)
replace cohort=4 if inrange(rel_start_all,2011,2019)


// keep if cohort==3, need to just use filters so I don't have to keep using and updating the data
// need to decide - ALL MARRIAGES or just first? - killewald restricts to just first, so does cooke. My validation is MUCH BETTER against those with first marraiges only...
keep if marriage_order_real==1
keep if (AGE_REF_>=18 & AGE_REF_<=55) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=55)

// drop those with no earnings or housework hours the whole time
bysort id: egen min_type = min(hh_earn_type) // since no earners is 4, if the minimum is 4, means that was it the whole time
label values min_type hh_earn_type
sort id survey_yr
browse id survey_yr min_type hh_earn_type

tab min_type // okay very few people had no earnings whole time
// drop if min_type ==4

bysort id: egen min_hw_type = min(housework_bkt) // since no earners is 4, if the minimum is 4, means that was it the whole time
label values min_hw_type housework_bkt
sort id survey_yr
browse id survey_yr min_hw_type housework_bkt

tab min_hw_type // same here
// drop if min_hw_type ==4

// need to make religion
// religion is new, but think I need to add given historical research. coding changes between 1984 and 1985, then again between 1994 and 1995. using past then, so this is fine. otherwise, need to recode in MAIN FILE before combining. okay still somewhat sketchy. coding like this for now, will update in real analysis

label define update_religion  ///
       1 "Catholic"  ///
       2 "Jewish"  ///
       8 "Protestant unspecified"  ///
      10 "Other non-Christian: Muslim, Rastafarian, etc."  ///
      13 "Greek/Russian/Eastern Orthodox"  ///
      97 "Other"  ///
      98 "DK"  ///
      99 "NA; refused"  ///
       0 "None"

recode RELIGION_HEAD_ (3/7=97)(9=97)(11/12=97)(14/31=97), gen(religion_head)
recode RELIGION_WIFE_ (3/7=97)(9=97)(11/12=97)(14/31=97), gen(religion_wife)
	   
label values religion_head religion_wife update_religion

// fix region
gen region = REGION_
replace region = . if inlist(REGION_,0,9)
label define region 1 "Northeast" 2 "North Central" 3 "South" 4 "West" 5 "Alaska,Hawaii" 6 "Foreign"
label values region region

// splitting the college group into who has a degree. also considering advanced degree as higher than college -- this currently only works for cohort 3. I think for college - the specific years matter to split advanced, but for no college - distinguishing between grades less relevant?
gen college_bkd=.
replace college_bkd=1 if (EDUC_WIFE_==16 & EDUC_HEAD_==16) | (EDUC_WIFE_==17 & EDUC_HEAD_==17)
replace college_bkd=2 if (EDUC_WIFE_==17 & EDUC_HEAD_ <= 16) | (EDUC_WIFE_==16 & EDUC_HEAD_ <= 15) 
replace college_bkd=3 if (EDUC_HEAD_==17 & EDUC_WIFE_ <= 16) | (EDUC_HEAD_==16 & EDUC_WIFE_ <= 15)
replace college_bkd=0 if couple_educ_gp==0

label define college_bkd 1 "Both" 2 "Wife" 3 "Husband"
label values college_bkd college_bkd

gen no_college_bkd=.
replace no_college_bkd=1 if couple_educ_gp==0 & educ_wife==educ_head
replace no_college_bkd=2 if couple_educ_gp==0 & educ_wife>educ_head & educ_wife!=.
replace no_college_bkd=3 if couple_educ_gp==0 & educ_wife<educ_head & educ_head!=.
replace no_college_bkd=0 if couple_educ_gp==1
label values no_college_bkd college_bkd

gen couple_educ_detail=.
replace couple_educ_detail=0 if educ_wife!=4 & educ_head!=4
replace couple_educ_detail=1 if educ_wife==4 & educ_head==4
replace couple_educ_detail=2 if educ_wife==4 & inlist(educ_head,1,2,3)
replace couple_educ_detail=3 if educ_head==4 & inlist(educ_wife,1,2,3)

label define couple_educ_detail 0 "Neither" 1 "Both" 2 "Wife" 3 "Husband"
label values couple_educ_detail couple_educ_detail

// more discrete measures of work contributions
input group
.10
.20
.30
.40
.50
.60
.70
.80
1
end

xtile female_hours_bucket = female_hours_pct, cut(group)
browse female_hours_bucket female_hours_pct weekly_hrs_wife ft_pt_wife weekly_hrs_head ft_pt_head

// something went wrong here
drop ft_pt_head
drop ft_pt_wife

gen ft_pt_head=0
replace ft_pt_head=1 if weekly_hrs_head>0 & weekly_hrs_head <=35
replace ft_pt_head=2 if weekly_hrs_head >35 & weekly_hrs_head<=200

gen ft_pt_wife=0
replace ft_pt_wife=1 if weekly_hrs_wife>0 & weekly_hrs_wife <=35
replace ft_pt_wife=2 if weekly_hrs_wife >35 & weekly_hrs_wife<=200

gen overwork_head = 0
replace overwork_head =1 if weekly_hrs_head >50 & weekly_hrs_head<=200 // used by Cha 2013

gen overwork_wife = 0 
replace overwork_wife = 1 if weekly_hrs_wife > 50 & weekly_hrs_wife<=200

gen bw_type=.
replace bw_type=1 if inlist(ft_pt_head,1,2) & ft_pt_wife==0
replace bw_type=2 if ft_pt_head==2 & ft_pt_wife==1
replace bw_type=3 if (ft_pt_head==2 & ft_pt_wife==2) | (ft_pt_wife==1 & ft_pt_head==1)
replace bw_type=4 if ft_pt_head==1 & ft_pt_wife==2
replace bw_type=5 if ft_pt_head==0 & inlist(ft_pt_wife,1,2)

label define bw_type 1 "Male BW" 2 "Male and a half" 3 "Dual" 4 "Female and a half" 5 "Female BW"
label values bw_type bw_type

gen bw_type_gp=.
replace bw_type_gp=1 if ft_head==1 & ft_wife==1
replace bw_type_gp=2 if ft_head==1 & ft_wife==0
replace bw_type_gp=3 if ft_head==0 & ft_wife==1
replace bw_type_gp=4 if ft_head==0 & ft_wife==0

label define bw_type_gp 1 "Both FT" 2 "Male FT" 3 "Female FT"  4 "Neither FT"
label values bw_type_gp bw_type_gp

gen bw_type_gp_alt=.
replace bw_type_gp_alt=1 if bw_type==3
replace bw_type_gp_alt=2 if inlist(bw_type,1,2)
replace bw_type_gp_alt=3 if inlist(bw_type,4,5)
replace bw_type_gp_alt=4 if ft_pt_wife==0 & ft_pt_head==0

label define bw_type_gp_alt 1 "Dual" 2 "Male BW" 3 "Female BW"  4 "Neither works"
label values bw_type_gp_alt bw_type_gp_alt

gen hours_type_hw=.
replace hours_type_hw=1 if bw_type==3 & housework_bkt==1
replace hours_type_hw=2 if bw_type==3 & housework_bkt==2
replace hours_type_hw=3 if bw_type==3 & housework_bkt==3
replace hours_type_hw=4 if inlist(bw_type,1,2) & housework_bkt==1
replace hours_type_hw=5 if inlist(bw_type,1,2) & housework_bkt==2
replace hours_type_hw=6 if inlist(bw_type,1,2) & housework_bkt==3
replace hours_type_hw=7 if inlist(bw_type,4,5) & housework_bkt==1
replace hours_type_hw=8 if inlist(bw_type,4,5) & housework_bkt==2
replace hours_type_hw=9 if inlist(bw_type,4,5) & housework_bkt==3

label define hours_type_hw 1 "Dual: Equal" 2 "Dual: Woman" 3 "Dual: Man" 4 "Male BW: Equal" 5 "Male BW: Woman" 6 "Male BW: Man" 7 "Female BW: Equal" 8 "Female BW: Woman" 9 "Female BW: Man"
label values hours_type_hw hours_type_hw


gen earn_type_hw=.
replace earn_type_hw=1 if hh_earn_type==1 & housework_bkt==1
replace earn_type_hw=2 if hh_earn_type==1 & housework_bkt==2
replace earn_type_hw=3 if hh_earn_type==1 & housework_bkt==3
replace earn_type_hw=4 if hh_earn_type==2 & housework_bkt==1
replace earn_type_hw=5 if hh_earn_type==2 & housework_bkt==2
replace earn_type_hw=6 if hh_earn_type==2 & housework_bkt==3
replace earn_type_hw=7 if hh_earn_type==3 & housework_bkt==1
replace earn_type_hw=8 if hh_earn_type==3 & housework_bkt==2
replace earn_type_hw=9 if hh_earn_type==3 & housework_bkt==3

label define earn_type_hw 1 "Dual: Equal" 2 "Dual: Woman" 3 "Dual: Man" 4 "Male BW: Equal" 5 "Male BW: Woman" 6 "Male BW: Man" 7 "Female BW: Equal" 8 "Female BW: Woman" 9 "Female BW: Man"
label values earn_type_hw earn_type_hw

gen division_bucket=5
replace division_bucket = 1 if hh_earn_type== 1 & housework_bkt== 1 // dual, dual
replace division_bucket = 2 if hh_earn_type== 2 & housework_bkt== 2 // male bw, female hw
replace division_bucket = 3 if hh_earn_type== 3 & housework_bkt== 3 // female bw, male hw
replace division_bucket = 4 if hh_earn_type== 1 & housework_bkt== 2 // dual, female hw

label define division_bucket 1 "Dual" 2 "Traditional" 3 "Counter-traditional" 4 "Second shift" 5 "All Other"
label values division_bucket division_bucket

// this doesn't capture OVERWORK
sum weekly_hrs_head if ft_pt_head==2, detail
sum weekly_hrs_wife if ft_pt_wife==2, detail

// dissimilarity
gen hours_diff = weekly_hrs_head - weekly_hrs_wife
browse hours_diff weekly_hrs_head weekly_hrs_wife
gen hours_diff_bkt = .
replace hours_diff_bkt = 1 if hours_diff <=10 & hours_diff >=-10
replace hours_diff_bkt = 2 if hours_diff >10 & hours_diff <=150
replace hours_diff_bkt = 3 if hours_diff <-10 & hours_diff >=-150

label define hours_diff_bkt 1 "Similar" 2 "Skew Male" 3 "Skew Female"
label values hours_diff_bkt hours_diff_bkt 

browse hours_diff_bkt hours_diff


gen hw_diff = housework_wife - housework_head
browse hw_diff housework_wife housework_head
gen hw_diff_bkt = .
replace hw_diff_bkt = 1 if hw_diff <=10 & hw_diff >=-10
replace hw_diff_bkt = 2 if hw_diff >10 & hw_diff <=150
replace hw_diff_bkt = 3 if hw_diff <-10 & hw_diff >=-150

label define hw_diff_bkt 1 "Similar" 2 "Skew Female" 3 "Skew Male"
label values hw_diff_bkt hw_diff_bkt 

browse hw_diff_bkt hw_diff

// test spline at 0.5
mkspline earn_ratio1 0.5 earn_ratio2 = female_earn_pct
browse female_earn_pct earn_ratio1 earn_ratio2 

mkspline hrs_ratio1 0.5 hrs_ratio2 = female_hours_pct
browse female_hours_pct hrs_ratio1 hrs_ratio2

// alternate earnings measures
*Convert to 1000s
gen earnings_1000s = couple_earnings / 1000

*log
gen earnings_total = couple_earnings + 1 
gen earnings_ln = ln(earnings_total)
* browse TAXABLE_HEAD_WIFE_ earnings_total earnings_ln

// gen earnings_ln2 = ln(TAXABLE_HEAD_WIFE_)
// replace earnings_ln2 = 0 if TAXABLE_HEAD_WIFE_ <=0

*square
gen earnings_sq = TAXABLE_HEAD_WIFE_ * TAXABLE_HEAD_WIFE_

* groups
gen earnings_bucket=.
replace earnings_bucket = 0 if TAXABLE_HEAD_WIFE_ <=0
replace earnings_bucket = 1 if TAXABLE_HEAD_WIFE_ > 0 		& TAXABLE_HEAD_WIFE_ <=10000
replace earnings_bucket = 2 if TAXABLE_HEAD_WIFE_ > 10000 	& TAXABLE_HEAD_WIFE_ <=20000
replace earnings_bucket = 3 if TAXABLE_HEAD_WIFE_ > 20000 	& TAXABLE_HEAD_WIFE_ <=30000
replace earnings_bucket = 4 if TAXABLE_HEAD_WIFE_ > 30000 	& TAXABLE_HEAD_WIFE_ <=40000
replace earnings_bucket = 5 if TAXABLE_HEAD_WIFE_ > 40000 	& TAXABLE_HEAD_WIFE_ <=50000
replace earnings_bucket = 6 if TAXABLE_HEAD_WIFE_ > 50000 	& TAXABLE_HEAD_WIFE_ <=60000
replace earnings_bucket = 7 if TAXABLE_HEAD_WIFE_ > 60000 	& TAXABLE_HEAD_WIFE_ <=70000
replace earnings_bucket = 8 if TAXABLE_HEAD_WIFE_ > 70000 	& TAXABLE_HEAD_WIFE_ <=80000
replace earnings_bucket = 9 if TAXABLE_HEAD_WIFE_ > 80000 	& TAXABLE_HEAD_WIFE_ <=90000
replace earnings_bucket = 10 if TAXABLE_HEAD_WIFE_ > 90000 	& TAXABLE_HEAD_WIFE_ <=100000
replace earnings_bucket = 11 if TAXABLE_HEAD_WIFE_ > 100000 & TAXABLE_HEAD_WIFE_ <=150000
replace earnings_bucket = 12 if TAXABLE_HEAD_WIFE_ > 150000 & TAXABLE_HEAD_WIFE_ !=.

label define earnings_bucket 0 "0" 1 "0-10000" 2 "10000-20000" 3 "20000-30000" 4 "30000-40000" 5 "40000-50000" 6 "50000-60000" 7 "60000-70000" ///
8 "70000-80000" 9 "80000-90000" 10 "90000-100000" 11 "100000-150000" 12 "150000+"
label values earnings_bucket earnings_bucket

*Spline
mkspline knot1 0 knot2 20 knot3 = earnings_1000s


// want to create time-invariant indicator of hh type in first year of marriage (but need to make sure it's year both spouses in hh) - some started in of year gah. use DUR? or rank years and use first rank? (actually is that a better duration?)
browse id survey_yr rel_start_all dur hh_earn_type_bkd
bysort id (survey_yr): egen yr_rank=rank(survey_yr)
gen hh_earn_type_mar = hh_earn_type_bkd if yr_rank==1
bysort id (hh_earn_type_mar): replace hh_earn_type_mar=hh_earn_type_mar[1]
label values hh_earn_type_mar earn_type_bkd

browse id survey_yr rel_start_all yr_rank dur hh_earn_type_bkd hh_earn_type_mar

// okay rolling change in female earn pct - absolute or relative?! absolute for now...
sort id survey_yr
gen female_earn_pct_chg = (female_earn_pct-female_earn_pct[_n-1]) if id==id[_n-1]
browse id survey_yr rel_start_all female_earn_pct female_earn_pct_chg

// alt cohab
gen ever_cohab=0
replace ever_cohab=1 if cohab_with_wife==1 | cohab_with_other==1

// categorical for number of children
recode NUM_CHILDREN_ (0=0)(1=1)(2=2)(3/13=3), gen(num_children)
label define num_children 0 "None" 1 "1 Child" 2 "2 Children" 3 "3+ Children"
label values num_children num_children

// square age of marriage
gen age_mar_head_sq = age_mar_head * age_mar_head
gen age_mar_wife_sq = age_mar_wife * age_mar_wife

// create binary home ownership variable
gen home_owner=0
replace home_owner=1 if HOUSE_STATUS_==1

// create new variable for having kids under 6 in household
gen children_under6=0
replace children_under6=1 if children==1 & AGE_YOUNG_CHILD_ < 6

// create dummy variable for interval length
gen interval=.
replace interval=1 if inrange(survey_yr,1968,1997)
replace interval=2 if inrange(survey_yr,1999,2019)

// missing value inspect
inspect age_mar_wife // 0
inspect age_mar_head // 0
inspect race_head // 2
inspect same_race // 0
inspect either_enrolled // 0
inspect REGION_ // 0
inspect cohab_with_wife // 0
inspect cohab_with_other // 0 
inspect pre_marital_birth // 0

// indicators of paid leave
gen paid_leave_state=0
replace paid_leave_state=1 if inlist(STATE_,6,34,36,44)

gen time_leave=.
replace time_leave=0 if STATE_==6 & survey_yr < 2004
replace time_leave=0 if STATE_==34 & survey_yr < 2009
replace time_leave=0 if STATE_==36 & survey_yr < 2014
replace time_leave=0 if STATE_==44 & survey_yr < 2018
replace time_leave=1 if STATE_==6 & survey_yr >= 2004
replace time_leave=1 if STATE_==34 & survey_yr >= 2009
replace time_leave=1 if STATE_==36 & survey_yr >= 2014
replace time_leave=1 if STATE_==44 & survey_yr >= 2018

// minimum wage
gen min_wage=0
replace min_wage=1 if inlist(STATE_,2,4,5,6,8,9,10,11,12,15,17,23,24,25,26,27,29,30,31,34,35,36,39,41,44,46,50,53,54)

// keep if cohort==3 - temp removing this, want to try some things
keep if inrange(rel_start_all,1995,2014)
keep if inlist(IN_UNIT,0,1,2)
drop if STATE_==11 // DC is missing a lot of state variables, so need to remove.

********************************************************************************
**# Bookmark #1
* Merge onto policy data
********************************************************************************
/*
statemin: minimum wage - 2017, I updated up until 2020
masssociallib_est: attitudes - 2014
policysociallib_est: social policy - 2014
policyeconlib_est: economic policy - 2014
unemployment: unemployment rate - 2017, I updated up until 2020
state_cpi_bfh_est: state CPI - 2010
fed min: "T:\Research Projects\State data\data_keep\fed_min.dta"
new policy file: "T:\Research Projects\State data\data_keep\final_measures.dta"
*/

rename STATE_ state_fips
rename survey_yr year
merge m:1 state_fips year using "T:\Research Projects\State data\data_keep\cspp_data_1985_2019.dta", keepusing(statemin masssociallib_est policysociallib_est policyeconlib_est unemployment state_cpi_bfh_est pollib_median)

drop if _merge==2
drop _merge

merge m:1 year using "T:\Research Projects\State data\data_keep\fed_min.dta"
drop if _merge==2
drop _merge

merge m:1 state_fips year using "T:\Research Projects\State data\data_keep\final_measures.dta"
drop if _merge==2
drop _merge

merge m:1 state_fips year using "T:\Research Projects\State data\data_keep\state_lca.dta"
drop if _merge==2
drop _merge

merge m:1 state_fips year using "T:\Research Projects\State data\data_keep\structural_familism.dta"
drop if _merge==2
drop _merge

// I need to remember - not all variables have data past 2010 - should I just extend forward. I could definitely add in the min wage and unemployment
browse year state_fips state_cpi_bfh_est


// also want to test some binary variables
/*
gen above_fed_min=0
replace above_fed_min=1 if statemin>fed_min & statemin!=.
replace above_fed_min=. if statemin==.
*/

gen state_cpi = (state_cpi_bfh_est*100) + 100

gen above_fed_cpi=0
replace above_fed_cpi=1 if state_cpi>fed_cpi & state_cpi!=.
replace above_fed_cpi=. if state_cpi==.

gen social_policy=0
replace social_policy=1 if policysociallib_est>0 & policysociallib_est!=.

xtile social_policy_gp = policysociallib_est, nq(5)
tabstat policysociallib_est, by(social_policy_gp)
// pctile social_policy_score = policysociallib_est, nq(5) genp(social_policy_gp)

xtile liberal_attitudes_gp = masssociallib_est, nq(5)
tabstat masssociallib_est, by(liberal_attitudes_gp)

// is there enough variation?
recode disapproval (2.154=1) (2.20/2.21=2) (2.2405=3) (2.27/2.29=4) (2.3935=5), gen(disapproval_bkt)

// creating four categorical variable of sexism and attitudes
sum structural_sexism
gen sexism_scale=0
replace sexism_scale=1 if structural_sexism > `r(mean)'
replace sexism_scale=. if structural_sexism==.

sum structural_familism
gen familism_scale=0
replace familism_scale=1 if structural_familism > `r(mean)'
replace familism_scale=. if structural_familism==.

gen familism_scale_det=.
sum structural_familism, detail
replace familism_scale_det=1 if structural_familism < `r(p25)'
replace familism_scale_det=2 if structural_familism >= `r(p25)' & structural_familism <=`r(p75)'
replace familism_scale_det=3 if structural_familism > `r(p75)' & structural_familism!=.
tabstat structural_familism, by(familism_scale_det)

sum gender_mood
gen gender_scale=0
replace gender_scale=1 if gender_mood > `r(mean)'
replace gender_scale=. if gender_mood==.

tab sexism_scale gender_scale // these are inverse remember kim
tab familism_scale gender_scale // these both go in the same direction
tab familism_scale sexism_scale // opposite

gen state_cat = .
replace state_cat=1 if familism_scale==0 & gender_scale == 0 // both trad
replace state_cat=2 if familism_scale==0 & gender_scale == 1 //  trad families, egal att
replace state_cat=3 if familism_scale==1 & gender_scale == 0 // egal families, trad att
replace state_cat=4 if familism_scale==1 & gender_scale == 1 // both good

label define state_cat 1 "Both Trad" 2 "Policy Trad" 3 "Policy Support" 4 "Both Good"
label values state_cat state_cat

rename f1 family_factor


// aggregate attitudinal measure
* One just average current
egen regional_attitudes_pct = rowmean(genderroles_egal working_mom_egal preschool_egal)
egen regional_attitudes_mean = rowmean(fepresch fechld fefam)

pwcorr regional_attitudes_pct regional_attitudes_mean // .9247

* PCA (following Pessin) - need to do at raw mean, not percentage? - okay but for now, I only pulled in percentage gah, but i have okay
* these don't all go same way gah do with pct for now
alpha genderroles_egal working_mom_egal preschool_egal // 0.7360 - matches Pessin (0.74). she centered it not rescaled?
factor genderroles_egal working_mom_egal preschool_egal, ipf
predict f1
rename f1 regional_attitudes_factor
pwcorr regional_attitudes_pct regional_attitudes_factor // .9680

// rescale?
sum regional_attitudes_factor
gen regional_attitudes_scaled=(regional_attitudes_factor - r(min)) /  (r(max) - r(min))
sum regional_attitudes_scaled

set scheme cleanplots

**# Analysis starts

**Quick descriptives needed
tab dissolve_lag couple_educ_gp, row
tab dissolve_lag predclass, row
tabstat structural_familism gender_mood, by(dissolve_lag)
tab ft_wife
tab ft_wife if dissolve_lag==1
tab ft_head
tab ft_head if dissolve_lag==1

alpha min_above_fed_st paid_leave_st senate_dems_st welfare_all_st educ_spend_percap_st earn_ratio_neg_st // structural familism. 0.70
alpha unemployment_st child_pov_st gini_st // economic uncertainty. 0.54
alpha earn_ratio_st lfp_ratio_st pov_ratio_st pctmaleleg_st no_paid_leave_st no_dv_gun_law_st senate_rep_st // structural sexism. 0.61

********************************************************************************
********************************************************************************
* Checks re: no earners
********************************************************************************
********************************************************************************

* Parents of kids under 6
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.interval i.home_owner knot1 knot2 knot3 i.couple_educ_gp"  // i.num_children

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Support for Dual-Earning: Percentiles") ytitle("Predicted Probability of Marital Dissolution") title("") xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") legend(position(6) ring(3) rows(1))  // plot1opts(lcolor("navy") mcolor("navy")) ci1opts(color("navy")) plot2opts(lcolor("ltblue") mcolor("ltblue")) ci2opts(color("ltblue")) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

* Parents of kids under 6
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.interval i.home_owner knot1 knot2 knot3 i.couple_educ_gp"  // i.num_children

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==1 & state_fips!=11, or
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Support for Dual-Earning: Percentiles") ytitle("Predicted Probability of Marital Dissolution") title("") xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") legend(position(6) ring(3) rows(1))  // plot1opts(lcolor("navy") mcolor("navy")) ci1opts(color("navy")) plot2opts(lcolor("ltblue") mcolor("ltblue")) ci2opts(color("ltblue")) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

* Parents of kids under 6
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.interval i.home_owner knot1 knot2 knot3 i.couple_educ_gp"  // i.num_children

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type `controls' if children_under6==1 & state_fips!=11, or
margins hh_earn_type

********************************************************************************
********************************************************************************
********************************************************************************
* Overall trends
********************************************************************************
********************************************************************************
********************************************************************************

logit dissolve_lag i.dur i.couple_educ_gp, or

logit dissolve_lag i.dur i.couple_educ_gp##i.state_fips, or nocons // prob gonna be a lot of collinearity / inability to estimate with small states?
outreg2 using "$results/state_test.xls", sideway stats(coef pval) label dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

forvalues s=1/56{
	capture logistic dissolve_lag i.dur i.couple_educ_gp if state_fips==`s'
	capture estimates store m`s'
} 

estimates dir
estimates table *, keep(i.couple_educ_gp) eform b p

estout * using "$results/state_test.xls", replace keep(1.couple_educ_gp) eform cells(b p)

// estout *, eform cells(b(keep(i.couple_educ_gp)) p(keep(i.couple_educ_gp)))

/* test
logit dissolve_lag i.dur i.couple_educ_gp if STATE_==1, or
logit dissolve_lag i.dur i.couple_educ_gp if STATE_==2, or // won't estimate
logit dissolve_lag i.dur i.couple_educ_gp if STATE_==3, or // no obs
logit dissolve_lag i.dur i.couple_educ_gp if STATE_==4, or // will estimate
logit dissolve_lag i.dur i.couple_educ_gp if STATE_==5, or // also will estimate
*/

********************************************************************************
********************************************************************************
********************************************************************************
**# * Models to use
* (Generally from SDA, but moving up / redoing to keep things separate and organized)
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
* Models that match primary divorce paper to validate
********************************************************************************

//* Main findings (to match Chapter 2) *//
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth  i.num_children i.interval i.home_owner knot1 knot2 knot3"

** Total sample
logit dissolve_lag i.dur i.hh_earn_type i.couple_educ_gp `controls', or
margins, dydx(hh_earn_type)

logit dissolve_lag i.dur i.housework_bkt i.couple_educ_gp `controls', or
margins, dydx(housework_bkt)

** College-educated
logit dissolve_lag i.dur i.hh_earn_type  `controls' if couple_educ_gp==1, or
margins, dydx(hh_earn_type)

logit dissolve_lag i.dur i.housework_bkt `controls' if couple_educ_gp==1, or
margins, dydx(housework_bkt)

** Non-college-educated
logit dissolve_lag i.dur i.hh_earn_type  `controls' if couple_educ_gp==0, or
margins, dydx(hh_earn_type)

logit dissolve_lag i.dur i.housework_bkt `controls' if couple_educ_gp==0, or
margins, dydx(housework_bkt)

//* Does structural familism generally predict dissolution? *//
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth  i.num_children i.interval i.home_owner knot1 knot2 knot3"

logit dissolve_lag i.dur c.structural_familism, or // it does PRIOR to controls, so controls prob picking some of that up
logit dissolve_lag i.dur c.structural_familism i.couple_educ_gp, or
margins, at(structural_familism=(-6(1)10))
margins, at(structural_familism=(-6(2)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) ylabel(, angle(0))  ytitle("Predicted Probability of Marital Dissolution") title("")

logit dissolve_lag i.dur c.structural_familism i.couple_educ_gp `controls', or // it does PRIOR to controls, so controls prob picking some of that up
margins, at(structural_familism=(-6(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) ylabel(, angle(0))  ytitle("Predicted Probability of Marital Dissolution") title("")

********************************************************************************
* Adding interactions of variables now
********************************************************************************
//* STRUCTURAL FAMILISM *//
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth  i.num_children i.interval i.home_owner knot1 knot2 knot3"

*Overall
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' i.couple_educ_gp if hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))

logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' i.couple_educ_gp if housework_bkt < 4, or
margins, dydx(housework_bkt) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .3)) ylabel(-.1(.1).3, angle(0)) ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Female Housework" 2 "Male Housework") rows(1))

*No College
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))

logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if couple_educ_gp==0 & housework_bkt < 4, or
margins, dydx(housework_bkt) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .3)) ylabel(-.1(.1).3, angle(0)) ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Female Housework" 2 "Male Housework") rows(1))

*College
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))

logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if couple_educ_gp==1 & housework_bkt < 4, or
margins, dydx(housework_bkt) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .3)) ylabel(-.1(.1).3, angle(0)) ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Female Housework" 2 "Male Housework") rows(1))


//* INDIVIDUAL COMPONENTS *//
// egen structural_familism= rowtotal(paid_leave_st prek_enrolled_public_st min_above_fed_st earn_ratio_neg_st unemployment_percap_st abortion_protected_st welfare_all_st)

local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth  i.num_children i.interval i.home_owner knot1 knot2 knot3 i.couple_educ_gp"

/* Total Sample*/
* Structural familism
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if hh_earn_type < 4, or
outreg2 using "$results/dissolution_AMES_familism.xls", sideway stats(coef pval) label ctitle(1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Paid Leave
logit dissolve_lag i.dur i.paid_leave i.hh_earn_type i.paid_leave#i.hh_earn_type `controls' if hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(paid_leave=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(paidleave) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* PreK Enrollment
logit dissolve_lag i.dur c.prek_enrolled_public i.hh_earn_type c.prek_enrolled_public#i.hh_earn_type `controls' if hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(prek_enrolled_public=(.10(.10).50))
sum prek_enrolled_public, detail
margins, dydx(hh_earn_type) at(prek_enrolled_public=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(prek) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Min Wage
logit dissolve_lag i.dur i.min_above_fed i.hh_earn_type i.min_above_fed#i.hh_earn_type `controls' if hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(min_above_fed=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(minwage) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Earnings Ratio
logit dissolve_lag i.dur c.earn_ratio i.hh_earn_type c.earn_ratio#i.hh_earn_type `controls' if hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(earn_ratio=(1(.1)1.5))
sum earn_ratio, detail
margins, dydx(hh_earn_type) at(earn_ratio=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(earnings) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Unemployment Compensation
logit dissolve_lag i.dur c.unemployment_percap i.hh_earn_type c.unemployment_percap#i.hh_earn_type `controls' if hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(unemployment_percap=(50(50)500))
sum unemployment_percap, detail
margins, dydx(hh_earn_type) at(unemployment_percap=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(unemployment) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Abortion protected
logit dissolve_lag i.dur i.abortion_protected i.hh_earn_type i.abortion_protected#i.hh_earn_type `controls' if hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(abortion_protected=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(abortion) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Welfare Expenditures
logit dissolve_lag i.dur c.welfare_all i.hh_earn_type c.welfare_all#i.hh_earn_type `controls' if hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(welfare_all=(500(500)2500))
sum welfare_all, detail
margins, dydx(hh_earn_type) at(welfare_all=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(welfare) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* General State Policy Liberalism (from CSPP - use to compare to familism results)
logit dissolve_lag i.dur c.pollib_median i.hh_earn_type c.pollib_median#i.hh_earn_type `controls' if hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(pollib_median=(-2(1)3))
sum pollib_median, detail
margins, dydx(hh_earn_type) at(pollib_median=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(liberalism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth  i.num_children i.interval i.home_owner knot1 knot2 knot3"

/* No College */
* Structural familism - to test
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
outreg2 using "$results/dissolution_AMES_familism.xls", sideway stats(coef pval) label ctitle(No 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Paid Leave
logit dissolve_lag i.dur i.paid_leave i.hh_earn_type i.paid_leave#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(paid_leave=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no paidleave) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* PreK Enrollment
logit dissolve_lag i.dur c.prek_enrolled_public i.hh_earn_type c.prek_enrolled_public#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(prek_enrolled_public=(.10(.10).50))
sum prek_enrolled_public, detail
margins, dydx(hh_earn_type) at(prek_enrolled_public=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no prek) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Min Wage
logit dissolve_lag i.dur i.min_above_fed i.hh_earn_type i.min_above_fed#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(min_above_fed=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no minwage) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Earnings Ratio
logit dissolve_lag i.dur c.earn_ratio i.hh_earn_type c.earn_ratio#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(earn_ratio=(1(.1)1.5))
sum earn_ratio, detail
margins, dydx(hh_earn_type) at(earn_ratio=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no earnings) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Unemployment Compensation
logit dissolve_lag i.dur c.unemployment_percap i.hh_earn_type c.unemployment_percap#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(unemployment_percap=(50(50)500))
sum unemployment_percap, detail
margins, dydx(hh_earn_type) at(unemployment_percap=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no unemployment) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Abortion protected
logit dissolve_lag i.dur i.abortion_protected i.hh_earn_type i.abortion_protected#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(abortion_protected=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no abortion) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Welfare Expenditures
logit dissolve_lag i.dur c.welfare_all i.hh_earn_type c.welfare_all#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(welfare_all=(500(500)2500))
sum welfare_all, detail
margins, dydx(hh_earn_type) at(welfare_all=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no welfare) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* General State Policy Liberalism (from CSPP - use to compare to familism results)
logit dissolve_lag i.dur c.pollib_median i.hh_earn_type c.pollib_median#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(pollib_median=(-2(1)3))
sum pollib_median, detail
margins, dydx(hh_earn_type) at(pollib_median=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no liberalism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)


/* College */
* Structural familism - to test
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
outreg2 using "$results/dissolution_AMES_familism.xls", sideway stats(coef pval) label ctitle(Coll 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Paid Leave
logit dissolve_lag i.dur i.paid_leave i.hh_earn_type i.paid_leave#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(paid_leave=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col paidleave) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* PreK Enrollment
logit dissolve_lag i.dur c.prek_enrolled_public i.hh_earn_type c.prek_enrolled_public#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(prek_enrolled_public=(.10(.10).50))
sum prek_enrolled_public, detail
margins, dydx(hh_earn_type) at(prek_enrolled_public=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col prek) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Min Wage
logit dissolve_lag i.dur i.min_above_fed i.hh_earn_type i.min_above_fed#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(min_above_fed=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col minwage) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Earnings Ratio
logit dissolve_lag i.dur c.earn_ratio i.hh_earn_type c.earn_ratio#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(earn_ratio=(1(.1)1.5))
sum earn_ratio, detail
margins, dydx(hh_earn_type) at(earn_ratio=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col earnings) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Unemployment Compensation
logit dissolve_lag i.dur c.unemployment_percap i.hh_earn_type c.unemployment_percap#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(unemployment_percap=(50(50)500))
sum unemployment_percap, detail
margins, dydx(hh_earn_type) at(unemployment_percap=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col unemployment) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Abortion protected
logit dissolve_lag i.dur i.abortion_protected i.hh_earn_type i.abortion_protected#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(2.hh_earn_type) at(abortion_protected=(0 1)) post // had to update bc #3 is collinnear
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col abortion) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Welfare Expenditures
logit dissolve_lag i.dur c.welfare_all i.hh_earn_type c.welfare_all#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(welfare_all=(500(500)2500))
sum welfare_all, detail
margins, dydx(hh_earn_type) at(welfare_all=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col welfare) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* General State Policy Liberalism (from CSPP - use to compare to familism results)
logit dissolve_lag i.dur c.pollib_median i.hh_earn_type c.pollib_median#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(pollib_median=(-2(1)3))
sum pollib_median, detail
margins, dydx(hh_earn_type) at(pollib_median=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col liberalism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* College Breakdowns */
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth  i.num_children i.interval i.home_owner knot1 knot2 knot3"

* Structural familism
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_detail==1 & hh_earn_type < 4, or // both college
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(both familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_detail==2 & hh_earn_type < 4, or // her college college
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(her familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_detail==3 & hh_earn_type < 4, or // him college college
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(him familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* General State Policy Liberalism (from CSPP - use to compare to familism results)
logit dissolve_lag i.dur c.pollib_median i.hh_earn_type c.pollib_median#i.hh_earn_type `controls' if couple_educ_detail==1 & hh_earn_type < 4, or // both college
sum pollib_median, detail
margins, dydx(hh_earn_type) at(pollib_median=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(both liberalism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.pollib_median i.hh_earn_type c.pollib_median#i.hh_earn_type `controls' if couple_educ_detail==2 & hh_earn_type < 4, or // her college college
sum pollib_median, detail
margins, dydx(hh_earn_type) at(pollib_median=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(her liberalism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.pollib_median i.hh_earn_type c.pollib_median#i.hh_earn_type `controls' if couple_educ_detail==3 & hh_earn_type < 4, or // him college college
sum pollib_median, detail
margins, dydx(hh_earn_type) at(pollib_median=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(him liberalism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)


********************************************************************************
**# Results by parental status (restricted to parents of young children)
********************************************************************************
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.interval i.home_owner knot1 knot2 knot3 i.couple_educ_gp"  // i.num_children

/* Parents */
*Baseline model
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4, or
outreg2 using "$results/dissolution_AMES_familism_parents.xls", sideway stats(coef pval) label ctitle(Parents 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

* Structural familism
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4, or
outreg2 using "$results/dissolution_AMES_familism_parents.xls", sideway stats(coef pval) label ctitle(Parents 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(parent familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Paid Leave
logit dissolve_lag i.dur i.paid_leave i.hh_earn_type i.paid_leave#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(paid_leave=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(parent paidleave) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* PreK Enrollment
logit dissolve_lag i.dur c.prek_enrolled_public i.hh_earn_type c.prek_enrolled_public#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4, or
sum prek_enrolled_public, detail
margins, dydx(hh_earn_type) at(prek_enrolled_public=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(parent prek) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Min Wage
logit dissolve_lag i.dur i.min_above_fed i.hh_earn_type i.min_above_fed#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(min_above_fed=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(parent minwage) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Earnings Ratio
logit dissolve_lag i.dur c.earn_ratio i.hh_earn_type c.earn_ratio#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4, or
sum earn_ratio, detail
margins, dydx(hh_earn_type) at(earn_ratio=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(parent earnings) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Unemployment Compensation
logit dissolve_lag i.dur c.unemployment_percap i.hh_earn_type c.unemployment_percap#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4, or
sum unemployment_percap, detail
margins, dydx(hh_earn_type) at(unemployment_percap=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(parent unemployment) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Abortion protected
logit dissolve_lag i.dur i.abortion_protected i.hh_earn_type i.abortion_protected#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4, or
margins, dydx(2.hh_earn_type) at(abortion_protected=(0 1)) post // had to update bc #3 is collinnear
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(parent abortion) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Welfare Expenditures
logit dissolve_lag i.dur c.welfare_all i.hh_earn_type c.welfare_all#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4, or
sum welfare_all, detail
margins, dydx(hh_earn_type) at(welfare_all=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(parent welfare) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* All parents (robustness)
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children==1 & hh_earn_type < 4, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(allparent familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Full sample (robustness)
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type i.num_children `controls' if hh_earn_type < 4, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(all familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* NOT Parents */
* Structural familism
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==0 & hh_earn_type < 4, or
outreg2 using "$results/dissolution_AMES_familism_parents.xls", sideway stats(coef pval) label ctitle(nos 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(no familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Paid Leave
logit dissolve_lag i.dur i.paid_leave i.hh_earn_type i.paid_leave#i.hh_earn_type `controls' if children_under6==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(paid_leave=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(no paidleave) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* PreK Enrollment
logit dissolve_lag i.dur c.prek_enrolled_public i.hh_earn_type c.prek_enrolled_public#i.hh_earn_type `controls' if children_under6==0 & hh_earn_type < 4, or
sum prek_enrolled_public, detail
margins, dydx(hh_earn_type) at(prek_enrolled_public=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(no prek) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Min Wage
logit dissolve_lag i.dur i.min_above_fed i.hh_earn_type i.min_above_fed#i.hh_earn_type `controls' if children_under6==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type) at(min_above_fed=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(no minwage) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Earnings Ratio
logit dissolve_lag i.dur c.earn_ratio i.hh_earn_type c.earn_ratio#i.hh_earn_type `controls' if children_under6==0 & hh_earn_type < 4, or
sum earn_ratio, detail
margins, dydx(hh_earn_type) at(earn_ratio=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(no earnings) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Unemployment Compensation
logit dissolve_lag i.dur c.unemployment_percap i.hh_earn_type c.unemployment_percap#i.hh_earn_type `controls' if children_under6==0 & hh_earn_type < 4, or
sum unemployment_percap, detail
margins, dydx(hh_earn_type) at(unemployment_percap=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(no unemployment) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Abortion protected
logit dissolve_lag i.dur i.abortion_protected i.hh_earn_type i.abortion_protected#i.hh_earn_type `controls' if children_under6==0 & hh_earn_type < 4, or
margins, dydx(2.hh_earn_type) at(abortion_protected=(0 1)) post // had to update bc #3 is collinnear
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(no abortion) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Welfare Expenditures
logit dissolve_lag i.dur c.welfare_all i.hh_earn_type c.welfare_all#i.hh_earn_type `controls' if children_under6==0 & hh_earn_type < 4, or
sum welfare_all, detail
margins, dydx(hh_earn_type) at(welfare_all=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(no welfare) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth  i.num_children i.interval i.home_owner knot1 knot2 knot3"

/* College x Parental Status */
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==1 & couple_educ_gp==1 & hh_earn_type < 4, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(col parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==0 & couple_educ_gp==1 & hh_earn_type < 4, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(col no parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* No College x Parental Status */
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==1 & couple_educ_gp==0 & hh_earn_type < 4, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(no parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==0 & couple_educ_gp==0 & hh_earn_type < 4, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/dissolution_AMES_familism_parents.xls", ctitle(no no parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

********************************************************************************
**# * Does it matter how "male-BW" and "dual-earning" are operationalized?
********************************************************************************
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.interval i.home_owner knot1 knot2 knot3 i.couple_educ_gp"  // i.num_children

* current def
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot

* alt type
logit dissolve_lag i.dur c.structural_familism i.bw_type_gp c.structural_familism#i.bw_type_gp `controls' if children_under6==1, or
sum structural_familism, detail
margins, dydx(bw_type_gp) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
sum structural_familism, detail
margins bw_type_gp, at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot

* alt type
logit dissolve_lag i.dur c.structural_familism i.bw_type_gp_alt c.structural_familism#i.bw_type_gp_alt `controls' if children_under6==1, or
sum structural_familism, detail
margins, dydx(bw_type_gp_alt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
sum structural_familism, detail
margins bw_type_gp_alt, at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot

* alt type 2
logit dissolve_lag i.dur c.structural_familism ib3.bw_type c.structural_familism#ib3.bw_type `controls' if children_under6==1, or
sum structural_familism, detail
margins, dydx(bw_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))

* just men's FT employment
logit dissolve_lag i.dur c.structural_familism i.ft_head c.structural_familism#i.ft_head `controls' if children_under6==1, or
sum structural_familism, detail
margins, dydx(ft_head) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
sum structural_familism, detail
margins ft_head, at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot

* men's earnings

* just women's FT employment
logit dissolve_lag i.dur c.structural_familism i.ft_wife c.structural_familism#i.ft_wife `controls' if children_under6==1, or
sum structural_familism, detail
margins, dydx(ft_wife) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
sum structural_familism, detail
margins ft_wife, at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot

* women's earnings

tab ft_head hh_earn_type, row
tab ft_head hh_earn_type, col // see, this is the problem - 93% of dual-earning couples have a husband working FT. and 95% of male BW do. so yes, obviously less male BW within FT head being 0 but FT employment of the head tells us v. little about whether or not they are male BW or dual-earning, which is why i don't like this definition. it's like his employment is a given - but whose employment is bringing home the most money - aka perhaps being prioritized? because if we say both employed FT - it's v. likely her work is not comparable to his, so it's like hard to say if ideologically they are seen as equal. whereas money might tell us that? use the motherhood wage penalty as motivation? both FT masks the actual dynamics of types of employment and earnings and flex work and such. also like Phil Cohen's argument - men are usually SOLE provider while women aren't.

tab ft_wife hh_earn_type, row
tab ft_wife hh_earn_type, col // okay so in "female BW" households - men are still 50% likely to work FT. but in male BW households, women are only 35% likely to work FT. This is really Phil Cohen's article I think. so if we assume both partners are working - money is a better distinguisher? (to Oppenheimer's point). and that is the GENDER nuance too. like it isn't just WORK but the resources provided from work. Also Gupta and such has some of this. like the gendered meaning of earnings. I tihnk this relates to Gerson / Pedulla as well - equity.

tab bw_type_gp hh_earn_type, row // like only 50% of "both FT" are considered dual-earning. 36% are male BW in terms of money
tab bw_type_gp hh_earn_type, col

********************************************************************************
********************************************************************************
**# Descriptive statistics
********************************************************************************
********************************************************************************
// for ref: local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.interval i.home_owner knot1 knot2 knot3 i.couple_educ_gp"  // i.num_children

tab hh_earn_type, gen(earn_type)
tab race_head, gen(race_head)
tab region, gen(region)

putexcel set "$results/Table1_Descriptives_chapter3", replace
putexcel B1:C1 = "Parents of children under 6", merge border(bottom)
putexcel D1:E1 = "Total Sample", merge border(bottom)
putexcel B2 = ("All") C2 = ("Dissolved") D2 = ("All") E2 = ("Dissolved")
putexcel A3 = "Unique Couples"

putexcel A4 = "Dual Earning HH"
putexcel A5 = "Male Breadwinner"
putexcel A6 = "Female Breadwinner"
putexcel A7 = "Structural Support for Working Families"
putexcel A8 = "Total Couple Earnings"
putexcel A9 = "At least one partner has college degree"
putexcel A10 = "Couple owns home"
putexcel A11 = "Husband's age at marriage"
putexcel A12 = "Wife's age at marriage"
putexcel A13 = "Husband's Race: White"
putexcel A14 = "Husband's Race: Black"
putexcel A15 = "Husband's Race: Indian"
putexcel A16 = "Husband's Race: Asian"
putexcel A17 = "Husband's Race: Latino"
putexcel A18 = "Husband's Race: Other"
putexcel A19 = "Husband's Race: Multiracial"
putexcel A20 = "Husband and wife same race"
putexcel A21 = "Either partner enrolled in school"
putexcel A22 = "Region: Northeast"
putexcel A23 = "Region: North Central"
putexcel A24 = "Region: South"
putexcel A25 = "Region: West"
putexcel A26 = "Region: Alaska, Hawaii"
putexcel A27 = "Husband Wife Cohabit"
putexcel A28 = "Other Premarital Cohabit"
putexcel A29 = "First Birth Premarital"

local meanvars "earn_type1 earn_type2 earn_type3 structural_familism couple_earnings couple_educ_gp home_owner age_mar_head age_mar_wife race_head1 race_head2 race_head3 race_head4 race_head5 race_head6 race_head7 same_race either_enrolled region1 region2 region3 region4 region5 cohab_with_wife cohab_with_other pre_marital_birth"

// Parents
forvalues w=1/26{
	local row=`w'+3
	local var: word `w' of `meanvars'
	mean `var' if children_under6==1
	matrix t`var'= e(b)
	putexcel B`row' = matrix(t`var'), nformat(#.#%)
}

// those who dissolved; value when dissolve_lag==1
forvalues w=1/26{
	local row=`w'+3
	local var: word `w' of `meanvars' 
	mean `var' if dissolve_lag==1 & children_under6==1
	matrix t`var'= e(b)
	putexcel C`row' = matrix(t`var'), nformat(#.#%)
}


// All couples
forvalues w=1/26{
	local row=`w'+3
	local var: word `w' of `meanvars'
	mean `var'
	matrix t`var'= e(b)
	putexcel D`row' = matrix(t`var'), nformat(#.#%)
}

// those who dissolved; value when dissolve_lag==1
forvalues w=1/26{
	local row=`w'+3
	local var: word `w' of `meanvars'
	mean `var' if dissolve_lag==1
	matrix t`var'= e(b)
	putexcel E`row' = matrix(t`var'), nformat(#.#%)
}

mean dur if children_under6==1
mean dur if children_under6==1 & dissolve_lag==1
mean dur
mean dur if dissolve_lag==1

unique id if children_under6==1
unique id if children_under6==1 & dissolve_lag==1
unique id 
unique id if dissolve_lag==1

********************************************************************************
**# Unpaid Labor
* Just doing key IV across groups of interest (aka structural familism)
********************************************************************************
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth  i.num_children i.interval i.home_owner knot1 knot2 knot3"

/* No College */
logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if couple_educ_gp==0 & housework_bkt < 4, or
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(no familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

/* College */
logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if couple_educ_gp==1 & housework_bkt < 4, or
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(col familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* College Breakdowns */
logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if couple_educ_detail==1 & housework_bkt < 4, or // both college
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(both familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if couple_educ_detail==2 & housework_bkt < 4, or // her college
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(her familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if couple_educ_detail==3 & housework_bkt < 4, or // him college
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(him familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* College x Parental Status */
logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if children_under6==1 & couple_educ_gp==1 & housework_bkt < 4, or
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(col parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if children_under6==0 & couple_educ_gp==1 & housework_bkt < 4, or
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(col no parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* No College x Parental Status */
logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if children_under6==1 & couple_educ_gp==0 & housework_bkt < 4, or
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(no parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if children_under6==0 & couple_educ_gp==0 & housework_bkt < 4, or
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(no no parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* Overall */
logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' i.couple_educ_gp if housework_bkt < 4, or
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(ovrl familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* Overall x Parental Status */
logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' i.couple_educ_gp if children_under6==1 & housework_bkt < 4, or
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(ovrl par familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' i.couple_educ_gp if children_under6==0 & housework_bkt < 4, or
sum structural_familism, detail
margins, dydx(housework_bkt) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_unpaid.xls", ctitle(ovrl not familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

********************************************************************************
**# Combined paid and unpaid labor
* Just doing key IV across groups of interest (aka structural familism)
********************************************************************************
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth  i.num_children i.interval i.home_owner knot1 knot2 knot3"

/* No College */
logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' if couple_educ_gp==0, or
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(no familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

logit dissolve_lag i.dur c.structural_familism ib2.division_bucket c.structural_familism#ib2.division_bucket `controls' if couple_educ_gp==0, or
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))

/* College */
logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' if couple_educ_gp==1, or
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(col familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism ib2.division_bucket c.structural_familism#ib2.division_bucket `controls' if couple_educ_gp==1, or
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))

/* College Breakdowns */
logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' if couple_educ_detail==1, or // both college
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(both familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' if couple_educ_detail==2, or // her college
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(her familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' if couple_educ_detail==3, or // him college
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(him familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* College x Parental Status */
logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' if children_under6==1 & couple_educ_gp==1, or
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(col parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' if children_under6==0 & couple_educ_gp==1, or
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(col no parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* No College x Parental Status */
logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' if children_under6==1 & couple_educ_gp==0, or
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(no parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' if children_under6==0 & couple_educ_gp==0, or
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(no no parent) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* Overall */
logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' i.couple_educ_gp, or
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(ovrl familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* Overall x Parental Status */
logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' i.couple_educ_gp if children_under6==1, or
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(ovrl par familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

logit dissolve_lag i.dur c.structural_familism i.division_bucket c.structural_familism#i.division_bucket `controls' i.couple_educ_gp if children_under6==0, or
sum structural_familism, detail
margins, dydx(division_bucket) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)')) post
outreg2 using "$results/AMES_familism_combined.xls", ctitle(ovrl not familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

********************************************************************************
********************************************************************************
**# Margins: using percentiles for "high" and "low" to get figures
********************************************************************************
********************************************************************************

local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth  i.num_children i.interval i.home_owner knot1 knot2 knot3"

// Total Sample
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' i.couple_educ_gp if hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p25)' `r(p75)'))
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p25)' `r(p75)'))

sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Familism Scale: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

// No College
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p25)' `r(p75)'))
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p25)' `r(p75)'))

sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Familism Scale: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

// College
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p25)' `r(p75)'))
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p25)' `r(p75)'))

sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Familism Scale: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))


// Parents
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.interval i.home_owner knot1 knot2 knot3 i.couple_educ_gp"  // i.num_children

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Familism Scale: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") plot1opts(lcolor("navy") mcolor("navy")) ci1opts(color("navy")) plot2opts(lcolor("ltblue") mcolor("ltblue")) ci2opts(color("ltblue")) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

// NOT Parents
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==0 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Familism Scale: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") plot1opts(lcolor("navy") mcolor("navy")) ci1opts(color("navy")) plot2opts(lcolor("ltblue") mcolor("ltblue")) ci2opts(color("ltblue")) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))s

// Parents + college
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.interval i.home_owner knot1 knot2 knot3"

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==1 & couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Familism Scale: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") plot1opts(lcolor("navy") mcolor("navy")) ci1opts(color("navy")) plot2opts(lcolor("ltblue") mcolor("ltblue")) ci2opts(color("ltblue")) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==1 & couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Familism Scale: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") plot1opts(lcolor("navy") mcolor("navy")) ci1opts(color("navy")) plot2opts(lcolor("ltblue") mcolor("ltblue")) ci2opts(color("ltblue")) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

// NOT parents + college
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.interval i.home_owner knot1 knot2 knot3"

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==0 & couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Familism Scale: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") plot1opts(lcolor("navy") mcolor("navy")) ci1opts(color("navy")) plot2opts(lcolor("ltblue") mcolor("ltblue")) ci2opts(color("ltblue")) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==0 & couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Familism Scale: percentiles") yline(0,lcolor(gs3))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") plot1opts(lcolor("navy") mcolor("navy")) ci1opts(color("navy")) plot2opts(lcolor("ltblue") mcolor("ltblue")) ci2opts(color("ltblue")) // yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

********************************************************************************
* Figures to use (dissertation)
********************************************************************************
* Parents of kids under 6
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.interval i.home_owner knot1 knot2 knot3 i.couple_educ_gp"  // i.num_children

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children_under6==1 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Support for Dual-Earning: Percentiles") ytitle("Predicted Probability of Marital Dissolution") title("") xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") legend(position(6) ring(3) rows(1))  // plot1opts(lcolor("navy") mcolor("navy")) ci1opts(color("navy")) plot2opts(lcolor("ltblue") mcolor("ltblue")) ci2opts(color("ltblue")) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

* All parents
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if children==1 & hh_earn_type < 4, or
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Support for Dual-Earning: Percentiles") ytitle("Predicted Probability of Marital Dissolution") title("") xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") legend(position(6) ring(3) rows(1))  // plot1opts(lcolor("navy") mcolor("navy")) ci1opts(color("navy")) plot2opts(lcolor("ltblue") mcolor("ltblue")) ci2opts(color("ltblue")) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

* Total sample
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.interval i.home_owner knot1 knot2 knot3 i.couple_educ_gp i.num_children" 

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if hh_earn_type < 4, or
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p5)' `r(p25)' `r(p50)' `r(p75)' `r(p95)'))
marginsplot, xtitle("Structural Support for Dual-Earning: Percentiles") ytitle("Predicted Probability of Marital Dissolution") title("") xlabel(-3.12 "5th" -0.64 "25th" 1.27 "50th" 3.57 "75th" 12.48 "95th") legend(position(6) ring(3) rows(1))  // plot1opts(lcolor("navy") mcolor("navy")) ci1opts(color("navy")) plot2opts(lcolor("ltblue") mcolor("ltblue")) ci2opts(color("ltblue")) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))

********************************************************************************
********************************************************************************
********************************************************************************
**# For ASA Paper
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
* Just policy variables -> do they predict dissolution?
********************************************************************************
/*
attitudes: disapproval genderroles_egal working_mom_egal preschool_egal
	margins, at(disapproval=(2.1(.10)2.4))
	margins, at(genderroles_egal=(0.56(.04)0.72))
	margins, at(working_mom_egal=(0.66(.02)0.72))
	margins, at(preschool_egal=(0.58(.02)0.64))
regional_attitudes_factor
	margins, at(regional_attitudes_factor=(-2.0(1)2.0))
min_above_fed: binary yes / no
	margins, at(min_above_fed=(0 1))
unemployment: continuous
	margins, at(unemployment=(3(2)11))
cc_pct_income: continuous
	margins, at(cc_pct_income=(0.05(.10)0.35))
paid_leave: binary yes / no
	margins, at(paid_leave=(0 1))
senate_dems: higher = more dems; .88 correlation with house
	margins, at(senate_dems=(0(.10)0.8))
cc_subsidies: higher = more eligible kids served
	margins, at(cc_subsidies=(0.05(.10)0.45))
LCA: predclass
	margins, at(predclass=(1(1)4))
*/

log using "$logdir/policy_dissolution.log", replace

// By education
forvalues g=0/1{
	qui melogit dissolve_lag i.dur disapproval if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(disapproval)
	margins, at(disapproval=(2.1(.10)2.4))

	qui melogit dissolve_lag i.dur regional_attitudes_factor if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(regional_attitudes_factor)
	margins, at(regional_attitudes_factor=(-2.0(1)2.0))
	
	qui melogit dissolve_lag i.dur genderroles_egal if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(genderroles_egal)
	margins, at(genderroles_egal=(0.56(.04)0.72))
	
	qui melogit dissolve_lag i.dur working_mom_egal if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(working_mom_egal)
	margins, at(working_mom_egal=(0.66(.02)0.72))
	
	qui melogit dissolve_lag i.dur preschool_egal if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(preschool_egal)
	margins, at(preschool_egal=(0.58(.02)0.64))
	
	qui melogit dissolve_lag i.dur i.min_above_fed if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(min_above_fed)
	margins, at(min_above_fed=(0 1))
	
	qui melogit dissolve_lag i.dur unemployment if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(unemployment)
	margins, at(unemployment=(3(2)11))	
	
	qui melogit dissolve_lag i.dur cc_pct_income if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(cc_pct_income)
	margins, at(cc_pct_income=(0.05(.10)0.35))
	
	qui melogit dissolve_lag i.dur i.predclass if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(predclass)
	margins, at(predclass=(1(1)4))
	
	qui melogit dissolve_lag i.dur senate_dems if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(senate_dems)
	margins, at(senate_dems=(0(.10)0.8))	
	
	qui melogit dissolve_lag i.dur cc_subsidies if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(cc_subsidies)
	margins, at(cc_subsidies=(0.05(.10)0.45))
	
	qui melogit dissolve_lag i.dur i.paid_leave if couple_educ_gp==`g' || state_fips:, or
	margins, dydx(paid_leave)
	margins, at(paid_leave=(0 1))
}

// Overall
 qui melogit dissolve_lag i.dur disapproval  || state_fips:, or
 margins, dydx(disapproval)
 margins, at(disapproval=(2.1(.10)2.4))
 
 qui melogit dissolve_lag i.dur regional_attitudes_factor || state_fips:, or
 margins, dydx(regional_attitudes_factor)
 margins, at(regional_attitudes_factor=(-2.0(1)2.0))
 
 qui melogit dissolve_lag i.dur genderroles_egal  || state_fips:, or
 margins, dydx(genderroles_egal)
 margins, at(genderroles_egal=(0.56(.04)0.72))
 
 qui melogit dissolve_lag i.dur working_mom_egal  || state_fips:, or
 margins, dydx(working_mom_egal)
 margins, at(working_mom_egal=(0.66(.02)0.72))
 
 qui melogit dissolve_lag i.dur preschool_egal  || state_fips:, or
 margins, dydx(preschool_egal)
 margins, at(preschool_egal=(0.58(.02)0.64))
 
 qui melogit dissolve_lag i.dur i.min_above_fed  || state_fips:, or
 margins, dydx(min_above_fed)
 margins, at(min_above_fed=(0 1))
 
 qui melogit dissolve_lag i.dur unemployment  || state_fips:, or
 margins, dydx(unemployment)
 margins, at(unemployment=(3(2)11)) 
 
 qui melogit dissolve_lag i.dur cc_pct_income  || state_fips:, or
 margins, dydx(cc_pct_income)
 margins, at(cc_pct_income=(0.05(.10)0.35))
 
 qui melogit dissolve_lag i.dur i.predclass  || state_fips:, or
 margins, dydx(predclass)
 margins, at(predclass=(1(1)4))
 
 qui melogit dissolve_lag i.dur senate_dems  || state_fips:, or
 margins, dydx(senate_dems)
 margins, at(senate_dems=(0(.10)0.8)) 
 
 qui melogit dissolve_lag i.dur cc_subsidies  || state_fips:, or
 margins, dydx(cc_subsidies)
 margins, at(cc_subsidies=(0.05(.10)0.45))
 
 qui melogit dissolve_lag i.dur i.paid_leave  || state_fips:, or
 margins, dydx(paid_leave)
 margins, at(paid_leave=(0 1))

log close

********************************************************************************
* Just looking for state variation atm
********************************************************************************
////////// No College \\\\\\\\\\\/

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth"
forvalues s=1/56{
	capture logistic dissolve_lag i.dur earnings_1000s `controls' if couple_educ_gp==0 & state_fips==`s'
	capture margins, dydx(earnings_1000s) post
	capture estimates store no_a`s'

	capture logistic dissolve_lag i.dur i.hh_earn_type earnings_1000s `controls' if couple_educ_gp==0 & state_fips==`s'
	capture margins, dydx(hh_earn_type) post
	capture estimates store no_b`s'
	
	capture logistic dissolve_lag i.dur i.ft_head i.ft_wife earnings_1000s `controls' if couple_educ_gp==0 & state_fips==`s'
	capture margins, dydx(ft_head ft_wife) post
	capture estimates store no_c`s'
	
} 

estimates dir
estimates table *, b p
estout no_* using "$results/state_no_college.xls", replace cells(b p)

////////// College \\\\\\\\\\\/

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth"
forvalues s=1/56{
	capture logistic dissolve_lag i.dur earnings_1000s `controls' if couple_educ_gp==1 & state_fips==`s'
	capture margins, dydx(earnings_1000s) post
	capture estimates store coll_a`s'

	capture logistic dissolve_lag i.dur i.hh_earn_type earnings_1000s `controls' if couple_educ_gp==1 & state_fips==`s'
	capture margins, dydx(hh_earn_type) post
	capture estimates store coll_b`s'
	
	capture logistic dissolve_lag i.dur i.ft_head i.ft_wife earnings_1000s `controls' if couple_educ_gp==1 & state_fips==`s'
	capture margins, dydx(ft_head ft_wife) post
	capture estimates store coll_c`s'
	
} 

estout coll_* using "$results/state_college.xls", replace cells(b p)


********************************************************************************
**# MODELS WITH INTERACTIONS
********************************************************************************
// log using "$logdir/policy_interactions_all.log", replace
// log using "$logdir/policy_interactions_all.log", append

********************************************************************************
* Interactions: Paid Work Arrangement - from ASA
********************************************************************************
log using "$logdir/policy_interactions_paid.log", replace
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3"

/* No College */

**attitude summary
melogit dissolve_lag i.dur c.disapproval i.hh_earn_type c.disapproval#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(disapproval=(2.1(.10)2.4))

**regional attitudes: factor var
melogit dissolve_lag i.dur c.regional_attitudes_factor i.hh_earn_type c.regional_attitudes_factor#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(regional_attitudes_factor=(-2.0(1)2.0))

	**regional attitudes: gender roles
	melogit dissolve_lag i.dur c.genderroles_egal i.hh_earn_type c.genderroles_egal#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
	margins, dydx(hh_earn_type) at(genderroles_egal=(0.56(.04)0.72))

	**regional attitudes: working mom
	melogit dissolve_lag i.dur c.working_mom_egal i.hh_earn_type c.working_mom_egal#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
	margins, dydx(hh_earn_type) at(working_mom_egal=(0.66(.02)0.72))

	**regional attitudes: preschool
	melogit dissolve_lag i.dur c.preschool_egal i.hh_earn_type c.preschool_egal#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
	margins, dydx(hh_earn_type) at(preschool_egal=(0.58(.02)0.64))

** Minimum wage
melogit dissolve_lag i.dur i.min_above_fed i.hh_earn_type i.min_above_fed#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(min_above_fed=(0 1))

	*Trying continuous
	melogit dissolve_lag i.dur statemin i.hh_earn_type c.statemin#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
	margins, dydx(hh_earn_type) at(statemin=(4(2)10))

**% democrats in senate
melogit dissolve_lag i.dur c.senate_dems i.hh_earn_type c.senate_dems#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(senate_dems=(0(.10)0.8))

**Paid Leave
melogit dissolve_lag i.dur i.paid_leave i.hh_earn_type i.paid_leave#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(paid_leave=(0 1))

**Childcare costs
melogit dissolve_lag i.dur c.cc_pct_income i.hh_earn_type c.cc_pct_income#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(cc_pct_income=(0.05(.10)0.35))

**State Latent Class
melogit dissolve_lag i.dur i.predclass i.hh_earn_type i.predclass#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(predclass=(1(1)4))

**Unemployment
melogit dissolve_lag i.dur c.unemployment i.hh_earn_type c.unemployment#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(unemployment=(3(2)11))

**Childcare subsidies
melogit dissolve_lag i.dur c.cc_subsidies i.hh_earn_type c.cc_subsidies#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(cc_subsidies=(0.05(.10)0.45))

**Structural Sexism
melogit dissolve_lag i.dur c.structural_sexism i.hh_earn_type c.structural_sexism#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(structural_sexism=(-9(1)5))

* Alt attitudes
melogit dissolve_lag i.dur c.gender_mood i.hh_earn_type c.gender_mood#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(gender_mood=(50(5)75))

/* Tabling for now
**Unemployment compensation
melogit dissolve_lag i.dur c.unemployment_comp i.hh_earn_type c.unemployment_comp#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(unemployment_comp=(200(200)800))

**Prek-12 education spending
melogit dissolve_lag i.dur c.educ_spend i.hh_earn_type c.educ_spend#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(educ_spend=(4000(1000)9000))

**Right to Work
melogit dissolve_lag i.dur i.right2work i.hh_earn_type i.right2work#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(right2work=(0 1))
*/

/* College */

**attitude summary
melogit dissolve_lag i.dur c.disapproval i.hh_earn_type c.disapproval#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(disapproval=(2.1(.10)2.4))

**regional attitudes: factor var
melogit dissolve_lag i.dur c.regional_attitudes_factor i.hh_earn_type c.regional_attitudes_factor#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(regional_attitudes_factor=(-2.0(1)2.0))

	**regional attitudes: gender roles
	melogit dissolve_lag i.dur c.genderroles_egal i.hh_earn_type c.genderroles_egal#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
	margins, dydx(hh_earn_type) at(genderroles_egal=(0.56(.04)0.72))

	**regional attitudes: working mom
	melogit dissolve_lag i.dur c.working_mom_egal i.hh_earn_type c.working_mom_egal#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
	margins, dydx(hh_earn_type) at(working_mom_egal=(0.66(.02)0.72))

	**regional attitudes: preschool
	melogit dissolve_lag i.dur c.preschool_egal i.hh_earn_type c.preschool_egal#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
	margins, dydx(hh_earn_type) at(preschool_egal=(0.58(.02)0.64))

** Minimum wage
melogit dissolve_lag i.dur i.min_above_fed i.hh_earn_type i.min_above_fed#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(min_above_fed=(0 1))

	*Trying continuous
	melogit dissolve_lag i.dur statemin i.hh_earn_type c.statemin#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
	margins, dydx(hh_earn_type) at(statemin=(4(2)10))

**% democrats in senate
melogit dissolve_lag i.dur c.senate_dems i.hh_earn_type c.senate_dems#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(senate_dems=(0(.10)0.8))

**Paid Leave
melogit dissolve_lag i.dur i.paid_leave i.hh_earn_type i.paid_leave#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(paid_leave=(0 1))

**Childcare costs
melogit dissolve_lag i.dur c.cc_pct_income i.hh_earn_type c.cc_pct_income#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(cc_pct_income=(0.05(.10)0.35))

**State Latent Class
melogit dissolve_lag i.dur i.predclass i.hh_earn_type i.predclass#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(predclass=(1(1)4))

**Unemployment
melogit dissolve_lag i.dur c.unemployment i.hh_earn_type c.unemployment#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(unemployment=(3(2)11))

**Childcare subsidies
melogit dissolve_lag i.dur c.cc_subsidies i.hh_earn_type c.cc_subsidies#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(cc_subsidies=(0.05(.10)0.45))

* Structural sexism
melogit dissolve_lag i.dur c.structural_sexism i.hh_earn_type c.structural_sexism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(structural_sexism=(-9(1)5))

* Alt attitudes
melogit dissolve_lag i.dur c.gender_mood i.hh_earn_type c.gender_mood#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(gender_mood=(50(5)75))

/* Tabling for now
**Unemployment compensation
melogit dissolve_lag i.dur c.unemployment_comp i.hh_earn_type c.unemployment_comp#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(unemployment_comp=(200(200)800))

**Prek-12 education spending
melogit dissolve_lag i.dur c.educ_spend i.hh_earn_type c.educ_spend#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(educ_spend=(4000(1000)9000))

**Right to Work
melogit dissolve_lag i.dur i.right2work i.hh_earn_type i.right2work#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
margins, dydx(hh_earn_type) at(right2work=(0 1))

*/

log close

********************************************************************************
**# Interactions: for SDA
********************************************************************************
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3"
logit dissolve_lag i.dur i.hh_earn_type `controls' i.couple_educ_gp if hh_earn_type < 4, or
logit dissolve_lag i.dur i.ft_head i.ft_wife `controls' i.couple_educ_gp if hh_earn_type < 4, or

// test 
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3"
melogit dissolve_lag i.dur c.structural_sexism i.hh_earn_type c.structural_sexism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 || state_fips:, or
logit dissolve_lag i.dur c.structural_sexism i.hh_earn_type c.structural_sexism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
logit dissolve_lag i.dur i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or

set scheme cleanplots

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3"
logit dissolve_lag i.dur i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
margins, dydx(hh_earn_type)
logit dissolve_lag i.dur i.ft_head i.ft_wife `controls' if couple_educ_gp==0 & hh_earn_type < 4, or
margins, dydx(ft_head ft_wife)

logit dissolve_lag i.dur i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type)
logit dissolve_lag i.dur ib3.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(hh_earn_type)
logit dissolve_lag i.dur i.ft_head i.ft_wife `controls' if couple_educ_gp==1 & hh_earn_type < 4, or
margins, dydx(ft_head ft_wife)

// temp code - can it be as simple as this?!
log using "$logdir/policy_interactions_sexism.log", replace

//* Does structural familism generally predict dissolution? *//

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3"
logit dissolve_lag i.dur c.structural_familism if state_fips!=11, or // it does PRIOR to controls, so controls prob picking some of that up
logit dissolve_lag i.dur c.structural_familism i.couple_educ_gp if state_fips!=11, or
margins, at(structural_familism=(-6(1)10))
margins, at(structural_familism=(-6(2)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) ylabel(, angle(0))  ytitle("Predicted Probability of Marital Dissolution") title("")

logit dissolve_lag i.dur c.structural_familism `controls' i.state_fips if state_fips!=11, or

logit dissolve_lag i.dur c.structural_familism if state_fips!=11 & couple_educ_gp==0, or
logit dissolve_lag i.dur c.structural_familism `controls'  if state_fips!=11 & couple_educ_gp==0, or // so again, only prior to controls
logit dissolve_lag i.dur c.structural_familism if state_fips!=11 & couple_educ_gp==1, or // doesn't even here without controls
logit dissolve_lag i.dur c.structural_familism `controls'  if state_fips!=11 & couple_educ_gp==1, or

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3"
logit dissolve_lag i.dur c.structural_sexism if state_fips!=11, or // true for sexism as well, interesting
logit dissolve_lag i.dur c.structural_sexism `controls'  if state_fips!=11, or

logit dissolve_lag i.dur c.structural_familism if state_fips!=11 & couple_educ_gp==0, or // no association
logit dissolve_lag i.dur c.structural_familism if state_fips!=11 & couple_educ_gp==1, or // not sig
logit dissolve_lag i.dur i.couple_educ_gp##c.structural_familism if state_fips!=11, or

//* Paid Work *//

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3"
* Structural sexism
logit dissolve_lag i.dur c.structural_sexism i.hh_earn_type c.structural_sexism#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_sexism=(-9(2)5))

// marginsplot, xtitle("Structural Sexism Scale") yline(0,lcolor(gs3)) ylabel(, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") plotregion(fcolor(white)) graphregion(fcolor(white)) title("")  legend(region(lcolor(white))) legend(size(small)) plot1opts(lcolor("blue")  msize("small") mcolor("blue"))  plot2opts(lcolor("pink") mcolor("pink") msize("small")) ciopts(color(*.4)) //  ci2opts(lcolor("pink")) ci1opts(lcolor("blue")) xlabel(, angle(0) labsize(small))

marginsplot, xtitle("Structural Sexism Scale") yline(0,lcolor(gs3)) ylabel(, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))
// graph query, schemes

* Structural familism
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))

logit dissolve_lag i.dur c.structural_familism_v0 i.hh_earn_type c.structural_familism_v0#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_familism_v0=(-6(2)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))

* Control for attitudes
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' c.gender_mood if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))

* Alt attitudes
logit dissolve_lag i.dur c.gender_mood i.hh_earn_type c.gender_mood#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(gender_mood=(50(5)75))
marginsplot, xtitle("Supportive Gender Role Attitudes") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))

* Combo
logit dissolve_lag i.dur i.state_cat i.hh_earn_type i.state_cat#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4  & state_fips!=11, or
margins, dydx(hh_earn_type) at(state_cat=(1(1)4))

* Structural sexism
logit dissolve_lag i.dur c.structural_sexism i.hh_earn_type c.structural_sexism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_sexism=(-9(2)5))
marginsplot, xtitle("Structural Sexism Scale") yline(0,lcolor(gs3)) ylabel(, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))

* Structural familism
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))

* Control for attitudes
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' c.gender_mood if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))

* Alt attitudes
logit dissolve_lag i.dur c.gender_mood i.hh_earn_type c.gender_mood#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4  & state_fips!=11, or
margins, dydx(hh_earn_type) at(gender_mood=(50(5)75))
marginsplot, xtitle("Supportive Gender Role Attitudes") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0)) ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1))

* Combo
logit dissolve_lag i.dur i.state_cat i.hh_earn_type i.state_cat#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(state_cat=(1(1)4))

//* Unpaid Work *//

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3"
* Structural sexism
logit dissolve_lag i.dur c.structural_sexism i.housework_bkt c.structural_sexism#i.housework_bkt `controls' if couple_educ_gp==0 & housework_bkt < 4 & state_fips!=11, or
margins, dydx(housework_bkt) at(structural_sexism=(-9(2)5))
marginsplot, xtitle("Structural Sexism Scale") yline(0,lcolor(gs3)) ylabel(, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Female Housework" 2 "Male Housework") rows(1))

* Structural familism
logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if couple_educ_gp==0 & housework_bkt < 4 & state_fips!=11, or
margins, dydx(housework_bkt) at(structural_familism=(-6(2)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .3)) ylabel(-.1(.1).3, angle(0)) ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Female Housework" 2 "Male Housework") rows(1))

* Alt attitudes
logit dissolve_lag i.dur c.gender_mood i.housework_bkt c.gender_mood#i.housework_bkt `controls' if couple_educ_gp==0 & housework_bkt < 4 & state_fips!=11, or
margins, dydx(housework_bkt) at(gender_mood=(50(5)75))
marginsplot, xtitle("Supportive Gender Role Attitudes") yline(0,lcolor(gs3)) yscale(range(-.1 .3)) ylabel(-.1(.1).3, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Female Housework" 2 "Male Housework") rows(1))

* Combo
logit dissolve_lag i.dur i.state_cat i.housework_bkt i.state_cat#i.housework_bkt `controls' if couple_educ_gp==0 & housework_bkt < 4  & state_fips!=11, or
margins, dydx(housework_bkt) at(state_cat=(1(1)4))

* Structural sexism
logit dissolve_lag i.dur c.structural_sexism i.housework_bkt c.structural_sexism#i.housework_bkt `controls' if couple_educ_gp==1 & housework_bkt < 4 & state_fips!=11, or
margins, dydx(housework_bkt) at(structural_sexism=(-9(2)5))
marginsplot, xtitle("Structural Sexism Scale") yline(0,lcolor(gs3)) ylabel(, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Female Housework" 2 "Male Housework") rows(1))

* Structural familism
logit dissolve_lag i.dur c.structural_familism i.housework_bkt c.structural_familism#i.housework_bkt `controls' if couple_educ_gp==1 & housework_bkt < 4 & state_fips!=11, or
margins, dydx(housework_bkt) at(structural_familism=(-6(2)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .3)) ylabel(-.1(.1).3, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Female Housework" 2 "Male Housework") rows(1))

* Alt attitudes
logit dissolve_lag i.dur c.gender_mood i.housework_bkt c.gender_mood#i.housework_bkt `controls' if couple_educ_gp==1 & housework_bkt < 4  & state_fips!=11, or
margins, dydx(housework_bkt) at(gender_mood=(50(5)75))
marginsplot, xtitle("Supportive Gender Role Attitudes") yline(0,lcolor(gs3)) yscale(range(-.1 .3)) ylabel(-.1(.1).3, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Female Housework" 2 "Male Housework") rows(1))

* Combo
logit dissolve_lag i.dur i.state_cat i.housework_bkt i.state_cat#i.housework_bkt `controls' if couple_educ_gp==1 & housework_bkt < 4 & state_fips!=11, or
margins, dydx(housework_bkt) at(state_cat=(1(1)4))

// get correlation of sexism and attitudes
pwcorr gender_mood structural_familism
pwcorr structural_sexism structural_familism
pwcorr structural_sexism gender_mood // negatively correlated which makes sense, MORe structrual sexism = LESS support for women

log close

// for figure
tabstat structural_familism structural_sexism gender_mood, by(state)

// test continuous indicators or is that too much?
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3"
logit dissolve_lag i.dur c.structural_familism c.female_earn_pct c.structural_familism#c.female_earn_pct `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, at(structural_familism=(-6(2)10) female_earn_pct=(0(.25)1))
marginsplot

logit dissolve_lag i.dur c.structural_familism c.female_earn_pct c.structural_familism#c.female_earn_pct `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, at(structural_familism=(-6(2)10) female_earn_pct=(0(.25)1))
marginsplot

// *IS EMPLOYMENT LESS ANNOYING KIMMM *//
log using "$logdir/policy_interactions_sexism.log", append

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3"
* Structural familism
logit dissolve_lag i.dur c.structural_familism i.ft_head i.ft_wife c.structural_familism#i.ft_head c.structural_familism#i.ft_wife  `controls' if couple_educ_gp==0 & state_fips!=11, or
margins, dydx(ft_head ft_wife) at(structural_familism=(-6(2)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Husband Employment" 2 "Wife Employment") rows(1))

logit dissolve_lag i.dur c.structural_familism i.ft_head i.ft_wife c.structural_familism#i.ft_head c.structural_familism#i.ft_wife  `controls' if couple_educ_gp==1 & state_fips!=11, or
margins, dydx(ft_head ft_wife) at(structural_familism=(-6(2)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Husband Employment" 2 "Wife Employment") rows(1))

* Alt attitudes
logit dissolve_lag i.dur c.gender_mood i.ft_head i.ft_wife c.gender_mood#i.ft_head c.gender_mood#i.ft_wife `controls' if couple_educ_gp==0 & state_fips!=11, or
margins, dydx(ft_head ft_wife)  at(gender_mood=(50(5)75))
marginsplot, xtitle("Supportive Gender Role Attitudes") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Husband Employment" 2 "Wife Employment") rows(1))

logit dissolve_lag i.dur c.gender_mood i.ft_head i.ft_wife c.gender_mood#i.ft_head c.gender_mood#i.ft_wife `controls' if couple_educ_gp==1 & state_fips!=11, or
margins, dydx(ft_head ft_wife)  at(gender_mood=(50(5)75))
marginsplot, xtitle("Supportive Gender Role Attitudes") yline(0,lcolor(gs3)) yscale(range(-.1 .15)) ylabel(-.1(.05).15, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Husband Employment" 2 "Wife Employment") rows(1))

log close


********************************************************************************
********************************************************************************
********************************************************************************
**# Try here (10/5/23)
********************************************************************************
********************************************************************************
********************************************************************************

tabstat structural_familism, by(state)
tabstat economic_challenges, by(state)
tabstat dissolve_lag, by(state)
tab couple_educ_gp hh_earn_type if hh_earn_type<4, row chi2

logit dissolve_lag i.dur c.structural_familism if state_fips!=11, or
logit dissolve_lag i.dur c.structural_familism_alt if state_fips!=11, or

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3 c.gender_mood"
logit dissolve_lag i.dur c.structural_familism_alt `controls' if state_fips!=11, or
logit dissolve_lag i.dur c.structural_familism_alt `controls' if state_fips!=11 & couple_educ_gp==0, or
logit dissolve_lag i.dur c.structural_familism_alt `controls' if state_fips!=11 & couple_educ_gp==1, or

local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3 c.gender_mood"
logit dissolve_lag i.dur i.hh_earn_type `controls' if state_fips!=11 & couple_educ_gp==1 & hh_earn_type<=4, or
logit dissolve_lag i.dur ib2.hh_earn_type `controls' structural_familism if state_fips!=11 & couple_educ_gp==1 & hh_earn_type<4, or
logit dissolve_lag i.dur i.hh_earn_type##i.familism_scale `controls' if state_fips!=11 & couple_educ_gp==1 & hh_earn_type<4, or
margins, dydx(hh_earn_type) at(familism_scale=(0 1))

logit dissolve_lag i.dur i.hh_earn_type##i.familism_scale `controls' if state_fips!=11 & couple_educ_gp==0 & hh_earn_type<4, or
margins, dydx(hh_earn_type) at(familism_scale=(0 1))

logit dissolve_lag i.dur i.hh_earn_type##i.familism_scale_det `controls' if state_fips!=11 & couple_educ_gp==1 & hh_earn_type<4, or
margins, dydx(hh_earn_type) at(familism_scale_det=(1 2 3))

// main figures: familism
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3 c.gender_mood"
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) plot1opts(lcolor("191 87 0") mcolor("191 87 0")) ci1opts(color("191 87 0")) plot2opts(lcolor("0 95 134") mcolor("0 95 134")) ci2opts(color("0 95 134")) // plot3opts(lcolor("248 151 31") mcolor("248 151 31")) ci3opts(color("248 151 31")) 

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
marginsplot, xtitle("Structural Familism Scale") yline(0,lcolor(gs3)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) plot1opts(lcolor("191 87 0") mcolor("191 87 0")) ci1opts(color("191 87 0")) plot2opts(lcolor("0 95 134") mcolor("0 95 134")) ci2opts(color("0 95 134")) // plot3opts(lcolor("248 151 31") mcolor("248 151 31")) ci3opts(color("248 151 31")) 

// main figures: economics
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3 c.gender_mood"
logit dissolve_lag i.dur c.economic_challenges i.hh_earn_type c.economic_challenges#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(economic_challenges=(-3(1)5))
marginsplot, xtitle("Economic Inequality") yline(0,lcolor(gs3)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) plot1opts(lcolor("191 87 0") mcolor("191 87 0")) ci1opts(color("191 87 0")) plot2opts(lcolor("0 95 134") mcolor("0 95 134")) ci2opts(color("0 95 134")) // plot3opts(lcolor("248 151 31") mcolor("248 151 31")) ci3opts(color("248 151 31")) 

logit dissolve_lag i.dur c.economic_challenges i.hh_earn_type c.economic_challenges#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(economic_challenges=(-3(1)5))
marginsplot, xtitle("Economic Inequality") yline(0,lcolor(gs3)) yscale(range(-.1 .1)) ylabel(-.1(.05).1, angle(0))  ytitle("Average Marginal Effects: Marital Dissolution") title("") legend(position(6) ring(3) order(1 "Male BW" 2 "Female BW") rows(1)) plot1opts(lcolor("191 87 0") mcolor("191 87 0")) ci1opts(color("191 87 0")) plot2opts(lcolor("0 95 134") mcolor("0 95 134")) ci2opts(color("0 95 134")) // plot3opts(lcolor("248 151 31") mcolor("248 151 31")) ci3opts(color("248 151 31")) 


********************************************************************************
**# Outreg: primary interactions
********************************************************************************

// *Paid Work: All variables in scale individually *//
	// egen structural_familism= rowtotal(min_above_fed_st paid_leave_st senate_dems_st welfare_all_st educ_spend_percap_st earn_ratio_neg_st)
	
// old controls: local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3 c.gender_mood"

local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.num_children i.interval knot1 knot2 knot3 c.gender_mood"

/* No College */
* Structural familism - to test
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
outreg2 using "$results/dissolution_AMES_familism.xls", sideway stats(coef pval) label ctitle(No 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Min Wage
logit dissolve_lag i.dur i.min_above_fed i.hh_earn_type i.min_above_fed#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(min_above_fed=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no minwage) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Paid Leave
logit dissolve_lag i.dur i.paid_leave i.hh_earn_type i.paid_leave#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(paid_leave=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no paidleave) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Senate Dems
logit dissolve_lag i.dur c.senate_dems i.hh_earn_type c.senate_dems#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(senate_dems=(.20(.10).80)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no dems) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Welfare Expenditures
logit dissolve_lag i.dur c.welfare_all i.hh_earn_type c.welfare_all#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(welfare_all=(500(500)2500)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no welfare) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Education Expenditures
logit dissolve_lag i.dur c.educ_spend_percap i.hh_earn_type c.educ_spend_percap#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(educ_spend_percap=(1000(200)2000)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no educ) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Earnings Ratio
logit dissolve_lag i.dur c.parent_earn_ratio i.hh_earn_type c.parent_earn_ratio#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(parent_earn_ratio=(1(.2)2)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no earnings) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Structural sexism
logit dissolve_lag i.dur c.structural_sexism i.hh_earn_type c.structural_sexism#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_sexism=(-8(2)4)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no sexism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Attitudes
logit dissolve_lag i.dur c.gender_mood i.hh_earn_type c.gender_mood#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(gender_mood=(50(5)75)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no attitudes) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Economic challenges
logit dissolve_lag i.dur c.economic_challenges i.hh_earn_type c.economic_challenges#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
outreg2 using "$results/dissolution_AMES_familism.xls", sideway stats(coef pval) label ctitle(No 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
margins, dydx(hh_earn_type) at(economic_challenges=(-3(1)5)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no economic) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Unemployment
logit dissolve_lag i.dur c.unemployment i.hh_earn_type c.unemployment#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(unemployment=(2(2)10)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no unemploy) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Child poverty
logit dissolve_lag i.dur c.child_pov i.hh_earn_type c.child_pov#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(child_pov=(.10(.05).30)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no pov) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Gini
logit dissolve_lag i.dur c.gini i.hh_earn_type c.gini#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(gini=(.55(.05).70)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(no gini) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* Both in model
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3 c.gender_mood"
logit dissolve_lag i.dur c.economic_challenges structural_familism i.hh_earn_type c.economic_challenges#i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p25)' `r(p75)'))
// margins, dydx(hh_earn_type) at(structural_familism=(`r(p10)' `r(p90)'))
margins hh_earn_type, at(structural_familism=(`r(p25)' `r(p75)'))
sum economic_challenges, detail
margins, dydx(hh_earn_type) at(economic_challenges=(`r(p25)' `r(p75)'))
margins hh_earn_type, at(economic_challenges=(`r(p25)' `r(p75)'))
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
margins, dydx(hh_earn_type) at(economic_challenges=(-3(1)5))
*/

/* College */
* Structural familism - to test
logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
outreg2 using "$results/dissolution_AMES_familism.xls", sideway stats(coef pval) label ctitle(Coll 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col familism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Min Wage
logit dissolve_lag i.dur i.min_above_fed i.hh_earn_type i.min_above_fed#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(min_above_fed=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col minwage) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Paid Leave
logit dissolve_lag i.dur i.paid_leave i.hh_earn_type i.paid_leave#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(paid_leave=(0 1)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col paidleave) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Senate Dems
logit dissolve_lag i.dur c.senate_dems i.hh_earn_type c.senate_dems#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(senate_dems=(.20(.10).80)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col dems) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Welfare Expenditures
logit dissolve_lag i.dur c.welfare_all i.hh_earn_type c.welfare_all#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(welfare_all=(500(500)2500)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col welfare) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Education Expenditures
logit dissolve_lag i.dur c.educ_spend_percap i.hh_earn_type c.educ_spend_percap#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(educ_spend_percap=(1000(200)2000)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col educ) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Earnings Ratio
logit dissolve_lag i.dur c.parent_earn_ratio i.hh_earn_type c.parent_earn_ratio#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(parent_earn_ratio=(1(.2)2)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col earnings) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Structural sexism
logit dissolve_lag i.dur c.structural_sexism i.hh_earn_type c.structural_sexism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_sexism=(-8(2)4)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col sexism) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Attitudes
logit dissolve_lag i.dur c.gender_mood i.hh_earn_type c.gender_mood#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(gender_mood=(50(5)75)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(col attitudes) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Economic challenges
logit dissolve_lag i.dur c.economic_challenges i.hh_earn_type c.economic_challenges#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
outreg2 using "$results/dissolution_AMES_familism.xls", sideway stats(coef pval) label ctitle(Coll 1) dec(2) eform alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append
margins, dydx(hh_earn_type) at(economic_challenges=(-3(1)5)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(coll economic) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Unemployment
logit dissolve_lag i.dur c.unemployment i.hh_earn_type c.unemployment#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(unemployment=(2(2)10)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(coll unemploy) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Child poverty
logit dissolve_lag i.dur c.child_pov i.hh_earn_type c.child_pov#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(child_pov=(.10(.05).30)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(coll pov) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

* Gini
logit dissolve_lag i.dur c.gini i.hh_earn_type c.gini#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(gini=(.55(.05).70)) post
outreg2 using "$results/dissolution_AMES_familism.xls", ctitle(coll gini) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

/* Both in model
local controls "age_mar_wife age_mar_head i.race_head i.same_race i.either_enrolled i.REGION_ cohab_with_wife cohab_with_other pre_marital_birth knot1 knot2 knot3 c.gender_mood"
logit dissolve_lag i.dur c.economic_challenges structural_familism i.hh_earn_type c.economic_challenges#i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p25)' `r(p75)'))
sum economic_challenges, detail
margins hh_earn_type, at(economic_challenges=(`r(p25)' `r(p75)'))
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
margins, dydx(hh_earn_type) at(economic_challenges=(-3(1)5))
*/

/* Margins: using percentiles for "high" and "low"*/
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.num_children i.interval knot1 knot2 knot3 c.gender_mood"

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
margins, dydx(hh_earn_type) at(structural_familism=(-5(1)10))
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p25)' `r(p75)'))
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p25)' `r(p75)'))

logit dissolve_lag i.dur c.economic_challenges i.hh_earn_type c.economic_challenges#i.hh_earn_type `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
sum economic_challenges, detail
margins hh_earn_type, at(economic_challenges=(`r(p25)' `r(p75)'))
sum economic_challenges, detail
margins, dydx(hh_earn_type) at(economic_challenges=(`r(p25)' `r(p75)'))

logit dissolve_lag i.dur c.structural_familism i.hh_earn_type c.structural_familism#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
sum structural_familism, detail
margins hh_earn_type, at(structural_familism=(`r(p25)' `r(p75)'))
sum structural_familism, detail
margins, dydx(hh_earn_type) at(structural_familism=(`r(p25)' `r(p75)'))

logit dissolve_lag i.dur c.economic_challenges i.hh_earn_type c.economic_challenges#i.hh_earn_type `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
sum economic_challenges, detail
margins hh_earn_type, at(economic_challenges=(`r(p25)' `r(p75)'))
sum economic_challenges, detail
margins, dydx(hh_earn_type) at(economic_challenges=(`r(p25)' `r(p75)'))

/* Just the measures*/
local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.num_children i.interval knot1 knot2 knot3 c.gender_mood"

logit dissolve_lag i.dur c.structural_familism `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
logit dissolve_lag i.dur c.economic_challenges `controls' if couple_educ_gp==0 & hh_earn_type < 4 & state_fips!=11, or
logit dissolve_lag i.dur c.structural_familism `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or
logit dissolve_lag i.dur c.economic_challenges `controls' if couple_educ_gp==1 & hh_earn_type < 4 & state_fips!=11, or

logit dissolve_lag i.dur c.structural_familism `controls' if couple_educ_gp==0 & state_fips!=11, or
logit dissolve_lag i.dur c.economic_challenges `controls' if couple_educ_gp==0 & state_fips!=11, or
logit dissolve_lag i.dur c.structural_familism `controls' if couple_educ_gp==1 & state_fips!=11, or
logit dissolve_lag i.dur c.economic_challenges `controls' if couple_educ_gp==1 & state_fips!=11, or

********************************************************************************
**# Does structural familism OR attitudes predict DoL?
********************************************************************************
mlogit hh_earn_type i.dur i.couple_educ_gp i.children if hh_earn_type < 4 & state_fips!=11, rrr // so yes, college-educated more likely to be dual-earning and female-BW than male BW
margins couple_educ_gp

mlogit hh_earn_type i.dur i.couple_educ_gp if hh_earn_type < 4 & state_fips!=11, rrr baseoutcome(1)

local controls "age_mar_wife age_mar_wife_sq age_mar_head age_mar_head_sq i.race_head i.same_race i.either_enrolled i.region cohab_with_wife cohab_with_other pre_marital_birth i.num_children i.interval knot1 knot2 knot3 c.gender_mood"

// Familism
mlogit hh_earn_type i.dur structural_familism i.children if hh_earn_type < 4 & state_fips!=11, rrr // when higher, more likely to be dual / female BW than male BW
margins, at(structural_familism=(-5(5)10)) // post
outreg2 using "$results/policy_DOL.xls", ctitle(total) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) replace

mlogit hh_earn_type i.dur structural_familism i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==0, rrr // no diffs
margins, at(structural_familism=(-5(5)10)) // post
outreg2 using "$results/policy_DOL.xls", ctitle(no) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mlogit hh_earn_type i.dur structural_familism i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==1, rrr // really the trends here
margins, at(structural_familism=(-5(5)10)) // post
outreg2 using "$results/policy_DOL.xls", ctitle(coll) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mlogit hh_earn_type i.dur structural_familism i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==0, rrr // no association
margins, at(structural_familism=(-5(5)10))
marginsplot, xtitle("Structural Familism Scale") ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) // plot2opts(lcolor("191 87 0") mcolor("191 87 0")) ci2opts(color("191 87 0")) plot3opts(lcolor("0 95 134") mcolor("0 95 134")) ci3opts(color("0 95 134")) plot1opts(lcolor(gray) mcolor(gray)) ci1opts(color(gray)) 
// plot1opts(lcolor("248 151 31") mcolor("248 151 31")) ci1opts(color("248 151 31")) 

mlogit hh_earn_type i.dur structural_familism i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==1, rrr // really the trends here
margins, at(structural_familism=(-5(5)10))
marginsplot, xtitle("Structural Familism Scale") ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) // plot2opts(lcolor("191 87 0") mcolor("191 87 0")) ci2opts(color("191 87 0")) plot3opts(lcolor("0 95 134") mcolor("0 95 134")) ci3opts(color("0 95 134")) plot1opts(lcolor(gray) mcolor(gray)) ci1opts(color(gray)) 

// Sexism
mlogit hh_earn_type i.dur structural_sexism i.children if hh_earn_type < 4 & state_fips!=11, rrr // makes sense - when higher, more likely to be male BW and less likely to be others
margins, at(structural_sexism=(-10(5)5)) post
outreg2 using "$results/policy_DOL.xls", ctitle(total) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

mlogit hh_earn_type i.dur structural_sexism i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==0, rrr // directional but not sig
margins, at(structural_sexism=(-10(5)5)) post
outreg2 using "$results/policy_DOL.xls", ctitle(no) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

mlogit hh_earn_type i.dur structural_sexism i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==1, rrr // most sig for female / male BW, not dual earning (only marginal)
margins, at(structural_sexism=(-10(5)5)) post
outreg2 using "$results/policy_DOL.xls", ctitle(coll) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)


// Attitudes
mlogit hh_earn_type i.dur gender_mood i.children if hh_earn_type < 4 & state_fips!=11, rrr // same results for familism. higher = more dual and female BW
margins, at(gender_mood=(55(10)75)) post
outreg2 using "$results/policy_DOL.xls", ctitle(total) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

mlogit hh_earn_type i.dur gender_mood i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==0, rrr // okay atttitudes actually sig here
margins, at(gender_mood=(55(10)75)) post
outreg2 using "$results/policy_DOL.xls", ctitle(no) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

mlogit hh_earn_type i.dur gender_mood i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==1, rrr
margins, at(gender_mood=(55(10)75)) post
outreg2 using "$results/policy_DOL.xls", ctitle(coll) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +)

mlogit hh_earn_type i.dur gender_mood i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==0, rrr
margins, at(gender_mood=(55(10)75))
marginsplot, xtitle("Gender Equality Mood") xlabel(55(10)75, format(%15.0gc)) ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) plot1opts(lcolor("191 87 0") mcolor("191 87 0")) ci1opts(color("191 87 0")) plot2opts(lcolor("0 95 134") mcolor("0 95 134")) ci2opts(color("0 95 134")) plot3opts(lcolor("248 151 31") mcolor("248 151 31")) ci3opts(color("248 151 31")) 

mlogit hh_earn_type i.dur gender_mood i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==1, rrr
margins, at(gender_mood=(55(10)75))
marginsplot, xtitle("Gender Equality Mood") xlabel(55(10)75, format(%15.0gc)) ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) plot1opts(lcolor("191 87 0") mcolor("191 87 0")) ci1opts(color("191 87 0")) plot2opts(lcolor("0 95 134") mcolor("0 95 134")) ci2opts(color("0 95 134")) plot3opts(lcolor("248 151 31") mcolor("248 151 31")) ci3opts(color("248 151 31")) 

//same models
mlogit hh_earn_type i.dur structural_familism gender_mood i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==0, rrr // only gender mood predictive

mlogit hh_earn_type i.dur structural_familism gender_mood i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==1, rrr // dual-earning = gender mood; female BW = structural
margins, at(structural_familism=(-5(5)10))
marginsplot, xtitle("Structural Familism Scale") ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) plot1opts(lcolor("191 87 0") mcolor("191 87 0")) ci1opts(color("191 87 0")) plot2opts(lcolor("0 95 134") mcolor("0 95 134")) ci2opts(color("0 95 134")) plot3opts(lcolor("248 151 31") mcolor("248 151 31")) ci3opts(color("248 151 31")) 

margins, at(gender_mood=(55(10)75))
marginsplot, xtitle("Gender Equality Mood") xlabel(55(10)75, format(%15.0gc)) ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) plot1opts(lcolor("191 87 0") mcolor("191 87 0")) ci1opts(color("191 87 0")) plot2opts(lcolor("0 95 134") mcolor("0 95 134")) ci2opts(color("0 95 134")) plot3opts(lcolor("248 151 31") mcolor("248 151 31")) ci3opts(color("248 151 31")) 

// Economic challenges
mlogit hh_earn_type i.dur economic_challenges i.children if hh_earn_type < 4 & state_fips!=11, rrr // when higher, more likely female BW than male BW, but dual = no change
margins, at(economic_challenges=(-3(1)5))
outreg2 using "$results/policy_DOL.xls", ctitle(total) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mlogit hh_earn_type i.dur economic_challenges i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==0, rrr // more likely to be female BW, but it comes from DUAL not male?! this is the eemrgency BW story?!
margins, at(economic_challenges=(-3(1)5))
outreg2 using "$results/policy_DOL.xls", ctitle(no) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mlogit hh_earn_type i.dur economic_challenges i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==1, rrr // no diffs
margins, at(economic_challenges=(-3(1)5))
outreg2 using "$results/policy_DOL.xls", ctitle(coll) dec(4) alpha(0.001, 0.01, 0.05, 0.10) symbol(***, **, *, +) append

mlogit hh_earn_type i.dur economic_challenges i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==0, rrr // counterintuive - female BW more likely when more challenges
margins, at(economic_challenges=(-3(2)5))
marginsplot, xtitle("Economic Uncertainty") ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) // plot2opts(lcolor("191 87 0") mcolor("191 87 0")) ci2opts(color("191 87 0")) plot3opts(lcolor("0 95 134") mcolor("0 95 134")) ci3opts(color("0 95 134")) plot1opts(lcolor(gray) mcolor(gray)) ci1opts(color(gray)) 
// plot1opts(lcolor("248 151 31") mcolor("248 151 31")) ci1opts(color("248 151 31")) 

mlogit hh_earn_type i.dur economic_challenges i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==1, rrr // no real association here
margins, at(economic_challenges=(-3(2)5))
marginsplot, xtitle("Economic Uncertainty") ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) //  plot2opts(lcolor("191 87 0") mcolor("191 87 0")) ci2opts(color("191 87 0")) plot3opts(lcolor("0 95 134") mcolor("0 95 134")) ci3opts(color("0 95 134")) plot1opts(lcolor(gray) mcolor(gray)) ci1opts(color(gray)) 

// Structural familism and economic in same model
mlogit hh_earn_type i.dur economic_challenges structural_familism i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==0, rrr // here, only economic challenges sig, and the effect is w female BW
margins, at(economic_challenges=(-3(2)5))
marginsplot, xtitle("Economic Uncertainty") ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) plot2opts(lcolor("191 87 0") mcolor("191 87 0")) ci2opts(color("191 87 0")) plot3opts(lcolor("0 95 134") mcolor("0 95 134")) ci3opts(color("0 95 134")) plot1opts(lcolor(gray) mcolor(gray)) ci1opts(color(gray)) 
// plot1opts(lcolor("248 151 31") mcolor("248 151 31")) ci1opts(color("248 151 31")) 

margins, at(structural_familism=(-5(5)10))
marginsplot, xtitle("Structural Familism Scale") ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) plot2opts(lcolor("191 87 0") mcolor("191 87 0")) ci2opts(color("191 87 0")) plot3opts(lcolor("0 95 134") mcolor("0 95 134")) ci3opts(color("0 95 134")) plot1opts(lcolor(gray) mcolor(gray)) ci1opts(color(gray)) 


mlogit hh_earn_type i.dur economic_challenges structural_familism i.children if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==1, rrr // here, structural familism higher = more female AND dual. economic challenges = less dual (but not sig for female BW)
margins, at(economic_challenges=(-3(2)5))
marginsplot, xtitle("Economic Uncertainty") ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) plot2opts(lcolor("191 87 0") mcolor("191 87 0")) ci2opts(color("191 87 0")) plot3opts(lcolor("0 95 134") mcolor("0 95 134")) ci3opts(color("0 95 134")) plot1opts(lcolor(gray) mcolor(gray)) ci1opts(color(gray)) 

margins, at(structural_familism=(-5(5)10))
marginsplot, xtitle("Structural Familism Scale") ylabel(, angle(0))  ytitle("Probability of Given Division of Labor") title("") legend(position(6) ring(3) order(1 "Dual Earner" 2 "Male BW" 3 "Female BW") rows(1)) plot2opts(lcolor("191 87 0") mcolor("191 87 0")) ci2opts(color("191 87 0")) plot3opts(lcolor("0 95 134") mcolor("0 95 134")) ci3opts(color("0 95 134")) plot1opts(lcolor(gray) mcolor(gray)) ci1opts(color(gray)) 

// alt
mlogit hh_earn_type i.dur regional_attitudes_factor if hh_earn_type < 4 & state_fips!=11, rrr // only sig for dual
margins, at(regional_attitudes_factor=(-2.0(2)2.0))
marginsplot

mlogit hh_earn_type i.dur regional_attitudes_factor if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==0, rrr // same
margins, at(regional_attitudes_factor=(-2.0(2)2.0))
marginsplot

mlogit hh_earn_type i.dur regional_attitudes_factor if hh_earn_type < 4 & state_fips!=11 & couple_educ_gp==1, rrr // nothing sig
margins, at(regional_attitudes_factor=(-2.0(2)2.0))
marginsplot

