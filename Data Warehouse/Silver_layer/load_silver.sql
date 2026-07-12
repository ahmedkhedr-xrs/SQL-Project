/*
===============================================================================
Stored Procedure : Load to silver 
===============================================================================
Script Purpose:
    This stored procedure is used to make a clean operation on all tables of our bronze
    layer stage by using different data cleansing techniques and finally make 
    'Incremental Load' to silver schema tables.

    It performs the following actions :
    - apply data cleaning operation on all tables on bronze layer 
    - make incremental load to silver layer
    - write this operation parts into silver load log table
*/

CREATE OR ALTER PROCEDURE silver.load_to_silver 
AS 
BEGIN
    -- 2 vars to calculte all batch excution time
    DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;

    -- var to calculate each table load time
    DECLARE @start_time DATETIME ;

    -- This 3 Vars response to calculate inserted , updated rows
    DECLARE @rows_insert INT , @rows_update INT
    DECLARE @merge_output TABLE (
    action_type NVARCHAR(10)
    );

    SET @batch_start_time = GETDATE();
    PRINT '==============================================================';
    PRINT '==> STARTING SILVER LAYER LOAD';
    PRINT '==============================================================';

    PRINT '------------------------------------------------';
	PRINT 'Loading CRM Tables';
	PRINT '------------------------------------------------';

	/*=======================================================================
      1) crm_category_reference  (simple MERGE, ID is the business key)
    =======================================================================*/
    PRINT'------------------------------------------'
    PRINT '>> Table: silver.crm_category_reference';
    SET @start_time = GETDATE();
    -- check if there is batches not loaded to silver layer
	IF EXISTS (SELECT * FROM silver.get_unload_batches_inline('crm_category_reference'))
	BEGIN 
    -- try to load this batches data to the silver layer
    BEGIN TRY
    -- insert load information to log table
        INSERT INTO silver.load_log(batch_name,table_name,status)
        SELECT * , 'crm_category_reference' , 'begin_load'
        FROM silver.get_unload_batches_inline('crm_category_reference')

        -- using UPSERT (MERGE Statement) to support incremental load operation
	    MERGE silver.crm_category_reference AS t
        USING (
            SELECT * 
            FROM (
                SELECT 
                    TRIM(ID) AS ID, 
                    TRIM(CAT) AS CAT,
                    TRIM(SUBCAT) AS SUBCAT, 
                    TRIM(WARRANTY) AS WARRANTY,
                    dwh_batch_name,
                    RANK() OVER(PARTITION BY TRIM(ID) ORDER BY dwh_added_time DESC) AS rn
                FROM bronze.crm_category_reference
                WHERE dwh_batch_name IN (SELECT * FROM silver.get_unload_batches_inline('crm_category_reference'))

        ) AS t1 
        WHERE rn = 1
        ) s
        ON t.ID = s.ID

        WHEN MATCHED THEN
        UPDATE SET 
            t.WARRANTY = s.WARRANTY,
            t.SUBCAT = s.SUBCAT,
            t.CAT = s.CAT ,
            t.dwh_batch_name = s.dwh_batch_name ,
            t.dwh_update_date = GETDATE()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (ID, CAT, SUBCAT, WARRANTY, dwh_batch_name)	
            VALUES (s.ID, s.CAT, s.SUBCAT, s.WARRANTY, s.dwh_batch_name)

        OUTPUT $action INTO @merge_output;
        -- Get hom many rows inserted and how many rows updated
        SELECT @rows_insert = COUNT(*) FROM @merge_output WHERE action_type = 'INSERT';
        SELECT @rows_update  = COUNT(*) FROM @merge_output WHERE action_type = 'UPDATE';

        -- after load operation success send its success information to log table
        INSERT INTO silver.load_log(batch_name,table_name,rows_inserted,rows_updated,status)
        SELECT * , 'crm_category_reference' ,@rows_insert , @rows_update ,'commit_load'
        FROM silver.get_unload_batches_inline('crm_category_reference')

        PRINT '[SUCCESS] inserted=' + CAST(@rows_insert AS VARCHAR) + ' updated=' + CAST(@rows_update AS VARCHAR)
                  + ' in ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS VARCHAR) + 's';
	END TRY 
    -- if an Error occure delete any inserted data and send error information to log table
    BEGIN CATCH
        DELETE FROM silver.crm_category_reference
        WHERE dwh_batch_name IN (SELECT * FROM silver.get_unload_batches_inline('crm_category_reference'))
        
        INSERT INTO silver.load_log(batch_name,table_name,status)
        SELECT * , 'crm_category_reference' , 'failed'
        FROM silver.get_unload_batches_inline('crm_category_reference')
        PRINT '[FAILED] crm_category_reference: ' + ERROR_MESSAGE();
    END CATCH
    END 
	ELSE PRINT'--The table ''crm_category_reference'' already loaded all batches'


    /*=======================================================================
      2) crm_customer_demographics  (MERGE, CID needs prefix cleanup)
    =======================================================================*/
    PRINT'------------------------------------------'
    PRINT '>> Table: silver.crm_customer_demographics';
    SET @start_time = GETDATE();
    -- check if there is batches not loaded to silver layer
	IF EXISTS (SELECT * FROM silver.get_unload_batches_inline('crm_customer_demographics'))
	BEGIN 
    -- try to load this batches data to the silver layer
    BEGIN TRY
    DELETE FROM @merge_output;
    -- insert load information to log table
        INSERT INTO silver.load_log(batch_name,table_name,status)
        SELECT * , 'crm_customer_demographics' , 'begin_load'
        FROM silver.get_unload_batches_inline('crm_customer_demographics')

        -- using UPSERT (MERGE Statement) to support incremental load operation
	    MERGE silver.crm_customer_demographics AS t
        USING (
            SELECT *
            FROM (
            SELECT 
	                CASE 
	                WHEN CID LIKE 'OLD%' THEN SUBSTRING(CID,4,LEN(CID)) 
	                ELSE CID END AS CID ,
	                BDATE ,
	                CASE UPPER(TRIM(GEN))
	                WHEN 'F' THEN 'Female'
	                WHEN 'Female' THEN 'Female'
	                WHEN 'M' THEN 'Male'
	                WHEN 'Male' THEN 'Male'
	                ELSE 'n/a' END GEN ,
                    dwh_batch_name ,
                    RANK() OVER(PARTITION BY CASE WHEN CID LIKE 'OLD%' THEN SUBSTRING(CID,4,LEN(CID)) 
	                ELSE CID END  ORDER BY dwh_added_time DESC) rn
            FROM bronze.crm_customer_demographics 
            WHERE dwh_batch_name IN 
            (SELECT batch_name FROM silver.get_unload_batches_inline('crm_customer_demographics'))
            ) t1
            WHERE rn = 1) s
        ON t.CID = s.CID

        WHEN MATCHED THEN
                UPDATE SET t.BDATE = s.BDATE, t.GEN = s.GEN,
                           t.dwh_batch_name = s.dwh_batch_name, t.dwh_update_date = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (CID, BDATE, GEN, dwh_batch_name)
                VALUES (s.CID, s.BDATE, s.GEN, s.dwh_batch_name)
            OUTPUT $action INTO @merge_output;

            SELECT @rows_insert = COUNT(*) FROM @merge_output WHERE action_type = 'INSERT';
            SELECT @rows_update = COUNT(*) FROM @merge_output WHERE action_type = 'UPDATE';

            INSERT INTO silver.load_log(batch_name, table_name, rows_inserted, rows_updated, status)
            SELECT batch_name, 'crm_customer_demographics', @rows_insert, @rows_update, 'commit_load'
            FROM silver.get_unload_batches_inline('crm_customer_demographics');

            PRINT '[SUCCESS] inserted=' + CAST(@rows_insert AS VARCHAR) + ' updated=' + CAST(@rows_update AS VARCHAR)
                  + ' in ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS VARCHAR) + 's';
	END TRY 
    -- if an Error occure delete any inserted data and send error information to log table
    BEGIN CATCH
        DELETE FROM silver.crm_customer_demographics
           WHERE dwh_batch_name IN (SELECT batch_name FROM silver.get_unload_batches_inline('crm_customer_demographics'));

        INSERT INTO silver.load_log(batch_name, table_name, status)
        SELECT batch_name, 'crm_customer_demographics', 'failed'
        FROM silver.get_unload_batches_inline('crm_customer_demographics');
        PRINT '[FAILED] crm_customer_demographics: ' + ERROR_MESSAGE();
    END CATCH
    END 
	ELSE PRINT'--The table ''crm_customer_demographics'' already loaded all batches'

    /*=======================================================================
      3) crm_customer_region  (MERGE, CID format differs from cst_key -> normalize)
    =======================================================================*/
    PRINT'------------------------------------------'
    PRINT '>> Table: silver.crm_customer_region';
    SET @start_time = GETDATE();
    IF EXISTS (SELECT * FROM silver.get_unload_batches_inline('crm_customer_region'))
    BEGIN
        BEGIN TRY
            DELETE FROM @merge_output;

            INSERT INTO silver.load_log(batch_name, table_name, status)
            SELECT batch_name, 'crm_customer_region', 'begin_load'
            FROM silver.get_unload_batches_inline('crm_customer_region');

            MERGE silver.crm_customer_region AS t
            USING (
                SELECT CID, REGION, dwh_batch_name
                FROM (
                    SELECT
                        CONVERT(INT,SUBSTRING(TRIM(CID),4,LEN(CID))) AS CID ,
                        CASE UPPER(TRIM(REGION))
                            WHEN 'CAIRO' THEN 'Cairo' WHEN 'CAI' THEN 'Cairo'
                            WHEN 'GIZA' THEN 'Giza' WHEN 'GZ' THEN 'Giza'
                            WHEN 'ALEXANDRIA' THEN 'Alexandria' WHEN 'ALEX' THEN 'Alexandria' WHEN 'ALX' THEN 'Alexandria'
                            WHEN 'QALYUBIA' THEN 'Qalyubia' WHEN 'QALYOUBIA' THEN 'Qalyubia'
                            WHEN 'SHARQIA' THEN 'Sharqia' WHEN 'EL-SHARQIA' THEN 'Sharqia'
                            WHEN 'DAKAHLIA' THEN 'Dakahlia' WHEN 'MANSOURA GOV' THEN 'Dakahlia'
                            WHEN 'GHARBIA' THEN 'Gharbia'
                            WHEN 'MONUFIA' THEN 'Monufia'
                            ELSE 'n/a'
                        END AS REGION,
                        dwh_batch_name,
                        ROW_NUMBER() OVER (
                            PARTITION BY CONVERT(INT,SUBSTRING(TRIM(CID),4,LEN(CID)))
                            ORDER BY dwh_added_time DESC
                        ) AS rn
                    FROM bronze.crm_customer_region
                    WHERE dwh_batch_name IN (SELECT batch_name FROM silver.get_unload_batches_inline('crm_customer_region'))
                ) dedup
                WHERE rn = 1
            ) AS s
            ON t.CID = s.CID
            WHEN MATCHED THEN
                UPDATE SET t.REGION = s.REGION, t.dwh_batch_name = s.dwh_batch_name, t.dwh_update_date = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (CID, REGION, dwh_batch_name )
                VALUES (s.CID, s.REGION, s.dwh_batch_name)
            OUTPUT $action INTO @merge_output;

            SELECT @rows_insert = COUNT(*) FROM @merge_output WHERE action_type = 'INSERT';
            SELECT @rows_update = COUNT(*) FROM @merge_output WHERE action_type = 'UPDATE';

            INSERT INTO silver.load_log(batch_name, table_name, rows_inserted, rows_updated, status)
            SELECT batch_name, 'crm_customer_region', @rows_insert, @rows_update, 'commit_load'
            FROM silver.get_unload_batches_inline('crm_customer_region');

            PRINT '[SUCCESS] inserted=' + CAST(@rows_insert AS VARCHAR) + ' updated=' + CAST(@rows_update AS VARCHAR)
                  + ' in ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS VARCHAR) + 's';
        END TRY
        BEGIN CATCH
            DELETE FROM silver.crm_customer_region
            WHERE dwh_batch_name IN (SELECT batch_name FROM silver.get_unload_batches_inline('crm_customer_region'));

            INSERT INTO silver.load_log(batch_name, table_name, status)
            SELECT batch_name, 'crm_customer_region', 'failed'
            FROM silver.get_unload_batches_inline('crm_customer_region');
            PRINT '[FAILED] crm_customer_region: ' + ERROR_MESSAGE();
        END CATCH
    END
	ELSE PRINT'--The table ''crm_customer_region'' already loaded all batches'
    
    ----------------------------------------------------------
    PRINT '------------------------------------------------';
	PRINT 'Loading ERP Tables';
	PRINT '------------------------------------------------';
    ----------------------------------------------------------

    /*=======================================================================
      4) erp_store_branches  (small reference table, MERGE for safety)
    =======================================================================*/
    PRINT'------------------------------------------'
    PRINT '>> Table: silver.erp_store_branches';
    SET @start_time = GETDATE();
    IF EXISTS (SELECT * FROM silver.get_unload_batches_inline('erp_store_branches'))
    BEGIN
        BEGIN TRY
            DELETE FROM @merge_output;

            INSERT INTO silver.load_log(batch_name, table_name, status)
            SELECT batch_name, 'erp_store_branches', 'begin_load'
            FROM silver.get_unload_batches_inline('erp_store_branches');

            MERGE silver.erp_store_branches AS t
            USING (
                SELECT branch_id, branch_name, city, open_date, dwh_batch_name
                FROM (
                    SELECT
                        branch_id,
                        TRIM(branch_name) AS branch_name,
                        TRIM(city) AS city,
                        open_date,
                        dwh_batch_name,
                        ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY dwh_added_time DESC) AS rn
                    FROM bronze.erp_store_branches
                    WHERE dwh_batch_name IN (SELECT batch_name FROM silver.get_unload_batches_inline('erp_store_branches'))
                ) dedup
                WHERE rn = 1
            ) AS s
            ON t.branch_id = s.branch_id
            WHEN MATCHED THEN
                UPDATE SET t.branch_name = s.branch_name, t.city = s.city, t.open_date = s.open_date,
                           t.dwh_batch_name = s.dwh_batch_name, t.dwh_update_date = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (branch_id, branch_name, city, open_date, dwh_batch_name )
                VALUES (s.branch_id, s.branch_name, s.city, s.open_date, s.dwh_batch_name)
            OUTPUT $action INTO @merge_output;

            SELECT @rows_insert = COUNT(*) FROM @merge_output WHERE action_type = 'INSERT';
            SELECT @rows_update = COUNT(*) FROM @merge_output WHERE action_type = 'UPDATE';

            INSERT INTO silver.load_log(batch_name, table_name, rows_inserted, rows_updated, status)
            SELECT batch_name, 'erp_store_branches', @rows_insert, @rows_update, 'commit_load'
            FROM silver.get_unload_batches_inline('erp_store_branches');

            PRINT '[SUCCESS] inserted=' + CAST(@rows_insert AS VARCHAR) + ' updated=' + CAST(@rows_update AS VARCHAR)
                  + ' in ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS VARCHAR) + 's';
        END TRY
        BEGIN CATCH
            DELETE FROM silver.erp_store_branches
            WHERE dwh_batch_name IN (SELECT batch_name FROM silver.get_unload_batches_inline('erp_store_branches'));

            INSERT INTO silver.load_log(batch_name, table_name, status)
            SELECT batch_name, 'erp_store_branches', 'failed'
            FROM silver.get_unload_batches_inline('erp_store_branches');
            PRINT '[FAILED] erp_store_branches: ' + ERROR_MESSAGE();
        END CATCH
    END
	ELSE PRINT'--The table ''erp_store_branches'' already loaded all batches'


    /*=======================================================================
      5) erp_store_customers  (SCD1 - overwrite, protected against stale data)
    =======================================================================*/
    PRINT'------------------------------------------'
    PRINT '>> Table: silver.erp_store_customers';
    SET @start_time = GETDATE();
    IF EXISTS (SELECT * FROM silver.get_unload_batches_inline('erp_store_customers'))
    BEGIN
        BEGIN TRY
            DELETE FROM @merge_output;

            INSERT INTO silver.load_log(batch_name, table_name, status)
            SELECT batch_name, 'erp_store_customers', 'begin_load'
            FROM silver.get_unload_batches_inline('erp_store_customers');

            MERGE silver.erp_store_customers AS t
            USING (
                SELECT cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date, dwh_batch_name
                FROM (
                    SELECT
                        cst_id,
                        cst_key,
                        TRIM(cst_firstname) AS cst_firstname,
                        TRIM(cst_lastname) AS cst_lastname,
                        CASE
                            WHEN UPPER(TRIM(cst_marital_status)) IN ('S', 'SINGLE') THEN 'Single'
                            WHEN UPPER(TRIM(cst_marital_status)) IN ('M', 'MARRIED') THEN 'Married'
                            ELSE 'n/a'
                        END AS cst_marital_status,
                        CASE
                            WHEN UPPER(TRIM(cst_gndr)) IN ('M', 'MALE') THEN 'Male'
                            WHEN UPPER(TRIM(cst_gndr)) IN ('F', 'FEMALE') THEN 'Female'
                            ELSE 'n/a'
                        END AS cst_gndr,
                        cst_create_date,
                        dwh_batch_name,
                        -- take the freshest incoming row per customer across ALL pending batches
                        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC, dwh_added_time DESC) AS rn
                    FROM bronze.erp_store_customers
                    WHERE dwh_batch_name IN (SELECT batch_name FROM silver.get_unload_batches_inline('erp_store_customers'))
                ) dedup
                WHERE rn = 1
            ) AS s
            ON t.cst_id = s.cst_id
            -- never let an older/stale record overwrite a newer one already in silver
            WHEN MATCHED AND s.cst_create_date >= t.cst_create_date THEN
                UPDATE SET t.cst_key = s.cst_key, t.cst_firstname = s.cst_firstname, t.cst_lastname = s.cst_lastname,
                           t.cst_marital_status = s.cst_marital_status, t.cst_gndr = s.cst_gndr,
                           t.cst_create_date = s.cst_create_date, t.dwh_batch_name = s.dwh_batch_name,
                           t.dwh_update_date = GETDATE()
            WHEN NOT MATCHED BY TARGET THEN
                INSERT (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date,
                        dwh_batch_name)
                VALUES (s.cst_id, s.cst_key, s.cst_firstname, s.cst_lastname, s.cst_marital_status, s.cst_gndr,
                        s.cst_create_date, s.dwh_batch_name)
            OUTPUT $action INTO @merge_output;

            SELECT @rows_insert = COUNT(*) FROM @merge_output WHERE action_type = 'INSERT';
            SELECT @rows_update = COUNT(*) FROM @merge_output WHERE action_type = 'UPDATE';

            INSERT INTO silver.load_log(batch_name, table_name, rows_inserted, rows_updated, status)
            SELECT batch_name, 'erp_store_customers', @rows_insert, @rows_update, 'commit_load'
            FROM silver.get_unload_batches_inline('erp_store_customers');

            PRINT '[SUCCESS] inserted=' + CAST(@rows_insert AS VARCHAR) + ' updated=' + CAST(@rows_update AS VARCHAR)
                  + ' in ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS VARCHAR) + 's';
        END TRY
        BEGIN CATCH
            DELETE FROM silver.erp_store_customers
            WHERE dwh_batch_name IN (SELECT batch_name FROM silver.get_unload_batches_inline('erp_store_customers'));

            INSERT INTO silver.load_log(batch_name, table_name, status)
            SELECT batch_name, 'erp_store_customers', 'failed'
            FROM silver.get_unload_batches_inline('erp_store_customers');
            PRINT '[FAILED] erp_store_customers: ' + ERROR_MESSAGE();
        END CATCH
    END
    ELSE PRINT '-- erp_store_customers: nothing pending';



    /*=======================================================================
      6) erp_store_products  (SCD2 - NOT a MERGE. Rebuild affected prd_keys.)
    =======================================================================*/
    PRINT'------------------------------------------'
    PRINT '>> Table: silver.erp_store_products';
    SET @start_time = GETDATE();
    IF EXISTS (SELECT * FROM silver.get_unload_batches_inline('erp_store_products'))
    BEGIN
    BEGIN TRY
        INSERT INTO silver.load_log(batch_name, table_name, status)
        SELECT batch_name, 'erp_store_products', 'begin_load'
        FROM silver.get_unload_batches_inline('erp_store_products');

        SELECT @rows_insert = COUNT(*)
        FROM bronze.erp_store_products
        WHERE dwh_batch_name IN (SELECT batch_name FROM silver.get_unload_batches_inline('erp_store_products'))

        INSERT INTO  silver.erp_store_products(prd_id,general_prd_key,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt,dwh_batch_name)
        SELECT
            prd_id ,
            LEFT(TRIM(prd_key),7) AS general_prd_key,
            TRIM(prd_key) AS prd_key ,
            TRIM(prd_nm) AS prd_nm,
            CASE WHEN prd_cost <= 0 THEN NULL ELSE prd_cost END AS prd_cost,
            CASE prd_line
                        WHEN 'M' THEN 'Mobile Devices' WHEN 'C' THEN 'Computers'
                        WHEN 'G' THEN 'Gaming' WHEN 'D' THEN 'Displays' WHEN 'A' THEN 'Accessories'
                        ELSE 'n/a'
                    END AS prd_line,
            prd_start_dt,
            prd_end_dt,
            dwh_batch_name
        FROM bronze.erp_store_products
        WHERE dwh_batch_name IN (SELECT batch_name FROM silver.get_unload_batches_inline('erp_store_products'))

        SELECT *
        INTO #temp_erp_products
        FROM silver.erp_store_products

        TRUNCATE TABLE silver.erp_store_products

        INSERT INTO silver.erp_store_products(prd_id,general_prd_key,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt,dwh_batch_name,dwh_create_date,dwh_update_date)
        (
        SELECT  prd_id, general_prd_key, prd_key  , prd_nm , prd_cost ,prd_line ,prd_start_dt 
		    ,DATEADD(DAY,-1,LEAD(prd_start_dt) OVER(PARTITION BY prd_key order by prd_start_dt))  AS prd_end_dt
		    ,dwh_batch_name , dwh_create_date , 
            CASE WHEN DATEADD(DAY,-1,LEAD(prd_start_dt) OVER(PARTITION BY prd_key order by prd_start_dt)) IS NOT NULL AND dwh_update_date IS NULL THEN GETDATE()
            ELSE dwh_update_date END dwh_update_date
        FROM #temp_erp_products
        )

        SELECT @rows_update = COUNT(*)
        FROM (
            SELECT *
            FROM silver.erp_store_products
            EXCEPT
            SELECT *
            FROM #temp_erp_products 
        ) t1
        

        INSERT INTO silver.load_log(batch_name, table_name , rows_inserted , rows_updated ,status)
        SELECT batch_name, 'erp_store_products', @rows_insert, @rows_update ,'commit_load'
        FROM silver.get_unload_batches_inline('erp_store_products');

        PRINT '[SUCCESS] inserted=' + CAST(@rows_insert AS VARCHAR) + ' updated=' + CAST(@rows_update AS VARCHAR)
                  + ' in ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS VARCHAR) + 's';
    END TRY
    BEGIN CATCH 
        INSERT INTO silver.load_log(batch_name, table_name, status)
        SELECT batch_name, 'erp_store_products', 'failed'
        FROM silver.get_unload_batches_inline('erp_store_products');

        PRINT '[FAILED] erp_store_products: ' + ERROR_MESSAGE();
    END CATCH
    END
    ELSE PRINT'--The table ''crm_customer_demographics'' already loaded all batches'


    /*=======================================================================
      7) erp_store_sales  (Fact table - Append only, no MERGE needed)
    =======================================================================*/
    PRINT'------------------------------------------'
    PRINT '>> Table: silver.erp_store_sales';
    SET @start_time = GETDATE();
    IF EXISTS (SELECT * FROM silver.get_unload_batches_inline('erp_store_sales'))
    BEGIN
        BEGIN TRY
            INSERT INTO silver.load_log(batch_name, table_name, status)
            SELECT batch_name, 'erp_store_sales', 'begin_load'
            FROM silver.get_unload_batches_inline('erp_store_sales');

            INSERT INTO silver.erp_store_sales
                (sls_ord_num, sls_prd_key, sls_cust_id, sls_store_id, sls_order_dt, sls_ship_dt, sls_due_dt,
                 sls_sales, sls_quantity, sls_price, dwh_batch_name)
            SELECT
                sls_ord_num,
                TRIM(sls_prd_key) AS sls_prd_key,
                sls_cust_id,
                sls_store_id,
                CASE WHEN sls_order_dt IS NULL OR sls_order_dt = 0 OR LEN(CAST(sls_order_dt AS VARCHAR)) != 8
                     THEN NULL ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) END AS sls_order_dt,
                CASE WHEN sls_ship_dt IS NULL OR sls_ship_dt = 0 OR LEN(CAST(sls_ship_dt AS VARCHAR)) != 8
                     THEN NULL ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) END AS sls_ship_dt,
                CASE WHEN sls_due_dt IS NULL OR sls_due_dt = 0 OR LEN(CAST(sls_due_dt AS VARCHAR)) != 8
                     THEN NULL ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) END AS sls_due_dt,
                CASE 
				WHEN sls_sales IS NULL OR sls_sales <= 0 OR (sls_sales != sls_quantity * ABS(sls_price) AND sls_price !=0) 
					THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			    END AS sls_sales, -- Recalculate sales if original value is missing or incorrect
			    sls_quantity,
			    CASE 
				WHEN sls_price IS NULL OR sls_price <= 0 
					THEN sls_sales / NULLIF(sls_quantity, 0)
				ELSE sls_price  -- Derive price if original value is invalid
			    END AS sls_price,
                dwh_batch_name
            FROM bronze.erp_store_sales
            WHERE dwh_batch_name IN (SELECT batch_name FROM silver.get_unload_batches_inline('erp_store_sales'));

            SET @rows_insert = @@ROWCOUNT;

            INSERT INTO silver.load_log(batch_name, table_name, rows_inserted, rows_updated, status)
            SELECT batch_name, 'erp_store_sales', @rows_insert, 0, 'commit_load'
            FROM silver.get_unload_batches_inline('erp_store_sales');

            PRINT '[SUCCESS] inserted=' + CAST(@rows_insert AS VARCHAR)
                  + ' in ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS VARCHAR) + 's';
        END TRY
        BEGIN CATCH
            DELETE FROM silver.erp_store_sales
            WHERE dwh_batch_name IN (SELECT batch_name FROM silver.get_unload_batches_inline('erp_store_sales'));

            INSERT INTO silver.load_log(batch_name, table_name, status)
            SELECT batch_name, 'erp_store_sales', 'failed'
            FROM silver.get_unload_batches_inline('erp_store_sales');
            PRINT '[FAILED] erp_store_sales: ' + ERROR_MESSAGE();
        END CATCH
    END
	ELSE PRINT'--The table ''erp_store_sales'' already loaded all batches'


    SET @batch_end_time = GETDATE();
    PRINT '==============================================================';
    PRINT '=> SILVER LAYER LOAD COMPLETED';
    PRINT '   - Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS VARCHAR) + ' seconds.';
    PRINT '==============================================================';

END