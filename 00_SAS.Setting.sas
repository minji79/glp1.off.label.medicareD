* start; 
ssh -X c-mkim255-59883@jhpcecms01.jhsph.edu  
srun --pty --x11 --partition=sas bash

* directory;
cd /cms01/data/dua/59883/
cd /users/59883/c-mkim255-59883/

* figure reset;
mv  .config/chromium/ .config/chromium.aside

* using SAS;
module load sas
csas -WORK /tmp/

/************************************************************************************
	1. Set library
************************************************************************************/

/* input file */
libname input "/users/59883/c-mkim255-59883/glp1off/sas_input";

/* MBSF 
	mbsf_abcd_summary_2020
 	mbsf_chronic_summary_2020
  mbsf_cc_summary_2020
  mbsf_costuse_2020
*/
libname mbsf16 "/cms01/data/dua/59883/mbsf/2016/SAS";
libname mbsf17 "/cms01/data/dua/59883/mbsf/2017/SAS";
libname mbsf18 "/cms01/data/dua/59883/mbsf/2018/SAS";
libname mbsf19 "/cms01/data/dua/59883/mbsf/2019/SAS";
libname mbsf20 "/cms01/data/dua/59883/mbsf/2020/SAS";

/* part_d_pde */
libname pde16 "/cms01/data/dua/59883/part_d_pde/2016/SAS";
libname pde17 "/cms01/data/dua/59883/part_d_pde/2017/SAS";
libname pde18 "/cms01/data/dua/59883/part_d_pde/2018/SAS";
libname pde19 "/cms01/data/dua/59883/part_d_pde/2019/SAS";
libname pde20 "/cms01/data/dua/59883/part_d_pde/2020/SAS";

/* part_d_formulary */
libname form16 "/cms01/data/dua/59883/part_d_formulary/2016/SAS";
libname form17 "/cms01/data/dua/59883/part_d_formulary/2017/SAS";
libname form18 "/cms01/data/dua/59883/part_d_formulary/2018/SAS";
libname form19 "/cms01/data/dua/59883/part_d_formulary/2019/SAS";
libname form20 "/cms01/data/dua/59883/part_d_formulary/2020/SAS";

/* part_d_pharmacy 
	pharm_char_2020
*/

/* part_d_plan 
	tier_2020
 	service_area_2020
	plan_char_2020
	plan_crosswalk_2020
	snp_contract_info_2020
	premium_2020
*/
libname plan16 "/cms01/data/dua/59883/part_d_plan/2016/SAS";
libname plan17 "/cms01/data/dua/59883/part_d_plan/2017/SAS";
libname plan18 "/cms01/data/dua/59883/part_d_plan/2018/SAS";
libname plan19 "/cms01/data/dua/59883/part_d_plan/2019/SAS";
libname plan20 "/cms01/data/dua/59883/part_d_plan/2020/SAS";

/* part_d_prescriber */
libname pres16 "/cms01/data/dua/59883/part_d_prescriber/2016/SAS";
libname pres17 "/cms01/data/dua/59883/part_d_prescriber/2017/SAS";
libname pres18 "/cms01/data/dua/59883/part_d_prescriber/2018/SAS";
libname pres19 "/cms01/data/dua/59883/part_d_prescriber/2019/SAS";
libname pres20 "/cms01/data/dua/59883/part_d_prescriber/2020/SAS";

/* ma_carrier : 16-19 
	bene_ff_2019
	carrier_base_enc_2019
	carrier_line_enc_2019
*/
libname ma_ca16 "/cms01/data/dua/59883/ma_carrier/2016/SAS";
libname ma_ca17 "/cms01/data/dua/59883/ma_carrier/2017/SAS";
libname ma_ca18 "/cms01/data/dua/59883/ma_carrier/2018/SAS";
libname ma_ca19 "/cms01/data/dua/59883/ma_carrier/2019/SAS";

/* ma_hha */
libname ma_hha16 "/cms01/data/dua/59883/ma_hha/2016/SAS";
libname ma_hha17 "/cms01/data/dua/59883/ma_hha/2017/SAS";
libname ma_hha18 "/cms01/data/dua/59883/ma_hha/2018/SAS";
libname ma_hha19 "/cms01/data/dua/59883/ma_hha/2019/SAS";

/* ma_ip 
	ip_base_enc_2019
 	ip_revenue_enc_2019
  ip_condition_codes_enc_2019
  ip_span_codes_enc_2019
  ip_occurrnce_codes_enc_2019
  ip_value_codes_enc_2019
*/
libname ma_ip16 "/cms01/data/dua/59883/ma_ip/2016/SAS";
libname ma_ip17 "/cms01/data/dua/59883/ma_ip/2017/SAS";
libname ma_ip18 "/cms01/data/dua/59883/ma_ip/2018/SAS";
libname ma_ip19 "/cms01/data/dua/59883/ma_ip/2019/SAS";

