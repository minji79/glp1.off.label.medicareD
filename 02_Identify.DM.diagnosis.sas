/************************************************************************************
| Project name : identify diabetes patients among GLP1 users
| Task Purpose : 
|      1. identify diabetes patients from TM claims using ICD10 & ICD9
|      2. identify diabetes patients using 'DIABETES_EVER' from MBSF abcd file
|      3. identify diabetes patients using 'DIABETES' from MBSF abcd file
|      4. identify diabetes patients from MA claims using ICD10 & ICD9 -> it doesn't work
| Final dataset : 
|	        input.glp1users_beneid_17to20_diag_TM
|         input.DM_TM
|         input.DM_MA -> it doesn't work
|         input.DM_diabetes_ever
|         input.DM_diabetes_cc
************************************************************************************/

/************************************************************************************
	1.    identify diabetes patients from TM claims using ICD10 & ICD9
************************************************************************************/

/**************************************************
* new table: input.glp1users_beneid_17to20_diag_TM
* original TM claims
* description: 
*       entire dignosis lists for study population
**************************************************/

%macro yearly(year=, data=, refer=);

proc sql;
	create table &data as
 	select distinct a.*, b.ICD_DGNS_CD1, &year as dig_year  /* diabetes_tm_yr */
	from input.glp1users_beneid_17to20 as a
 	left join &refer as b
  	on a.BENE_ID = b.BENE_ID;
quit;

%mend yearly;

%yearly(data=tm_car21, year=2021, refer=tm_car21.bcarrier_claims_2021);
%yearly(data=tm_car20, year=2020, refer=tm_car20.bcarrier_claims_2020);
%yearly(data=tm_car19, year=2019, refer=tm_car19.bcarrier_claims_2019);
%yearly(data=tm_car18, year=2018, refer=tm_car18.bcarrier_claims_k_2018);
%yearly(data=tm_car17, year=2017, refer=tm_car17.bcarrier_claims_k_2017);
%yearly(data=tm_car16, year=2016, refer=tm_car16.bcarrier_claims_k_2016);
%yearly(data=tm_car15, year=2015, refer=tm_car15.bcarrier_claims_k_2015);

%yearly(data=tm_ip21, year=2021, refer=tm_ip21.inpatient_base_claims_2021);
%yearly(data=tm_ip20, year=2020, refer=tm_ip20.inpatient_base_claims_2020);
%yearly(data=tm_ip19, year=2019, refer=tm_ip19.inpatient_base_claims_2019);
%yearly(data=tm_ip18, year=2018, refer=tm_ip18.inpatient_base_claims_k_2018);
%yearly(data=tm_ip17, year=2017, refer=tm_ip17.inpatient_base_claims_k_2017);
%yearly(data=tm_ip16, year=2016, refer=tm_ip16.inpatient_base_claims_k_2016);
%yearly(data=tm_ip15, year=2015, refer=tm_ip15.inpatient_base_claims_k_2015);

%yearly(data=tm_op21, year=2021, refer=tm_op21.outpatient_base_claims_2021);
%yearly(data=tm_op20, year=2020, refer=tm_op20.outpatient_base_claims_2020);
%yearly(data=tm_op19, year=2019, refer=tm_op19.outpatient_base_claims_2019);
%yearly(data=tm_op18, year=2018, refer=tm_op18.outpatient_base_claims_k_2018);
%yearly(data=tm_op17, year=2017, refer=tm_op17.outpatient_base_claims_k_2017);
%yearly(data=tm_op16, year=2016, refer=tm_op16.outpatient_base_claims_k_2016);
%yearly(data=tm_op15, year=2015, refer=tm_op15.outpatient_base_claims_k_2015);

%yearly(data=tm_hha21, year=2021, refer=tm_hha21.hha_base_claims_2021);
%yearly(data=tm_hha20, year=2020, refer=tm_hha20.hha_base_claims_2020);
%yearly(data=tm_hha19, year=2019, refer=tm_hha19.hha_base_claims_2019);
%yearly(data=tm_hha18, year=2018, refer=tm_hha18.hha_base_claims_k_2018);
%yearly(data=tm_hha17, year=2017, refer=tm_hha17.hha_base_claims_k_2017);
%yearly(data=tm_hha16, year=2016, refer=tm_hha16.hha_base_claims_k_2016);
%yearly(data=tm_hha15, year=2015, refer=tm_hha15.hha_base_claims_k_2015);

