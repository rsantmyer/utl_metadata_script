CREATE OR REPLACE PACKAGE BODY PKG_METADATA_SCRIPT AS
/******************************************************************************
   NAME:       PKG_METADATA_SCRIPT
   PURPOSE:  This package generates metadata scripts for maintaining data in tables.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        5/28/2017   Robert Santmyer  1. Created this package.
******************************************************************************/
   --Package globals
   TYPE global_vars_rec IS RECORD 
   ( v_on_clause              VARCHAR2(1000)
   , v_update_set_clause      VARCHAR2(4000)
   , v_pk_predicate_clause    VARCHAR2(1000)
   , v_pk_using_clause        VARCHAR2(1000)
   , v_order_by_clause        VARCHAR2(1000)
   , v_collection_name        VARCHAR2(30)
   , v_source_schema          VARCHAR2(30)
   , v_source_table           VARCHAR2(30)
   , v_source_filter          VARCHAR2(1000)
   , v_source_table_col_count VARCHAR2(10)
   , initialized  BOOLEAN := FALSE
   --, rep_vars     t_aa
   );
   
   TYPE global_vars_aa IS TABLE OF global_vars_rec INDEX BY PLS_INTEGER;
   g global_vars_aa;                                 --Index is statement handle

   pkg_is_initialized BOOLEAN := FALSE;
   
   --Forward declarations
   PROCEDURE Initialize_p( ip_stmt_hndl    IN NUMBER
                         , ip_schema_name  IN VARCHAR2
                         , ip_table_name   IN VARCHAR2
                         , ip_db_link      IN VARCHAR2 );

   --Functions and procedures
   FUNCTION open_handle_f( ip_table_name   IN VARCHAR2
                         , ip_schema_name  IN VARCHAR2 DEFAULT NULL
                         , ip_db_link      IN VARCHAR2 DEFAULT NULL)
     RETURN NUMBER
   IS
      c_max_open_handles CONSTANT NUMBER := 3;
      v_statement_handle NUMBER;
      v_open_handles     NUMBER;
   BEGIN
      SELECT NVL(MAX(statement_handle),0)+1 AS statement_handle
           , COUNT(*)
        INTO v_statement_handle
           , v_open_handles
        FROM gt_metadata_script;
   
      assert(v_open_handles <= c_max_open_handles,'open_handle_f: Maximum open statement handles exceeded.');
      assert(ip_schema_name IS NULL OR ip_schema_name = UPPER(ip_schema_name), 'ip_schema_name must be upper case');
      assert(ip_table_name  = UPPER(ip_table_name), 'ip_table_name must be upper case');
      
      Initialize_p( ip_stmt_hndl    => v_statement_handle
                  , ip_schema_name  => NVL(ip_schema_name, USER)
                  , ip_table_name   => ip_table_name
                  , ip_db_link      => ip_db_link );

      pkg_is_initialized := TRUE;
   
      COMMIT;
   
      RETURN v_statement_handle;
   END open_handle_f;

  
  
   PROCEDURE Initialize_p( ip_stmt_hndl    IN NUMBER
                         , ip_schema_name  IN VARCHAR2
                         , ip_table_name   IN VARCHAR2
                         , ip_db_link      IN VARCHAR2 )
   IS
      rec_gt_metadata_script gt_metadata_script%ROWTYPE;
   BEGIN
      rec_gt_metadata_script.STATEMENT_HANDLE         := ip_stmt_hndl;
      rec_gt_metadata_script.SCHEMA_NAME              := ip_schema_name;
      rec_gt_metadata_script.TABLE_NAME               := ip_table_name;
      rec_gt_metadata_script.DB_LINK                  := ip_db_link;
      rec_gt_metadata_script.BREAK_BY_LEADING_PK_COLS := 0;
      rec_gt_metadata_script.FILTER_PROVIDED          := 'N';
      
      INSERT 
        INTO gt_metadata_script
      VALUES rec_gt_metadata_script;

      --g(ip_stmt_hndl).system_id     := ip_system_id;
      --g(ip_stmt_hndl).as_of_date    := TRUNC(SYSDATE);
      --define_replacement_vars;
      g(ip_stmt_hndl).initialized   := TRUE;
   END Initialize_p;  

   
   
   PROCEDURE add_filter_columns_p( ip_stmt_hndl          IN NUMBER 
                                 , ip_break_level        IN NUMBER
                                 , ip_column_01_value    IN VARCHAR2 DEFAULT NULL
                                 , ip_column_02_value    IN VARCHAR2 DEFAULT NULL )
   IS
      rec_gt_metadata_script      gt_metadata_script%ROWTYPE;
      rec_constraint              all_constraints%ROWTYPE;
      rec_gt_metadata_sf_col_val  gt_metadata_sf_col_val%ROWTYPE;
      v_filter_script             VARCHAR2(4000); 
   BEGIN
      assert( ip_break_level IN (1,2)
            , 'Only break_level "1" and "2" are supported; Found: '
            ||ip_break_level );
   
      SELECT *
        INTO rec_gt_metadata_script
        FROM gt_metadata_script
       WHERE statement_handle = ip_stmt_hndl;
       
      assert( rec_gt_metadata_script.break_by_leading_pk_cols = 0
            , 'break_by_leading_pk_cols is already set to: '
            || rec_gt_metadata_script.break_by_leading_pk_cols );

      v_filter_script := 
