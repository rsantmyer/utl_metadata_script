CREATE OR REPLACE PACKAGE BODY TEST_PKG_METADATA_SCRIPT AS

   g_stmt_handle NUMBER;

   PROCEDURE setup AS
   BEGIN
      -- Initialize test data or test environment
      g_stmt_handle := PKG_METADATA_SCRIPT.open_handle_f( ip_table_name => 'UTLMS_TEST_OBJECT_ATTRIBUTE' );
   END setup;

   PROCEDURE teardown AS
   BEGIN
      -- Clean up test data or test environment
      PKG_METADATA_SCRIPT.close_handle(g_stmt_handle);
   END teardown;

   PROCEDURE generate_scripts IS
   BEGIN
     PKG_METADATA_SCRIPT.gen_meta_script_p(g_stmt_handle);
     PKG_METADATA_SCRIPT.gen_filter_meta_scripts_p(g_stmt_handle);
     PKG_METADATA_SCRIPT.gen_data_script_p(g_stmt_handle);
   END generate_scripts;

   PROCEDURE no_filtering IS
      l_count NUMBER;
   BEGIN
      -- Test that no filtering generates metadata and data script
      pkg_metadata_script.gen_meta_script_p(g_stmt_handle);
      pkg_metadata_script.gen_filter_meta_scripts_p(g_stmt_handle);
      pkg_metadata_script.gen_data_script_p(g_stmt_handle);

      SELECT COUNT(*) INTO l_count FROM gt_metadata_script WHERE statement_handle = g_stmt_handle AND data_script IS NOT NULL;
      ut.expect( l_count ).to_equal( 1 ); -- Expecting 1 row with data_script generated when no filtering is applied);
   END no_filtering;

   PROCEDURE level_1_break_no_filter AS
        l_count NUMBER;
   BEGIN
      -- Test level 1 break with no filter
      pkg_metadata_script.add_filter_columns_p(g_stmt_handle, 1);
      pkg_metadata_script.gen_meta_script_p(g_stmt_handle);
      pkg_metadata_script.gen_filter_meta_scripts_p(g_stmt_handle);
      pkg_metadata_script.gen_data_script_p(g_stmt_handle);

      SELECT COUNT(*) INTO l_count FROM gt_metadata_script WHERE statement_handle = g_stmt_handle AND data_script IS NULL;
      -- Expecting 1 row with data_script generated
      ut.expect( l_count, 'Checking one entry in gt_metadata_script and data_script is NULL' ).to_equal( 1 ); 

      SELECT COUNT(*) INTO l_count FROM gt_metadata_script_filter_col WHERE statement_handle = g_stmt_handle AND column_name IS NOT NULL;
      -- Expecting 1 row in gt_metadata_script_filter_col with column_name populated when level 1 break is applied
      ut.expect( l_count, 'Checking one entry in gt_metadata_script_filter_col and column_name is NOT NULL' ).to_equal( 1 ); 

      SELECT COUNT(*) INTO l_count FROM gt_metadata_sf_col_val WHERE statement_handle = g_stmt_handle AND data_script IS NOT NULL;
      -- Expecting at least 2 rows with filtered metadata script generated when level 1 break is applied with no filter
      ut.expect( l_count, 'Checking filtered metadata script generation' ).to_be_greater_than( 1 ); 
   END level_1_break_no_filter;

   PROCEDURE level_1_break_with_filter AS
        l_count NUMBER;
        l_level_1_filter_value VARCHAR2(100) := 'TABLE';
        L_script_name VARCHAR2(100);
   BEGIN
      -- Test level 1 break with filter
        pkg_metadata_script.add_filter_columns_p(g_stmt_handle, 1, l_level_1_filter_value);
        pkg_metadata_script.gen_meta_script_p(g_stmt_handle);
        pkg_metadata_script.gen_filter_meta_scripts_p(g_stmt_handle);
        pkg_metadata_script.gen_data_script_p(g_stmt_handle);

        -- Expecting 1 row with data_script generated when level 1 break is applied with filter on 'TABLE'
        SELECT COUNT(*) INTO l_count FROM gt_metadata_script WHERE statement_handle = g_stmt_handle AND data_script IS NULL;
        ut.expect( l_count, 'Checking one entry in gt_metadata_script and data_script is NULL' ).to_equal( 1 );

        -- Expecting 1 row in gt_metadata_script_filter_col with column_name populated when level 1 break is applied with filter on 'TABLE'
        SELECT COUNT(*) INTO l_count FROM gt_metadata_script_filter_col WHERE statement_handle = g_stmt_handle AND column_name IS NOT NULL;
        ut.expect( l_count, 'Checking one entry in gt_metadata_script_filter_col and column_name is NOT NULL' ).to_equal( 1 );

        -- Expecting exactly 1 row with filtered metadata script generated when level 1 break is applied with filter on 'TABLE'
        SELECT COUNT(*), MAX(SCRIPT_NAME) INTO l_count, l_script_name FROM gt_metadata_sf_col_val WHERE statement_handle = g_stmt_handle AND data_script IS NOT NULL;
        ut.expect( l_count, 'Checking filtered metadata script generation' ).to_equal( 1 );
        --ut.expect( l_script_name, 'Checking that the generated script name contains "TABLE"' ).to_contain( 'TABLE' );
        ut.expect( l_script_name ).to_equal( 'UTLMS_TEST_OBJECT_ATTRIBUTE.TABLE.sql' );
   END level_1_break_with_filter;

   PROCEDURE level_2_break_no_filter AS
        l_count NUMBER;
        l_count_src NUMBER;
   BEGIN
      -- Test level 2 break with no filter
        pkg_metadata_script.add_filter_columns_p(g_stmt_handle, 2);
        pkg_metadata_script.gen_meta_script_p(g_stmt_handle);
        pkg_metadata_script.gen_filter_meta_scripts_p(g_stmt_handle);
        pkg_metadata_script.gen_data_script_p(g_stmt_handle);

        -- Expecting 1 row with data_script generated when level 2 break is applied with no filter
        SELECT COUNT(*) INTO l_count FROM gt_metadata_script WHERE statement_handle = g_stmt_handle AND data_script IS NULL;
        ut.expect( l_count, 'Checking one entry in gt_metadata_script and data_script is NULL' ).to_equal( 1 );
        -- Expecting 2 rows in gt_metadata_script_filter_col with column_name populated when level 2 break is applied with no filter
        SELECT COUNT(*) INTO l_count FROM gt_metadata_script_filter_col WHERE statement_handle = g_stmt_handle AND column_name IS NOT NULL;
        ut.expect( l_count, 'Checking two entries in gt_metadata_script_filter_col and column_name is NOT NULL' ).to_equal( 2 );
        -- Expecting the number of rows in gt_metadata_sf_col_val to equal the number of distinct combinations of values in the first two PK columns of the UTLMS_TEST_OBJECT_ATTRIBUTE table, which should be greater than 2, when level 2 break is applied with no filter
        SELECT COUNT(*)
        INTO l_count_src
          FROM ( SELECT DISTINCT OBJECT_TYPE, OBJECT_NAME
                   FROM UTLMS_TEST_OBJECT_ATTRIBUTE
               )
        ;   
        SELECT COUNT(*) INTO l_count FROM gt_metadata_sf_col_val WHERE statement_handle = g_stmt_handle AND data_script IS NOT NULL;
        ut.expect( l_count, 'Checking filtered metadata script generation count' ).to_equal( l_count_src );

   END level_2_break_no_filter;

   PROCEDURE level_2_break_with_level_1_filter AS
        l_count NUMBER;
        l_count_src NUMBER;
        level_1_filter_value VARCHAR2(100) := 'TABLE';
   BEGIN
      -- Test level 2 break with level 1 filter
        pkg_metadata_script.add_filter_columns_p(g_stmt_handle, 2, level_1_filter_value);
        pkg_metadata_script.gen_meta_script_p(g_stmt_handle);
        pkg_metadata_script.gen_filter_meta_scripts_p(g_stmt_handle);
        pkg_metadata_script.gen_data_script_p(g_stmt_handle);

        -- Expecting 1 row with data_script generated when level 2 break is applied with level 1 filter on 'TABLE'
        SELECT COUNT(*) INTO l_count FROM gt_metadata_script WHERE statement_handle = g_stmt_handle AND data_script IS NULL;
        ut.expect( l_count, 'Checking one entry in gt_metadata_script and data_script is NULL' ).to_equal( 1 );
        -- Expecting 2 rows in gt_metadata_script_filter_col with column_name populated when level 2 break is applied with level 1 filter on 'TABLE'
        SELECT COUNT(*) INTO l_count FROM gt_metadata_script_filter_col WHERE statement_handle = g_stmt_handle AND column_name IS NOT NULL;
        ut.expect( l_count, 'Checking two entries in gt_metadata_script_filter_col and column_name is NOT NULL' ).to_equal( 2 );
        -- Expecting the number of rows in gt_metadata_sf_col_val to equal the number of distinct combinations of values in the first two PK columns of the UTLMS_TEST_OBJECT_ATTRIBUTE table where OBJECT_TYPE = 'TABLE', which should be greater than 2, when level 2 break is applied with level 1 filter on 'TABLE'
        SELECT COUNT(*)
        INTO l_count_src
          FROM ( SELECT DISTINCT OBJECT_NAME
                   FROM UTLMS_TEST_OBJECT_ATTRIBUTE
                  WHERE OBJECT_TYPE = level_1_filter_value
               )
        ;   
        SELECT COUNT(*) INTO l_count FROM gt_metadata_sf_col_val WHERE statement_handle = g_stmt_handle AND data_script IS NOT NULL;
        ut.expect( l_count, 'Checking filtered metadata script generation count' ).to_equal( l_count_src );
      
   END level_2_break_with_level_1_filter;

   PROCEDURE level_2_break_with_level_1_and_level_2_filter AS
        l_count NUMBER;
        level_1_filter_value VARCHAR2(100) := 'TABLE';
        level_2_filter_value VARCHAR2(100) := 'EMPLOYEES';
   BEGIN
      -- Test level 2 break with level 1 and level 2 filter
        pkg_metadata_script.add_filter_columns_p(g_stmt_handle, 2, level_1_filter_value, level_2_filter_value);
        pkg_metadata_script.gen_meta_script_p(g_stmt_handle);
        pkg_metadata_script.gen_filter_meta_scripts_p(g_stmt_handle);
        pkg_metadata_script.gen_data_script_p(g_stmt_handle);

        -- Expecting 1 row with data_script generated when level 2 break is applied with level 1 filter on 'TABLE'
        SELECT COUNT(*) INTO l_count FROM gt_metadata_script WHERE statement_handle = g_stmt_handle AND data_script IS NULL;
        ut.expect( l_count, 'Checking one entry in gt_metadata_script and data_script is NULL' ).to_equal( 1 );
        -- Expecting 2 rows in gt_metadata_script_filter_col with column_name populated when level 2 break is applied with level 1 filter on 'TABLE'
        SELECT COUNT(*) INTO l_count FROM gt_metadata_script_filter_col WHERE statement_handle = g_stmt_handle AND column_name IS NOT NULL;
        ut.expect( l_count, 'Checking two entries in gt_metadata_script_filter_col and column_name is NOT NULL' ).to_equal( 2 );
        -- Expecting exactly 1 row with filtered metadata script generated when level 2 break is applied with level 1 filter on 'TABLE' and level 2 filter on 'EMPLOYEES'
        SELECT COUNT(*) INTO l_count FROM gt_metadata_sf_col_val WHERE statement_handle = g_stmt_handle AND data_script IS NOT NULL;
        ut.expect( l_count, 'Checking filtered metadata script generation count' ).to_equal( 1 );
   END level_2_break_with_level_1_and_level_2_filter;

END TEST_PKG_METADATA_SCRIPT;
