DECLARE
   -- UTL_FILE parameters
   L_INPUT_DIRECTORY CONSTANT VARCHAR2(30) := 'DATA_PUMP_DIR'; -- Directory object for input file
   L_INPUT_FILE     CONSTANT VARCHAR2(100) := 'category_codes.txt'; -- Input file with category codes (one per line)
   L_INPUT_HANDLE    UTL_FILE.FILE_TYPE;
   
   -- Variables for processing
   v_category_code   VARCHAR2(50);
   v_category_pk     NUMBER;
   v_product_code    VARCHAR2(50);
   v_product_pk      NUMBER;
   v_start_time      TIMESTAMP;
   v_end_time        TIMESTAMP;
   v_product_count   NUMBER := 0;
   v_processed_count NUMBER := 0;
   v_category_count  NUMBER := 0;
   v_total_products  NUMBER := 0;

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
   DBMS_OUTPUT.PUT_LINE('=== PRODUCT ANALYSIS SCRIPT WITH FILE INPUT STARTED ===');
   DBMS_OUTPUT.PUT_LINE('Start time: ' || TO_CHAR(v_start_time, 'YYYY-MM-DD HH24:MI:SS.FF'));
   DBMS_OUTPUT.PUT_LINE('===========================================');

   -- Open the input file for reading
   DBMS_OUTPUT.PUT_LINE('Attempting to open input file');
   BEGIN
      L_INPUT_HANDLE := UTL_FILE.FOPEN(L_INPUT_DIRECTORY, L_INPUT_FILE, 'R');
      DBMS_OUTPUT.PUT_LINE('Input file opened successfully');
   EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: Invalid UTL_FILE path. Ensure directory object ' || L_INPUT_DIRECTORY || ' is created and points to a valid server path.');
         DBMS_OUTPUT.PUT_LINE('File path error - check directory object');
         RETURN;
      WHEN UTL_FILE.INVALID_OPERATION THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: Invalid file operation. Check file permissions and existence.');
         DBMS_OUTPUT.PUT_LINE('File operation error - check file exists and is readable');
         RETURN;
      WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('ERROR: Failed to open input file: ' || SQLERRM);
         DBMS_OUTPUT.PUT_LINE('File open failed with error: ' || SQLERRM);
         RETURN;
   END;

   -- Process each category code from the file
   DBMS_OUTPUT.PUT_LINE('Starting to read category codes from file');
   LOOP
      BEGIN
         UTL_FILE.GET_LINE(L_INPUT_HANDLE, v_category_code);
         -- Trim whitespace and skip empty lines
         v_category_code := TRIM(v_category_code);
         IF v_category_code IS NULL OR LENGTH(v_category_code) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Skipping empty line');
            CONTINUE;
         END IF;
         
         v_category_count := v_category_count + 1;
         DBMS_OUTPUT.PUT_LINE('');
         DBMS_OUTPUT.PUT_LINE('Processing category ' || v_category_count || ': ' || v_category_code);
         
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Reached end of file');
            EXIT;
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Failed to read line from file: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('File read error: ' || SQLERRM);
            EXIT;
      END;

      -- For each category code in the input file, get the first PK with that code and use it for all processing
      DBMS_OUTPUT.PUT_LINE('Attempting to find first PK for category code: ' || v_category_code);
      BEGIN
         SELECT pk INTO v_category_pk FROM categories WHERE p_code = v_category_code AND ROWNUM = 1;
         DBMS_OUTPUT.PUT_LINE('Using PK ' || v_category_pk || ' for category code ' || v_category_code);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Category code ' || v_category_code || ' not found. Skipping.');
            DBMS_OUTPUT.PUT_LINE('Category lookup failed - no data found');
            CONTINUE;
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Failed to lookup category ' || v_category_code || ': ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Category lookup failed with error: ' || SQLERRM);
            CONTINUE;
      END;

      -- Count total products for this category
      DBMS_OUTPUT.PUT_LINE('Counting products for category PK: ' || v_category_pk);
      BEGIN
         SELECT COUNT(*) INTO v_product_count 
         FROM products p
         JOIN cat2prodrel c2p ON c2p.targetpk = p.pk
         WHERE c2p.sourcepk = v_category_pk;
         DBMS_OUTPUT.PUT_LINE('Found ' || v_product_count || ' products for this category');
         v_total_products := v_total_products + v_product_count;
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to count products: ' || SQLERRM);
            v_product_count := 0;
      END;

      -- For each product mapped to the category, process as before
      DBMS_OUTPUT.PUT_LINE('Starting product processing loop for category: ' || v_category_code);
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
         DBMS_OUTPUT.PUT_LINE('Processing product ' || v_processed_count || ' (Category: ' || v_category_code || ')');
         DBMS_OUTPUT.PUT_LINE('Product code: ' || v_product_code || ', Product PK: ' || v_product_pk);
         DBMS_OUTPUT.PUT_LINE('===== PROCESSING PRODUCT: ' || v_product_code || ' (PK: ' || v_product_pk || ') IN CATEGORY: ' || v_category_code || ' =====');
         DBMS_OUTPUT.PUT_LINE('');

         -- Script 1: Base Variant Relationship Analysis
         DBMS_OUTPUT.PUT_LINE('Starting Script 1 - Base Variant Relationship Analysis');
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
         EXCEPTION
            WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('Script 1 failed: ' || SQLERRM);
         END;
         DBMS_OUTPUT.PUT_LINE('===========================================');
         DBMS_OUTPUT.PUT_LINE('');

         -- Script 2: Category to Product Relationship
         DBMS_OUTPUT.PUT_LINE('Starting Script 2 - Category to Product Relationship');
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
         EXCEPTION
            WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('Script 2 failed: ' || SQLERRM);
         END;
         DBMS_OUTPUT.PUT_LINE('===========================================');
         DBMS_OUTPUT.PUT_LINE('');

         -- Script 3: Gallery Images Analysis
         DBMS_OUTPUT.PUT_LINE('Starting Script 3 - Gallery Images Analysis');
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
         EXCEPTION
            WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('Script 3 failed: ' || SQLERRM);
         END;
         DBMS_OUTPUT.PUT_LINE('===========================================');
         DBMS_OUTPUT.PUT_LINE('');

         -- Script 4: Product Features Analysis
         DBMS_OUTPUT.PUT_LINE('Starting Script 4 - Product Features Analysis');
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
         EXCEPTION
            WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('Script 4 failed: ' || SQLERRM);
         END;
         DBMS_OUTPUT.PUT_LINE('===========================================');
         DBMS_OUTPUT.PUT_LINE('');

         -- Script 5: Product Seller Brand Analysis
         DBMS_OUTPUT.PUT_LINE('Starting Script 5 - Product Seller Brand Analysis');
         DBMS_OUTPUT.PUT_LINE('===== PRODUCT SELLER BRAND ANALYSIS =====');
         DBMS_OUTPUT.PUT_LINE('P_CODE | P_TITLE | P_ARTICLEDESCRIPTION | P_ARTICLEMINIDESCRIPTION | P_MRP | P_BRANDCOLOR | P_SIZE | P_NETQUANTITY | P_WEIGHT | P_LENGTH | P_WIDTH | P_HEIGHT | ' ||
             'P_SELLERNAME | P_SELLERID | P_SELLERSKU | P_SELLERARTICLESKU | P_READYTOSHIP | P_BRANDCODE | BRAND_NAME | BRAND_DESCRIPTION | P_PRODUCTSTATUS | ' ||
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
              WHERE p.p_code = v_product_code
            ) LOOP
              DBMS_OUTPUT.PUT_LINE(
                rec.p_code || ' | ' || rec.p_title || ' | ' || rec.p_articledescription || ' | ' || rec.p_articleminidescription || ' | ' ||
                rec.p_mrp || ' | ' || rec.p_brandcolor || ' | ' || rec.p_size || ' | ' || rec.p_netquantity || ' | ' || rec.p_weight || ' | ' ||
                rec.p_length || ' | ' || rec.p_width || ' | ' || rec.p_height || ' | ' || rec.p_sellername || ' | ' || rec.p_sellerid || ' | ' ||
                rec.p_sellersku || ' | ' || rec.p_sellerarticlesku || ' | ' || rec.p_readytoship || ' | ' || rec.p_brandcode || ' | ' ||
                rec.brand_name || ' | ' || rec.brand_description || ' | ' || rec.p_productstatus || ' | ' || rec.p_searchable || ' | ' ||
                rec.p_onlinedate || ' | ' || rec.p_offlinedate || ' | ' || rec.p_l1categorycode || ' | ' || rec.p_l2categorycode || ' | ' ||
                rec.p_l3categorycode || ' | ' || rec.p_l4categorycode
              );
            END LOOP;
         EXCEPTION
            WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('Script 5 failed: ' || SQLERRM);
         END;
         DBMS_OUTPUT.PUT_LINE('===========================================');
         DBMS_OUTPUT.PUT_LINE('');

         -- Script 6: Rich Attribute Analysis
         DBMS_OUTPUT.PUT_LINE('Starting Script 6 - Rich Attribute Analysis');
         DBMS_OUTPUT.PUT_LINE('===== RICH ATTRIBUTE ANALYSIS =====');
         DBMS_OUTPUT.PUT_LINE('P_CODE | SELLERINFO | RichAttributePK | HomeDelivery | ExpressDelivery | ClickAndCollect | SameDayDelivery | ProductType | DeliveryFulfillModeByP1 | ReturnFulfillMode | ReturnFulfillModeByP1 | GiftWrappable | ReturnAtStoreEligible | IsFragile | IsPrecious | MediationRequired | ScheduledDelivery | TypeOfItem1 | TypeOfItem2 | ShippingModes | PaymentModes | DeliveryFulfillModes | WarrantyType | IsPromotionAllowed | EMI | IsSshipCodEligible | GstEligible | P_CANCELLATIONWINDOW | P_RETURNWINDOW | P_REPLACEMENTWINDOW | P_EXCHANGEALLOWEDWINDOW | P_WARRANTYPERIOD | P_LEADTIMEFORHOMEDELIVERY | P_SELLERFULFILLEDSHIPPINGCHARG | P_CATALOGVERSION | P_PRODUCTSOURCE | P_SELLERINFO_ATTR | ACLTS | PROPTS | P_SELLERHANDLINGTIME | P_RETURNATSTOREELIGIBLE | P_MANUFACTURERSDETAILS | P_IMPORTERSDETAILS | P_PACKERSDETAILS | P_GENERICNAME | P_COUNTRYOFORIGIN | SEALED');
         BEGIN
           FOR rec IN (
             SELECT p.p_code,
                    r.p_sellerinfo,
                    r.pk AS RichAttributePK,
                    he.code AS HomeDelivery,
                    ee.code AS ExpressDelivery,
                    ce.code AS ClickAndCollect,
                    sde.code AS SameDayDelivery,
                    pte.code AS ProductType,
                    dfp1.code AS DeliveryFulfillModeByP1,
                    rfm.code AS ReturnFulfillMode,
                    rfp1.code AS ReturnFulfillModeByP1,
                    gwe.code AS GiftWrappable,
                    rse.code AS ReturnAtStoreEligible,
                    fe.code AS IsFragile,
                    pe.code AS IsPrecious,
                    mre.code AS MediationRequired,
                    sde2.code AS ScheduledDelivery,
                    toi1.code AS TypeOfItem1,
                    toi2.code AS TypeOfItem2,
                    sme.code AS ShippingModes,
                    pme.code AS PaymentModes,
                    dfme.code AS DeliveryFulfillModes,
                    wte.code AS WarrantyType,
                    ipa.code AS IsPromotionAllowed,
                    emi.code AS EMI,
                    sce.code AS IsSshipCodEligible,
                    ge.code AS GstEligible,
                    r.P_CANCELLATIONWINDOW,
                    r.P_RETURNWINDOW,
                    r.P_REPLACEMENTWINDOW,
                    r.P_EXCHANGEALLOWEDWINDOW,
                    r.P_WARRANTYPERIOD,
                    r.P_LEADTIMEFORHOMEDELIVERY,
                    r.P_SELLERFULFILLEDSHIPPINGCHARG,
                    r.P_CATALOGVERSION,
                    r.P_PRODUCTSOURCE,
                    r.P_SELLERINFO AS P_SELLERINFO_ATTR,
                    r.ACLTS,
                    r.PROPTS,
                    r.P_SELLERHANDLINGTIME,
                    r.P_RETURNATSTOREELIGIBLE,
                    r.P_MANUFACTURERSDETAILS,
                    r.P_IMPORTERSDETAILS,
                    r.P_PACKERSDETAILS,
                    r.P_GENERICNAME,
                    r.P_COUNTRYOFORIGIN,
                    r.SEALED
             FROM products p
             JOIN mplsellerinfo s ON s.p_productsource = p.pk
             LEFT JOIN mplrichattribute r ON r.p_sellerinfo = s.pk
             LEFT JOIN enumerationvalues he ON r.p_homeDelivery = he.pk
             LEFT JOIN enumerationvalues ee ON r.p_expressDelivery = ee.pk
             LEFT JOIN enumerationvalues ce ON r.p_clickAndCollect = ce.pk
             LEFT JOIN enumerationvalues sde ON r.p_sameDayDelivery = sde.pk
             LEFT JOIN enumerationvalues pte ON r.p_productType = pte.pk
             LEFT JOIN enumerationvalues dfp1 ON r.p_deliveryFulfillModeByP1 = dfp1.pk
             LEFT JOIN enumerationvalues rfm ON r.p_returnFulfillMode = rfm.pk
             LEFT JOIN enumerationvalues rfp1 ON r.p_returnFulfillModeByP1 = rfp1.pk
             LEFT JOIN enumerationvalues gwe ON r.p_giftWrappable = gwe.pk
             LEFT JOIN enumerationvalues rse ON r.p_returnAtStoreEligible = rse.pk
             LEFT JOIN enumerationvalues fe ON r.p_isFragile = fe.pk
             LEFT JOIN enumerationvalues pe ON r.p_isPrecious = pe.pk
             LEFT JOIN enumerationvalues mre ON r.p_mediationRequired = mre.pk
             LEFT JOIN enumerationvalues sde2 ON r.p_scheduledDelivery = sde2.pk
             LEFT JOIN enumerationvalues toi1 ON r.p_typeOfItem1 = toi1.pk
             LEFT JOIN enumerationvalues toi2 ON r.p_typeOfItem2 = toi2.pk
             LEFT JOIN enumerationvalues sme ON r.p_shippingModes = sme.pk
             LEFT JOIN enumerationvalues pme ON r.p_paymentModes = pme.pk
             LEFT JOIN enumerationvalues dfme ON r.p_deliveryFulfillModes = dfme.pk
             LEFT JOIN enumerationvalues wte ON r.p_warrantyType = wte.pk
             LEFT JOIN enumerationvalues ipa ON r.p_isPromotionAllowed = ipa.pk
             LEFT JOIN enumerationvalues emi ON r.p_emi = emi.pk
             LEFT JOIN enumerationvalues sce ON r.p_isSshipCodEligible = sce.pk
             LEFT JOIN enumerationvalues ge ON r.p_gstEligible = ge.pk
             WHERE p.p_code = v_product_code
           ) LOOP
             DBMS_OUTPUT.PUT_LINE(
               rec.p_code || ' | ' ||
               rec.p_sellerinfo || ' | ' ||
               rec.RichAttributePK || ' | ' ||
               rec.HomeDelivery || ' | ' ||
               rec.ExpressDelivery || ' | ' ||
               rec.ClickAndCollect || ' | ' ||
               rec.SameDayDelivery || ' | ' ||
               rec.ProductType || ' | ' ||
               rec.DeliveryFulfillModeByP1 || ' | ' ||
               rec.ReturnFulfillMode || ' | ' ||
               rec.ReturnFulfillModeByP1 || ' | ' ||
               rec.GiftWrappable || ' | ' ||
               rec.ReturnAtStoreEligible || ' | ' ||
               rec.IsFragile || ' | ' ||
               rec.IsPrecious || ' | ' ||
               rec.MediationRequired || ' | ' ||
               rec.ScheduledDelivery || ' | ' ||
               rec.TypeOfItem1 || ' | ' ||
               rec.TypeOfItem2 || ' | ' ||
               rec.ShippingModes || ' | ' ||
               rec.PaymentModes || ' | ' ||
               rec.DeliveryFulfillModes || ' | ' ||
               rec.WarrantyType || ' | ' ||
               rec.IsPromotionAllowed || ' | ' ||
               rec.EMI || ' | ' ||
               rec.IsSshipCodEligible || ' | ' ||
               rec.GstEligible || ' | ' ||
               rec.P_CANCELLATIONWINDOW || ' | ' ||
               rec.P_RETURNWINDOW || ' | ' ||
               rec.P_REPLACEMENTWINDOW || ' | ' ||
               rec.P_EXCHANGEALLOWEDWINDOW || ' | ' ||
               rec.P_WARRANTYPERIOD || ' | ' ||
               rec.P_LEADTIMEFORHOMEDELIVERY || ' | ' ||
               rec.P_SELLERFULFILLEDSHIPPINGCHARG || ' | ' ||
               rec.P_CATALOGVERSION || ' | ' ||
               rec.P_PRODUCTSOURCE || ' | ' ||
               rec.P_SELLERINFO_ATTR || ' | ' ||
               rec.ACLTS || ' | ' ||
               rec.PROPTS || ' | ' ||
               rec.P_SELLERHANDLINGTIME || ' | ' ||
               rec.P_RETURNATSTOREELIGIBLE || ' | ' ||
               rec.P_MANUFACTURERSDETAILS || ' | ' ||
               rec.P_IMPORTERSDETAILS || ' | ' ||
               rec.P_PACKERSDETAILS || ' | ' ||
               rec.P_GENERICNAME || ' | ' ||
               rec.P_COUNTRYOFORIGIN || ' | ' ||
               rec.SEALED
             );
           END LOOP;
         EXCEPTION
           WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE('Script 6 failed: ' || SQLERRM);
         END;
         DBMS_OUTPUT.PUT_LINE('===========================================');
         DBMS_OUTPUT.PUT_LINE('');

         -- Script 6: Thumbnail Images Analysis
         DBMS_OUTPUT.PUT_LINE('Starting Script 6 - Thumbnail Images Analysis');
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
         EXCEPTION
            WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('Script 6 failed: ' || SQLERRM);
         END;
         DBMS_OUTPUT.PUT_LINE('===========================================');
         DBMS_OUTPUT.PUT_LINE('');

         -- Script 7: Product Classification Attributes Analysis
         DBMS_OUTPUT.PUT_LINE('Starting Script 7 - Product Classification Attributes Analysis');
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
         EXCEPTION
            WHEN OTHERS THEN
               DBMS_OUTPUT.PUT_LINE('Script 7 failed: ' || SQLERRM);
         END;
         DBMS_OUTPUT.PUT_LINE('===========================================');
         DBMS_OUTPUT.PUT_LINE('');

         DBMS_OUTPUT.PUT_LINE('Completed processing for product: ' || v_product_code);
      END LOOP;
      
      DBMS_OUTPUT.PUT_LINE('Completed processing for category: ' || v_category_code);
   END LOOP;

   -- Close the input file
   IF UTL_FILE.IS_OPEN(L_INPUT_HANDLE) THEN
      UTL_FILE.FCLOSE(L_INPUT_HANDLE);
      DBMS_OUTPUT.PUT_LINE('Input file closed');
   END IF;

   v_end_time := SYSTIMESTAMP;
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('=== SCRIPT EXECUTION SUMMARY ===');
   DBMS_OUTPUT.PUT_LINE('End time: ' || TO_CHAR(v_end_time, 'YYYY-MM-DD HH24:MI:SS.FF'));
   DBMS_OUTPUT.PUT_LINE('Total execution time: ' || 
                       EXTRACT(SECOND FROM (v_end_time - v_start_time)) || ' seconds');
   DBMS_OUTPUT.PUT_LINE('Categories processed: ' || v_category_count);
   DBMS_OUTPUT.PUT_LINE('Total products across all categories: ' || v_total_products);
   DBMS_OUTPUT.PUT_LINE('Products processed: ' || v_processed_count);
   DBMS_OUTPUT.PUT_LINE('Script execution complete.');

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('=== SCRIPT EXECUTION FAILED ===');
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
      DBMS_OUTPUT.PUT_LINE('Error code: ' || SQLCODE);
      DBMS_OUTPUT.PUT_LINE('Error backtrace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());
      DBMS_OUTPUT.PUT_LINE('Script failed with unexpected error');
      DBMS_OUTPUT.PUT_LINE('Last processed product: ' || v_product_code);
      DBMS_OUTPUT.PUT_LINE('Products processed before error: ' || v_processed_count);
      DBMS_OUTPUT.PUT_LINE('Categories processed before error: ' || v_category_count);
      
      -- Close the file if it's still open
      IF UTL_FILE.IS_OPEN(L_INPUT_HANDLE) THEN
         UTL_FILE.FCLOSE(L_INPUT_HANDLE);
         DBMS_OUTPUT.PUT_LINE('Input file closed due to error');
      END IF;
END; 