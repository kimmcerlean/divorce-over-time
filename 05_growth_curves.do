********************************************************************************
* Growth curves of female earnings % over marital duration
* growth_curves.do
* Kim McErlean
********************************************************************************

use "$data_keep\PSID_marriage_recoded_sample.dta", clear // created in 1a - no longer using my original order

gen cohort=.
replace cohort=1 if inrange(rel_start_all,1969,1989)
replace cohort=2 if inrange(rel_start_all,1990,2010)
replace cohort=3 if inrange(rel_start_all,2011,2019)

keep if cohort==2 // | cohort==3 // start with contemporary marriages - match divorce time frame
keep if marriage_order_real==1 // for now, just FIRST marriage
keep if (AGE_REF_>=18 & AGE_REF_<=55) &  (AGE_SPOUSE_>=18 & AGE_SPOUSE_<=55) // working age

rename STATE_ statefip
gen year = survey_yr
// merge m:1 year statefip using "T:/Research Projects/State data/data_keep/2010_2018_state_policies.dta", keepusing(cc_percent_served leave_policy leave_policy_score eitc_credit tanf_rate tanf_basic tanf_cc tanf_max cost_of_living20 tanf_max_cost abortion dems_legis women_legis) // adding in policy info
merge m:1 statefip using "$data_tmp\PSID_state_data.dta", keepusing(cost_living	living_wage	leave_policy_score sexism paid_leave) // trying new measures of policy, this is not yet updated for over time
drop if _merge==2
drop _merge


// also need to restrict to people who we observe from start. Some I have their start date, but not sure if in PSID whole time? so min dur = 0/1? Would I have done anything in file 1 that would remove early years of people? definitely removed if no partner, but that is still relevant here - need female earnings to get this...
bysort id: egen first_dur=min(dur)
keep if inlist(first_dur,1,2) // keeping one OR two because when survey shifted to biannual, year two may feasibly be the first time we can observe a full year of data?

// key splits:
* class: couple_educ_gp
* ever divorce: ever_dissolve - moved this to step 1a
sort id survey_yr
browse id survey_yr rel_start_all rel_end_all status_all hh_earn_type_bkd dissolve_lag ever_dissolve dur first_dur MARITAL_PAIRS_ if inlist(id,2009,2986,2992)
tab status_all ever_dissolve // lol this is very discordant... see IDs 2986, 2992 - okay got fixed, but still concerned on timing
* first child? for now - any children - think when doing actual curves, need to add a spline (or whatever - from DP class) at TIME of child: children - but 0 in years without, want EVER
by id: egen ever_children=max(children)
sort id survey_yr

// collapse by duration - do steps at a time
tab dur // when should I cut it off - did 1990 - 2019, so max is 30, but probably not a ton of people, so do 20? because even that is low.

// trying to divide by leave policy (as one example)
gen leave_policy_group=.
replace leave_policy_group=0 if leave_policy_score==0
replace leave_policy_group=1 if leave_policy_score>0 & leave_policy_score<=25
replace leave_policy_group=2 if leave_policy_score>25 & leave_policy_score<=80
replace leave_policy_group=3 if leave_policy_score>=85 & leave_policy_score!=.

gen leave_policy_group2=.
replace leave_policy_group2=0 if leave_policy_score==0
replace leave_policy_group2=1 if leave_policy_score>0 & leave_policy_score<=25
replace leave_policy_group2=2 if leave_policy_score>25 & leave_policy_score!=.

gen sexism_gp=.
replace sexism_gp=1 if sexism <=-2
replace sexism_gp=2 if sexism > -2 & sexism < 2
replace sexism_gp=3 if sexism >=2 & sexism!=.

label define sexism 1 "Low" 2 "Moderate" 3 "High"
label values sexism_gp sexism

// new variables to split at time of first birth (probably need to update to ANY birth but that's a later problem)
// The main variables in model: post (dummy for post period), time (time from start of study) and their interaction; these variables relate to treatment effect. - is post 1 or 0? or is it time post? if 1 or zero, then is interaction helpful?

gen post_first_birth=0
replace post_first_birth=1 if survey_yr>=when_first_birth

* interact - Okay per Singer and Willett p 192, think I do need both
gen post_dur = 0 if post_first_birth==0
replace post_dur=(survey_yr - when_first_birth) if post_first_birth==1

gen post_dur_interact = post_first_birth * dur

browse survey_yr dur post_dur when_first_birth post_first_birth post_dur_interact

// need to recode weekly hours (do I need to do this BEFORE making buckets??)
recode weekly_hrs_head (998/999=.)
recode weekly_hrs_wife (998/999=.)
recode housework_head (998/999=.)
recode housework_wife (998/999=.)

// want to create time-invariant indicator of hh type in first year of marriage (but need to make sure it's year both spouses in hh) - some started in off year gah. use DUR? or rank years and use first rank? (actually is that a better duration?)
browse id survey_yr rel_start_all dur hh_earn_type
bysort id (survey_yr): egen yr_rank=rank(survey_yr)
gen hh_earn_type_mar = hh_earn_type if yr_rank==1
bysort id (hh_earn_type_mar): replace hh_earn_type_mar=hh_earn_type_mar[1]
label values hh_earn_type_mar hh_earn_type

// drop if hh_earn_type_mar==4 // no earners

********************************************************************************
* Exploratory plots
********************************************************************************

preserve
collapse (median) female_earn_pct, by(dur)
twoway line female_earn_pct dur if dur <=20
restore

