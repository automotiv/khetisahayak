-- Simple test script to verify database connection and basic functionality
DECLARE
   v_count NUMBER;
   v_category_count NUMBER;
   v_product_count NUMBER;
   v_start_time TIMESTAMP;
   v_end_time TIMESTAMP;
BEGIN
   -- Enable DBMS_OUTPUT with large buffer
   DBMS_OUTPUT.ENABLE(1000000);
   
   v_start_time := SYSTIMESTAMP;
   DBMS_OUTPUT.PUT_LINE('=== DATABASE CONNECTION TEST STARTED ===');
   DBMS_OUTPUT.PUT_LINE('Start time: ' || TO_CHAR(v_start_time, 'YYYY-MM-DD HH24:MI:SS.FF'));
   DBMS_OUTPUT.PUT_LINE('Debug: Script execution started');
   DBMS_OUTPUT.PUT_LINE('');
   
   -- Test 1: Check if we can query basic system information
   DBMS_OUTPUT.PUT_LINE('Debug: Starting Test 1 - Basic query test');
   SELECT COUNT(*) INTO v_count FROM DUAL;
   DBMS_OUTPUT.PUT_LINE('Test 1 - Basic query: SUCCESS (Count from DUAL: ' || v_count || ')');
   DBMS_OUTPUT.PUT_LINE('Debug: Test 1 completed successfully');
   DBMS_OUTPUT.PUT_LINE('');
   
   -- Test 2: Check if categories table exists and has data
   DBMS_OUTPUT.PUT_LINE('Debug: Starting Test 2 - Categories table test');
   BEGIN
      SELECT COUNT(*) INTO v_category_count FROM categories;
      DBMS_OUTPUT.PUT_LINE('Test 2 - Categories table: SUCCESS (Count: ' || v_category_count || ')');
      DBMS_OUTPUT.PUT_LINE('Debug: Categories table accessible, found ' || v_category_count || ' records');
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Test 2 - Categories table: FAILED - ' || SQLERRM);
         DBMS_OUTPUT.PUT_LINE('Debug: Error code: ' || SQLCODE);
         DBMS_OUTPUT.PUT_LINE('Debug: Error occurred at line: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());
   END;
   DBMS_OUTPUT.PUT_LINE('');
   
   -- Test 3: Check if products table exists and has data
   DBMS_OUTPUT.PUT_LINE('Debug: Starting Test 3 - Products table test');
   BEGIN
      SELECT COUNT(*) INTO v_product_count FROM products;
      DBMS_OUTPUT.PUT_LINE('Test 3 - Products table: SUCCESS (Count: ' || v_product_count || ')');
      DBMS_OUTPUT.PUT_LINE('Debug: Products table accessible, found ' || v_product_count || ' records');
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Test 3 - Products table: FAILED - ' || SQLERRM);
         DBMS_OUTPUT.PUT_LINE('Debug: Error code: ' || SQLCODE);
         DBMS_OUTPUT.PUT_LINE('Debug: Error occurred at line: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());
   END;
   DBMS_OUTPUT.PUT_LINE('');
   
   -- Test 4: Show some sample category codes
   DBMS_OUTPUT.PUT_LINE('Debug: Starting Test 4 - Sample category codes test');
   DBMS_OUTPUT.PUT_LINE('Test 4 - Sample category codes:');
   BEGIN
      FOR rec IN (
         SELECT p_code, p_name 
         FROM categories 
         WHERE p_code LIKE 'MP%' 
         AND ROWNUM <= 5
      ) LOOP
         DBMS_OUTPUT.PUT_LINE('  ' || rec.p_code || ' - ' || rec.p_name);
      END LOOP;
      DBMS_OUTPUT.PUT_LINE('Debug: Successfully retrieved sample category codes');
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Debug: Failed to retrieve category codes - ' || SQLERRM);
   END;
   DBMS_OUTPUT.PUT_LINE('');
   
   -- Test 5: Show some sample product codes
   DBMS_OUTPUT.PUT_LINE('Debug: Starting Test 5 - Sample product codes test');
   DBMS_OUTPUT.PUT_LINE('Test 5 - Sample product codes:');
   BEGIN
      FOR rec IN (
         SELECT p_code, p_title 
         FROM products 
         WHERE ROWNUM <= 5
      ) LOOP
         DBMS_OUTPUT.PUT_LINE('  ' || rec.p_code || ' - ' || rec.p_title);
      END LOOP;
      DBMS_OUTPUT.PUT_LINE('Debug: Successfully retrieved sample product codes');
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Debug: Failed to retrieve product codes - ' || SQLERRM);
   END;
   DBMS_OUTPUT.PUT_LINE('');
   
   -- Test 6: Check additional required tables
   DBMS_OUTPUT.PUT_LINE('Debug: Starting Test 6 - Additional table checks');
   DBMS_OUTPUT.PUT_LINE('Test 6 - Additional required tables:');
   
   -- Check cat2prodrel table
   BEGIN
      SELECT COUNT(*) INTO v_count FROM cat2prodrel;
      DBMS_OUTPUT.PUT_LINE('  cat2prodrel table: SUCCESS (Count: ' || v_count || ')');
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('  cat2prodrel table: FAILED - ' || SQLERRM);
   END;
   
   -- Check medias table
   BEGIN
      SELECT COUNT(*) INTO v_count FROM medias;
      DBMS_OUTPUT.PUT_LINE('  medias table: SUCCESS (Count: ' || v_count || ')');
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('  medias table: FAILED - ' || SQLERRM);
   END;
   
   -- Check productfeatures table
   BEGIN
      SELECT COUNT(*) INTO v_count FROM productfeatures;
      DBMS_OUTPUT.PUT_LINE('  productfeatures table: SUCCESS (Count: ' || v_count || ')');
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('  productfeatures table: FAILED - ' || SQLERRM);
   END;
   
   DBMS_OUTPUT.PUT_LINE('');
   
   v_end_time := SYSTIMESTAMP;
   DBMS_OUTPUT.PUT_LINE('=== CONNECTION TEST COMPLETE ===');
   DBMS_OUTPUT.PUT_LINE('End time: ' || TO_CHAR(v_end_time, 'YYYY-MM-DD HH24:MI:SS.FF'));
   DBMS_OUTPUT.PUT_LINE('Total execution time: ' || 
                       EXTRACT(SECOND FROM (v_end_time - v_start_time)) || ' seconds');
   DBMS_OUTPUT.PUT_LINE('Debug: All tests completed');
   
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('=== CONNECTION TEST FAILED ===');
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
      DBMS_OUTPUT.PUT_LINE('Error code: ' || SQLCODE);
      DBMS_OUTPUT.PUT_LINE('Error backtrace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());
      DBMS_OUTPUT.PUT_LINE('Debug: Script failed with unexpected error');
END;
/ 