Q'{INSERT
     INTO gt_metadata_sf_col_val
        ( STATEMENT_HANDLE
        , ID
        , FILTER_COLUMN_01_VALUE
        , FILTER_COLUMN_02_VALUE )
   SELECT }' || ip_stmt_hndl || Q'{
        , ROWNUM
        , :pk_col_01:
        , :pk_col_02: 
     FROM (SELECT DISTINCT :pk_col_01:, :pk_col_02: FROM }' || rec_gt_metadata_script.schema_name || '.' || rec_gt_metadata_script.table_name || Q'{ ORDER BY :pk_col_01: , :pk_col_02: ) }';
        
      SELECT *
        INTO rec_constraint
        FROM all_constraints
       WHERE owner = rec_gt_metadata_script.schema_name
         AND table_name = rec_gt_metadata_script.table_name
         AND constraint_type = 'P';
      
      FOR rec
       IN (SELECT a.column_name
                , a.position
                , b.data_type
             FROM all_cons_columns a
             JOIN all_tab_columns b
               ON a.owner = b.owner
              AND a.table_name = b.table_name
              AND a.column_name = b.column_name
            WHERE a.owner = rec_gt_metadata_script.schema_name
              AND a.constraint_name = rec_constraint.constraint_name
              AND a.table_name = rec_gt_metadata_script.table_name
              AND a.position <= ip_break_level
            ORDER BY a.position )
      LOOP
         assert( rec.data_type IN ('VARCHAR2','NUMBER')
               , 'filter column data_type must be "VARCHAR2" or "NUMBER"; Found: '
               ||rec.data_type );
      
         INSERT 
           INTO gt_metadata_script_filter_col
              ( statement_handle
              , pk_col_position
              , column_name
              , data_type )
         VALUES
              ( ip_stmt_hndl
              , rec.position
              , rec.column_name
              , rec.data_type
              );

         v_filter_script := REPLACE(v_filter_script, ':pk_col_'||TO_CHAR(rec.position, 'FM09')||':', rec.column_name);
         rec_gt_metadata_script.break_by_leading_pk_cols := rec_gt_metadata_script.break_by_leading_pk_cols + 1;
      END LOOP;
      
      IF ( rec_gt_metadata_script.break_by_leading_pk_cols < 2 )
      THEN
         v_filter_script := REPLACE(v_filter_script, ':pk_col_02:', 'NULL' );
      END IF;
      
      UPDATE gt_metadata_script
         SET break_by_leading_pk_cols = rec_gt_metadata_script.break_by_leading_pk_cols
           , filter_provided = CASE WHEN ip_column_01_value IS NULL THEN 'N' ELSE 'Y' END
       WHERE statement_handle = ip_stmt_hndl;

      IF ip_column_01_value IS NOT NULL THEN
         rec_gt_metadata_sf_col_val.statement_handle       := ip_stmt_hndl;
         rec_gt_metadata_sf_col_val.id                     := 1;
         rec_gt_metadata_sf_col_val.filter_column_01_value := ip_column_01_value;
         rec_gt_metadata_sf_col_val.filter_column_02_value := ip_column_02_value;
      
         INSERT 
           INTO gt_metadata_sf_col_val
         VALUES rec_gt_metadata_sf_col_val;
      ELSE
         --we need to find all distinct values and add them
         EXECUTE IMMEDIATE v_filter_script;
      END IF;
       
      COMMIT;
   END add_filter_columns_p;
   
   

   PROCEDURE close_handle( ip_stmt_hndl          IN NUMBER )
   IS
   BEGIN
      g.DELETE(ip_stmt_hndl);
      DELETE FROM gt_metadata_sf_col_val        WHERE statement_handle = ip_stmt_hndl;
      DELETE FROM gt_metadata_script_filter_col WHERE statement_handle = ip_stmt_hndl;
      DELETE FROM gt_metadata_script            WHERE statement_handle = ip_stmt_hndl;
      
      COMMIT;
   END close_handle;

   

   PROCEDURE gen_data_script_p( ip_stmt_hndl IN NUMBER )
   IS
      rec_gt_metadata_script  gt_metadata_script%ROWTYPE;
   BEGIN
      SELECT *
        INTO rec_gt_metadata_script
        FROM gt_metadata_script
       WHERE statement_handle = ip_stmt_hndl;
       
      assert( rec_gt_metadata_script.generator_script IS NOT NULL
            , 'generator_script is NULL, run "gen_meta_script_p" first' );
      
      IF rec_gt_metadata_script.break_by_leading_pk_cols = 0
      THEN
         EXECUTE IMMEDIATE rec_gt_metadata_script.generator_script;
      ELSE
         FOR rec_gt_metadata_sf_col_val
          IN ( SELECT * 
                 FROM gt_metadata_sf_col_val
                WHERE statement_handle = ip_stmt_hndl
                ORDER BY id )
         LOOP
            EXECUTE IMMEDIATE rec_gt_metadata_sf_col_val.generator_script;
         END LOOP;
      END IF;
   END gen_data_script_p;


   
   PROCEDURE build_clauses( ip_stmt_hndl     IN NUMBER
                          , ip_source_schema IN VARCHAR2
                          , ip_source_table  IN VARCHAR2 )
   IS
      TYPE columns_t IS TABLE OF VARCHAR2(30)
         INDEX BY PLS_INTEGER;
      rec_constraint      all_constraints%ROWTYPE;
      l_pk_columns        columns_t;
      l_non_pk_columns    columns_t;
      
   BEGIN
      SELECT *
        INTO rec_constraint
        FROM all_constraints
       WHERE constraint_type = 'P' --PRIMARY_KEY
         AND owner = ip_source_schema
         AND table_name = ip_source_table;
         
      SELECT column_name
        BULK COLLECT INTO l_pk_columns
        FROM all_cons_columns
       WHERE owner = ip_source_schema
         AND constraint_name = rec_constraint.constraint_name
       ORDER BY position;

      SELECT column_name
        BULK COLLECT INTO l_non_pk_columns
        FROM all_tab_columns
       WHERE owner = ip_source_schema
         AND table_name = ip_source_table
         AND column_name 
            NOT IN 
            ( SELECT column_name
                FROM all_cons_columns
               WHERE owner = ip_source_schema
                 AND constraint_name = rec_constraint.constraint_name
            )
       ORDER BY column_id;
      
      SELECT COUNT(*)
        INTO g(ip_stmt_hndl).v_source_table_col_count
        FROM all_tab_columns
       WHERE owner = ip_source_schema
         AND table_name = ip_source_table;

      --build on_clause and pk_predicate_clause and pk_using_clause and order_by_clause
      FOR indx IN 1..l_pk_columns.COUNT
      LOOP
         IF indx > 1
         THEN
            g(ip_stmt_hndl).v_on_clause := g(ip_stmt_hndl).v_on_clause ||' AND '||CHR(10);
            g(ip_stmt_hndl).v_pk_predicate_clause := g(ip_stmt_hndl).v_pk_predicate_clause ||' AND ';
            g(ip_stmt_hndl).v_pk_using_clause := g(ip_stmt_hndl).v_pk_using_clause||', IN ';
            g(ip_stmt_hndl).v_order_by_clause := g(ip_stmt_hndl).v_order_by_clause||', ';
         ELSE
            NULL;
         END IF;
         g(ip_stmt_hndl).v_on_clause := g(ip_stmt_hndl).v_on_clause ||'                 A.'||RPAD(l_pk_columns(indx),30)||' = :collection_name:(i).'||l_pk_columns(indx);
         g(ip_stmt_hndl).v_pk_predicate_clause := g(ip_stmt_hndl).v_pk_predicate_clause ||l_pk_columns(indx)||' = :'||l_pk_columns(indx);
         g(ip_stmt_hndl).v_pk_using_clause := g(ip_stmt_hndl).v_pk_using_clause ||'REC.'||l_pk_columns(indx);
         g(ip_stmt_hndl).v_order_by_clause := g(ip_stmt_hndl).v_order_by_clause || l_pk_columns(indx);
      END LOOP;
      
      --build update_set_clause
      FOR indx IN 1..l_non_pk_columns.COUNT
      LOOP
         IF indx > 1
         THEN
            g(ip_stmt_hndl).v_update_set_clause := g(ip_stmt_hndl).v_update_set_clause ||CHR(10)||'         , A.';
         ELSE
            g(ip_stmt_hndl).v_update_set_clause := g(ip_stmt_hndl).v_update_set_clause          ||'           A.';
         END IF;
         g(ip_stmt_hndl).v_update_set_clause := g(ip_stmt_hndl).v_update_set_clause 
           ||RPAD(l_non_pk_columns(indx),31)||' = :collection_name:(i).'||l_non_pk_columns(indx);
      END LOOP;
      
   END build_clauses;


   
   PROCEDURE gen_meta_script_p( ip_stmt_hndl IN NUMBER )
   IS
      rec_gt_metadata_script  gt_metadata_script%ROWTYPE;
   BEGIN
      SELECT *
        INTO rec_gt_metadata_script
        FROM gt_metadata_script
       WHERE statement_handle = ip_stmt_hndl;
      
      --------------------------------------------------------------------------
      --begin assignment to rec_gt_metadata_script.generator_script
      --------------------------------------------------------------------------
      rec_gt_metadata_script.generator_script := 
