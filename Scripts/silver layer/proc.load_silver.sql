/*
================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
================================================================================

Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
    Actions Performed:
        - Truncates Silver tables.
        - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;

================================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN 
    DECLARE @Start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
    SET @batch_start_time = GETDATE();
    PRINT '==========================';
    PRINT 'loading silver layer:';
    PRINT '==========================';

    PRINT '--------------------------';
    PRINT 'loading CRM tables';
    PRINT '--------------------------';

-- loading silver.crm_cust_info
    SET @Start_time = GETDATE();
    PRINT 'TRUNCATING TABLE:[silver].[crm_cust_info]'
    TRUNCATE TABLE [silver].[crm_cust_info]
    PRINT'INSERTING DATA INTO: [silver].[crm_cust_info]'
    INSERT INTO [silver].[crm_cust_info](
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date)
    
    SELECT  
    cst_id,
    cst_key,
    TRIM(cst_firstname) cst_firstname,
    TRIM(cst_lastname) cst_lastname,
    CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
    	   WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
    	   ELSE 'N/A'
    END cst_marital_status, 
    CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
    	   WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
    	  ELSE 'N/A'
    END cst_gndr,	 	 
    cst_create_date
    FROM(
    SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM [bronze].[crm_cust_info]
    WHERE cst_id IS NOT NULL)t
    WHERE flag_last = 1	
    SET @end_time = GETDATE();
    PRINT '-----------------------';
    
    PRINT '-----------------------------------------------------------------------------------------------------';
    PRINT 'LOAD DURATION'+ CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'SECONDS';
    PRINT '-----------------------------------------------------------------------------------------------------';
    
-------------------------------------------------------------------------------------------------------------

SET @start_time = GETDATE();
PRINT 'TRUNCATING TABLE: [silver].[crm_prd_info]'
TRUNCATE TABLE [silver].[crm_prd_info]
PRINT 'INSERTING DATA INTO: [silver].[crm_prd_info]'
INSERT INTO  [silver].[crm_prd_info] (
    prd_id,
    cat_id, 
    prd_key, 
    prd_nm,
    prd_cost, 
    prd_line,
    prd_start_dt, 
    prd_end_dt 
)

SELECT   
      prd_id,
      REPLACE(SUBSTRING(prd_key, 1,5), '-', '_') AS cat_id,
      SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
      prd_nm,
      ISNULL(prd_cost,0) AS prd_cost,
      CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'N/A'
    END AS prd_line,
     CAST (prd_start_dt AS DATE) prd_start_dt,
     DATEADD(DAY,-1,
     LEAD(CAST(prd_start_dt AS DATE)) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
FROM [bronze].[crm_prd_info]
SET @end_time = GETDATE();
PRINT '-----------------------';

PRINT '-----------------------------------------------------------------------------------------------------';
PRINT 'LOAD DURATION'+ CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'SECONDS';
PRINT '-----------------------------------------------------------------------------------------------------';

------------------------------------------------------------------------------------------------------------------------
SET @start_time = GETDATE();
PRINT'>> TRUNCATING TABLE: silver.crm_sales_details'
TRUNCATE TABLE silver.crm_sales_details
PRINT'INSERTING DATA INTO: silver.crm_sales_details'
INSERT INTO silver.crm_sales_details(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
    )

SELECT 
      sls_ord_num,
      sls_prd_key, 
      sls_cust_id,
      CASE WHEN LEN(sls_order_dt) != 8 OR sls_order_dt = 0 THEN NULL 
      ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
      END AS sls_order_dt,
      CASE WHEN LEN(sls_ship_dt) != 8 OR sls_ship_dt = 0 THEN NULL 
      ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
      END AS sls_ship_dt,
       CASE WHEN LEN(sls_due_dt) != 8 OR sls_due_dt = 0 THEN NULL 
      ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
      END AS sls_due_dt,
      	CASE WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * sls_price
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales,
      sls_quantity,
	CASE WHEN sls_price <= 0 OR sls_price IS NULL
		THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price 
	END AS sls_price

  FROM [bronze].[crm_sales_details]
  SET @end_time = GETDATE();
PRINT '-----------------------';

PRINT '-----------------------------------------------------------------------------------------------------';
PRINT 'LOAD DURATION'+ CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'SECONDS';
PRINT '-----------------------------------------------------------------------------------------------------';

-------------------------------------------------------------------------------------------------------------------
    
    PRINT '--------------------------';
    PRINT 'loading ERP tables';
    PRINT '--------------------------';

SET @start_time = GETDATE();
PRINT '>> TRUNCATING DATA INTO:[silver].[erp_cust_az12]'
TRUNCATE TABLE  [silver].[erp_cust_az12]
PRINT '>>INSETING DATA INTO:[silver].[erp_cust_az12]'
INSERT INTO [silver].[erp_cust_az12](
cid,
bdate,
gen
)

SELECT 
CASE WHEN CID = 'NAS%' THEN SUBSTRING(CID,4, LEN(CID))
ELSE CID
END cid,
CASE WHEN BDATE > GETDATE() THEN NULL
	ELSE BDATE
END AS bdate,

CASE WHEN UPPER(TRIM(GEN)) IN  ('F','Female' )THEN 'Female'
	WHEN UPPER(TRIM(GEN)) IN  ('M','Male') THEN 'Male'
	ELSE UPPER(TRIM(GEN))
END AS gen
FROM [bronze].[erp_cust_az12]
SET @end_time = GETDATE();
PRINT '-----------------------';

PRINT '-----------------------------------------------------------------------------------------------------';
PRINT 'LOAD DURATION'+ CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'SECONDS';
PRINT '-----------------------------------------------------------------------------------------------------';

------------------------------------------------------------------------------------------------------------------------
SET @start_time = GETDATE();
PRINT '>> TRUNCATING TABLE: [silver].[erp_loc_a101]';
TRUNCATE TABLE [silver].[erp_loc_a101]
PRINT '>>INSERTING DATA INTO: [silver].[erp_loc_a101]'
INSERT INTO [silver].[erp_loc_a101](
CID,
CNTRY)

SELECT
REPLACE(CID, '-','') AS cid, 
CASE WHEN TRIM(CNTRY) IN ('US','USA') THEN 'United states'
	WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
	WHEN TRIM(CNTRY) = '' OR TRIM(CNTRY) IS NULL THEN 'N/A'
	ELSE TRIM(CNTRY)
END AS cntry
FROM [bronze].[erp_loc_a101]
SET @end_time = GETDATE();
PRINT '-----------------------';

PRINT '-----------------------------------------------------------------------------------------------------';
PRINT 'LOAD DURATION'+ CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'SECONDS';
PRINT '-----------------------------------------------------------------------------------------------------';

---------------------------------------------------------------------------------------------------------------------------
SET @start_time = GETDATE()
PRINT '>> TRUNCATING TABLE: silver.erp_px_cat_g1v2';
TRUNCATE TABLE silver.erp_px_cat_g1v2
PRINT '>> INSERTING DATA INTO: silver.erp_px_cat_g1v2';
INSERT INTO silver.erp_px_cat_g1v2(ID,CAT,SUBCAT,MAINTENANCE)

SELECT 
      ID,
      CAT,
      SUBCAT,
      MAINTENANCE
  FROM [bronze].[erp_px_cat_g1v2]
  SET @end_time = GETDATE();
  PRINT '-----------------------';
PRINT '-----------------------------------------------------------------------------------------------------'
PRINT 'LOAD DURATION'+ CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + 'SECONDS';
PRINT '-----------------------------------------------------------------------------------------------------'
  SET @batch_end_time = GETDATE();
  PRINT '====================================';
  PRINT 'loading silver layer is completed';
  PRINT '- Tatal Loading Duration'+ CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'SECONDS';
  PRINT '=====================================';
  END TRY
  BEGIN CATCH 
   PRINT '=====================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOAD';
        PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'ERROR STATE  : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '=====================================';
END CATCH

END
------------------------------------------------------------------------------------------------------------------------------
