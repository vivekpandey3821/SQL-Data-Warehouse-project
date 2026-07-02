/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================

Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the 'BULK INSERT' command to load data from csv files to bronze tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;

===============================================================================
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN

    -- Track the execution time for each table load.
    DECLARE @START_TIME DATETIME,
            @END_TIME DATETIME;

    BEGIN TRY

        PRINT '============================================';
        PRINT 'LOADING BRONZE LAYERS';
        PRINT '============================================';

        /*============================================================
          CRM Data Load
        ============================================================*/

        PRINT '--------------------------------------------';
        PRINT 'LOADING CRM TABLES';
        PRINT '--------------------------------------------';

        -- Customer master data
        SET @START_TIME = GETDATE();

        PRINT '>>TRUNCATING TABLE : bronze.crm_cust_info<<';

        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> INSERTING DATA INTO : bronze.crm_cust_info';

        BULK INSERT bronze.crm_cust_info
        FROM 'D:\warehouse dataset\sql-data-warehouse-project\datasets\source_crm/cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @END_TIME = GETDATE();

        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>>LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '------------------------------------------------------------------------------------------';


        -- Product master data
        SET @START_TIME = GETDATE();

        PRINT '>>TRUNCATING TABLE : bronze.crm_prd_info<<';

        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> INSERTING DATA INTO : bronze.crm_prd_info';

        BULK INSERT bronze.crm_prd_info
        FROM 'D:\warehouse dataset\sql-data-warehouse-project\datasets\source_crm/prd_info.csv'
        WITH (
            FIRST_ROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @END_TIME = GETDATE();

        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>>LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '------------------------------------------------------------------------------------------';


        -- Sales transaction data
        SET @START_TIME = GETDATE();

        PRINT '>> TRUNCATING TABLE : bronze.crm_sales_details <<';

        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> INSERTING DATA INTO : bronze.crm_sales_details';

        BULK INSERT bronze.crm_sales_details
        FROM 'D:\warehouse dataset\sql-data-warehouse-project\datasets\source_crm/sales_details.csv'
        WITH (
            FIRST_ROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @END_TIME = GETDATE();

        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>>LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '------------------------------------------------------------------------------------------';


        /*============================================================
          ERP Data Load
        ============================================================*/

        PRINT '--------------------------------------------';
        PRINT 'LOADING ERP TABLES';
        PRINT '--------------------------------------------';

        -- Customer master attributes
        SET @START_TIME = GETDATE();

        PRINT '>>TRUNCATING DATA : bronze.erp_cust_az12<<';

        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '>>INSERTING DATA INTO : bronze.erp_cust_az12';

        BULK INSERT bronze.erp_cust_az12
        FROM 'D:\warehouse dataset\sql-data-warehouse-project\datasets\source_erp/cust_az12.csv'
        WITH (
            FIRST_ROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @END_TIME = GETDATE();

        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>>LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '------------------------------------------------------------------------------------------';


        -- Customer location data
        SET @START_TIME = GETDATE();

        PRINT '>>TRUNCATING TABLE : bronze.erp_loc_a101<<';

        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>>INSERTING DATA INTO : bronze.erp_loc_a101';

        BULK INSERT bronze.erp_loc_a101
        FROM 'D:\warehouse dataset\sql-data-warehouse-project\datasets\source_erp/loc_a101.csv'
        WITH (
            FIRST_ROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @END_TIME = GETDATE();

        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>>LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '------------------------------------------------------------------------------------------';


        -- Product category reference data
        SET @START_TIME = GETDATE();

        PRINT '>>TRUNCATING TABLE : bronze.erp_px_cat_g1v2<<';

        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>>INSERTING DATA INTO : bronze.erp_px_cat_g1v2';

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'D:\warehouse dataset\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
        WITH (
            FIRST_ROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @END_TIME = GETDATE();

        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>>LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) + ' SECONDS';
        PRINT '------------------------------------------------------------------------------------------';

    END TRY

    BEGIN CATCH

        /*============================================================
          Display SQL Server error details if the load fails.
        ============================================================*/

        PRINT '=====================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOAD';
        PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'ERROR STATE  : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '=====================================';

    END CATCH

END;