Q'[DECLARE
   TYPE t_all_tab_col IS TABLE OF ALL_TAB_COLUMNS%ROWTYPE INDEX BY BINARY_INTEGER;
   TYPE rec_anydata   IS RECORD 
      (DATA_TYPE    VARCHAR2(30),
       VARCHAR_DATA VARCHAR2(2000),
       NUMBER_DATA  NUMBER,
       DATE_DATA    DATE,
       CLOB_DATA    CLOB
      );
   TYPE t_anydata IS TABLE OF rec_anydata INDEX BY VARCHAR2(100);
   --
   l_all_tab_col t_all_tab_col;
   l_anydata     t_anydata;
   --
   v_output_clob           CLOB;
   v_collection_name       VARCHAR2(30)  := ':collection_name:';
   v_collection_name_len   NUMBER        := LENGTH(v_collection_name);
   v_max_column_name_len   NUMBER;
   v_rpad_amount           NUMBER;
   --
   v_use_this_index INTEGER              := 1; --:in_index_start_num;
   --
   CURSOR C1_CUR IS
   SELECT *
     FROM :source_schema:.:source_table:
    WHERE :source_filter:
    ORDER BY :order_by_clause:;
   --
   CURSOR C_COLUMN_INFO IS
   SELECT *
     FROM ALL_TAB_COLUMNS
    WHERE OWNER = ':source_schema:'
      AND TABLE_NAME = ':source_table:'
    ORDER BY COLUMN_ID;

   PROCEDURE print_header
   IS
   BEGIN
      v_output_clob :=   'DECLARE'||CHR(10)
                       ||'   TYPE t_:source_table: IS TABLE OF :source_schema:.:source_table:%ROWTYPE INDEX BY BINARY_INTEGER;'
                       ||CHR(10)
                       ||'   :collection_name: t_:source_table:;'
                       ||CHR(10)
                       ||CHR(10)
                       ||'   V_I PLS_INTEGER := 0;'
                       ||CHR(10)
                       ||CHR(10)
                       ||'BEGIN'
                       ||CHR(10);
   END print_header;

   PROCEDURE print_trailer
   IS
      v_current_column_cnt NUMBER;
   BEGIN
      SELECT COUNT(*)
        INTO v_current_column_cnt
        FROM ALL_TAB_COLUMNS
       WHERE OWNER = ':source_schema:'
         AND TABLE_NAME = ':source_table:';

      assert(v_current_column_cnt = :source_table_col_count:, 'Column count differs from expected. Modify the "UPDATE SET" clause and current column count.');

      v_output_clob := v_output_clob ||