preserve
collapse (median) female_earn_pct, by(dur couple_educ_gp ever_dissolve ever_children)
restore

preserve
collapse (median) female_earn_pct, by(dur couple_educ_gp)
twoway (line female_earn_pct dur if dur <=20 & couple_educ_gp==0) (line female_earn_pct dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "No College" 2 "College"))
graph export "$results\earn_pct_education.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct if pre_marital_birth==0, by(dur couple_educ_gp)
twoway (line female_earn_pct dur if dur <=20 & couple_educ_gp==0) (line female_earn_pct dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "No College" 2 "College"))
restore

preserve
collapse (median) female_earn_pct, by(dur pre_marital_birth)
twoway (line female_earn_pct dur if dur <=20 & pre_marital_birth==0) (line female_earn_pct dur if dur <=20 & pre_marital_birth==1), legend(on order(1 "Childless" 2 "Parents"))
restore

preserve
collapse (median) female_earn_pct if pre_marital_birth==0, by(dur couple_educ_gp hh_earn_type_mar)
twoway (line female_earn_pct dur if dur <=20 & hh_earn_type_mar==1 & couple_educ_gp==1) (line female_earn_pct dur if dur <=20 & hh_earn_type_mar==2  & couple_educ_gp==1) (line female_earn_pct dur if dur <=20 & hh_earn_type_mar==3  & couple_educ_gp==1), legend(on order(1 "Dual" 2 "Male BW" 3 "Female BW"))
twoway (line female_earn_pct dur if dur <=20 & hh_earn_type_mar==1 & couple_educ_gp==0) (line female_earn_pct dur if dur <=20 & hh_earn_type_mar==2  & couple_educ_gp==0) (line female_earn_pct dur if dur <=20 & hh_earn_type_mar==3  & couple_educ_gp==0), legend(on order(1 "Dual" 2 "Male BW" 3 "Female BW"))

restore

preserve
collapse (median) female_earn_pct wife_housework_pct, by(dur couple_educ_gp)
twoway (line female_earn_pct dur if dur <=20 & couple_educ_gp==0) (line wife_housework_pct dur if dur <=20 & couple_educ_gp==0) (line female_earn_pct dur if dur <=20 & couple_educ_gp==1) (line wife_housework_pct dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "NC Earnings" 2 "NC HW" 3 "Coll Earnings" 4 "Coll HW"))
restore

// whose earnings are changing?
preserve
collapse (median) earnings_head earnings_wife, by(dur couple_educ_gp)
twoway (line earnings_head dur if dur <=20 & couple_educ_gp==1) (line earnings_wife dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "Coll Head" 2 "Coll Wife")) // WAIT this is so interesting - it is ALL THE HUSBAND not the wife? is this why hours shows less of an association? bc she maybe is not pulling back, her husband just earns more??

twoway (line earnings_head dur if dur <=20 & couple_educ_gp==0) (line earnings_wife dur if dur <=20 & couple_educ_gp==0), legend(on order(1 "NC Head" 2 "NC Wife")) 

twoway (line earnings_head dur if dur <=20 & couple_educ_gp==0) (line earnings_wife dur if dur <=20 & couple_educ_gp==0) (line earnings_head dur if dur <=20 & couple_educ_gp==1) (line earnings_wife dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "NC Head" 2 "NC Wife" 3 "Coll Head" 4 "Coll Wife"))
restore


preserve
collapse (median) female_hours_pct, by(dur couple_educ_gp)
twoway (line female_hours_pct dur if dur <=20 & couple_educ_gp==0) (line female_hours_pct dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "No College" 2 "College"))
restore

// whose hours are changing?
preserve
collapse (median) weekly_hrs_head weekly_hrs_wife, by(dur couple_educ_gp)
twoway (line weekly_hrs_head dur if dur <=20 & couple_educ_gp==1) (line weekly_hrs_wife dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "Coll Head" 2 "Coll Wife")) // okay so his hours don't really increase, hers DO after about year 10 - babies?? is this penalty v. premium?
restore

preserve
collapse (mean) weekly_hrs_head weekly_hrs_wife, by(dur couple_educ_gp)
twoway (line weekly_hrs_head dur if dur <=20 & couple_educ_gp==1) (line weekly_hrs_wife dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "Coll Head" 2 "Coll Wife")) // okay mean is good once I got rid of those 999s duh kim

twoway (line weekly_hrs_head dur if dur <=20 & couple_educ_gp==0) (line weekly_hrs_wife dur if dur <=20 & couple_educ_gp==0), legend(on order(1 "NC Head" 2 "NC Wife")) 

twoway (line weekly_hrs_head dur if dur <=20 & couple_educ_gp==0) (line weekly_hrs_wife dur if dur <=20 & couple_educ_gp==0) (line weekly_hrs_head dur if dur <=20 & couple_educ_gp==1) (line weekly_hrs_wife dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "NC Head" 2 "NC Wife" 3 "Coll Head" 4 "Coll Wife"))
restore

preserve
collapse (mean) weekly_hrs_head weekly_hrs_wife housework_head housework_wife earnings_wife earnings_head, by(dur couple_educ_gp)
twoway (line weekly_hrs_head dur if dur <=20 & couple_educ_gp==1) (line weekly_hrs_wife dur if dur <=20 & couple_educ_gp==1) (line housework_head dur if dur <=20 & couple_educ_gp==1) (line housework_wife dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "Work Head" 2 "Work Wife" 3 "HW Head" 4 "HW Wife")) // okay i am obsessed with this. DOES almost look like housework precedes employment

