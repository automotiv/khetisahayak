-- Simple product test script to isolate ORA-01422 error
DECLARE
   v_category_code   VARCHAR2(50) := 'MP0001';
   v_category_pk     NUMBER;
   v_product_code    VARCHAR2(50);
   v_product_pk      NUMBER;
   v_count           NUMBER;
BEGIN
   -- Enable DBMS_OUTPUT
   DBMS_OUTPUT.ENABLE(1000000);
   
   DBMS_OUTPUT.PUT_LINE('=== SIMPLE PRODUCT TEST STARTED ===');
   DBMS_OUTPUT.PUT_LINE('Debug: Testing category code: ' || v_category_code);
   
   -- Test 1: Find category PK
   DBMS_OUTPUT.PUT_LINE('Debug: Test 1 - Finding category PK');
   BEGIN
      SELECT pk INTO v_category_pk FROM categories WHERE p_code = v_category_code;
      DBMS_OUTPUT.PUT_LINE('Debug: Category PK found: ' || v_category_pk);
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: Category not found');
         RETURN;
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: Category lookup failed: ' || SQLERRM);
         RETURN;
   END;
   
   -- Test 2: Count products in category
   DBMS_OUTPUT.PUT_LINE('Debug: Test 2 - Counting products in category');
   BEGIN
      SELECT COUNT(*) INTO v_count 
      FROM products p
      JOIN cat2prodrel c2p ON c2p.targetpk = p.pk
      WHERE c2p.sourcepk = v_category_pk;
      DBMS_OUTPUT.PUT_LINE('Debug: Found ' || v_count || ' products in category');
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: Product count failed: ' || SQLERRM);
         RETURN;
   END;
   
   -- Test 3: Get first product
   DBMS_OUTPUT.PUT_LINE('Debug: Test 3 - Getting first product');
   BEGIN
      SELECT p.pk, p.p_code INTO v_product_pk, v_product_code
      FROM products p
      JOIN cat2prodrel c2p ON c2p.targetpk = p.pk
      WHERE c2p.sourcepk = v_category_pk
      AND ROWNUM = 1;
      DBMS_OUTPUT.PUT_LINE('Debug: First product - Code: ' || v_product_code || ', PK: ' || v_product_pk);
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: No products found in category');
         RETURN;
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: Product lookup failed: ' || SQLERRM);
         RETURN;
   END;
   
   -- Test 4: Simple product query
   DBMS_OUTPUT.PUT_LINE('Debug: Test 4 - Simple product query');
   BEGIN
      FOR rec IN (
         SELECT p_code, p_title, p_mrp, p_productstatus
         FROM products 
         WHERE p_code = v_product_code
      ) LOOP
         DBMS_OUTPUT.PUT_LINE('Product: ' || rec.p_code || ' - ' || rec.p_title || ' - MRP: ' || rec.p_mrp);
      END LOOP;
      DBMS_OUTPUT.PUT_LINE('Debug: Simple product query completed');
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: Simple product query failed: ' || SQLERRM);
   END;
   
   -- Test 5: Check for duplicate P_CODE values
   DBMS_OUTPUT.PUT_LINE('Debug: Test 5 - Checking for duplicate P_CODE values');
   BEGIN
      SELECT COUNT(*) INTO v_count
      FROM products 
      WHERE p_code = v_product_code;
      DBMS_OUTPUT.PUT_LINE('Debug: Found ' || v_count || ' products with code ' || v_product_code);
      
      IF v_count > 1 THEN
         DBMS_OUTPUT.PUT_LINE('WARNING: Multiple products with same P_CODE found!');
         FOR rec IN (
            SELECT pk, p_code, p_title
            FROM products 
            WHERE p_code = v_product_code
         ) LOOP
            DBMS_OUTPUT.PUT_LINE('  PK: ' || rec.pk || ', Code: ' || rec.p_code || ', Title: ' || rec.p_title);
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: Duplicate check failed: ' || SQLERRM);
   END;
   
   DBMS_OUTPUT.PUT_LINE('=== SIMPLE PRODUCT TEST COMPLETED ===');
   
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('=== SIMPLE PRODUCT TEST FAILED ===');
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
      DBMS_OUTPUT.PUT_LINE('Error code: ' || SQLCODE);
END;
/ 