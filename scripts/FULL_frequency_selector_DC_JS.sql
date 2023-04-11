--Danielle Cadet
-- buildable code for finding purchase pair frequency; the SELECT statements where characteristics should be added are commented throughout the script
-- shoe_req is primary stockno
-- req_ columns relate to primary items
-- add_ columns relate to secondary (add-on) items

--Jennifer Schreiner
--Keep/add only columns Chris listed; update alias and naming conventions; moved comments to end of code section; updated code to search on codes versus names/strings

WITH base AS
				( 
					-- Step 2: all_reqs expanded
					-- all products with their secondary and descriptors for both
					-- add columns for secondary items on this level
	
					SELECT shoe_requested
						, req_dept
						, req_major
				  		, req_minor
						, store
						, district
						, state_code
						, zip
						, lat
						, long
						, org
						, add_product
						, department AS add_dept
						, major AS add_major
				  		, minor AS add_minor	
					FROM (
 						-- Step 1: all_reqs
						-- all products with their secondary and descriptors for primary purchase only
						-- add columns for primary items and store table columns on this level	
						SELECT primary_stockno AS shoe_requested
								, department AS req_dept
								, major AS req_major
								, minor AS req_minor
								, district
								, store_state_alpha AS state_code
								, store_zip AS zip
								, latitude AS lat
								, longitude AS long
								, div_org AS org
								, stores.store
								, secondary_stockno AS add_product
							FROM sold_with
								FULL JOIN products
									ON sold_with.primary_stockno = products.stockno
								FULL JOIN stores
									ON sold_with.store = stores.store
								WHERE stores.store NOT IN ('0256', '0705', '0934', '1002', '1289', '1264')
									 ) AS base  
						
						FULL JOIN products
							ON add_product = products.stockno) 	

--Step 6: ranking recommendations for each store 
SELECT 
    shoe_requested
    , add_product
    , product_type
    , combo_count
    , call_product
    , CASE
       WHEN product_type = '1'
            THEN ROW_NUMBER() OVER (PARTITION BY call_product ORDER BY combo_count desc)
        ELSE ROW_NUMBER() OVER (PARTITION BY call_product ORDER BY combo_count desc)
		END AS call_rank
FROM (
		--Step 5: add call_product for easy filtering sorting
		SELECT
				shoe_requested
				, add_product
				, product_type
				, combo_count
				, CASE
				WHEN combo_count > 2 
					AND product_type = '1' THEN '1' --product type 1=shoe, 2=accessory; THEN 1=keep; 0=kick 
				WHEN combo_count <= 2
					AND product_type = '1' THEN '0'
				WHEN combo_count >= 3 
					AND product_type = '2' THEN '1'
				WHEN combo_count < 3
					AND product_type = '2' THEN '0'
				ELSE '-1' -- -1 = ignore
				END AS call_product
		FROM  
			-- Step 4: high_correlation
			-- counting the number of times a pair is found, organized by hierachy
		(
			SELECT shoe_requested
				, add_product
				, product_type
				, COUNT(add_product) AS combo_count  
			FROM (
				-- Step 3: product_match
				-- adding column for product type and lining up stock numbers
				SELECT shoe_requested
					, CASE
						WHEN add_dept LIKE '01'
							OR  add_dept LIKE '02'
							OR  add_dept LIKE '03'
							OR  add_dept LIKE '04'
							OR  add_dept LIKE '07' THEN '1' -- 01=shoe
							ELSE '2' -- 02=accessory
						END AS product_type
					, add_product
				FROM base
			) AS product_match
			GROUP BY shoe_requested
			, add_product
			, product_type
			ORDER BY shoe_requested ASC 			
		) AS high_correlation
	ORDER BY combo_count DESC 
) AS rank_call 