twoway (line weekly_hrs_head dur if dur <=20 & couple_educ_gp==0) (line weekly_hrs_wife dur if dur <=20 & couple_educ_gp==0) (line housework_head dur if dur <=20 & couple_educ_gp==0) (line housework_wife dur if dur <=20 & couple_educ_gp==0), legend(on order(1 "Work Head" 2 "Work Wife" 3 "HW Head" 4 "HW Wife"))

twoway (line weekly_hrs_head dur if dur <=20 & couple_educ_gp==0) (line weekly_hrs_wife dur if dur <=20 & couple_educ_gp==0) (line weekly_hrs_head dur if dur <=20 & couple_educ_gp==1) (line weekly_hrs_wife dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "NC Head" 2 "NC Wife" 3 "Coll Head" 4 "Coll Wife"))
restore

preserve
collapse (mean) female_earn_pct female_hours_pct wife_housework_pct, by(dur couple_educ_gp)	
restore

preserve
collapse (median) female_earn_pct if inrange(REGION_,1,4) & couple_educ_gp==1, by(dur REGION_)
twoway (line female_earn_pct dur if dur <=20 & REGION_==1) (line female_earn_pct dur if dur <=20 & REGION_==2) (line female_earn_pct dur if dur <=20 & REGION_==3) (line female_earn_pct dur if dur <=20 & REGION_==4), legend(on order(1 "Northeast" 2 "North Central" 3 "South" 4 "West"))
graph export "$results\earn_pct_region_college.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct if inrange(REGION_,1,4) & couple_educ_gp==1, by(dur STATE_)
twoway (line female_earn_pct dur if dur <=20 & STATE_==6) (line female_earn_pct dur if dur <=20 & STATE_==36) (line female_earn_pct dur if dur <=20 & STATE_==48) (line female_earn_pct dur if dur <=20 & STATE_==17) (line female_earn_pct dur if dur <=20 & STATE_==5), legend(on order(1 "California" 2 "New York" 3 "Texas" 4 "Illinois" 5 "Arkansas"))
graph export "$results\earn_pct_state_college.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct if couple_educ_gp==1, by(dur leave_policy_group)
twoway (line female_earn_pct dur if dur <=20 & leave_policy_group==0) (line female_earn_pct dur if dur <=20 & leave_policy_group==1) (line female_earn_pct dur if dur <=20 & leave_policy_group==2) (line female_earn_pct dur if dur <=20 & leave_policy_group==3), legend(on order(1 "None" 2 "Low" 3 "Medium" 4 "High"))
graph export "$results\earn_pct_policy_college.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct if year >=2011 & year<2019, by(dur leave_policy_group2)
twoway (line female_earn_pct dur if dur <=15 & leave_policy_group2==0) (line female_earn_pct dur if dur <=15 & leave_policy_group2==1) (line female_earn_pct dur if dur <=15 & leave_policy_group2==2), legend(on order(1 "Poor" 2 "Average" 3 "Good"))
graph export "$results\earn_pct_policy_all.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct, by(dur paid_leave couple_educ_gp)
twoway (line female_earn_pct dur if dur <=15 & paid_leave==0 & couple_educ_gp==0) (line female_earn_pct dur if dur <=15 & paid_leave==1 & couple_educ_gp==0) (line female_earn_pct dur if dur <=15 & paid_leave==0 & couple_educ_gp==1) (line female_earn_pct dur if dur <=15 & paid_leave==1 & couple_educ_gp==1) , legend(on order(1 "NC - No leave" 2 "NC - leave" 3 "Coll - no leave" 4 "Coll - leave"))
restore

preserve
collapse (median) female_earn_pct if couple_educ_gp==1 & ever_children==1, by(dur paid_leave)
twoway (line female_earn_pct dur if dur <=15 & paid_leave==0) (line female_earn_pct dur if dur <=15 & paid_leave==1), legend(on order(1 "No leave" 2 "Leave"))
restore

preserve
collapse (median) female_earn_pct if couple_educ_gp==1, by(dur paid_leave ever_children)
twoway (line female_earn_pct dur if dur <=15 & paid_leave==0 & ever_children==0) (line female_earn_pct dur if dur <=15 & paid_leave==1 & ever_children==0) (line female_earn_pct dur if dur <=15 & paid_leave==0 & ever_children==1) (line female_earn_pct dur if dur <=15 & paid_leave==1 & ever_children==1), legend(on order(1 "No leave - no kids" 2 "Leave - no kids" 3 "No leave" 4 "Leave"))
restore


preserve
collapse (median) female_earn_pct, by(dur sexism_gp)
twoway (line female_earn_pct dur if dur <=15 & sexism_gp==1) (line female_earn_pct dur if dur <=15 & sexism_gp==2) (line female_earn_pct dur if dur <=15 & sexism_gp==3), legend(on order(1 "Low" 2 "Medium" 3 "High"))
restore

preserve
collapse (median) female_earn_pct if couple_educ_gp==1 & ever_children==1, by(dur sexism_gp)
twoway (line female_earn_pct dur if dur <=15 & sexism_gp==1) (line female_earn_pct dur if dur <=15 & sexism_gp==2) (line female_earn_pct dur if dur <=15 & sexism_gp==3), legend(on order(1 "Low" 2 "Medium" 3 "High"))
restore


preserve
collapse (median) female_earn_pct if couple_educ_gp==1, by(dur sexism_gp)
twoway (line female_earn_pct dur if dur <=15 & sexism_gp==1) (line female_earn_pct dur if dur <=15 & sexism_gp==2) (line female_earn_pct dur if dur <=15 & sexism_gp==3), legend(on order(1 "Low" 2 "Medium" 3 "High"))
restore



