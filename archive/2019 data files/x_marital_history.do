use "$PSID/mh_85_19.dta", clear

/* first rename for ease*/
rename MH1 releaseno
rename MH2 main_fam_id
rename MH3 main_per_id
rename MH4 sex
rename MH5 mo_born
rename MH6 yr_born
rename MH7 spouse_fam_id
rename MH8 spouse_per_id
rename MH9 marrno 
rename MH10 mo_married
rename MH11 yr_married
rename MH12 status
rename MH13 mo_widdiv
rename MH14 yr_widdiv
rename MH15 mo_sep
rename MH16 yr_sep
rename MH17 history
rename MH18 num_marriages
rename MH19 marital_status
rename MH20 num_records

label define status 1 "Intact" 3 "Widow" 4 "Divorce" 5 "Separation" 7 "Other" 8 "DK" 9 "Never Married"
label values status status

gen unique_id = (main_fam_id*1000) + main_per_id
// browse unique_id main_per_id main_fam_id

browse unique_id marrno status yr_widdiv yr_sep

egen yr_end = rowmin(yr_widdiv yr_sep)
browse unique_id marrno status yr_widdiv yr_sep yr_end

// this is currently LONG - one record per marriage. want to make WIDE

drop mo_born mo_widdiv yr_widdiv mo_sep yr_sep history
bysort unique_id: egen year_birth = min(yr_born)
drop yr_born

reshape wide spouse_fam_id spouse_per_id mo_married yr_married status yr_end, i(unique_id main_per_id main_fam_id) j(marrno)
// gen INTERVIEW_NUM_1968 = fam_id

save "$created_data/2019/marital_history_wide_2019.dta", replace

********************************************************************************
* Just cohabitation - for partner
********************************************************************************

use "$PSID/family_matrix_68_19.dta", clear // relationship matrix downloaded from PSID site

unique MX5 MX6 // should match the 82000 in other file? -- okay so it does. I am dumb because I restricted to only partners. omg this explains evertything

rename MX5 ego_1968_id 
rename MX6 ego_per_num
recode MX7 (1=1)(2=2)(3/8=3)(9=2)(10=1)(11/19=3)(20/22=2)(23/87=3)(88=2)(89/120=3), gen(ego_rel) // ego relationship to ref. because also only really useful if one is reference person bc otherwise i don't get a ton of info about them
recode MX12 (1=1)(2=2)(3/8=3)(9=2)(10=1)(11/19=3)(20/22=2)(23/87=3)(88=2)(89/120=3), gen(alter_rel) // alter relationship to ref

label define rels 1 "Ref" 2 "Spouse/Partner" 3 "Other"
label values ego_rel alter_rel rels

gen partner_1968_id = MX10 if MX8==22
gen partner_per_num = MX11 if MX8==22
gen unique_id = (ego_1968_id*1000) + ego_per_num // how they tell you to identify in main file
// egen ego_unique = concat(ego_1968_id ego_per_num), punct(_)
// egen partner_unique = concat(partner_1968_id partner_per_num), punct(_)
gen partner_unique_id = (partner_1968_id*1000) + partner_per_num

// try making specific variable to match E30002 that is 1968 id? but what if not in 1968??

keep if MX8==22

browse MX2 ego_1968_id ego_per_num unique_id partner_1968_id partner_per_num partner_unique_id MX8 // does unique_id track over years? or just 1 record per year? might this be wrong?

keep MX2 ego_1968_id ego_per_num unique_id partner_1968_id partner_per_num partner_unique_id MX8

// seeing if not working because needs to be LONG 
reshape wide partner_1968_id partner_per_num partner_unique_id MX8, i(ego_1968_id ego_per_num unique_id) j(MX2)

// for ego - will match on unique_id? need to figure out how to match partner, keep separate?
rename ego_1968_id main_fam_id
rename ego_per_num main_per_id

// browse main_fam_id main_per_id unique_id

gen spouse_fam_id = main_fam_id
gen spouse_per_id = main_per_id
// gen INTERVIEW_NUM_1968 = INTERVIEW_NUM_

// okay so not JUST the ids, but also YEAR?!  unique MX2 main_per_id INTERVIEW_NUM_
// rename MX2 survey_yr

unique main_per_id main_fam_id

save "$temp/2019/PSID_partner_history.dta", replace // really this is just cohabitation NOT marriages.
