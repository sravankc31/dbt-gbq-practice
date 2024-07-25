WITH

 pi AS (
   SELECT awd.AWD_DSID, TRIM(pers.NAME) AS NAME, pers.DSID AS PERS_DSID
   ,      pers.SRC_UPD_DTTM
   FROM OIH.DIM_AWD_TEAM awd
   INNER JOIN OIH.DIM_PERS pers
   ON pers.EMAIL_ADDR = awd.EMAIL_ADDR
   WHERE ROLE_NAME = 'Principal Investigator'
   AND END_DATE is null AND PRJ_DSID = '0'
)

,ga AS (
   SELECT awd.AWD_DSID, TRIM(pers.NAME) AS NAME, pers.DSID AS PERS_DSID
   ,      pers.SRC_UPD_DTTM
   FROM OIH.DIM_AWD_TEAM awd
   INNER JOIN OIH.DIM_PERS pers
   ON pers.EMAIL_ADDR = awd.EMAIL_ADDR
   WHERE ROLE_NAME = 'Grants Administrator'
   AND END_DATE is null AND PRJ_DSID = '0'
)

,ba as (
   SELECT awd.AWD_DSID, pers.NAME, pers.DSID AS PERS_DSID
   ,      pers.SRC_UPD_DTTM
   FROM OIH.DIM_AWD_TEAM awd
   INNER JOIN OIH.DIM_PERS pers
   ON pers.EMAIL_ADDR = awd.EMAIL_ADDR
   WHERE ROLE_NAME = 'Billing Accountant'
   AND END_DATE is null AND PRJ_DSID = '0'
)

,attr AS (
SELECT awd.DSID
,      Broad_Utils.f_String_2_Metric(awd.ANTICIPATED_AMT) AS ANTICIPATED_AMT
,      awd.REV_TERMS
,      awd.BILL_TYPE
,      awd.INST_AWD_ACTIVITY
,      awd.CONVERGE_ID
,      spnsr.Sponsor AS ORA_Prime_Sponsor_Name
FROM OIH.DIM_AWD_ATTRIBUTES awd
LEFT OUTER JOIN Broad_OIH.v_EDW_dim_Sponsor spnsr ON spnsr.Sponsor_DSID = awd.FT_PRIM_SPONSOR
)

,oblig AS (
SELECT AWD_DWID
,      SUM(IFNULL(DIR_FNDG_AMT,0) + IFNULL(INDIR_FNDG_AMT, 0)) AS Obligated_Funding_Amount
FROM OIH.FACT_AWD_FNDG_ISSUE
GROUP BY 1
)

,status AS (
 SELECT DISTINCT SRC_Status_Name, RECON_String FROM OIH.t_EDW_ORA_Grant_Status_XREF
)  

SELECT
       grt.DWID                    AS ORA_Grant_BID
,      grt.DSID                    AS ORA_Grant_DSID
,      grt.SRC_UPD_DTTM            AS ORA_Grant_Relevance_AT
,      grt.BID                     AS ORA_Grant_Number
,      grt.DESCR                   AS ORA_Grant_Name
,      grt.NAME                    AS ORA_Grant_Nickname
,      grt.AWD_TYP_CD              AS ORA_Sponsor_Type
,      grt.BDGT_BEG_DT             AS ORA_Valid_From_Date
,      grt.BDGT_END_DT             AS ORA_Valid_to_Date
,      grt.SPNSR_DSID              AS ORA_Sponsor_DSID
,      ga.PERS_DSID                AS ORA_OSR_Admin_DSID
,      pi.PERS_DSID                AS ORA_Grant_PI_DSID
,      ba.PERS_DSID                AS ORA_Grant_Billing_Accountant_DSID
,      grt.BID                     AS ORA_Grant
,      grt.BDGT_BEG_DT             AS ORA_Grant_Start_Date
,      grt.BDGT_END_DT             AS ORA_Grant_End_Date
,      grt.AWD_STAT_CD             AS ORA_Grant_Status
,      status.RECON_String         AS ORA_Grant_Status_RECON
,      grt.BID                     AS ORA_Award_Number
,      grt.FUND                    AS ORA_Fund
,      pi.SRC_UPD_DTTM             AS ORA_Grant_PI_Relevance_AT
,      pi.NAME                     AS ORA_Grant_PI
,      ga.SRC_UPD_DTTM             AS ORA_OSR_Admin_Relevance_AT
,      ga.NAME                     AS ORA_OSR_Admin
,      ga.NAME                     AS ORA_Grant_GA
,      ba.NAME                     AS ORA_Grant_Billing_Accountant
,      spnsr.Sponsor_Relevance_AT  AS ORA_Sponsor_Relevance_AT
,      spnsr.Sponsor               AS ORA_Sponsor
,      spnsr.Sponsor_Number        AS ORA_Funding_Source_Number
,      attr.ORA_Prime_Sponsor_Name AS ORA_Prime_Sponsor_Name
,      attr.BILL_TYPE        	   AS ORA_Bill_Type
,      attr.INST_AWD_ACTIVITY      AS ORA_Instrument_Type
,      attr.CONVERGE_ID        	   AS CONVERGE_ID
,      attr.REV_TERMS 		 	   AS ORA_Rev_Terms
,      attr.ANTICIPATED_AMT        AS ORA_Grant_Anticipated_Funding_Amount
-- ,      contract.EST_AMT            AS ORA_Grant_Obligated_Funding_Amount
,      oblig.Obligated_Funding_Amount AS ORA_Grant_Obligated_Funding_Amount
,      CASE WHEN grt.SRC_INS_DTTM = grt.SRC_UPD_DTTM THEN True ELSE False END AS ORA_Is_Initial_Record
FROM OIH.DIM_AWD grt
LEFT OUTER JOIN attr ON attr.DSID = grt.DSID
-- LEFT OUTER JOIN contract ON contract.AWD_DSID = grt.DSID
LEFT OUTER JOIN pi ON pi.AWD_DSID = grt.DSID
LEFT OUTER JOIN ga ON ga.AWD_DSID = grt.DSID
LEFT OUTER JOIN ba ON ba.AWD_DSID = grt.DSID
LEFT OUTER JOIN oblig ON grt.DWID = oblig.AWD_DWID
LEFT OUTER JOIN status ON status.SRC_Status_Name = grt.AWD_STAT_CD
INNER JOIN Broad_OIH.v_EDW_dim_Sponsor spnsr ON spnsr.Sponsor_DSID = grt.SPNSR_DSID