preserve
collapse (median) female_earn_pct, by(dur sexism_gp couple_educ_gp)
twoway (line female_earn_pct dur if dur <=15 & sexism_gp==1 & couple_educ_gp==0) (line female_earn_pct dur if dur <=15 & sexism_gp==2 & couple_educ_gp==0) (line female_earn_pct dur if dur <=15 & sexism_gp==3 & couple_educ_gp==0) (line female_earn_pct dur if dur <=15 & sexism_gp==1 & couple_educ_gp==1) (line female_earn_pct dur if dur <=15 & sexism_gp==2 & couple_educ_gp==1) (line female_earn_pct dur if dur <=15 & sexism_gp==3 & couple_educ_gp==1) , legend(on order(1 "NC Low" 2 "NC Mod" 3 "NC High" 4 "Cll Low" 5 "Coll Mod" 6 "coll high"))
restore


preserve
collapse (median) female_earn_pct, by(dur pre_marital_birth couple_educ_gp)
twoway (line female_earn_pct dur if dur <=15 & pre_marital_birth==0 & couple_educ_gp==0) (line female_earn_pct dur if dur <=15 & pre_marital_birth==1 & couple_educ_gp==0) (line female_earn_pct dur if dur <=15 & pre_marital_birth==0 & couple_educ_gp==1) (line female_earn_pct dur if dur <=15 & pre_marital_birth==1 & couple_educ_gp==1) , legend(on order(1 "NC Childless" 2 "NC Parent" 3 "Coll - Childless" 4 "Coll - Parent"))
restore


preserve
collapse (median) female_earn_pct if ever_dissolve==0, by(dur couple_educ_gp)
twoway (line female_earn_pct dur if dur <=20 & couple_educ_gp==0) (line female_earn_pct dur if dur <=20 & couple_educ_gp==1), legend(on order(1 "No College" 2 "College"))
graph export "$results\earn_pct_education_intact.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct if ever_dissolve==1, by(dur couple_educ_gp)
twoway (line female_earn_pct dur if dur <=15 & couple_educ_gp==0) (line female_earn_pct dur if dur <=15 & couple_educ_gp==1), legend(on order(1 "No College" 2 "College"))
graph export "$results\earn_pct_education_ended.jpg", as(jpg) name("Graph") quality(90) replace
restore


preserve
collapse (median) female_earn_pct, by(dur ever_dissolve)
twoway (line female_earn_pct dur if dur <=20 & ever_dissolve==0) (line female_earn_pct dur if dur <=20 & ever_dissolve==1), legend(on order(1 "Intact" 2 "Dissolved"))
graph export "$results\earn_pct_dissolved.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct, by(dur ever_children)
twoway (line female_earn_pct dur if dur <=20 & ever_children==0) (line female_earn_pct dur if dur <=20 & ever_children==1), legend(on order(1 "No Children" 2 "Children"))
graph export "$results\earn_pct_children.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct, by(dur couple_educ_gp ever_dissolve)
twoway (line female_earn_pct dur if dur <=20 & couple_educ_gp==0 & ever_dissolve==0) (line female_earn_pct dur if dur <=20 & couple_educ_gp==0 & ever_dissolve==1) (line female_earn_pct dur if dur <=20 & couple_educ_gp==1 & ever_dissolve==0) (line female_earn_pct dur if dur <=20 & couple_educ_gp==1 & ever_dissolve==1), legend(on order(1 "NC - Intact" 2 "NC - Dissolved" 3 "Coll - Intact" 4 "Coll-Dissolved"))
twoway (line female_earn_pct dur if dur <=10 & couple_educ_gp==0 & ever_dissolve==0) (line female_earn_pct dur if dur <=10 & couple_educ_gp==0 & ever_dissolve==1) (line female_earn_pct dur if dur <=10 & couple_educ_gp==1 & ever_dissolve==0) (line female_earn_pct dur if dur <=10 & couple_educ_gp==1 & ever_dissolve==1), legend(on order(1 "NC - Intact" 2 "NC - Dissolved" 3 "Coll - Intact" 4 "Coll-Dissolved"))
graph export "$results\earn_pct_educ_x_dissolved.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct, by(dur couple_educ_gp ever_children)
twoway (line female_earn_pct dur if dur <=20 & couple_educ_gp==0 & ever_children==0) (line female_earn_pct dur if dur <=20 & couple_educ_gp==0 & ever_children==1) (line female_earn_pct dur if dur <=20 & couple_educ_gp==1 & ever_children==0) (line female_earn_pct dur if dur <=20 & couple_educ_gp==1 & ever_children==1), legend(on order(1 "NC - No Children" 2 "NC - Children" 3 "Coll - No Children" 4 "Coll-Children"))
graph export "$results\earn_pct_educ_x_children.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct if couple_educ_gp==1, by(dur ever_children)
twoway (line female_earn_pct dur if dur <=20 & ever_children==0) (line female_earn_pct dur if dur <=20 & ever_children==1), legend(on order(1 "No Children" 2 "Children"))
restore

