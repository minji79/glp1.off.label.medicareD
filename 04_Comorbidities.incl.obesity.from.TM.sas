/************************************************************************************
| Project name : identify diabetes patient among GLP1 users
| Task Purpose : 
|      1. identify diabetes patient among GLP1 users (n = 6830, 9.88%)
|      2. identify hypertension patient among GLP1 users (n = 17261, 24.97%)
|      3. identify acute MI patient among GLP1 users (n = 2477, 3.58%)
|      4. identify heart failure patient among GLP1 users (n = 10233, 14.81%)
|      5. identify stroke patient among GLP1 users (n = 6903, 9.99%)
|      6. identify alzheimer among GLP1 users (n = 659, 0.95%)
| Final dataset : 
|         input.glp1users_beneid_17to20_cc
************************************************************************************/

* base data = input.glp1users_beneid_17to20_diag_TM;

/************************************************************************************
	1.    identify obesity patient among GLP1 users (n = 6830, 9.88%)
************************************************************************************/

* 1. from TM claims;

data obesity_id;
	set input.glp1users_beneid_17to20_diag_TM;
	if ICD_DGNS_CD1 in ('E660', 'E6601', 'E661', 'E662', 'E663', 'E668', 'E66811', 'E66812', 'E66813', 'E669', 
 				'278', '2780', '27801', '27802'); 
run;
data obesity_id; set obesity_id; obesity = 1; run;

* 2. merge with study population;

proc sql;
	create table input.glp1users_beneid_17to20_cc as
 	select distinct a.*, b.obesity
  	from input.glp1users_beneid_17to20 as a
   	left join obesity_id as b
    on a.BENE_ID=b.BENE_ID;
quit;

data input.glp1users_beneid_17to20_cc; set input.glp1users_beneid_17to20_cc; if missing(obesity) then obesity =0; run;
proc freq data=input.glp1users_beneid_17to20_cc; table obesity; run;

/************************************************************************************
	2.    identify hypertension patient among GLP1 users (n = 17261, 24.97%)
************************************************************************************/

* 1. from TM claims;

data htn_id;
	set input.glp1users_beneid_17to20_diag_TM;
	if ICD_DGNS_CD1 in ('I11', 'I110', 'I119', 'I120', 'I129', 'I130', 'I150', 'I151', 'I152','I158','I159','I160','I161', 
 		'401', '4011', '4019', '402', '4020', '4021', '4029', '403', '4030', '4031', '405', '4050', '4051'); 
run;
data htn_id; set htn_id; htn = 1; run;

* 2. merge with study population;

proc sql;
	create table input.glp1users_beneid_17to20_cc as
 	select distinct a.*, b.htn
  	from input.glp1users_beneid_17to20_cc as a
   	left join htn_id as b
    on a.BENE_ID=b.BENE_ID;
quit;

data input.glp1users_beneid_17to20_cc; set input.glp1users_beneid_17to20_cc; if missing(htn) then htn =0; run;
proc freq data=input.glp1users_beneid_17to20_cc; table htn; run;


/************************************************************************************
	3.    identify acute MI patient among GLP1 users (n = 2477, 3.58%)
************************************************************************************/

* 1. from BMSF cc 2020;
proc sql;
	create table input.glp1users_beneid_17to20_cc as
 	select distinct a.*, b.AMI_EVER, b.HF_EVER, b.STROKE_TIA_EVER, b.ALZH_EVER

	from input.glp1users_beneid_17to20_cc as a
  left join mbsf20.mbsf_chronic_summary_2020 as b 
  on a.BENE_ID = b.BENE_ID;
   
quit; /* 69115 obs */

data input.glp1users_beneid_17to20_cc;
  set input.glp1users_beneid_17to20_cc;

  acute_mi_bmsf = ifn(missing(AMI_EVER), 0, 1);
  hf_bmsf = ifn(missing(HF_EVER), 0, 1);
  stroke_bmsf = ifn(missing(STROKE_TIA_EVER), 0, 1);
  alzh_bmsf = ifn(missing(ALZH_EVER), 0, 1);
run;  /* 69115 obs */


* 2. from TM claims;

data mi_id;
	set input.glp1users_beneid_17to20_diag_TM;
	if ICD_DGNS_CD1 in ('I219', 'I22', 'I220', 'I221', 'I252', 
 			'410', '4100', '4101', '4102', '4103', '4104', '4105', '4106', '4107', '4108', '4109'); 
run;
data mi_id; set mi_id; acute_mi_tm = 1; run;


* 3. merge with study population;
proc sql;
	create table mi_id as
 	select distinct a.*, b.acute_mi_tm
  	from input.glp1users_beneid_17to20_cc as a
   	left join mi_id as b
    on a.BENE_ID=b.BENE_ID;
quit;
data mi_id; set mi_id; if missing(acute_mi_tm) then acute_mi_tm =0; run;

