DECLARE
   -- UTL_FILE parameters
   L_INPUT_DIRECTORY CONSTANT VARCHAR2(30) := 'DATA_PUMP_DIR'; -- Directory object for input file
   L_INPUT_FILE     CONSTANT VARCHAR2(100) := 'category_codes.txt'; -- Input file with product codes (one per line)
   L_DIRECTORY_ALIAS CONSTANT VARCHAR2(30) := 'DATA_PUMP_DIR'; -- Output directory object
   L_FILE_NAME       CONSTANT VARCHAR2(100) := 'product_details_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.txt';
   L_FILE_HANDLE     UTL_FILE.FILE_TYPE;
   L_INPUT_HANDLE    UTL_FILE.FILE_TYPE;

   -- Variables for scalable processing
   v_category_code   VARCHAR2(50);
   v_category_pk     NUMBER;
   v_product_code    VARCHAR2(50);
   v_product_pk      NUMBER;

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
            (SELECT MAX(P_CODE) FROM PRODUCTS WHERE PK = COALESCE(p.P_BASEPRODUCT, p.PK)) AS BASE_PRODUCT_CODE,
            (SELECT MAX(P_TITLE) FROM PRODUCTS WHERE PK = COALESCE(p.P_BASEPRODUCT, p.PK)) AS BASE_PRODUCT_TITLE,
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
   -- Open the output file for writing
   L_FILE_HANDLE := UTL_FILE.FOPEN(L_DIRECTORY_ALIAS, L_FILE_NAME, 'W');
   -- Open the input file for reading
   L_INPUT_HANDLE := UTL_FILE.FOPEN(L_INPUT_DIRECTORY, L_INPUT_FILE, 'R');
   LOOP
      BEGIN
         UTL_FILE.GET_LINE(L_INPUT_HANDLE, v_category_code);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            EXIT;
      END;
      -- Get the category PK
      BEGIN
         SELECT pk INTO v_category_pk FROM categories WHERE p_code = v_category_code;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            UTL_FILE.PUT_LINE(L_FILE_HANDLE, '===== ERROR: Category code ' || v_category_code || ' not found. Skipping. =====');
            UTL_FILE.NEW_LINE(L_FILE_HANDLE);
            CONTINUE;
      END;

      -- For each product mapped to the category, process as before
      FOR prod_rec IN (
         SELECT p.pk, p.p_code
         FROM products p
         JOIN cat2prodrel c2p ON c2p.targetpk = p.pk
         WHERE c2p.sourcepk = v_category_pk
         AND ROWNUM <= 2
      ) LOOP
         v_product_code := prod_rec.p_code;
         v_product_pk := prod_rec.pk;

         UTL_FILE.PUT_LINE(L_FILE_HANDLE, '===== PROCESSING PRODUCT: ' || v_product_code || ' (PK: ' || v_product_pk || ') IN CATEGORY: ' || v_category_code || ' =====');
         UTL_FILE.NEW_LINE(L_FILE_HANDLE);

         -- Script 1: Base Variant Relationship Analysis
         UTL_FILE.put_line(L_FILE_HANDLE, '===== BASE VARIANT RELATIONSHIP ANALYSIS =====');
         UTL_FILE.put_line(L_FILE_HANDLE,
            'RN | PRODUCT_ID | PRODUCT_CODE | TITLE | PRODUCT_TYPE | BASE_PRODUCT_CODE | VARIANTS | SIZE | COLOR | MRP | STATUS | THUMBNAIL_COUNT | PRODUCT_URL');
         FOR rec IN c_product(v_product_code) LOOP
            UTL_FILE.put_line(L_FILE_HANDLE,
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
         UTL_FILE.put_line(L_FILE_HANDLE, '===========================================');
         UTL_FILE.new_line(L_FILE_HANDLE);

         -- Script 2: Category to Product Relationship
         UTL_FILE.put_line(L_FILE_HANDLE, '===== CATEGORY TO PRODUCT RELATIONSHIP =====');
         UTL_FILE.PUT_LINE(L_FILE_HANDLE, 'CATEGORY_CODE | MPCODE | PRODUCT_PK | CATEGORY_PK');
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
           UTL_FILE.PUT_LINE(L_FILE_HANDLE,
             rec.category_code || ' | ' ||
             rec.mpcode || ' | ' ||
             rec.product_pk || ' | ' ||
             rec.category_pk
           );
         END LOOP;
         UTL_FILE.put_line(L_FILE_HANDLE, '===========================================');
         UTL_FILE.new_line(L_FILE_HANDLE);

         -- Script 3: Gallery Images Analysis
         UTL_FILE.put_line(L_FILE_HANDLE, '===== GALLERY IMAGES ANALYSIS =====');
         UTL_FILE.put_line(L_FILE_HANDLE,
            'P_CODE | QUALIFIER | MIME | MEDIATYPE | DESCRIPTION | PRIORITY | INTERNAL_URL | ALT_TEXT | REMOVABLE');
         FOR rec IN c_gallery_media(v_product_code) LOOP
            UTL_FILE.put_line(L_FILE_HANDLE,
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
         UTL_FILE.put_line(L_FILE_HANDLE, '===========================================');
         UTL_FILE.new_line(L_FILE_HANDLE);

         -- Script 4: Product Features Analysis
         UTL_FILE.put_line(L_FILE_HANDLE, '===== PRODUCT FEATURES ANALYSIS =====');
         UTL_FILE.PUT_LINE(L_FILE_HANDLE,
           'P_PRODUCT | PRODUCT_CODE | FEATURE | FEATURE_VALUE');
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
           UTL_FILE.PUT_LINE(L_FILE_HANDLE,
               rec.P_PRODUCT     || ' | ' ||
               rec.product_code  || ' | ' ||
               rec.feature       || ' | ' ||
               rec.feature_value );
         END LOOP;
         UTL_FILE.put_line(L_FILE_HANDLE, '===========================================');
         UTL_FILE.new_line(L_FILE_HANDLE);

         -- Script 5: Product Seller Brand Analysis
         UTL_FILE.put_line(L_FILE_HANDLE, '===== PRODUCT SELLER BRAND ANALYSIS =====');
         UTL_FILE.put_line(L_FILE_HANDLE,
             'P_CODE | P_TITLE | P_ARTICLEDESCRIPTION | P_ARTICLEMINIDESCRIPTION | P_MRP | P_BRANDCOLOR | P_SIZE | P_NETQUANTITY | P_WEIGHT | P_LENGTH | P_WIDTH | P_HEIGHT | ' ||
             'P_SELLERNAME | P_SELLERID | P_SELLERSKU | P_SELLERARTICLESKU | P_READYTOSHIP | P_WARRANTYTYPE | P_WARRANTYPERIOD | P_HOMEDELIVERY | P_EXPRESSDELIVERY | ' ||
             'P_CLICKANDCOLLECT | P_EMI | P_ISFRAGILE | P_ISPRECIOUS | P_GIFTWRAPPABLE | P_BRANDCODE | BRAND_NAME | BRAND_DESCRIPTION | P_PRODUCTSTATUS | ' ||
             'P_SEARCHABLE | P_ONLINEDATE | P_OFFLINEDATE | P_L1CATEGORYCODE | P_L2CATEGORYCODE | P_L3CATEGORYCODE | P_L4CATEGORYCODE'
         );
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
           UTL_FILE.PUT_LINE(L_FILE_HANDLE,
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
         UTL_FILE.put_line(L_FILE_HANDLE, '===========================================');
         UTL_FILE.new_line(L_FILE_HANDLE);

         -- Script 6: Thumbnail Images Analysis
         UTL_FILE.put_line(L_FILE_HANDLE, '===== THUMBNAIL IMAGES ANALYSIS =====');
         UTL_FILE.put_line(L_FILE_HANDLE,
            'P_CODE | QUALIFIER | MIME | MEDIATYPE | DESCRIPTION | PRIORITY | INTERNAL_URL | ALT_TEXT | REMOVABLE');
         FOR rec IN c_thumbnail_media(v_product_code) LOOP
            UTL_FILE.put_line(L_FILE_HANDLE,
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
         UTL_FILE.put_line(L_FILE_HANDLE, '===========================================');
         UTL_FILE.new_line(L_FILE_HANDLE);

         -- Script 7: Product Classification Attributes Analysis
         UTL_FILE.put_line(L_FILE_HANDLE, '===== PRODUCT CLASSIFICATION ATTRIBUTES ANALYSIS =====');
         UTL_FILE.put_line(L_FILE_HANDLE, 'PRODUCT | UNIT | CLASSIFICATIONATTRIBUTE | NAME | CATEGORY | VALUE | DATATYPE');
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
           UTL_FILE.PUT_LINE(L_FILE_HANDLE,
               rec.product || ' | ' ||
               rec.unit || ' | ' ||
               rec.classificationattribute || ' | ' ||
               rec.name || ' | ' ||
               rec.category || ' | ' ||
               rec.value || ' | ' ||
               rec.datatype
           );
         END LOOP;
         UTL_FILE.put_line(L_FILE_HANDLE, '===========================================');
         UTL_FILE.new_line(L_FILE_HANDLE);

      END LOOP;
   END LOOP;

   UTL_FILE.FCLOSE(L_INPUT_HANDLE);

   -- Close the file if everything completed successfully
   IF UTL_FILE.IS_OPEN(L_FILE_HANDLE) THEN
      UTL_FILE.FCLOSE(L_FILE_HANDLE);
   END IF;
   DBMS_OUTPUT.PUT_LINE('Script execution complete. Output written to file: ' || L_DIRECTORY_ALIAS || '/' || L_FILE_NAME);

EXCEPTION
   WHEN UTL_FILE.INVALID_PATH THEN
      DBMS_OUTPUT.PUT_LINE('Error: Invalid UTL_FILE path. Ensure directory object ' || L_DIRECTORY_ALIAS || ' is created and points to a valid server path.');
   WHEN UTL_FILE.READ_ERROR THEN
      DBMS_OUTPUT.PUT_LINE('Error: Read error.');
      IF UTL_FILE.IS_OPEN(L_FILE_HANDLE) THEN UTL_FILE.FCLOSE(L_FILE_HANDLE); END IF;
   WHEN UTL_FILE.WRITE_ERROR THEN
      DBMS_OUTPUT.PUT_LINE('Error: Write error.');
      IF UTL_FILE.IS_OPEN(L_FILE_HANDLE) THEN UTL_FILE.FCLOSE(L_FILE_HANDLE); END IF;
   WHEN UTL_FILE.INVALID_OPERATION THEN
      DBMS_OUTPUT.PUT_LINE('Error: Invalid file operation (e.g., trying to read from a write-only file).');
      IF UTL_FILE.IS_OPEN(L_FILE_HANDLE) THEN UTL_FILE.FCLOSE(L_FILE_HANDLE); END IF;
   WHEN UTL_FILE.INTERNAL_ERROR THEN
      DBMS_OUTPUT.PUT_LINE('Error: Internal UTL_FILE error.');
      IF UTL_FILE.IS_OPEN(L_FILE_HANDLE) THEN UTL_FILE.FCLOSE(L_FILE_HANDLE); END IF;
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
      IF UTL_FILE.IS_OPEN(L_FILE_HANDLE) THEN
         UTL_FILE.FCLOSE(L_FILE_HANDLE);
      END IF;
END;
/ 