-- Diagnostic script to check for duplicate category codes
DECLARE
   v_category_code VARCHAR2(50) := 'MPH1122109102';
   v_count NUMBER;
   v_total_duplicates NUMBER := 0;
BEGIN
   -- Enable DBMS_OUTPUT
   DBMS_OUTPUT.ENABLE(1000000);
   
   DBMS_OUTPUT.PUT_LINE('=== CATEGORY DUPLICATE DIAGNOSTIC ===');
   DBMS_OUTPUT.PUT_LINE('Checking for duplicate category codes...');
   DBMS_OUTPUT.PUT_LINE('');
   
   -- Check the specific category code from your file
   DBMS_OUTPUT.PUT_LINE('Checking category code: ' || v_category_code);
   SELECT COUNT(*) INTO v_count FROM categories WHERE p_code = v_category_code;
   DBMS_OUTPUT.PUT_LINE('Found ' || v_count || ' categories with code: ' || v_category_code);
   
   IF v_count > 1 THEN
      DBMS_OUTPUT.PUT_LINE('WARNING: Multiple categories found with same code!');
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('Details of all categories with code ' || v_category_code || ':');
      DBMS_OUTPUT.PUT_LINE('PK | P_CODE');
      FOR rec IN (
         SELECT pk, p_code
         FROM categories 
         WHERE p_code = v_category_code
         ORDER BY pk
      ) LOOP
         DBMS_OUTPUT.PUT_LINE(rec.pk || ' | ' || rec.p_code);
      END LOOP;
   ELSE
      DBMS_OUTPUT.PUT_LINE('No duplicates found for this category code.');
   END IF;
   
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('=== CHECKING FOR ALL DUPLICATE CATEGORY CODES ===');
   
   -- Find all duplicate category codes
   FOR rec IN (
      SELECT p_code, COUNT(*) as cnt
      FROM categories 
      WHERE p_code LIKE 'MP%'
      GROUP BY p_code
      HAVING COUNT(*) > 1
      ORDER BY cnt DESC, p_code
   ) LOOP
      v_total_duplicates := v_total_duplicates + 1;
      DBMS_OUTPUT.PUT_LINE('Duplicate found: ' || rec.p_code || ' appears ' || rec.cnt || ' times');
      
      -- Show details for first few duplicates
      IF v_total_duplicates <= 5 THEN
         DBMS_OUTPUT.PUT_LINE('  Details:');
         FOR detail_rec IN (
            SELECT pk, p_code
            FROM categories 
            WHERE p_code = rec.p_code
            ORDER BY pk
         ) LOOP
            DBMS_OUTPUT.PUT_LINE('    PK: ' || detail_rec.pk || ', Code: ' || detail_rec.p_code);
         END LOOP;
         DBMS_OUTPUT.PUT_LINE('');
      END IF;
   END LOOP;
   
   IF v_total_duplicates = 0 THEN
      DBMS_OUTPUT.PUT_LINE('No duplicate category codes found.');
   ELSE
      DBMS_OUTPUT.PUT_LINE('Total duplicate category codes found: ' || v_total_duplicates);
   END IF;
   
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('=== SAMPLE UNIQUE CATEGORY CODES ===');
   DBMS_OUTPUT.PUT_LINE('Here are some unique category codes you can use:');
   FOR rec IN (
      SELECT p_code
      FROM categories 
      WHERE p_code LIKE 'MP%'
      AND p_code NOT IN (
         SELECT p_code 
         FROM categories 
         WHERE p_code LIKE 'MP%'
         GROUP BY p_code
         HAVING COUNT(*) > 1
      )
      AND ROWNUM <= 10
      ORDER BY p_code
   ) LOOP
      DBMS_OUTPUT.PUT_LINE('  ' || rec.p_code);
   END LOOP;
   
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('=== RECOMMENDATIONS ===');
   IF v_total_duplicates > 0 THEN
      DBMS_OUTPUT.PUT_LINE('1. Your database has duplicate category codes. This is causing the ORA-01422 error.');
      DBMS_OUTPUT.PUT_LINE('2. The script has been fixed to use ROWNUM = 1 to handle duplicates.');
      DBMS_OUTPUT.PUT_LINE('3. Consider cleaning up duplicate categories in your database.');
      DBMS_OUTPUT.PUT_LINE('4. Use unique category codes from the sample list above.');
   ELSE
      DBMS_OUTPUT.PUT_LINE('No duplicate issues found. Your category codes are unique.');
   END IF;
   
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('=== DIAGNOSTIC COMPLETE ===');
   
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('=== DIAGNOSTIC FAILED ===');
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
      DBMS_OUTPUT.PUT_LINE('Error code: ' || SQLCODE);
END;