/* merge */
data tm_dig_id; 
set tm_car21 tm_car20 tm_car19 tm_car18 tm_car17 tm_car16 tm_car15
tm_ip21 tm_ip20 tm_ip19 tm_ip18 tm_ip17 tm_ip16 tm_ip15 
tm_op21 tm_op20 tm_op19 tm_op18 tm_op17 tm_op16 tm_op15
tm_hha21 tm_hha20 tm_hha19 tm_hha18 tm_hha17 tm_hha16 tm_hha15; 
run;

/* remain only distinct one */
proc sql;
	create table input.glp1users_beneid_17to20_diag_TM as
 	select distinct a.* 
	from tm_dig_id as a;
quit;

* 2. find diabetes by using ICD10, ICD9;
data dm_tm;
	set input.glp1users_beneid_17to20_diag_TM;
	if ICD_DGNS_CD1 in ('E11','E110','E1100','E1101',
 		'E111','E1110','E1111','E112','E1121','E1122','E1129','E113','E1131','E11311','E11319','E1132','E11321','E113211','E113212','E113213','E113219',
  		'E11329','E113291','E113292','E113293','E113299','E1133','E1134','E1135','E1136','E1137','E1139','E114','E115','E116',
 		'E11618', 'E11620','E11621','E11622','E11628','E11630','E11638','E11641', 'E11649', 'E1165', 'E1169', 'E118', 'E119',
     '250', '2500', '2501', '2502', '2503', '2504', '2505', '2506', '2507', '2508', '2509');
run;
data dm_tm; set dm_tm; diabetes_tm = 1; run;
proc sort data=dm_tm; by BENE_ID dig_year; run;


* secondary disgnosis code;
%macro yearly(year=, data=, refer=);

/* Step 1: Join input dataset with reference dataset */
proc sql;
    create table &data as
    select distinct a.*, 
           b.ICD_DGNS_CD2, b.ICD_DGNS_CD3, b.ICD_DGNS_CD4, b.ICD_DGNS_CD5, 
           b.ICD_DGNS_CD6, b.ICD_DGNS_CD7, b.ICD_DGNS_CD8, b.ICD_DGNS_CD9, 
           b.ICD_DGNS_CD10, b.ICD_DGNS_CD11, b.ICD_DGNS_CD12,
           &year as dig_year /* Year of diagnosis */
    from input.glp1users_beneid_17to20 as a
    left join &refer as b
    on a.BENE_ID = b.BENE_ID;
quit;

/* Step 2: Create diabetes_2nd_tm indicator */
data &data;
    set &data;
    diabetes_2nd_tm = 0; /* Initialize variable */

    array DGNS_CD[11] ICD_DGNS_CD2-ICD_DGNS_CD12; /* Array for diagnosis codes */

    do k = 1 to dim(DGNS_CD);
        if DGNS_CD[k] in: ('E11', 'E110', 'E1100', 'E1101', 
            'E111', 'E1110', 'E1111', 'E112', 'E1121', 'E1122', 'E1129', 
            'E113', 'E1131', 'E11311', 'E11319', 'E1132', 'E11321', 'E113211', 
            'E113212', 'E113213', 'E113219', 'E11329', 'E113291', 'E113292', 
            'E113293', 'E113299', 'E1133', 'E1134', 'E1135', 'E1136', 'E1137', 
            'E1139', 'E114', 'E115', 'E116', 'E11618', 'E11620', 'E11621', 
            'E11622', 'E11628', 'E11630', 'E11638', 'E11641', 'E11649', 
            'E1165', 'E1169', 'E118', 'E119', '250', '2500', '2501', '2502', 
            '2503', '2504', '2505', '2506', '2507', '2508', '2509') 
        then diabetes_2nd_tm = 1;
    end;

    drop k; /* Drop the loop counter */
run;

%mend yearly;
%yearly(data=tm_car21, year=2021, refer=tm_car21.bcarrier_claims_2021);
%yearly(data=tm_car20, year=2020, refer=tm_car20.bcarrier_claims_2020);
%yearly(data=tm_car19, year=2019, refer=tm_car19.bcarrier_claims_2019);
%yearly(data=tm_car18, year=2018, refer=tm_car18.bcarrier_claims_k_2018);
%yearly(data=tm_car17, year=2017, refer=tm_car17.bcarrier_claims_k_2017);
%yearly(data=tm_car16, year=2016, refer=tm_car16.bcarrier_claims_k_2016);
%yearly(data=tm_car15, year=2015, refer=tm_car15.bcarrier_claims_k_2015);

