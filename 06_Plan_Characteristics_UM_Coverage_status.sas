/************************************************************************************
| Project name : identify UM status, coverage for each prescriptions of glp1 users
| Task Purpose : 
|      1. Identify UM status for each prescriptions of glp1 user
|      2. Identify Part D coverage for each prescriptions of glp1 user (n=6330, 9.16% uncovered)
|      3. 
| Final dataset : 
|	      input.glp1users_beneid_17to20_um
|	      input.glp1users_pde_17to20_coverage
|	      input.glp1users_beneid_17to20_plan
************************************************************************************/

/************************************************************************************
	1.    Identify UM status for each prescriptions of glp1 user
************************************************************************************/

%macro yearly(year=, refer=);

proc sql;
	create table um_&year as
 	select distinct a.*, b.TIER_ID, b.PRIOR_AUTHORIZATION_YN, b.STEP, b.QUANTITY_LIMIT_YN
	from input.glp1users_pde_17to20 as a
 	left join &refer as b
  	on a.FORMULARY_ID=b.FORMULARY_ID and a.FRMLRY_RX_ID = b.FRMLRY_RX_ID
   where year(SRVC_DT) = &year;
quit;

%mend yearly;
%yearly(year=2020, refer=form20.formulary_2020);
%yearly(year=2019, refer=form19.formulary_2019);
%yearly(year=2018, refer=form18.formulary_2018);
%yearly(year=2017, refer=form17.formulary_2017);
%yearly(year=2016, refer=form16.formulary_2016);

data input.glp1users_beneid_17to20_um; 
  set um_2020 um_2019 um_2018 um_2017 um_2016; 
  keep BENE_ID FORMULARY_ID FRMLRY_RX_ID SRVC_DT TIER_ID PRIOR_AUTHORIZATION_YN STEP QUANTITY_LIMIT_YN;
run;

/* NA fill */
data input.glp1users_beneid_17to20_um; set input.glp1users_beneid_17to20_um; if missing(STEP) then STEP = 0; run;
data input.glp1users_beneid_17to20_um; set input.glp1users_beneid_17to20_um; if missing(PRIOR_AUTHORIZATION_YN) then PRIOR_AUTHORIZATION_YN = 0; run;

/* Any restriction */
data input.glp1users_beneid_17to20_um; 
  set input.glp1users_beneid_17to20_um; 
  if PRIOR_AUTHORIZATION_YN = 1 | STEP =1 then any_restict = 1;
  else any_restict = 0;
run;

/************************************************************************************
	2.    Identify Part D coverage for each prescriptions of glp1 user (n=6330, 9.16% uncovered)
************************************************************************************/

%macro yearly(year=, refer=);

data pde_&year; set input.glp1users_pde_17to20; where year(SRVC_DT) = &year; run;

proc sql;
	 create table covered_&year as
   select distinct 
       a.*, 
       b.*, 
       case 
            when b.FORMULARY_ID is null then 1  /* Row not found in Table B */
            else 0                             /* Row matched in Table B */
        end as not_found_flag
    from pde_&year as a
    left join &refer as b 
    on a.FORMULARY_ID = b.FORMULARY_ID and a.FRMLRY_RX_ID = b.FRMLRY_RX_ID;
quit;

%mend yearly;
%yearly(year=2020, refer=form20.formulary_2020);
%yearly(year=2019, refer=form19.formulary_2019);
%yearly(year=2018, refer=form18.formulary_2018);
%yearly(year=2017, refer=form17.formulary_2017);
%yearly(year=2016, refer=form16.formulary_2016);


data input.glp1users_pde_17to20_coverage; 
  set covered_2020 covered_2019 covered_2018 covered_2017 covered_2016;
  keep BENE_ID FORMULARY_ID FRMLRY_RX_ID SRVC_DT not_found_flag;
  where not_found_flag =1;
run;

/* NA fill */
data input.glp1users_beneid_17to20_um; set input.glp1users_beneid_17to20_um; if missing(not_found_flag) then not_found_flag = 0; run;

proc freq data=input.glp1users_pde_17to20_coverage; table not_found_flag; run; /* 6330, 9.16% uncovered */
  
/************************************************************************************
	3.    Type of plan
************************************************************************************/

%macro yearly(year=, refer=);

proc sql;
	create table plan_&year as
 	select distinct a.*, b.CONTRACT_ID, b.DED_AMT, b.DED_COINS, b.DED_COPAY, b.DED_COSTSHARE_TIERS, b.EGHP_CALENDAR_YEAR_FLAG, 
  				b.EGWP_INDICATOR, b.INCREASED_ICL, b.OOPT_AMT, b.PLAN_ID, b.REDUCED_COST_SHARE, b.REDUCED_DED, b.REDUCED_OOPT_CS, b.REDUCED_PREICL_CS
	from input.glp1users_pde_17to20 as a
 	left join &refer as b
  	on a.PLAN_CNTRCT_REC_ID = b.CONTRACT_ID and a.FORMULARY_ID = b.FORMULARY_ID
   where year(SRVC_DT) = &year;
quit;

%mend yearly;
%yearly(year=2020, refer=plan20.plan_char_2020);
%yearly(year=2019, refer=plan19.plan_char_2019);
%yearly(year=2018, refer=plan18.plan_char_2018);
%yearly(year=2017, refer=plan17.plan_char_2017);
%yearly(year=2016, refer=plan16.plan_char_2016);

data input.glp1users_beneid_17to20_plan; 
  set plan_2020 plan_2019 plan_2018 plan_2017 plan_2016; 
run;

proc print data = input.glp1users_beneid_17to20_plan (obs=10); run;

proc print data = plan20.plan_char_2020 (obs=10); run;
data plan20;
	set plan20.plan_char_2020;
 	cov_cri $10. ded_ap $10.;
 	cov_cri = input(COV_CRITERIA, $BEN_COV);
 	ded_ap = input(DED_APPLY, $DED_AP);
run;

data plan20;
    set plan20.plan_char_2020;
    length Cov_cri $10 Ded_ap $10;
    Cov_cri = put(COV_CRITERIA, $bene_cov.);
    Ded_ap = put(DED_APPLY, $ded_ap.);
run;
proc print data = plan20 (obs=10); run;

data plan19;
    set plan19.plan_char_2019;
    Cov_cri = put(COV_CRITERIA, $bene_cov.);
    Ded_ap = put(DED_APPLY, $ded_ap.);
run;
proc print data = plan19 (obs=10); run;



proc print data = plan19.plan_char_2019 (obs=10); run;



/************************************************************************************
	4.    co-pay & co-insurance
************************************************************************************/

%macro yearly(year=, refer=);

proc sql;
	create table plan_&year as
 	select distinct a.*, b.PRE_ICL_COSTSHARE_TYPE
	from input.glp1users_pde_17to20 as a
 	left join &refer as b
  	on a.PLAN_CNTRCT_REC_ID = b.CONTRACT_ID and a.PLAN_ID = b.PLAN_ID
   where year(SRVC_DT) = &year;
quit;

%mend yearly;
%yearly(year=2022, refer=plan.tier_2022);
%yearly(year=2021, refer=plan.tier_2021);
%yearly(year=2020, refer=plan.tier_2020);
%yearly(year=2019, refer=plan.tier_2019);
%yearly(year=2018, refer=plan.tier_2018);
%yearly(year=2017, refer=plan.tier_2017);