/* ma_op */
libname ma_op16 "/cms01/data/dua/59883/ma_op/2016/SAS";
libname ma_op17 "/cms01/data/dua/59883/ma_op/2017/SAS";
libname ma_op18 "/cms01/data/dua/59883/ma_op/2018/SAS";
libname ma_op19 "/cms01/data/dua/59883/ma_op/2019/SAS";

/* ma_snf */
libname ma_snf16 "/cms01/data/dua/59883/ma_op/2016/SAS";
libname ma_snf17 "/cms01/data/dua/59883/ma_op/2017/SAS";
libname ma_snf18 "/cms01/data/dua/59883/ma_op/2018/SAS";
libname ma_snf19 "/cms01/data/dua/59883/ma_op/2019/SAS";


/* mdppas : 18-20 */ 
libname mdppas18 "/cms01/data/dua/59883/mdppas/2018/SAS";
libname mdppas19 "/cms01/data/dua/59883/mdppas/2019/SAS";
libname mdppas20 "/cms01/data/dua/59883/mdppas/2020/SAS";

/* mds : 14-21 */ 
libname mds16 "/cms01/data/dua/59883/mdppas/2016/SAS";
libname mds17 "/cms01/data/dua/59883/mdppas/2017/SAS";
libname mds18 "/cms01/data/dua/59883/mdppas/2018/SAS";
libname mds19 "/cms01/data/dua/59883/mdppas/2019/SAS";
libname mds20 "/cms01/data/dua/59883/mdppas/2020/SAS";
libname mds21 "/cms01/data/dua/59883/mdppas/2021/SAS";

/* medpar : 14-21 */
libname medpar16 "/cms01/data/dua/59883/medpar/2016/SAS";
libname medpar17 "/cms01/data/dua/59883/medpar/2017/SAS";
libname medpar18 "/cms01/data/dua/59883/medpar/2018/SAS";
libname medpar19 "/cms01/data/dua/59883/medpar/2019/SAS";
libname medpar20 "/cms01/data/dua/59883/medpar/2020/SAS";
libname medpar21 "/cms01/data/dua/59883/medpar/2021/SAS";


/* tm_carrier : 15-21 */
libname tm_car15 "/cms01/data/dua/59883/tm_carrier/2015/SAS";
libname tm_car16 "/cms01/data/dua/59883/tm_carrier/2016/SAS";
libname tm_car17 "/cms01/data/dua/59883/tm_carrier/2017/SAS";
libname tm_car18 "/cms01/data/dua/59883/tm_carrier/2018/SAS";
libname tm_car19 "/cms01/data/dua/59883/tm_carrier/2019/SAS";
libname tm_car20 "/cms01/data/dua/59883/tm_carrier/2020/SAS";
libname tm_car21 "/cms01/data/dua/59883/tm_carrier/2021/SAS";

/* tm_hha : 15-21 */ 
libname tm_hha15 "/cms01/data/dua/59883/tm_hha/2015/SAS";
libname tm_hha16 "/cms01/data/dua/59883/tm_hha/2016/SAS";
libname tm_hha17 "/cms01/data/dua/59883/tm_hha/2017/SAS";
libname tm_hha18 "/cms01/data/dua/59883/tm_hha/2018/SAS";
libname tm_hha19 "/cms01/data/dua/59883/tm_hha/2019/SAS";
libname tm_hha20 "/cms01/data/dua/59883/tm_hha/2020/SAS";
libname tm_hha21 "/cms01/data/dua/59883/tm_hha/2021/SAS";

/* tm_ip : 15-21 */ 
libname tm_ip15 "/cms01/data/dua/59883/tm_ip/2015/SAS";
libname tm_ip16 "/cms01/data/dua/59883/tm_ip/2016/SAS";
libname tm_ip17 "/cms01/data/dua/59883/tm_ip/2017/SAS";
libname tm_ip18 "/cms01/data/dua/59883/tm_ip/2018/SAS";
libname tm_ip19 "/cms01/data/dua/59883/tm_ip/2019/SAS";
libname tm_ip20 "/cms01/data/dua/59883/tm_ip/2020/SAS";
libname tm_ip21 "/cms01/data/dua/59883/tm_ip/2021/SAS";

/* tm_op : 15-21 */ 
libname tm_op15 "/cms01/data/dua/59883/tm_op/2015/SAS";
libname tm_op16 "/cms01/data/dua/59883/tm_op/2016/SAS";
libname tm_op17 "/cms01/data/dua/59883/tm_op/2017/SAS";
libname tm_op18 "/cms01/data/dua/59883/tm_op/2018/SAS";
libname tm_op19 "/cms01/data/dua/59883/tm_op/2019/SAS";
libname tm_op20 "/cms01/data/dua/59883/tm_op/2020/SAS";
libname tm_op21 "/cms01/data/dua/59883/tm_op/2021/SAS";