preserve
collapse (median) female_earn_pct if ever_dissolve==0, by(dur couple_educ_gp ever_children)
twoway (line female_earn_pct dur if dur <=20 & couple_educ_gp==0 & ever_children==0) (line female_earn_pct dur if dur <=20 & couple_educ_gp==0 & ever_children==1) (line female_earn_pct dur if dur <=20 & couple_educ_gp==1 & ever_children==0) (line female_earn_pct dur if dur <=20 & couple_educ_gp==1 & ever_children==1), legend(on order(1 "NC - No Children" 2 "NC - Children" 3 "Coll - No Children" 4 "Coll-Children"))
graph export "$results\earn_pct_educ_x_children_intact.jpg", as(jpg) name("Graph") quality(90) replace
restore

generate u1 = runiform()
twoway (line female_earn_pct dur if couple_educ_gp==1 & dur <=15 & u1>=.25000 & u1<=.29999) // what is general shape
twoway (line female_earn_pct dur, sort) if couple_educ_gp==1  & dur <=15 & u1>=.25000 & u1<=.29999
twoway (line female_earn_pct post_dur, sort) if couple_educ_gp==1 & post_dur <=15 & u1>=.25000 & u1<=.29999 // what is general shape

twoway (scatter female_earn_pct dur) if couple_educ_gp==1
twoway (scatter female_earn_pct dur) if couple_educ_gp==1  & dur <=15 & u1>=.29000 & u1<=.29999

separate female_earn_pct, by(couple_educ_gp)
twoway (scatter female_earn_pct0 post_dur) (scatter female_earn_pct1 post_dur) (qfit female_earn_pct0 post_dur) (qfit female_earn_pct1 post_dur) if post_dur  <=15 & u1>=.79500 & u1<=.79999, legend(order(1 "No COllege" 2 "College" 3 "Fit-No" 4 "Fit -Coll"))

twoway (line female_earn_pct dur if id==93, sort) (line female_earn_pct dur if id==123, sort) (line female_earn_pct dur if id==37092, sort)  (line female_earn_pct dur if id==16743, sort)  (line female_earn_pct dur if id==54769, sort) 

********************************************************************************
* Growth curve attempts
********************************************************************************
// should I predict or do margins? (are those different idk) I think predict is easier when I add lots of variables, but margins sufficient otherwise? (see that book i downloaded p 218 (40 / 50))

// lol are these growth curves? (see assignment 3 and lecture 7 from Dan's class)
// also: https://stats.oarc.ucla.edu/stata/faq/linear-growth-models-xtmixed-vs-sem/
// and: https://data.princeton.edu/pop510/egm

mixed female_earn_pct dur|| id: dur // would I need to do durations in individuals in states??? (to add contextual?)
// baseline is 36.7% (constant), with each year of duration, goes down .135% (-.00135 is the coefficient)
margins, at(dur=(1(2)15)) // so is this how I graph the curve? am I allowed to make non-linear??
marginsplot

mixed female_earn_pct dur if couple_educ_gp==1 & post_marital_birth==0 & pre_marital_birth==0 || id: dur // this would be true test of always childless - so not sig.
margins, at(dur=(1(2)15))
marginsplot

mixed female_earn_pct dur if couple_educ_gp==1 & pre_marital_birth==0 || id: dur // this is childlesS + those who had first birth in marriage - okay so sig, but can't isolate marriage v parenthood I guess?
margins, at(dur=(1(2)15))
marginsplot

mixed female_earn_pct dur if couple_educ_gp==0 & post_marital_birth==0 & pre_marital_birth==0 || id: dur // this would be true test of always childless - still is for them
margins, at(dur=(1(2)15))
marginsplot

mixed female_earn_pct dur if couple_educ_gp==0 & pre_marital_birth==0 || id: dur 
margins, at(dur=(1(2)15))
marginsplot

mixed female_earn_pct c.dur##i.hh_earn_type_mar if couple_educ_gp==0 & pre_marital_birth==0 || id: dur 
margins i.hh_earn_type_mar, at(dur=(1(2)15))
marginsplot

mixed female_earn_pct c.dur##i.hh_earn_type_mar if couple_educ_gp==1 & pre_marital_birth==0 || id: dur 
margins i.hh_earn_type_mar, at(dur=(1(2)15))
marginsplot

mixed female_earn_pct dur c.dur#c.dur || id: dur, covariance(unstructured) // this is curvilinear, so also probably add squared term
margins, at(dur=(1(2)15))
marginsplot

mixed female_earn_pct dur|| id: dur, cov(un) 
/* from assignment: There is also significant covariance, suggesting that, the higher the initial level of anxiety, the faster it
declines over time. This makes sense given the plot of women from question 1 – they start with higher
anxiety and see a steeper decline over time.
This is true in this as well - so college start higher and decline faster
*/

mixed female_earn_pct dur post_dur i.post_first_birth || id: dur // 6.4 on p 198 of Singer and Willet, the binary = change in elevation, the post_dur = change in slope
mixed female_earn_pct dur post_dur i.post_first_birth if couple_educ_gp==0 || id: dur // 6.4 on p 198 of Singer and Willet, the binary = change in elevation, the post_dur = change in slope
mixed female_earn_pct dur post_dur i.post_first_birth if couple_educ_gp==1 || id: dur // 6.4 on p 198 of Singer and Willet, the binary = change in elevation, the post_dur = change in slope
mixed female_earn_pct dur post_dur i.post_first_birth if couple_educ_gp==1 & pre_marital_birth==0 || id: dur // I *think* I need to restrict to those who has their first birth in marriage, so duration is calculating the childless people until they transition to parenthood? is this right? okay so this is opposite conclusion? becomes LESS specialized over time? and actually my results are for people who transition to parenthood? well this ruins everything lol...
mixed female_earn_pct dur post_dur i.post_first_birth if couple_educ_gp==0 & pre_marital_birth==0 || id: dur 