%yearly(data=tm_ip21, year=2021, refer=tm_ip21.inpatient_base_claims_2021);
%yearly(data=tm_ip20, year=2020, refer=tm_ip20.inpatient_base_claims_2020);
%yearly(data=tm_ip19, year=2019, refer=tm_ip19.inpatient_base_claims_2019);
%yearly(data=tm_ip18, year=2018, refer=tm_ip18.inpatient_base_claims_k_2018);
%yearly(data=tm_ip17, year=2017, refer=tm_ip17.inpatient_base_claims_k_2017);
%yearly(data=tm_ip16, year=2016, refer=tm_ip16.inpatient_base_claims_k_2016);
%yearly(data=tm_ip15, year=2015, refer=tm_ip15.inpatient_base_claims_k_2015);

%yearly(data=tm_op21, year=2021, refer=tm_op21.outpatient_base_claims_2021);
%yearly(data=tm_op20, year=2020, refer=tm_op20.outpatient_base_claims_2020);
%yearly(data=tm_op19, year=2019, refer=tm_op19.outpatient_base_claims_2019);
%yearly(data=tm_op18, year=2018, refer=tm_op18.outpatient_base_claims_k_2018);
%yearly(data=tm_op17, year=2017, refer=tm_op17.outpatient_base_claims_k_2017);
%yearly(data=tm_op16, year=2016, refer=tm_op16.outpatient_base_claims_k_2016);
%yearly(data=tm_op15, year=2015, refer=tm_op15.outpatient_base_claims_k_2015);

%yearly(data=tm_hha21, year=2021, refer=tm_hha21.hha_base_claims_2021);
%yearly(data=tm_hha20, year=2020, refer=tm_hha20.hha_base_claims_2020);
%yearly(data=tm_hha19, year=2019, refer=tm_hha19.hha_base_claims_2019);
%yearly(data=tm_hha18, year=2018, refer=tm_hha18.hha_base_claims_k_2018);
%yearly(data=tm_hha17, year=2017, refer=tm_hha17.hha_base_claims_k_2017);
%yearly(data=tm_hha16, year=2016, refer=tm_hha16.hha_base_claims_k_2016);
%yearly(data=tm_hha15, year=2015, refer=tm_hha15.hha_base_claims_k_2015);

/* Merge all datasets */
data input.tm_dig_2nd_id;
    set tm_car21 tm_car20 tm_car19 tm_car18 tm_car17 tm_car16 tm_car15
        tm_ip21 tm_ip20 tm_ip19 tm_ip18 tm_ip17 tm_ip16 tm_ip15
        tm_op21 tm_op20 tm_op19 tm_op18 tm_op17 tm_op16 tm_op15
        tm_hha21 tm_hha20 tm_hha19 tm_hha18 tm_hha17 tm_hha16 tm_hha15;
run;
proc sort data=input.tm_dig_2nd_id; by BENE_ID dig_year; run;

proc sql;
    create table input.tm_dig_2nd_id as
    select distinct BENE_ID, index_date, dig_year, diabetes_2nd_tm
    from input.tm_dig_2nd_id
    where diabetes_2nd_tm =1;
quit;


* 3. merge with the study population;
/**************************************************
* new table: input.DM_TM
* original 
* description: 
*       identify diabetes patients from TM claims using ICD10 & ICD9
**************************************************/
proc sql;
	create table input.DM_TM as
 	select distinct a.*, b.diabetes_tm, b.dig_year as diabetes_tm_yr
	from input.glp1users_beneid_17to20 as a
  left join dm_tm as b
  on a.BENE_ID = b.BENE_ID;
quit;
data input.DM_TM; set input.DM_TM; if missing(diabetes_tm) then diabetes_tm =0; run;

proc sql;
	create table input.DM_TM as
 	select distinct a.*, b.diabetes_2nd_tm, b.dig_year as diabetes_2nd_tm_yr
	from input.DM_TM as a
  left join input.tm_dig_2nd_id as b
  on a.BENE_ID = b.BENE_ID and a.diabetes_tm_yr=b.dig_year;
quit;


/************************************************************************************
	2.    identify diabetes patients using 'DIABETES_EVER' from MBSF abcd file
************************************************************************************/

%macro yearly(data=, refer=);

proc sql;
	create table &data as
 	select distinct a.*, b.DIABETES_EVER
	from input.glp1users_beneid_17to20 as a
 	left join &refer as b
  	on a.BENE_ID = b.BENE_ID;
quit;

%mend yearly;

