**********************************************************************************
* Stats server
**********************************************************************************
if `"`c(hostname)'"' == "PPRC-STATS-P01"{
	global homedir "T:" // comment this out if you are not using the PRC Remote Server

	* This is the base directory with the setup files.
	* It is the directory you should change into before executing any files
	global code "$homedir/github/divorce-over-time"


	* This locations of folders containing the original data files
	global PSID "/data/PSID"
	global SIPP2014 "/data/sipp/2014"
	global ACS "/data/ACS"
	global CPS "/data/CPS"


	* Note that these directories will contain all "created" files - including intermediate data, results, and log files.

	* created data files
	global created_data "$homedir/Research Projects/Dissertation - Union Dissolution/data_keep"
	global state_data "$homedir/Research Projects/State data/data_keep"
	global structural "$homedir/data/structural support measure"

	* results
	global results "$homedir/Research Projects/Dissertation - Union Dissolution/results"

	* logdir
	global logdir "$homedir/Research Projects/Dissertation - Union Dissolution/logs"

	* temporary data files (they get deleted without a second thought)
	global temp "$homedir/Research Projects/Dissertation - Union Dissolution/data_tmp"
}

**********************************************************************************
* Personal computer
**********************************************************************************
if `"`c(hostname)'"' == "LAPTOP-TP2VHI6B"{
	global homedir "G:\Other computers\My Laptop\Documents"
	
	global code "$homedir/Github/divorce-over-time"
	
	* created data files
	global created_data "$homedir/Dissertation/Union Dissolution/data/created"
	global results "$homedir/Dissertation/Union Dissolution/results"
	global logdir "$homedir/Dissertation/Union Dissolution/data/log files"
	global temp "$homedir/Dissertation/Union Dissolution/data/created/temp"

}

set maxvar 10000

// net install mecompare, from("https://tdmize.github.io/data/") replace
// ssc install spost13_ado, replace

********************************************************************************
/* Create macro for current date
global logdate = string( d(`c(current_date)'), "%dCY.N.D" ) 		// create a macro for the date*/

/********************************************************************************
* Notes on order of operations
1. download data from PSID and run through PSID-generated .do files. Will name those "PSID-full"
2. In this github folder, run x_rename_variables, which you will get frm Excel sheet. This creates "PSID-full-renamed"
3. Then, go into step 1, need to add any new variables to the reshape (see Excel) and run through step 1 to get new long data file.
4. Then run step 2 - need that relationship history
4. Then, run through step 3 - this is where most recodes happen
5. Then, go into marital dissolution specific folder for analysis and descriptives

********************************************************************************/