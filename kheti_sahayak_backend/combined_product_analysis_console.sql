DECLARE
   -- Variables for processing
   v_category_code   VARCHAR2(50) := 'MP0001'; -- Hardcoded category code for testing
   v_category_pk     NUMBER;
   v_product_code    VARCHAR2(50);
   v_product_pk      NUMBER;
   v_start_time      TIMESTAMP;
   v_end_time        TIMESTAMP;
   v_product_count   NUMBER := 0;
   v_processed_count NUMBER := 0;

   -- Script 1: Base Variant Relationship Analysis
   CURSOR c_product(p_code_in VARCHAR2) IS
      WITH product_hierarchy AS (
         SELECT
            p.PK,
            p.P_CODE,
            p.P_TITLE,
            p.P_BASEPRODUCT,
            p.P_SIZE,
            p.P_COLOUR,
            p.P_GENDER,
            p.P_MRP,
            p.P_PRODUCTSTATUS,
            p.P_THUMBNAILS,
            CASE
               WHEN p.P_BASEPRODUCT IS NULL AND EXISTS (
                  SELECT 1 FROM PRODUCTS WHERE P_BASEPRODUCT = p.PK
               ) THEN 'BASE PRODUCT'
               WHEN p.P_BASEPRODUCT IS NULL THEN 'SIMPLE PRODUCT'
               ELSE 'VARIANT'
            END AS PRODUCT_TYPE,
            (SELECT MAX(P_CODE) FROM PRODUCTS WHERE PK = COALESCE(p.P_BASEPRODUCT, p.PK) AND ROWNUM = 1) AS BASE_PRODUCT_CODE,
            (SELECT MAX(P_TITLE) FROM PRODUCTS WHERE PK = COALESCE(p.P_BASEPRODUCT, p.PK) AND ROWNUM = 1) AS BASE_PRODUCT_TITLE,
            (SELECT COUNT(*) FROM PRODUCTS WHERE P_BASEPRODUCT = COALESCE(p.P_BASEPRODUCT, p.PK)) AS VARIANT_COUNT,
            ROW_NUMBER() OVER (ORDER BY
               CASE
                  WHEN p.P_BASEPRODUCT IS NULL AND EXISTS (
                     SELECT 1 FROM PRODUCTS WHERE P_BASEPRODUCT = p.PK
                  ) THEN 0
                  WHEN p.P_BASEPRODUCT IS NULL THEN 1
                  ELSE 2
               END, p.P_CODE) AS RN
         FROM PRODUCTS p
         WHERE COALESCE(p.P_BASEPRODUCT, p.PK) = (
            SELECT COALESCE(P_BASEPRODUCT, PK)
            FROM PRODUCTS
            WHERE P_CODE = p_code_in
            AND ROWNUM = 1
         )
      )
      SELECT
         ph.RN AS RN,
         ph.PK,
         ph.P_CODE,
         ph.P_TITLE,
         ph.PRODUCT_TYPE,
         ph.BASE_PRODUCT_CODE,
         ph.VARIANT_COUNT,
         ph.P_SIZE,
         ph.P_COLOUR,
         ph.P_MRP,
         CASE
            WHEN ph.P_PRODUCTSTATUS = 1 THEN 'ACTIVE'
            ELSE 'INACTIVE'
         END AS STATUS,
         (
            SELECT COUNT(*)
            FROM (
               SELECT TRIM(REGEXP_SUBSTR(ph.P_THUMBNAILS, '[^,]+', 1, LEVEL)) AS media_id
               FROM DUAL
               CONNECT BY LEVEL <= REGEXP_COUNT(ph.P_THUMBNAILS, '[^,]+')
            )
         ) AS THUMBNAIL_COUNT,
         'https://www.tatacliq.com/p?q=' || ph.P_CODE AS PRODUCT_URL
      FROM product_hierarchy ph
      ORDER BY ph.RN;

   -- Script 3: Gallery Images Analysis
   CURSOR c_gallery_media(p_code_in VARCHAR2) IS
      WITH product_data AS (
         SELECT  pk,
                 p_code,
                 p_title,
                 SUBSTR(p_galleryimages,
                        INSTR(p_galleryimages || ',#1,', ',#1,') + 4) AS gallery_container_pks
         FROM   products
         WHERE  p_code = p_code_in
           AND  p_galleryimages IS NOT NULL
      ),
      media_container_ids AS (
         SELECT  pd.p_code,
                 TRIM(REGEXP_SUBSTR(pd.gallery_container_pks,
                                    '[^,]+', 1, LEVEL)) AS container_pk
         FROM   product_data pd
         CONNECT BY LEVEL <= REGEXP_COUNT(pd.gallery_container_pks, '[^,]+')
                AND PRIOR pd.pk = pd.pk
                AND PRIOR DBMS_RANDOM.VALUE IS NOT NULL
      )
      SELECT  m.p_code         AS p_code,
              m.p_qualifier    AS qualifier,
              m.p_mime         AS mime,
              m.p_mediatype    AS mediatype,
              m.p_description  AS descr,
              m.p_mediapriority AS priority,
              m.p_internalurl  AS internal_url,
              m.p_alttext      AS alt_text,
              m.p_removable    AS removable
      FROM    media_container_ids  mc
      JOIN    medias             m  ON m.p_mediacontainer = mc.container_pk;

   -- Script 6: Thumbnail Images Analysis
   CURSOR c_thumbnail_media(p_code_in VARCHAR2) IS
      WITH product_data AS (
         SELECT  pk,
                 p_code,
                 p_title,
                 SUBSTR(p_thumbnails,
                        INSTR(p_thumbnails || ',#1,', ',#1,') + 4) AS gallery_data
         FROM   products
         WHERE  p_code = p_code_in
           AND  p_thumbnails IS NOT NULL
      ),
      media_ids AS (
         SELECT  pd.pk,
                 pd.p_code,
                 pd.p_title,
                 TRIM(REGEXP_SUBSTR(pd.gallery_data,
                                    '[^,]+',
                                    1, LEVEL)) AS media_id
         FROM   product_data pd
         CONNECT BY LEVEL <= REGEXP_COUNT(pd.gallery_data, '[^,]+')
                AND PRIOR pd.pk = pd.pk
                AND PRIOR DBMS_RANDOM.VALUE IS NOT NULL
         START WITH pd.pk IS NOT NULL
      )
      SELECT  m.p_code             AS p_code,
              m.p_qualifier        AS qualifier,
              m.p_mime             AS mime,
              m.p_mediatype        AS mediatype,
              m.p_description      AS descr,
              m.p_mediapriority    AS priority,
              m.p_internalurl      AS internal_url,
              m.p_alttext          AS alt_text,
              m.p_removable        AS removable
      FROM    media_ids  mi
      JOIN    medias     m  ON m.pk = mi.media_id;