%yearly(data=mbsf20, refer=mbsf20.mbsf_chronic_summary_2020);
%yearly(data=mbsf19, refer=mbsf19.mbsf_cc_summary_2019);
%yearly(data=mbsf18, refer=mbsf18.mbsf_cc_summary_2018);
%yearly(data=mbsf17, refer=mbsf17.mbsf_cc_summary_2017);
%yearly(data=mbsf16, refer=mbsf16.mbsf_cc_summary_2016);


/* merge */
data mbsf_dm; set mbsf20 mbsf19 mbsf18 mbsf17 mbsf16; run;
data mbsf_dm; set mbsf_dm; diabetes_ever_indicator = 1; diabetes_ever_yr = year(DIABETES_EVER); run;

/* merge with the study population */
/**************************************************
* new table: input.DM_diabetes_ever
* original 
* description: 
*       identify diabetes patients using 'DIABETES_EVER' from MBSF abcd file
**************************************************/
proc sql;
	create table input.DM_diabetes_ever as
 	select distinct a.*, b.diabetes_ever_indicator as diabetes_ever, b.diabetes_ever_yr
	from input.glp1users_beneid_17to20 as a
  left join mbsf_dm as b
  on a.BENE_ID=b.BENE_ID;
quit;
data input.DM_diabetes_ever; set input.DM_diabetes_ever; if missing(diabetes_ever) then diabetes_ever =0; run;

/************************************************************************************
	3.    identify diabetes patients using 'DIABETES' from MBSF abcd file
************************************************************************************/

%macro yearly(year=, data=, refer=);

proc sql;
	create table &data as
 	select distinct a.*, b.DIABETES, &year as diabetes_yr
	from input.glp1users_beneid_17to20 as a
 	left join &refer as b
  	on a.BENE_ID = b.BENE_ID;
quit;

%mend yearly;

%yearly(year= 2020, data=mbsf20, refer=mbsf20.mbsf_chronic_summary_2020);
%yearly(year= 2019, data=mbsf19, refer=mbsf19.mbsf_cc_summary_2019);
%yearly(year= 2018, data=mbsf18, refer=mbsf18.mbsf_cc_summary_2018);
%yearly(year= 2017, data=mbsf17, refer=mbsf17.mbsf_cc_summary_2017);
%yearly(year= 2016, data=mbsf16, refer=mbsf16.mbsf_cc_summary_2016);

/* merge */
data mbsf_dm2; set mbsf20 mbsf19 mbsf18 mbsf17 mbsf16; run;

/* remain DIABETES == 1 OR 3 (Beneficiary met claims criteria regardless of coverage)*/
data mbsf_dm2; 
  set mbsf_dm2; 
  if DIABETES in (1, 3);
run;

proc print data=mbsf_dm2 (obs=20); run;

data mbsf_dm2; set mbsf_dm2; diabetes_indicator = 1; run;

/* merge with the study population */
/**************************************************
* new table: input.DM_diabetes_cc
* original 
* description: 
*       identify diabetes patients using 'DIABETES' from MBSF abcd file
**************************************************/
proc sql;
	create table input.DM_diabetes_cc as
 	select distinct a.*, b.diabetes_indicator as diabetes_cc, b.diabetes_yr as diabetes_cc_yr
	from input.glp1users_beneid_17to20 as a
  left join mbsf_dm2 as b
  on a.BENE_ID=b.BENE_ID;
quit;
data input.DM_diabetes_cc; set input.DM_diabetes_cc; if missing(diabetes_cc) then diabetes_cc =0; run;

/************************************************************************************
	4.    identify diabetes patients from MA claims using ICD10 & ICD9 -> it doesn't work
************************************************************************************/

/**************************************************
* new table: input.glp1users_beneid_17to20_diag_MA
* original MA claims
* description: 
*       entire dignosis lists for study population
**************************************************/

* primary & secondary disgnosis code;
%macro yearly(year=, data=, refer=);

/* Step 1: Join input dataset with reference dataset */
proc sql;
    create table &data as
    select distinct a.*, &year as diabetes_ma_yr,
           b.ICD_DGNS_CD1, b.ICD_DGNS_CD2, b.ICD_DGNS_CD3, b.ICD_DGNS_CD4, 
           b.ICD_DGNS_CD5, b.ICD_DGNS_CD6, b.ICD_DGNS_CD7, b.ICD_DGNS_CD8, 
           b.ICD_DGNS_CD9, b.ICD_DGNS_CD10, b.ICD_DGNS_CD11, b.ICD_DGNS_CD12,
           &year as dig_year /* Year of diagnosis */
    from input.glp1users_beneid_17to20 as a
    left join &refer as b
    on a.BENE_ID = b.BENE_ID;
quit;

