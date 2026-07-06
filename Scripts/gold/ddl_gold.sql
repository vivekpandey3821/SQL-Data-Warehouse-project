/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================

Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema).

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.

===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
CREATE VIEW gold.dim_customers AS
SELECT 
ROW_NUMBER() OVER(ORDER BY ci.cst_key) AS Customer_key,
ci.cst_id AS Customer_id,
ci.cst_key AS Customer_number ,
ci.cst_firstname AS First_name,
ci.cst_lastname AS Last_name,
la.CNTRY AS Country,
ci.cst_marital_status AS Marital_status,
CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr -- CMR IS THE MASTER FOR GNDR INFO
	 WHEN CO.GEN = '' THEN 'N/A'	
	ELSE COALESCE(CO.GEN, 'N/A')
END Gender,
CO.BDATE AS Birthdate,
ci.cst_create_date AS Create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 co
ON        ci.cst_key = co.CID
LEFT JOIN silver.erp_loc_a101 la
ON        ci.cst_key = la.CID

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
CREATE VIEW gold.dim_products AS
SELECT 
ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt,pn.prd_key) AS Product_key,
pn.prd_id AS Product_id,
pn.prd_key AS Priduct_number ,
pn.prd_nm AS Product_name,
pn.cat_id AS Category_id,
pc.CAT AS Category,
pc.SUBCAT AS Subcategory,
pc.MAINTENANCE,
pn.prd_cost AS Cost,
pn.prd_line AS Product_line,
pn.prd_start_dt AS Start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON		  pn.cat_id = pc.ID
WHERE prd_end_dt IS NULL  -- FILTER HISTORICAL DATA

-- =============================================================================
-- Create Dimension: gold.fact_sales
-- =============================================================================
CREATE VIEW gold.fact_sales AS
SELECT 
sd.sls_ord_num AS Order_number,
pr.Product_key,
cu.Customer_key,
sd.sls_order_dt AS Order_date,
sd.sls_ship_dt AS Shipping_date,
sd.sls_due_dt AS Due_date,
sd.sls_sales AS Sales_amount,
sd.sls_quantity AS Quantity,
sd.sls_price AS Price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON		  sd.sls_prd_key = pr.Priduct_number
LEFT JOIN gold.dim_customers cu
ON		  sd.sls_cust_id = cu.Customer_id























