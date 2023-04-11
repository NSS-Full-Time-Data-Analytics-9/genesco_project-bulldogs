--Danielle Cadet
--Feel free to remove the extra columns from step 1 and 2 to help it run faster if needed.
-- buildable code for finding purchase pair frequency; the SELECT statements where characteristics should be added are commented throughout the script
-- shoe_requested is primary stockno
-- req_ columns relate to primary items
-- add_ columns relate to secondary (add-on) items

--Jennifer Schreiner
--Kept only the columns approved by Chris to keep, along with brand columns; changed all_recs to all_reqs; moved comments to end of code section; shortened some renamed columsn

-- NATIONAL VIEW (1st Hierarchy):
WITH all_reqs AS (
	SELECT shoe_req
		, req_brand
		, req_desc
		, req_dept
		, req_major
		, purch_month
		, store
		, zipcode
		, add_product
		, brand_id AS add_brand
		, style_descr AS add_desc
		, department_name AS add_dept
		, major_name AS add_major  	-- Step 2: all_recs expanded
			-- all products with their secondary and descriptors for both
			-- add columns for secondary items on this level
	FROM(
			SELECT primary_stockno AS shoe_req
			, brand_id AS req_brand
			, style_descr AS req_desc
			, department_name AS req_department
			, major_name AS req_major
			, EXTRACT(MONTH FROM DATE(transaction_date)) AS purchase_month
			, store_zip AS zipcode
			, stores.store
			, secondary_stockno AS add_product
		FROM sold_with
		FULL JOIN products
			ON sold_with.primary_stockno = products.stockno
		FULL JOIN stores
			ON sold_with.store = stores.store
		) AS all_recs
	FULL JOIN products
		ON add_product = products.stockno   -- Step 1: all_recs
			-- all products with their secondary and descriptors for primary purchase only
			-- add columns for primary items and store table columns on this level
)
--Step 6: ranking recommendations for each store 
SELECT 
    shoe_requested
    , add_product
    , product_type
    , purchase_pair_freq
    , call_product
    , CASE
       WHEN product_type = 'shoe'
            THEN ROW_NUMBER() OVER (PARTITION BY call_product ORDER BY purchase_pair_freq desc)
        ELSE ROW_NUMBER() OVER (PARTITION BY call_product ORDER BY purchase_pair_freq desc)
		END AS call_rank
FROM (
		--Step 5: add call_product for easy filtering sorting
		SELECT
				shoe_requested
				, add_product
				, product_type
				, purchase_pair_freq
				, CASE
				WHEN purchase_pair_freq > 2 
					AND product_type = 'shoe' THEN 'keep'
				WHEN purchase_pair_freq <= 2
					AND product_type = 'shoe' THEN 'kick'
				WHEN purchase_pair_freq > 3 
					AND product_type = 'accessory' THEN 'keep'
				WHEN purchase_pair_freq <= 3
					AND product_type = 'accessory' THEN 'kick'
				ELSE 'ignore'
				END AS call_product
		FROM 
		(
			-- Step 4: high_correlation
			-- counting the number of times a pair is found, organized by hierachy
			SELECT shoe_requested,
				add_product
				, product_type
				, COUNT(add_product) AS purchase_pair_freq
			FROM (
				-- Step 3: product_match
				-- adding column for product type and lining up stock numbers
				SELECT shoe_requested
					, CASE
						WHEN add_department LIKE '01%'
							OR  add_department LIKE '02%'
							OR  add_department LIKE '03%'
							OR  add_department LIKE '04%'
							OR  add_department LIKE '07%' THEN 'shoe'
							ELSE 'accessory' 
						END AS product_type
					, add_product
				FROM all_recs
			) AS product_match
			GROUP BY shoe_requested
			, add_product
			, product_type
			ORDER BY shoe_requested ASC
		) AS high_correlation
	ORDER BY purchase_pair_freq DESC
) AS rank_call

-- WHERE call_product = 'keep'
-- AND product_type = 'shoe'