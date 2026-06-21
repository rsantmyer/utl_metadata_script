SET LONG 100000
SET LONGCHUNKSIZE 100000
SET PAGESIZE 200
SET LINESIZE 200
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT Generating one script per OBJECT_TYPE...

VARIABLE stmt_handle NUMBER

EXEC :stmt_handle := PKG_METADATA_SCRIPT.open_handle_f('UTLMS_EXAMPLE_METADATA');
EXEC PKG_METADATA_SCRIPT.add_filter_columns_p(:stmt_handle, 1);
EXEC PKG_METADATA_SCRIPT.gen_meta_script_p(:stmt_handle);
EXEC PKG_METADATA_SCRIPT.gen_filter_meta_scripts_p(:stmt_handle);
EXEC PKG_METADATA_SCRIPT.gen_data_script_p(:stmt_handle);

COLUMN filter_column_01_value FORMAT A24
COLUMN script_name FORMAT A48
COLUMN data_script_preview FORMAT A100

SELECT filter_column_01_value,
       script_name,
       DBMS_LOB.SUBSTR(data_script, 1200, 1) AS data_script_preview
  FROM gt_metadata_sf_col_val
 WHERE statement_handle = :stmt_handle
 ORDER BY filter_column_01_value;

EXEC PKG_METADATA_SCRIPT.close_handle(:stmt_handle);

