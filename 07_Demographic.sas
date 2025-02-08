/************************************************************************************
| Project name : Identify off label use of GLP1 following several definitions
| Task Purpose : 
|      1. add age
| Final dataset : 
|       input.glp1users_pde_17to20_demo
************************************************************************************/


/************************************************************************************
	1.    Age
************************************************************************************/

proc sql;
  create table demo_age as
  select distinct a.*, b.BENE_BIRTH_DT
  from input.glp1users_pde_17to20 as a left join mbsf20.mbsf_abcd_summary_2020 as b
  on a.BENE_ID = b.BENE_ID;
quit;

data input.glp1users_pde_17to20_demo;
  set demo_age;
  year_birth = year(BENE_BIRTH_DT);
  age_at_index = year(SRVC_DT) - year_birth;
run;

proc means data=input.glp1users_pde_17to20_demo n nmiss mean std;
  var age_at_index;
  title "age";
run;


/************************************************************************************
	2.   Race
************************************************************************************/

proc sql;
  create table input.glp1users_pde_17to20_demo as
  select distinct a.*, b.BENE_RACE_CD 
  from input.glp1users_pde_17to20_demo as a left join mbsf20.mbsf_abcd_summary_2020 as b
  on a.BENE_ID = b.BENE_ID;
quit;

/************************************************************************************
	3.   State
************************************************************************************/

proc sql;
  create table demo_state as
  select distinct a.*, b.STATE_CODE   
  from input.glp1users_pde_17to20 as a left join mbsf20.mbsf_abcd_summary_2020 as b
  on a.BENE_ID = b.BENE_ID;
quit;

* make region indicator;
data demo_state;
    set demo_state;
    length region $10.;

    if STATE_CODE in ('07', '08', '09', '10', '20', '22', '23', '29', '33', '39', '41') then region = "Northeast";
    else if STATE_CODE in ('14', '15', '16', '17', '23', '24', '25', '26', '28', '35', '36', '42', '44', '45', '52') then region = "Midwest";
    else if STATE_CODE in ('01', '04', '10', '11', '18', '19', '21', '24', '25', '34', '36', '37', '40', '42', '43', '44', '46', '50', '51', '54') then region = "South";
    else if STATE_CODE in ('02', '03', '05', '06', '12', '13', '26', '29', '30', '32', '38', '45', '46', '53', '63') then region = "West";
    else region = "Unknown";
run;
proc freq data=demo_state; table region; run;

* merge with file;
proc sql;
  create table input.glp1users_pde_17to20_demo as
  select distinct a.*, b.STATE_CODE, b.region
  from input.glp1users_pde_17to20_demo as a left join demo_state as b
  on a.BENE_ID = b.BENE_ID;
quit;