mixed female_earn_pct dur post_dur i.post_first_birth i.couple_educ_gp c.dur#i.couple_educ_gp c.post_dur#i.couple_educ_gp i.post_first_birth#i.couple_educ_gp || id: dur // is this how I do an interaction? have to interact EVERTYTHING? or just what I think college will change?

mixed female_hours_pct dur post_dur i.post_first_birth i.couple_educ_gp c.dur#i.couple_educ_gp c.post_dur#i.couple_educ_gp i.post_first_birth#i.couple_educ_gp || id: dur

mixed female_earn_pct dur post_dur i.post_first_birth if couple_educ_gp==1 & paid_leave==0 || id: dur // 6.4 on p 198 of Singer and Willet, the binary = change in elevation, the post_dur = change in slope
mixed female_earn_pct dur post_dur i.post_first_birth if couple_educ_gp==1 & paid_leave==1 || id: dur // 6.4 on p 198 of Singer and Willet, the binary = change in elevation, the post_dur = change in slope

mixed female_earn_pct dur post_dur i.post_first_birth i.paid_leave i.paid_leave#c.post_dur i.paid_leave#i.post_first_birth if couple_educ_gp==1 || id: dur 

mixed female_hours_pct dur post_dur i.post_first_birth i.hh_earn_type_mar c.dur#i.hh_earn_type_mar c.post_dur#i.hh_earn_type_mar i.post_first_birth#i.hh_earn_type_mar if couple_educ_gp==0 & pre_marital_birth==0 || id: dur // wait these are hours, is that fine? or should I do earnings GAH

mixed female_hours_pct dur post_dur i.post_first_birth i.hh_earn_type_mar c.dur#i.hh_earn_type_mar c.post_dur#i.hh_earn_type_mar i.post_first_birth#i.hh_earn_type_mar if couple_educ_gp==1 & pre_marital_birth==0 || id: dur

mixed female_earn_pct dur post_dur i.post_first_birth i.hh_earn_type_mar c.dur#i.hh_earn_type_mar c.post_dur#i.hh_earn_type_mar i.post_first_birth#i.hh_earn_type_mar if couple_educ_gp==0 & pre_marital_birth==0 || id: dur //
mixed female_earn_pct dur post_dur i.post_first_birth i.hh_earn_type_mar c.dur#i.hh_earn_type_mar c.post_dur#i.hh_earn_type_mar i.post_first_birth#i.hh_earn_type_mar if couple_educ_gp==1 & pre_marital_birth==0 || id: dur

mixed wife_housework_pct dur post_dur i.post_first_birth i.hh_earn_type_mar c.dur#i.hh_earn_type_mar c.post_dur#i.hh_earn_type_mar i.post_first_birth#i.hh_earn_type_mar if couple_educ_gp==0 & pre_marital_birth==0 || id: dur //
mixed wife_housework_pct dur post_dur i.post_first_birth i.hh_earn_type_mar c.dur#i.hh_earn_type_mar c.post_dur#i.hh_earn_type_mar i.post_first_birth#i.hh_earn_type_mar if couple_educ_gp==1 & pre_marital_birth==0 || id: dur

/*
okay do I need to add coefficients to do this, not rely on margins since happening all at once?
margins post_first_birth, at(post_dur=(1(2)10))
margins, at(dur=(1(2)19) post_dur=(1(2)10))
margins post_first_birth, at(dur=(1(2)19) post_dur=(1(2)10))
*/

mixed female_earn_pct dur i.post_first_birth c.dur#i.post_first_birth || id: dur // alt, 6.5 - I don't like this because I am not 100% sure i get it
gen first_birth=0
replace first_birth=1 if when_first_birth==survey_yr
replace first_birth=1 if (when_first_birth==(survey_yr-1)) & survey_yr >=1997

mean dur if first_birth==1 // how long into marriage, on average, is first birth (to calculate curve) - 3.3
tabstat dur if first_birth==1, by(couple_educ_gp) // 2.8 for neither college, 3.8 for college

gen no_college=(couple_educ_gp==0)
gen college=(couple_educ_gp==1)
gen no_dur= no_college*dur
gen coll_dur=college*dur

gen dur_sq = dur * dur

mixed female_earn_pct c.dur##i.couple_educ_gp|| id: dur, cov(un) 
margins couple_educ_gp, at(dur=(1(2)19)) // so is this how I graph the curve? am I allowed to make non-linear??
marginsplot

mixed female_earn_pct c.dur##i.couple_educ_gp if post_first_birth==0 || id: dur, cov(un) //so PRE birth to sort of answer - is it marriage or parenthood?? - wait so both get MORE egal??
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

mixed female_earn_pct dur_sq c.dur##i.couple_educ_gp if ever_dissolve==0 || id: dur, cov(un)  // intact - get more specialized
margins couple_educ_gp, at(dur=(1(2)19)) 
marginsplot

mixed female_earn_pct dur_sq c.dur##i.couple_educ_gp if ever_dissolve==0 & post_first_birth==0 || id: dur, cov(un)  // intact prior to birth - less dramatic, college sort of declines
margins couple_educ_gp, at(dur=(1(2)19)) 
marginsplot

mixed female_earn_pct dur_sq c.dur##i.couple_educ_gp if ever_dissolve==1 || id: dur, cov(un) // dissolved
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