/* Step 2: Create diabetes_ma indicator */
data &data;
    set &data;
    diabetes_ma = 0;

    array DGNS_CD[12] ICD_DGNS_CD1-ICD_DGNS_CD12;

    do k = 1 to dim(DGNS_CD);
        if DGNS_CD[k] in: ('E11', 'E110', 'E1100', 'E1101', 
            'E111', 'E1110', 'E1111', 'E112', 'E1121', 'E1122', 'E1129', 
            'E113', 'E1131', 'E11311', 'E11319', 'E1132', 'E11321', 'E113211', 
            'E113212', 'E113213', 'E113219', 'E11329', 'E113291', 'E113292', 
            'E113293', 'E113299', 'E1133', 'E1134', 'E1135', 'E1136', 'E1137', 
            'E1139', 'E114', 'E115', 'E116', 'E11618', 'E11620', 'E11621', 
            'E11622', 'E11628', 'E11630', 'E11638', 'E11641', 'E11649', 
            'E1165', 'E1169', 'E118', 'E119', '250', '2500', '2501', '2502', 
            '2503', '2504', '2505', '2506', '2507', '2508', '2509') 
        then diabetes_ma = 1;
    end;

    drop k; /* Drop the loop counter */
run;

%mend yearly;
%yearly(data=ma_ca19, year=2019, refer=ma_ca19.carrier_base_enc_2019);
%yearly(data=ma_ca18, year=2018, refer=ma_ca18.carrier_base_enc_2018);
%yearly(data=ma_ca17, year=2017, refer=ma_ca19.carrier_base_enc_2017);
%yearly(data=ma_ca16, year=2016, refer=ma_ca19.carrier_base_enc_2016);

%yearly(data=ma_ip19, year=2019, refer=ma_ip19.ip_base_enc_2019);
%yearly(data=ma_ip18, year=2018, refer=ma_ip18.ip_base_enc_2018);
%yearly(data=ma_ip17, year=2017, refer=ma_ip17.ip_base_enc_2017);
%yearly(data=ma_ip16, year=2016, refer=ma_ip16.ip_base_enc_2016);

%yearly(data=ma_op19, year=2019, refer=ma_op19.op_base_enc_2019);
%yearly(data=ma_op18, year=2018, refer=ma_op18.op_base_enc_2018);
%yearly(data=ma_op17, year=2017, refer=ma_op17.op_base_enc_2017);
%yearly(data=ma_op16, year=2016, refer=ma_op16.op_base_enc_2016);

%yearly(data=ma_hha19, year=2019, refer=ma_hha19.hha_base_enc_2019);
%yearly(data=ma_hha18, year=2018, refer=ma_hha18.hha_base_enc_2018);
%yearly(data=ma_hha17, year=2017, refer=ma_hha17.hha_base_enc_2017);
%yearly(data=ma_hha16, year=2016, refer=ma_hha16.hha_base_enc_2016);

%yearly(data=ma_snf19, year=2019, refer=ma_snf19.snf_base_enc_2019);
%yearly(data=ma_snf18, year=2018, refer=ma_snf18.snf_base_enc_2018);
%yearly(data=ma_snf17, year=2017, refer=ma_snf17.snf_base_enc_2017);
%yearly(data=ma_snf16, year=2016, refer=ma_snf16.snf_base_enc_2016);


/* Merge all datasets */
data dm_ma;
    set ma_ca19 ma_ca18 ma_ca17 ma_ca16
        ma_ip19 ma_ip18 ma_ip17 ma_ip16
        ma_op19 ma_op18 ma_op17 ma_op16
        ma_hha19 ma_hha18 ma_hha17 ma_hha16
        ma_snf19 ma_snf18 ma_snf17 ma_snf16;
run;
data dm_ma; set dm_ma_ip dm_ma_hha; diabetes_ma =1; run;

proc sql;
    create table input.dm_ma as
    select distinct BENE_ID, index_date, diabetes_ma, diabetes_ma_yr
    from dm_ma
    where diabetes_ma =1;
quit;

* 3. merge with the study population;
/**************************************************
* new table: input.DM_MA
* original 
* description: 
*       identify diabetes patients from MA claims using ICD10 & ICD9
**************************************************/
proc sql;
	create table input.DM_MA as
 	select distinct a.*, b.diabetes_ma, b.diabetes_ma_yr
	from input.glp1users_beneid_17to20 as a
  left join dm_ma as b
  on a.BENE_ID = b.BENE_ID;
quit;
data input.DM_MA; set input.DM_MA; if missing(diabetes_ma) then diabetes_ma =0; run;