* 4. if either BMSF = 1 | TM = 1, then mi = 1;
data input.glp1users_beneid_17to20_cc;
	set mi_id;
 	if acute_mi_bmsf = 1 | acute_mi_tm = 1 then acute_mi =1;
  	drop acute_mi_bmsf acute_mi_tm AMI_EVER; 
run;
data input.glp1users_beneid_17to20_cc; set input.glp1users_beneid_17to20_cc; if missing(acute_mi) then acute_mi =0; run;
proc freq data=input.glp1users_beneid_17to20_cc; table acute_mi; run;


/************************************************************************************
	4.    identify heart failure patient among GLP1 users (n = 10233, 14.81%)
************************************************************************************/

* 1. from BMSF cc 2020;
* 2. from TM claims;
data hf_id;
	set input.glp1users_beneid_17to20_diag_TM;
	if ICD_DGNS_CD1 in ('I50', 'I500', 'I501', 'I502', 'I503', 'I504', 'I508', 'I509', 
 		            '428', '4280', '4281', '4282', '42820', '42821', '42822', '4283', '42830', '42831', '42832', '4284', '42840', '4289'); 
run;
data hf_id; set hf_id; hf_tm = 1; run;

* 3. merge with study population;
proc sql;
	create table hf_id as
 	select distinct a.*, b.hf_tm
  	from input.glp1users_beneid_17to20_cc as a
   	left join hf_id as b
    on a.BENE_ID=b.BENE_ID;
quit;
data hf_id; set hf_id; if missing(hf_tm) then hf_tm =0; run;

* 4. if either BMSF = 1 | TM = 1, then mi = 1;
data input.glp1users_beneid_17to20_cc;
	set hf_id;
 	if hf_bmsf = 1 | hf_tm = 1 then hf =1;
  	drop hf_bmsf hf_tm HF_EVER;
run;
data input.glp1users_beneid_17to20_cc; set input.glp1users_beneid_17to20_cc; if missing(hf) then hf =0; run;
proc freq data=input.glp1users_beneid_17to20_cc; table hf; run;


/************************************************************************************
	5.    identify stroke patient among GLP1 users (n = 6903, 9.99%)
************************************************************************************/

* 1. from BMSF cc 2020;
* 2. from TM claims;
data stroke_id;
	set input.glp1users_beneid_17to20_diag_TM;
	if ICD_DGNS_CD1 in ('I630','I63549','I6359','I636','I6381','I6389','I639','I64',
 		            '430', '431', '432', '433', '434', '4341', '4349', '435', '436', '437', '438'); 
run;
data stroke_id; set stroke_id; stroke_tm = 1; run;

* 3. merge with study population;
proc sql;
	create table stroke_id as
 	select distinct a.*, b.stroke_tm
  	from input.glp1users_beneid_17to20_cc as a
   	left join stroke_id as b
    on a.BENE_ID=b.BENE_ID;
quit;
data stroke_id; set stroke_id; if missing(stroke_tm) then stroke_tm =0; run;

* 4. if either BMSF = 1 | TM = 1, then mi = 1;
data input.glp1users_beneid_17to20_cc;
	set stroke_id;
 	if stroke_bmsf = 1 | stroke_tm = 1 then stroke =1;
  	drop stroke_bmsf stroke_tm STROKE_TIA_EVER;
run;
data input.glp1users_beneid_17to20_cc; set input.glp1users_beneid_17to20_cc; if missing(stroke) then stroke =0; run;
proc freq data=input.glp1users_beneid_17to20_cc; table stroke; run;

proc print data=input.glp1users_beneid_17to20_cc(obs=10); run;


/************************************************************************************
	6.    identify alzheimer among GLP1 users (n = 659, 0.95%)
************************************************************************************/

* 1. from BMSF cc 2020;
* 2. from TM claims;
data alzh_id;
	set input.glp1users_beneid_17to20_diag_TM;
	if ICD_DGNS_CD1 in ('G30','G300','G301','G308','G309',
 		            '331', '3310', '3311', '29411'); 
run;
data alzh_id; set alzh_id; alzh_tm = 1; run;

* 3. merge with study population;
proc sql;
	create table alzh_id as
 	select distinct a.*, b.alzh_tm
  	from input.glp1users_beneid_17to20_cc as a
   	left join alzh_id as b
    on a.BENE_ID=b.BENE_ID;
quit;
data alzh_id; set alzh_id; if missing(alzh_tm) then alzh_tm =0; run;

* 4. if either BMSF = 1 | TM = 1, then mi = 1;
data input.glp1users_beneid_17to20_cc;
	set alzh_id;
 	if alzh_bmsf = 1 | alzh_tm = 1 then alzh =1;
  	drop alzh_bmsf alzh_tm ALZH_EVER;
run;
data input.glp1users_beneid_17to20_cc; set input.glp1users_beneid_17to20_cc; if missing(alzh) then alzh =0; run;
proc freq data=input.glp1users_beneid_17to20_cc; table alzh; run;

proc print data=input.glp1users_beneid_17to20_cc(obs=10); run;