mixed female_earn_pct dur_sq c.dur##i.couple_educ_gp if ever_dissolve==1 & post_first_birth==0 || id: dur, cov(un) // dissolved - almost become like female BW? so is it that normative? OR the anticipation?
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

mixed female_earn_pct dur_sq c.dur##i.couple_educ_gp|| id: dur, cov(un) 
margins couple_educ_gp, at(dur=(1(2)19)) // I am not 100% sure this totally worked as curvilinear? 
marginsplot

mixed female_earn_pct no_college college no_dur coll_dur, nocons || id: no_college college no_dur coll_dur, cov(ind) // okay does this work? is interaction needed, because of time scale?
mixed female_earn_pct no_college college no_dur coll_dur, nocons ||id: no_college no_dur, nocons cov(ind) ||id: college coll_dur, nocons cov(ind) var // from handout 4, p 10...if I change cov to indepdent, can't LR test

// so college start higher and decrease faster than no college. no college actually do not see sig decline over time?
// how do I graph this?? okay margins

mixed female_earn_pct dur ///
|| statefip: dur, covariance(unstructured) ///
|| id:  dur, covariance(unstructured) mle

// do i put all predictors in first level, regardless of what level measured at? I think if I put in first level, it is the difference between (have to do math) - if in all levels, it is the actual value? i don't know how it works if one predictor is one level and the other is another....
gen unpaid=(paid_leave==0)
gen paid_dur= paid_leave*dur
gen unpaid_dur=unpaid*dur

mixed female_earn_pct paid_leave unpaid paid_dur unpaid_dur, nocons ||statefip: paid_leave unpaid paid_dur unpaid_dur, cov(ind) || id: dur, cov(ind) 
mixed female_earn_pct paid_leave unpaid paid_dur unpaid_dur, nocons ||statefip: dur, cov(ind) || id: dur, cov(ind) 

mixed female_earn_pct dur c.dur##c.dur##i.paid_leave if couple_educ_gp==1 || statefip: dur || id: dur, cov(un) 
margins paid_leave, at(dur=(1(2)19)) //
marginsplot

/*
The coefficients on schgend levels 2 and 3 indicate that girls-only
schools have a significantly higher intercept than the other school
types. However, the slopes for all three school types are statistically
indistinguishable.
true here - paid leave = higher intercept but no different slope
*/
mixed female_earn_pct c.dur##i.paid_leave if couple_educ_gp==0 || statefip: dur || id: dur, cov(un) 

mixed female_earn_pct c.dur##i.ever_children if couple_educ_gp==1 ||statefip: dur || id: dur, cov(un) 
margins ever_children, at(dur=(1(2)19)) //
marginsplot

// is discontinuous growth this easy? https://www.statalist.org/forums/forum/general-stata-discussion/general/1494743-interpretation-of-terms-in-discontinuous-growth-model-%E2%80%93-mixed-command

//hours
mixed female_hours_pct dur|| id: dur
margins, at(dur=(1(2)15))
marginsplot

mixed female_hours_pct dur c.dur#c.dur || id: dur, covariance(unstructured)
margins, at(dur=(1(2)15))
marginsplot

mixed female_hours_pct c.dur##i.couple_educ_gp || id: dur, cov(un)  // so in growth curves, the effects are MUCH more dramatic for earnings percentage, interestingly. WHICH TO USE? (or both?)
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

mixed female_hours_pct dur post_dur i.post_first_birth if couple_educ_gp==1 & pre_marital_birth==0 || id: dur // so decline, but not sig
mixed female_hours_pct dur post_dur i.post_first_birth if couple_educ_gp==0 & pre_marital_birth==0 || id: dur // pre kid - goes up, post kid - goes down

//housework
mixed wife_housework_pct dur|| id: dur
margins, at(dur=(1(2)15))
marginsplot

mixed wife_housework_pct dur c.dur#c.dur || id: dur, covariance(unstructured)
margins, at(dur=(1(2)15))
marginsplot

mixed wife_housework_pct c.dur##i.couple_educ_gp|| id: dur, cov(un) 
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

mixed wife_housework_pct dur post_dur i.post_first_birth || id: dur // 6.4 on p 198 of Singer and Willet, the binary = change in elevation, the post_dur = change in slope
mixed wife_housework_pct dur post_dur i.post_first_birth if couple_educ_gp==0 || id: dur // 6.4 on p 198 of Singer and Willet, the binary = change in elevation, the post_dur = change in slope
mixed wife_housework_pct dur post_dur i.post_first_birth if couple_educ_gp==1 || id: dur // 6.4 on p 198 of Singer and Willet, the binary = change in elevation, the post_dur = change in slope


mixed wife_housework_pct dur post_dur i.post_first_birth i.couple_educ_gp c.dur#i.couple_educ_gp c.post_dur#i.couple_educ_gp i.post_first_birth#i.couple_educ_gp || id: dur // 6.4 on p 198 of Singer and Willet, the binary = change in elevation, the post_dur = change in slope

// okay does housework just LOOK like it is going up because it goes up when people have babies and people havve babies at different durations and then it compounds as people have babies bc housework is permanently elevated? so when I split from marriage to birth, it is actually consistent? revisit the just change elevation not slope part. I think I remove post_dur? so housework is permanently elevated when you have a kid? but specialization is not, except for college-educated? necessity v. choice? wait this is interesting.

// partners's hours specifically
gen logged_wife = ln(earnings_wife)
mixed logged_wife c.dur##i.couple_educ_gp|| id: dur, cov(un)  // both go up, no college slightly faster
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

mixed weekly_hrs_wife c.dur##i.couple_educ_gp|| id: dur, cov(un)  // both down, college faster
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