BEGIN
   -- Enable DBMS_OUTPUT with large buffer
   DBMS_OUTPUT.ENABLE(1000000);
   
   v_start_time := SYSTIMESTAMP;
   DBMS_OUTPUT.PUT_LINE('=== PRODUCT ANALYSIS SCRIPT STARTED ===');
   DBMS_OUTPUT.PUT_LINE('Start time: ' || TO_CHAR(v_start_time, 'YYYY-MM-DD HH24:MI:SS.FF'));
   DBMS_OUTPUT.PUT_LINE('Debug: Script execution started');
   DBMS_OUTPUT.PUT_LINE('Debug: Category code to process: ' || v_category_code);
   DBMS_OUTPUT.PUT_LINE('===========================================');

   -- Get the category PK
   DBMS_OUTPUT.PUT_LINE('Debug: Attempting to find category PK for code: ' || v_category_code);
   BEGIN
      SELECT pk INTO v_category_pk FROM categories WHERE p_code = v_category_code;
      DBMS_OUTPUT.PUT_LINE('Debug: Found category PK: ' || v_category_pk);
      DBMS_OUTPUT.PUT_LINE('Found category PK: ' || v_category_pk);
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: Category code ' || v_category_code || ' not found. Exiting.');
         DBMS_OUTPUT.PUT_LINE('Debug: Category lookup failed - no data found');
         RETURN;
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: Failed to lookup category: ' || SQLERRM);
         DBMS_OUTPUT.PUT_LINE('Debug: Category lookup failed with error: ' || SQLERRM);
         DBMS_OUTPUT.PUT_LINE('Debug: Error code: ' || SQLCODE);
         RETURN;
   END;

   -- Count total products for this category
   DBMS_OUTPUT.PUT_LINE('Debug: Counting products for category PK: ' || v_category_pk);
   BEGIN
      SELECT COUNT(*) INTO v_product_count 
      FROM products p
      JOIN cat2prodrel c2p ON c2p.targetpk = p.pk
      WHERE c2p.sourcepk = v_category_pk;
      DBMS_OUTPUT.PUT_LINE('Debug: Found ' || v_product_count || ' products for this category');
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Debug: Failed to count products: ' || SQLERRM);
         v_product_count := 0;
   END;

   -- For each product mapped to the category, process as before
   DBMS_OUTPUT.PUT_LINE('Debug: Starting product processing loop');
   FOR prod_rec IN (
      SELECT p.pk, p.p_code
      FROM products p
      JOIN cat2prodrel c2p ON c2p.targetpk = p.pk
      WHERE c2p.sourcepk = v_category_pk
      AND ROWNUM <= 2
   ) LOOP
      v_product_code := prod_rec.p_code;
      v_product_pk := prod_rec.pk;
      v_processed_count := v_processed_count + 1;

      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('Debug: Processing product ' || v_processed_count || ' of up to 2');
      DBMS_OUTPUT.PUT_LINE('Debug: Product code: ' || v_product_code || ', Product PK: ' || v_product_pk);
      DBMS_OUTPUT.PUT_LINE('===== PROCESSING PRODUCT: ' || v_product_code || ' (PK: ' || v_product_pk || ') IN CATEGORY: ' || v_category_code || ' =====');
      DBMS_OUTPUT.PUT_LINE('');

      -- Script 1: Base Variant Relationship Analysis
      DBMS_OUTPUT.PUT_LINE('Debug: Starting Script 1 - Base Variant Relationship Analysis');
      DBMS_OUTPUT.PUT_LINE('===== BASE VARIANT RELATIONSHIP ANALYSIS =====');
      DBMS_OUTPUT.PUT_LINE('RN | PRODUCT_ID | PRODUCT_CODE | TITLE | PRODUCT_TYPE | BASE_PRODUCT_CODE | VARIANTS | SIZE | COLOR | MRP | STATUS | THUMBNAIL_COUNT | PRODUCT_URL');
      BEGIN
         FOR rec IN c_product(v_product_code) LOOP
            DBMS_OUTPUT.PUT_LINE(
               rec.RN || ' | ' ||
               rec.PK || ' | ' ||
               rec.P_CODE || ' | ' ||
               rec.P_TITLE || ' | ' ||
               rec.PRODUCT_TYPE || ' | ' ||
               rec.BASE_PRODUCT_CODE || ' | ' ||
               rec.VARIANT_COUNT || ' | ' ||
               rec.P_SIZE || ' | ' ||
               rec.P_COLOUR || ' | ' ||
               rec.P_MRP || ' | ' ||
               rec.STATUS || ' | ' ||
               rec.THUMBNAIL_COUNT || ' | ' ||
               rec.PRODUCT_URL);
         END LOOP;
         DBMS_OUTPUT.PUT_LINE('Debug: Script 1 completed successfully');
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Debug: Script 1 failed: ' || SQLERRM);
      END;
      DBMS_OUTPUT.PUT_LINE('===========================================');
      DBMS_OUTPUT.PUT_LINE('');

      -- Script 2: Category to Product Relationship
      DBMS_OUTPUT.PUT_LINE('Debug: Starting Script 2 - Category to Product Relationship');
      DBMS_OUTPUT.PUT_LINE('===== CATEGORY TO PRODUCT RELATIONSHIP =====');
      DBMS_OUTPUT.PUT_LINE('CATEGORY_CODE | MPCODE | PRODUCT_PK | CATEGORY_PK');
      BEGIN
         FOR rec IN (
           SELECT
               cc.P_CODE AS category_code,
               prd.P_CODE AS mpcode,
               prd.PK AS product_pk,
               cprel.SOURCEPK AS category_pk
           FROM
               cat2prodrel cprel,
               products prd,
               categories cc
           WHERE
               cprel.TARGETPK = v_product_pk
               AND cprel.TARGETPK = prd.PK
               AND cc.PK = cprel.SOURCEPK
               AND cc.P_CODE LIKE 'MP%'
         ) LOOP
           DBMS_OUTPUT.PUT_LINE(
             rec.category_code || ' | ' ||
             rec.mpcode || ' | ' ||
             rec.product_pk || ' | ' ||
             rec.category_pk
           );
         END LOOP;
         DBMS_OUTPUT.PUT_LINE('Debug: Script 2 completed successfully');
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Debug: Script 2 failed: ' || SQLERRM);
      END;
      DBMS_OUTPUT.PUT_LINE('===========================================');
      DBMS_OUTPUT.PUT_LINE('');

      -- Script 3: Gallery Images Analysis
      DBMS_OUTPUT.PUT_LINE('Debug: Starting Script 3 - Gallery Images Analysis');
      DBMS_OUTPUT.PUT_LINE('===== GALLERY IMAGES ANALYSIS =====');
      DBMS_OUTPUT.PUT_LINE('P_CODE | QUALIFIER | MIME | MEDIATYPE | DESCRIPTION | PRIORITY | INTERNAL_URL | ALT_TEXT | REMOVABLE');
      BEGIN
         FOR rec IN c_gallery_media(v_product_code) LOOP
            DBMS_OUTPUT.PUT_LINE(
               rec.p_code       || ' | ' ||
               rec.qualifier    || ' | ' ||
               rec.mime         || ' | ' ||
               rec.mediatype    || ' | ' ||
               rec.descr        || ' | ' ||
               rec.priority     || ' | ' ||
               rec.internal_url || ' | ' ||
               rec.alt_text     || ' | ' ||
               rec.removable);
         END LOOP;
         DBMS_OUTPUT.PUT_LINE('Debug: Script 3 completed successfully');
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Debug: Script 3 failed: ' || SQLERRM);
      END;
      DBMS_OUTPUT.PUT_LINE('===========================================');
      DBMS_OUTPUT.PUT_LINE('');

      -- Script 4: Product Features Analysis
      DBMS_OUTPUT.PUT_LINE('Debug: Starting Script 4 - Product Features Analysis');
      DBMS_OUTPUT.PUT_LINE('===== PRODUCT FEATURES ANALYSIS =====');
      DBMS_OUTPUT.PUT_LINE('P_PRODUCT | PRODUCT_CODE | FEATURE | FEATURE_VALUE');
      BEGIN
         FOR rec IN (
           SELECT
               pf.P_PRODUCT,
               pd.p_code                   AS product_code,
               cc.P_CODE                   AS feature,
               CAST(
                   CASE
                      WHEN enums.code = 'enum' THEN
                         ( SELECT cval.P_CODE
                             FROM classattrvalues cval
                            WHERE cval.pk = TO_NUMBER(
                                    REGEXP_REPLACE(DBMS_LOB.SUBSTR(pf.P_STRINGVALUE,100)
                                                   ,'[^0-9]',''))
                           AND ROWNUM = 1 )
                      ELSE DBMS_LOB.SUBSTR(pf.P_STRINGVALUE,4000,1)
                   END AS VARCHAR2(4000)
               )                           AS feature_value
           FROM   productfeatures     pf
           JOIN   products            pd   ON pd.pk = pf.P_PRODUCT
           JOIN   cat2attrrel         crel ON crel.pk = pf.P_CLASSIFICATIONATTRIBUTEASSIG
           JOIN   classificationattrs cc   ON cc.pk  = crel.P_CLASSIFICATIONATTRIBUTE
           JOIN   enumerationvalues3  enums ON enums.pk = crel.P_ATTRIBUTETYPE
           WHERE  pd.p_code = v_product_code
         ) LOOP
           DBMS_OUTPUT.PUT_LINE(
               rec.P_PRODUCT     || ' | ' ||
               rec.product_code  || ' | ' ||
               rec.feature       || ' | ' ||
               rec.feature_value );
         END LOOP;
         DBMS_OUTPUT.PUT_LINE('Debug: Script 4 completed successfully');
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Debug: Script 4 failed: ' || SQLERRM);
      END;
      DBMS_OUTPUT.PUT_LINE('===========================================');
      DBMS_OUTPUT.PUT_LINE('');

      -- Script 5: Product Seller Brand Analysis
      DBMS_OUTPUT.PUT_LINE('Debug: Starting Script 5 - Product Seller Brand Analysis');
      DBMS_OUTPUT.PUT_LINE('===== PRODUCT SELLER BRAND ANALYSIS =====');
      DBMS_OUTPUT.PUT_LINE('P_CODE | P_TITLE | P_ARTICLEDESCRIPTION | P_ARTICLEMINIDESCRIPTION | P_MRP | P_BRANDCOLOR | P_SIZE | P_NETQUANTITY | P_WEIGHT | P_LENGTH | P_WIDTH | P_HEIGHT | ' ||
          'P_SELLERNAME | P_SELLERID | P_SELLERSKU | P_SELLERARTICLESKU | P_READYTOSHIP | P_WARRANTYTYPE | P_WARRANTYPERIOD | P_HOMEDELIVERY | P_EXPRESSDELIVERY | ' ||
          'P_CLICKANDCOLLECT | P_EMI | P_ISFRAGILE | P_ISPRECIOUS | P_GIFTWRAPPABLE | P_BRANDCODE | BRAND_NAME | BRAND_DESCRIPTION | P_PRODUCTSTATUS | ' ||
          'P_SEARCHABLE | P_ONLINEDATE | P_OFFLINEDATE | P_L1CATEGORYCODE | P_L2CATEGORYCODE | P_L3CATEGORYCODE | P_L4CATEGORYCODE'
      );
      BEGIN
         FOR rec IN (
           SELECT
             p.p_code,
             p.p_title,
             p.p_articledescription,
             p.p_articleminidescription,
             p.p_mrp,
             p.p_brandcolor,
             p.p_size,
             p.p_netquantity,
             p.p_weight,
             p.p_length,
             p.p_width,
             p.p_height,
             s.p_sellername,
             s.p_sellerid,
             s.p_sellersku,
             s.p_sellerarticlesku,
             s.p_readytoship,
             r.p_warrantytype,
             r.p_warrantypERIOD,
             r.p_homedelivery,
             r.p_expressdelivery,
             r.p_clickandcollect,
             r.p_emi,
             r.p_isfragile,
             r.p_isprecious,
             r.p_giftwrappable,
             b.p_brandcode,
             b.p_name AS brand_name,
             b.p_description AS brand_description,
             p.p_productstatus,
             p.p_searchable,
             TO_CHAR(p.p_onlinedate, 'YYYY-MM-DD HH24:MI:SS') AS p_onlinedate,
             TO_CHAR(p.p_offlinedate, 'YYYY-MM-DD HH24:MI:SS') AS p_offlinedate,
             p.p_l1categorycode,
             p.p_l2categorycode,
             p.p_l3categorycode,
             p.p_l4categorycode
           FROM products p
           JOIN mplbrand b ON b.p_productsource = p.pk
           JOIN mplsellerinfo s ON s.p_productsource = p.pk
           LEFT JOIN mplrichattribute r ON r.p_sellerinfo = s.pk
           WHERE p.p_code = v_product_code
         ) LOOP
           DBMS_OUTPUT.PUT_LINE(
             rec.p_code || ' | ' || rec.p_title || ' | ' || rec.p_articledescription || ' | ' || rec.p_articleminidescription || ' | ' ||
             rec.p_mrp || ' | ' || rec.p_brandcolor || ' | ' || rec.p_size || ' | ' || rec.p_netquantity || ' | ' || rec.p_weight || ' | ' ||
             rec.p_length || ' | ' || rec.p_width || ' | ' || rec.p_height || ' | ' || rec.p_sellername || ' | ' || rec.p_sellerid || ' | ' ||
             rec.p_sellersku || ' | ' || rec.p_sellerarticlesku || ' | ' || rec.p_readytoship || ' | ' || rec.p_warrantytype || ' | ' ||
             rec.p_warrantypERIOD || ' | ' || rec.p_homedelivery || ' | ' || rec.p_expressdelivery || ' | ' || rec.p_clickandcollect || ' | ' ||
             rec.p_emi || ' | ' || rec.p_isfragile || ' | ' || rec.p_isprecious || ' | ' || rec.p_giftwrappable || ' | ' || rec.p_brandcode || ' | ' ||
             rec.brand_name || ' | ' || rec.brand_description || ' | ' || rec.p_productstatus || ' | ' || rec.p_searchable || ' | ' ||
             rec.p_onlinedate || ' | ' || rec.p_offlinedate || ' | ' || rec.p_l1categorycode || ' | ' || rec.p_l2categorycode || ' | ' ||
             rec.p_l3categorycode || ' | ' || rec.p_l4categorycode
           );
         END LOOP;
         DBMS_OUTPUT.PUT_LINE('Debug: Script 5 completed successfully');
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Debug: Script 5 failed: ' || SQLERRM);
      END;
      DBMS_OUTPUT.PUT_LINE('===========================================');
      DBMS_OUTPUT.PUT_LINE('');

      -- Script 6: Thumbnail Images Analysis
      DBMS_OUTPUT.PUT_LINE('Debug: Starting Script 6 - Thumbnail Images Analysis');
      DBMS_OUTPUT.PUT_LINE('===== THUMBNAIL IMAGES ANALYSIS =====');
      DBMS_OUTPUT.PUT_LINE('P_CODE | QUALIFIER | MIME | MEDIATYPE | DESCRIPTION | PRIORITY | INTERNAL_URL | ALT_TEXT | REMOVABLE');
      BEGIN
         FOR rec IN c_thumbnail_media(v_product_code) LOOP
            DBMS_OUTPUT.PUT_LINE(
               rec.p_code        || ' | ' ||
               rec.qualifier     || ' | ' ||
               rec.mime          || ' | ' ||
               rec.mediatype     || ' | ' ||
               rec.descr         || ' | ' ||
               rec.priority      || ' | ' ||
               rec.internal_url  || ' | ' ||
               rec.alt_text      || ' | ' ||
               rec.removable);
         END LOOP;
         DBMS_OUTPUT.PUT_LINE('Debug: Script 6 completed successfully');
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Debug: Script 6 failed: ' || SQLERRM);
      END;
      DBMS_OUTPUT.PUT_LINE('===========================================');
      DBMS_OUTPUT.PUT_LINE('');

      -- Script 7: Product Classification Attributes Analysis
      DBMS_OUTPUT.PUT_LINE('Debug: Starting Script 7 - Product Classification Attributes Analysis');
      DBMS_OUTPUT.PUT_LINE('===== PRODUCT CLASSIFICATION ATTRIBUTES ANALYSIS =====');
      DBMS_OUTPUT.PUT_LINE('PRODUCT | UNIT | CLASSIFICATIONATTRIBUTE | NAME | CATEGORY | VALUE | DATATYPE');
      BEGIN
         FOR rec IN (
           SELECT
               p.p_code AS product,
               caa.p_unit AS unit,
               ca.p_code AS classificationattribute,
               caalp.p_name AS name,
               c.p_code AS category,
               CASE
                   WHEN enu.code = 'enum'
                       THEN (SELECT ep.p_code
                             FROM classattrvalues ep
                             WHERE ep.pk = TO_CHAR(pf.p_stringvalue)
                             AND ROWNUM = 1)
                   ELSE TO_CHAR(pf.p_stringvalue)
               END AS value,
               enu.code AS datatype
           FROM productfeatures pf
           JOIN products p
               ON p.pk = pf.p_product
           JOIN cat2attrrel caa
               ON caa.pk = pf.p_classificationattributeassig
           JOIN classificationattrs ca
               ON ca.pk = caa.p_classificationattribute
           JOIN categories c
               ON c.pk = caa.p_classificationclass
           JOIN enumerationvalues3 enu
               ON enu.pk = caa.p_attributetype
           JOIN CLASSIFICATIONATTRSLP caalp
               ON caalp.itempk = ca.pk
           WHERE p.p_code = v_product_code
         ) LOOP
           DBMS_OUTPUT.PUT_LINE(
               rec.product || ' | ' ||
               rec.unit || ' | ' ||
               rec.classificationattribute || ' | ' ||
               rec.name || ' | ' ||
               rec.category || ' | ' ||
               rec.value || ' | ' ||
               rec.datatype
           );
         END LOOP;
         DBMS_OUTPUT.PUT_LINE('Debug: Script 7 completed successfully');
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Debug: Script 7 failed: ' || SQLERRM);
      END;
      DBMS_OUTPUT.PUT_LINE('===========================================');
      DBMS_OUTPUT.PUT_LINE('');

      DBMS_OUTPUT.PUT_LINE('Debug: Completed processing for product: ' || v_product_code);
   END LOOP;

   v_end_time := SYSTIMESTAMP;
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('=== SCRIPT EXECUTION SUMMARY ===');
   DBMS_OUTPUT.PUT_LINE('End time: ' || TO_CHAR(v_end_time, 'YYYY-MM-DD HH24:MI:SS.FF'));
   DBMS_OUTPUT.PUT_LINE('Total execution time: ' || 
                       EXTRACT(SECOND FROM (v_end_time - v_start_time)) || ' seconds');
   DBMS_OUTPUT.PUT_LINE('Category processed: ' || v_category_code || ' (PK: ' || v_category_pk || ')');
   DBMS_OUTPUT.PUT_LINE('Total products in category: ' || v_product_count);
   DBMS_OUTPUT.PUT_LINE('Products processed: ' || v_processed_count);
   DBMS_OUTPUT.PUT_LINE('Script execution complete.');
   DBMS_OUTPUT.PUT_LINE('Debug: All processing completed successfully');

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('=== SCRIPT EXECUTION FAILED ===');
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
      DBMS_OUTPUT.PUT_LINE('Error code: ' || SQLCODE);
      DBMS_OUTPUT.PUT_LINE('Error backtrace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());
      DBMS_OUTPUT.PUT_LINE('Debug: Script failed with unexpected error');
      DBMS_OUTPUT.PUT_LINE('Debug: Last processed product: ' || v_product_code);
      DBMS_OUTPUT.PUT_LINE('Debug: Products processed before error: ' || v_processed_count);
END;
/ 