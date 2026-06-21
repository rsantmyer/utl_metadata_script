SET LONG 100000
SET LONGCHUNKSIZE 100000
SET PAGESIZE 200
SET LINESIZE 200
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT Generating one full-table script with an explicit statement handle...

VARIABLE stmt_handle NUMBER

EXEC :stmt_handle := PKG_METADATA_SCRIPT.open_handle_f('UTLMS_EXAMPLE_METADATA');
EXEC PKG_METADATA_SCRIPT.gen_meta_script_p(:stmt_handle);
EXEC PKG_METADATA_SCRIPT.gen_data_script_p(:stmt_handle);

COLUMN script_name FORMAT A40
COLUMN data_script_preview FORMAT A120

SELECT script_name,
       DBMS_LOB.SUBSTR(data_script, 4000, 1) AS data_script_preview
  FROM gt_metadata_script
 WHERE statement_handle = :stmt_handle;

EXEC PKG_METADATA_SCRIPT.close_handle(:stmt_handle);