Q'|-------------------------------------------------------------------------------- 
-------------------------------------------------------------------------------- 
-------------------------------------------------------------------------------- 
   FORALL i IN :collection_name:.FIRST..:collection_name:.LAST
      MERGE INTO :source_schema:.:source_table: A
         USING (SELECT NULL FROM dual)
            ON (
:on_clause:
               )
      WHEN MATCHED
      THEN
         UPDATE SET
:update_set_clause:
      WHEN NOT MATCHED
      THEN
         INSERT VALUES :collection_name:(I);
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
   COMMIT;
   --ROLLBACK;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      RAISE;
END;
/
|';
   END print_trailer;

   FUNCTION PRINT_VAL (in_rec_anydata rec_anydata, in_col_name VARCHAR2)
   RETURN VARCHAR2 
   IS
      v_return_val VARCHAR2(32000);
      v_init_char  VARCHAR2(1);
   BEGIN
      CASE in_col_name
      WHEN 'CREATED_DATE'
      THEN
         RETURN 'SYSDATE';
      WHEN 'UPDATED_DATE'
      THEN
         RETURN 'SYSDATE';
      ELSE
         NULL;
      END CASE;
      
      CASE in_rec_anydata.DATA_TYPE
      WHEN 'VARCHAR2'
         THEN
            IF    INSTR(in_rec_anydata.VARCHAR_DATA, CHR(10)) > 0
               OR LENGTH(in_rec_anydata.VARCHAR_DATA) > 70
            THEN
               v_init_char := CHR(10);
            ELSE
               v_init_char := NULL;
            END IF;

            CASE WHEN in_rec_anydata.VARCHAR_DATA IS NULL
            THEN 
               v_return_val := 'NULL';
            WHEN INSTR(in_rec_anydata.VARCHAR_DATA,'''') > 0
              OR INSTR(in_rec_anydata.VARCHAR_DATA, CHR(10)) > 0
              OR LENGTH(in_rec_anydata.VARCHAR_DATA) > 70
            THEN
               v_return_val := v_init_char||'Q''{'||in_rec_anydata.VARCHAR_DATA||'}''';
            ELSE
               v_return_val := v_init_char||Q'{'}'||in_rec_anydata.VARCHAR_DATA||Q'{'}';
            END CASE;
      WHEN 'NUMBER'
         THEN
            IF in_rec_anydata.NUMBER_DATA IS NULL
            THEN 
               v_return_val := 'NULL';
            ELSE
               v_return_val := TO_CHAR(in_rec_anydata.NUMBER_DATA); 
            END IF;
      WHEN 'DATE'
         THEN
            IF in_rec_anydata.DATE_DATA IS NULL
            THEN 
               v_return_val := 'NULL';
            ELSE
               v_return_val := 'TO_DATE('''||TO_CHAR(in_rec_anydata.DATE_DATA,'MM-DD-YYYY')||''',''MM-DD-YYYY'')'; 
            END IF;
      WHEN 'CLOB'
         THEN
            IF in_rec_anydata.CLOB_DATA IS NULL
            THEN 
               v_return_val := 'NULL';
            ELSE
               v_return_val := 'Q''{'||in_rec_anydata.CLOB_DATA||'}'''; 
            END IF;

      END CASE;
      RETURN v_return_val;
   END PRINT_VAL;
   

BEGIN
   OPEN C_COLUMN_INFO;
   LOOP
      FETCH C_COLUMN_INFO BULK COLLECT INTO l_all_tab_col;
      EXIT WHEN C_COLUMN_INFO%NOTFOUND;
   END LOOP;
   CLOSE C_COLUMN_INFO;

   SELECT MAX(LENGTH(column_name))
     INTO v_max_column_name_len
     FROM all_tab_columns
    WHERE OWNER = ':source_schema:'
      AND TABLE_NAME = ':source_table:';
      
   v_rpad_amount := v_collection_name_len + v_max_column_name_len + 6 + 1; --LENGTH('(V_I).') + SPACE

   print_header;

   FOR REC IN C1_CUR 
   LOOP
      l_anydata.DELETE;
      v_output_clob := v_output_clob 
--                     ||LPAD(' ',81,'-')||CHR(10)
--                     ||LPAD(' ',5,'-')||REC.DESCRIPTION||CHR(10)
                     ||LPAD(' ',81,'-')||CHR(10);

      IF C1_CUR%ROWCOUNT >= 1 THEN
         v_output_clob := v_output_clob
--                        ||'--V_I := '||TO_CHAR(v_use_this_index)||';'||CHR(10)
                        ||'V_I := V_I + 1;'||CHR(10)
--                        ||'--'||CHR(10)
                        ;
      ELSE
         v_output_clob := v_output_clob
                        ||'V_I := '||TO_CHAR(v_use_this_index)||';'||CHR(10);
      END IF;

      FOR I IN l_all_tab_col.FIRST..l_all_tab_col.LAST
      LOOP
         l_anydata(l_all_tab_col(I).column_name).DATA_TYPE := l_all_tab_col(I).DATA_TYPE;
         
         CASE l_all_tab_col(I).DATA_TYPE
         WHEN 'VARCHAR2' THEN
            EXECUTE IMMEDIATE 'SELECT '||l_all_tab_col(i).column_name||' FROM :source_schema:.:source_table: WHERE :pk_predicate_clause:'
            INTO l_anydata(l_all_tab_col(I).column_name).VARCHAR_DATA 
            USING IN :pk_using_clause:;
         WHEN 'NUMBER' THEN
            EXECUTE IMMEDIATE 'SELECT '||l_all_tab_col(i).column_name||' FROM :source_schema:.:source_table: WHERE :pk_predicate_clause:'
            INTO l_anydata(l_all_tab_col(I).column_name).NUMBER_DATA 
            USING IN :pk_using_clause:;
         WHEN 'DATE' THEN
            EXECUTE IMMEDIATE 'SELECT '||l_all_tab_col(i).column_name||' FROM :source_schema:.:source_table: WHERE :pk_predicate_clause:'
            INTO l_anydata(l_all_tab_col(I).column_name).DATE_DATA 
            USING IN :pk_using_clause:;
         WHEN 'CLOB' THEN
            EXECUTE IMMEDIATE 'SELECT '||l_all_tab_col(i).column_name||' FROM :source_schema:.:source_table: WHERE :pk_predicate_clause:'
            INTO l_anydata(l_all_tab_col(I).column_name).CLOB_DATA 
            USING IN :pk_using_clause:;
         END CASE;
         v_output_clob := v_output_clob
                        ||RPAD(v_collection_name||'(V_I).'||l_all_tab_col(I).column_name, v_rpad_amount)||':= '
                        ||PRINT_VAL( l_anydata(l_all_tab_col(I).column_name), l_all_tab_col(I).column_name )
                        ||';'||CHR(10);

      END LOOP;
      v_use_this_index := v_use_this_index + 1;
   END LOOP;
   
   print_trailer;
   
   UPDATE :script_store_table: 
      SET data_script = v_output_clob
    WHERE statement_handle = :statement_handle:
      AND :sf_col_val_clause: ;
    
   COMMIT;
   

END; ]';
      --------------------------------------------------------------------------
      --end assignment to rec_gt_metadata_script.generator_script
      --------------------------------------------------------------------------
      
      g(ip_stmt_hndl).v_collection_name := 'l_'||LOWER(rec_gt_metadata_script.table_name);
     
      --build_clauses(v_source_schema, v_source_table);
      build_clauses( ip_stmt_hndl     => ip_stmt_hndl
                   , ip_source_schema => rec_gt_metadata_script.schema_name
                   , ip_source_table  => rec_gt_metadata_script.table_name );
     
      rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':on_clause:'              , g(ip_stmt_hndl).v_on_clause );
      rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':update_set_clause:'      , g(ip_stmt_hndl).v_update_set_clause );
      rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':pk_predicate_clause:'    , g(ip_stmt_hndl).v_pk_predicate_clause );
      rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':pk_using_clause:'        , g(ip_stmt_hndl).v_pk_using_clause );
      rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':order_by_clause:'        , g(ip_stmt_hndl).v_order_by_clause );
      --                                                                                                                     
      rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':collection_name:'        , g(ip_stmt_hndl).v_collection_name );
      rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':source_schema:'          , rec_gt_metadata_script.schema_name );
      rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':source_table:'           , rec_gt_metadata_script.table_name );
      rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':source_table_col_count:' , g(ip_stmt_hndl).v_source_table_col_count );
      rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':statement_handle:'       , ip_stmt_hndl );

      IF rec_gt_metadata_script.break_by_leading_pk_cols = 0 THEN
         --if we are generating the script for all data in the table, set the filter to "1=1"
         rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':source_filter:'       , '1=1' );
         rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':script_store_table:'  , 'gt_metadata_script' );
         rec_gt_metadata_script.generator_script := REPLACE(rec_gt_metadata_script.generator_script, ':sf_col_val_clause:'  , '1=1' );
      ELSE
         --do nothing for now
         NULL;
      END IF;
      
      UPDATE gt_metadata_script
         SET script_name      = table_name || '.sql'
           , generator_script = rec_gt_metadata_script.generator_script
       WHERE statement_handle = ip_stmt_hndl;
       
      COMMIT;
   END gen_meta_script_p;
   
   
   
   PROCEDURE gen_filter_meta_scripts_p( ip_stmt_hndl IN NUMBER )
   IS
      rec_gt_metadata_script  gt_metadata_script%ROWTYPE;
      v_temp_val              VARCHAR2(1000);
   BEGIN
      SELECT *
        INTO rec_gt_metadata_script
        FROM gt_metadata_script
       WHERE statement_handle = ip_stmt_hndl;
       
      FOR rec_script_filter_val
       IN ( SELECT * 
              FROM gt_metadata_sf_col_val
             WHERE statement_handle = ip_stmt_hndl )
      LOOP
         g(ip_stmt_hndl).v_source_filter := NULL;
         
         FOR rec_filter_col
          IN ( SELECT *
                 FROM gt_metadata_script_filter_col
                WHERE statement_handle = ip_stmt_hndl
                ORDER BY pk_col_position )
         LOOP 
            IF rec_filter_col.pk_col_position > 1 THEN
               assert( rec_filter_col.pk_col_position <= 2, 'Only key columns up to 2 are supported' );
               g(ip_stmt_hndl).v_source_filter := g(ip_stmt_hndl).v_source_filter || ' AND ';
               v_temp_val := rec_script_filter_val.filter_column_02_value;
            ELSE
               v_temp_val := rec_script_filter_val.filter_column_01_value;
            END IF;
            
            CASE rec_filter_col.data_type
            WHEN 'VARCHAR2' THEN
               g(ip_stmt_hndl).v_source_filter := g(ip_stmt_hndl).v_source_filter 
                                               || rec_filter_col.column_name || ' = ' || Q'<Q'{>' || v_temp_val || Q'<}'>';
            WHEN 'NUMBER' THEN
               g(ip_stmt_hndl).v_source_filter := g(ip_stmt_hndl).v_source_filter 
                                               || rec_filter_col.column_name || ' = ' || v_temp_val;
            ELSE
               assert(FALSE, 'Unsupported data_type: '||rec_filter_col.data_type);
            END CASE;
            
         END LOOP;                                  --rec_filter_col
         
         rec_script_filter_val.generator_script := rec_gt_metadata_script.generator_script;
         rec_script_filter_val.generator_script := REPLACE(rec_script_filter_val.generator_script, ':source_filter:' , g(ip_stmt_hndl).v_source_filter );
         rec_script_filter_val.generator_script := REPLACE(rec_script_filter_val.generator_script, ':script_store_table:' , 'gt_metadata_sf_col_val' );
         rec_script_filter_val.generator_script := REPLACE(rec_script_filter_val.generator_script, ':sf_col_val_clause:' , 'id = ' || rec_script_filter_val.id );
         
         --UPDATE THE META SCRIPT
         UPDATE gt_metadata_sf_col_val
            SET script_name      = rec_gt_metadata_script.table_name ||'.'|| filter_column_01_value || NVL2(filter_column_02_value,'.',NULL) || filter_column_02_value || '.sql'
              , generator_script = rec_script_filter_val.generator_script
          WHERE statement_handle = ip_stmt_hndl
            AND id = rec_script_filter_val.id;
         
      END LOOP;                                     --rec_script_filter_val
      
      COMMIT;
   END gen_filter_meta_scripts_p;



   FUNCTION get_metadata_script( ip_table_name   IN VARCHAR2
                               , ip_schema_name  IN VARCHAR2 DEFAULT NULL
                               , ip_db_link      IN VARCHAR2 DEFAULT NULL )
       RETURN apex_t_clob PIPELINED
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      v_statement_handle NUMBER;
   BEGIN
      v_statement_handle := open_handle_f( ip_table_name  => ip_table_name
                                         , ip_schema_name => ip_schema_name
                                         , ip_db_link     => ip_db_link )
      ;
      GEN_META_SCRIPT_P(v_statement_handle);
      GEN_DATA_SCRIPT_P(v_statement_handle)
      ;
      FOR REC IN (SELECT *
                    FROM 
                   TABLE(APEX_STRING.SPLIT_CLOBS (p_str   => (SELECT DATA_SCRIPT FROM GT_METADATA_SCRIPT WHERE statement_handle = v_statement_handle)
                                                --  p_sep   IN VARCHAR2    DEFAULT apex_application.LF,
                                                --  p_limit IN PLS_INTEGER DEFAULT NULL 
                                                  )
                        ) )
      LOOP
         PIPE ROW( REC.COLUMN_VALUE );
      END LOOP;
      --close the handle and clean up
      close_handle(v_statement_handle);
   EXCEPTION
      WHEN NO_DATA_NEEDED THEN
         close_handle(v_statement_handle);
   END get_metadata_script;


END PKG_METADATA_SCRIPT;

/
