/************************************************************************************
| Project name : identify GLP1 users with MA status indicators
| Task Purpose : 
|      1. GLP1 new users from 2018 - 2020 (n = 69,115)
|      2. Remain the first fill among GLP1 new users's records from 2018 - 2020 (n = 69,115)
|      3. Key ID summary for glp1 users (n = 69,115)
| Final dataset : 
|	input.glp1users_pde_17to20_long
|	input.glp1users_pde_17to20
|	input.glp1users_beneid_17to20
************************************************************************************/

/************************************************************************************
	1.    GLP1 new users from 2018 - 2020 (n = 69,115)
************************************************************************************/

/**************************************************
* new table: input.glp1users_pde_17to20_long
* original table: pde_file_2017 - pde_file_2020
* description: 
*       long dataset inclduing all GLP1 Rx for each patient
*       glp1 = GNN in ('SEMAGLUTIDE', 'TIRZEPATIDE')
*       no glp1 users in pde_file_2017 -> all of the users in "input.glp1users_pde_17to20" are new users
**************************************************/

* 1. Select Ozempic(semaglutide), Rybelsus(semaglutide), Mounjaro(tirzepatide) by year;

%macro yearly(data=, refer=);

data &data;
  set &refer;
  if GNN in ('SEMAGLUTIDE', 'TIRZEPATIDE');
run;

%mend yearly;
%yearly(data=glp1users_v00, refer=pde20.pde_file_2020);
%yearly(data=glp1users_v01, refer=pde19.pde_file_2019);
%yearly(data=glp1users_v02, refer=pde18.pde_file_2018);
%yearly(data=glp1users_v03, refer=pde17.pde_file_2017);

/* 2017 -> 0 obs */


* 2. stack all files;
data input.glp1users_pde_17to20_long;
 set work.glp1users_v00 work.glp1users_v01 work.glp1users_v02 work.glp1users_v03;
run;  /* 380305 */

proc sort data=input.glp1users_pde_17to20_long;
  by BENE_ID SRVC_DT;
run;

* 3. count distinct beneficiaries;
proc sql;
	select count(distinct BENE_ID) as distinct_patient_count
 	from input.glp1users_pde_17to20_long;
quit;      /* 69115 obs */


/************************************************************************************
	2.    Remain the first fill among GLP1 new users's records from 2018 - 2020 (n = 69,115)
************************************************************************************/

/**************************************************
* new table: input.glp1users_pde_17to20
* original input.glp1users_pde_17to20_long
* description: 
*       distinct patient - the first fill
*       the first prescription date = index date
**************************************************/

proc sort data=input.glp1users_pde_17to20_long;
  by BENE_ID SRVC_DT;
run;

data input.glp1users_pde_17to20;
  set input.glp1users_pde_17to20_long;
  by BENE_ID;
  if first.BENE_ID;
run;   /* n = 69,115 */

/************************************************************************************
	3.    Key ID summary for glp1 users (n = 69,115)
************************************************************************************/

/**************************************************
* new table: input.glp1users_beneid_17to20
* original table: input.glp1users_pde_17to20
* description: BENE_ID for 69,115
**************************************************/

proc sql;
	create table input.glp1users_beneid_17to20 as
 	select distinct a.BENE_ID
  	from input.glp1users_pde_17to20 as a;
quit;   /* 69115 obs */