mixed housework_wife c.dur##i.couple_educ_gp|| id: dur, cov(un) // college HW goes up, no college does not
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

gen logged_head = ln(earnings_head)
mixed logged_head c.dur##i.couple_educ_gp|| id: dur, cov(un) // his earnings go up, faster for college
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

mixed weekly_hrs_head c.dur##i.couple_educ_gp|| id: dur, cov(un) // both go up, same speed
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

mixed housework_head c.dur##i.couple_educ_gp|| id: dur, cov(un)  // college housework actually goes up, no college goes down
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

gen logged_gap=logged_head-logged_wife
mixed logged_gap c.dur##i.couple_educ_gp|| id: dur, cov(un)  // 
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

gen hours_gap = weekly_hrs_head - weekly_hrs_wife
mixed hours_gap c.dur##i.couple_educ_gp|| id: dur, cov(un)  // 
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

gen hw_gap = housework_wife - housework_head
mixed hw_gap c.dur##i.couple_educ_gp|| id: dur, cov(un) // 
margins couple_educ_gp, at(dur=(1(2)19))
marginsplot

// if I want to do sem (see slide 57, week 7) - I am pretty sure it needs to be WIDE.
/*
infile id y1-y5 x using marqual_wide.dat
// setup sem Model 1a (unconditional growth common residual variance)
sem (y1 <- Intercept@1 Slope@0 _cons@0) ///
 (y2 <- Intercept@1 Slope@1 _cons@0) ///
 (y3 <- Intercept@1 Slope@2 _cons@0) ///
 (y4 <- Intercept@1 Slope@3 _cons@0) ///
 (y5 <- Intercept@1 Slope@4 _cons@0) ///
 (Intercept <- _cons) ///
 (Slope <- _cons ), ///
var(e.y1@var e.y2@var e.y
*/

// parallel growth curves
* https://www.stata.com/statalist/archive/2012-07/msg00932.html
* Umberson et al used SEM

*********************************************************************
* Misc things
*********************************************************************

// to standardize on TIME TO DIVORCE
by id: egen rel_end_temp= max(survey_yr) if rel_end_all==9998
replace rel_end_all = rel_end_temp if rel_end_all==9998

gen transition_dur=.
replace transition_dur = survey_yr-rel_end_all
replace transition_dur = dur if transition_dur==. // should be all those intact

preserve
collapse (median) female_earn_pct, by(transition_dur ever_dissolve couple_educ_gp)

twoway (line female_earn_pct transition_dur if ever_dissolve==1 & couple_educ_gp==0 & transition_dur<=0 & transition_dur>=-15) (line female_earn_pct transition_dur if ever_dissolve==1 & couple_educ_gp==1 & transition_dur<=0 & transition_dur>=-15), legend(on order(1 "Dissolved, Non" 2 "Dissolved, College"))
graph export "$results\earn_pct_educ_x_dissolved_duration.jpg", as(jpg) name("Graph") quality(90) replace

restore


// also try to standardize on time pre and post first child??
browse id survey_yr rel_start_all rel_end_all status_all female_earn_pct children FIRST_BIRTH_YR NUM_CHILDREN_ BIRTHS_REF_ BIRTH_SPOUSE_ BIRTH_YR_ dur

gen first_birth_dur=.
replace first_birth_dur = survey_yr-FIRST_BIRTH_YR if ever_children==1
browse id survey_yr rel_start_all rel_end_all status_all female_earn_pct first_birth_dur children ever_children FIRST_BIRTH_YR dur if first_birth_dur < -1000 // eventually need to use FULL FILE (including like pre marriage) and see if I can get actual birth year when they transiton from 0 to 1, but that won't work right now, because i don't have full history

preserve
collapse (median) female_earn_pct if ever_children==1 & FIRST_BIRTH_YR!=9999, by(first_birth_dur couple_educ_gp)

twoway (line female_earn_pct first_birth_dur if couple_educ_gp==0 & first_birth_dur>=-10 & first_birth_dur<=20) (line female_earn_pct first_birth_dur if couple_educ_gp==1 & first_birth_dur>=-10 & first_birth_dur<=20), legend(on order(1 "Non" 2 "College"))
graph export "$results\earn_pct_educ_x_children_duration.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct if ever_children==1 & FIRST_BIRTH_YR!=9999 & ever_dissolve==0, by(first_birth_dur couple_educ_gp)

twoway (line female_earn_pct first_birth_dur if couple_educ_gp==0 & first_birth_dur>=-10 & first_birth_dur<=20) (line female_earn_pct first_birth_dur if couple_educ_gp==1 & first_birth_dur>=-10 & first_birth_dur<=20), legend(on order(1 "Non" 2 "College"))
graph export "$results\earn_pct_educ_x_children_duration_intact.jpg", as(jpg) name("Graph") quality(90) replace
restore

preserve
collapse (median) female_earn_pct if ever_children==1 & FIRST_BIRTH_YR!=9999 & ever_dissolve==1, by(first_birth_dur couple_educ_gp)

twoway (line female_earn_pct first_birth_dur if couple_educ_gp==0 & first_birth_dur>=-10 & first_birth_dur<=10) (line female_earn_pct first_birth_dur if couple_educ_gp==1 & first_birth_dur>=-10 & first_birth_dur<=10), legend(on order(1 "Non" 2 "College"))
graph export "$results\earn_pct_educ_x_children_duration)dissolve.jpg", as(jpg) name("Graph") quality(90) replace
restore