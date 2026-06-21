CREATE OR REPLACE PACKAGE PKG_METADATA_SCRIPT AS
/******************************************************************************
   NAME:       PKG_METADATA_SCRIPT

   DESCRIPTION: 
   - Generate metadata scripts for a specified table, with optional filtering.
   - Support for generating scripts that break by leading primary key columns.
   - Store generated script lines in a global temporary table for retrieval.

   Features:
   * open_handle_f: Initializes a new script generation session and returns a statement handle.
   * add_filter_columns_p: (optional) Adds filter column values to the session for generating filtered scripts.
   * close_handle: Closes the session and releases resources.
   * gen_meta_script_p: Generates the metadata script based on the provided statement handle.
   * gen_filter_meta_scripts_p: Generates metadata scripts with applied filters.
   * gen_data_script_p: Generates data scripts based on the provided statement handle.
   * get_metadata_script: Retrieves the generated metadata script as a pipelined function.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        05/28/2017  Robert Santmyer  Created this package.
   1.1        05/07/2026  Robert Santmyer  Added get_metadata_script function to return generated script as pipelined function.
******************************************************************************/


-- open_handle_f: Initializes a new script generation session and returns a statement handle.
-- Parameters:
-- ip_table_name: Name of the table for which to generate the metadata script.
-- ip_schema_name: Optional schema name to filter the metadata script generation.
-- ip_db_link: Optional database link to access a remote database for metadata script generation.
-- Returns:
-- A statement handle (number) that can be used in subsequent calls to generate scripts and retrieve results.
-- Usage:
-- DECLARE
--   v_stmt_handle NUMBER;
-- BEGIN
--   v_stmt_handle := PKG_METADATA_SCRIPT.open_handle_f('MY_TABLE');
--   PKG_METADATA_SCRIPT.add_filter_columns_p(v_stmt_handle, 1, 'FILTER_VALUE_1', 'FILTER_VALUE_2');
--   PKG_METADATA_SCRIPT.gen_meta_script_p(v_stmt_handle);
--   PKG_METADATA_SCRIPT.gen_filter_meta_scripts_p(v_stmt_handle);
--   PKG_METADATA_SCRIPT.gen_data_script_p(v_stmt_handle);
--   PKG_METADATA_SCRIPT.close_handle(v_stmt_handle);
-- END;
FUNCTION open_handle_f( ip_table_name   IN VARCHAR2
                      , ip_schema_name  IN VARCHAR2 DEFAULT NULL
                      , ip_db_link      IN VARCHAR2 DEFAULT NULL )
  RETURN NUMBER;


-- add_filter_columns_p: Adds filter column values to the session for generating filtered scripts.
-- Parameters:
-- ip_stmt_hndl: The statement handle returned by open_handle_f to identify the session.
-- ip_break_level: The level of the leading primary key column to apply the filter on (1 for first PK column, 2 for second, etc.).
-- ip_column_01_value: Optional - The filter value for the first column (used when ip_break_level is 1).
-- ip_column_02_value: Optional - The filter value for the second column (used when ip_break_level is 2).
--
-- Usage:
--
-- add_filter_columns_p(
--     p_stmt_handle,
--     p_num_pk_cols,
--     p_filter_val_1  => optional,
--     p_filter_val_2  => optional
-- );
--
-- Behavior:
-- - If no filter values are provided:
--     Generates scripts for each distinct PK combination up to p_num_pk_cols
--
-- - If filter values are provided:
--     Generates script only for rows matching the provided PK values
--
-- Examples:
--
-- 1) Break by first PK column (no filtering)
-- PKG_METADATA_SCRIPT.add_filter_columns_p(v_stmt_handle, 1);
--
-- 2) Filter on first PK column
-- PKG_METADATA_SCRIPT.add_filter_columns_p(
--     v_stmt_handle,
--     1,
--     'FILTER_VALUE_1'
-- );
--
-- 3) Break by first + second PK columns (no filtering)
-- PKG_METADATA_SCRIPT.add_filter_columns_p(v_stmt_handle, 2);
--
-- 4) Filter on first + second PK columns
-- PKG_METADATA_SCRIPT.add_filter_columns_p(
--     v_stmt_handle,
--     2,
--     'FILTER_VALUE_1',
--     'FILTER_VALUE_2'
-- );
   PROCEDURE add_filter_columns_p( ip_stmt_hndl          IN NUMBER 
                                    , ip_break_level        IN NUMBER   DEFAULT 1
                                    , ip_column_01_value    IN VARCHAR2 DEFAULT NULL
                                    , ip_column_02_value    IN VARCHAR2 DEFAULT NULL );
   
   -- gen_meta_script_p: Generates the metadata script based on the provided statement handle.
   -- Parameters:
   -- ip_stmt_hndl: The statement handle returned by open_handle_f that identifies the session for which to generate the metadata script.
   -- Usage:
   -- PKG_METADATA_SCRIPT.gen_meta_script_p(v_stmt_handle);
   PROCEDURE gen_meta_script_p( ip_stmt_hndl IN NUMBER );   

   -- gen_filter_meta_scripts_p: Generates metadata scripts with applied filters based on the provided statement handle.
   -- Parameters:
   -- ip_stmt_hndl: The statement handle returned by open_handle_f that identifies the session for which to generate the filtered metadata scripts.
   -- Usage:
   -- PKG_METADATA_SCRIPT.gen_filter_meta_scripts_p(v_stmt_handle);
   PROCEDURE gen_filter_meta_scripts_p( ip_stmt_hndl IN NUMBER );
   
   -- gen_data_script_p: Generates data scripts based on the provided statement handle.
   -- Parameters:
   -- ip_stmt_hndl: The statement handle returned by open_handle_f that identifies the session for which to generate the data scripts.
   -- Usage:
   -- PKG_METADATA_SCRIPT.gen_data_script_p(v_stmt_handle);
   PROCEDURE gen_data_script_p( ip_stmt_hndl IN NUMBER );

   -- close_handle: Closes the session and releases resources associated with the provided statement handle.
   -- Parameters:
   -- ip_stmt_hndl: The statement handle returned by open_handle_f that identifies the session to be closed.
   -- Usage:
   -- PKG_METADATA_SCRIPT.close_handle(v_stmt_handle);
   PROCEDURE close_handle( ip_stmt_hndl          IN NUMBER );

   -- Added in version 1.1 to return generated script as pipelined function
   -- Returns the generated metadata script as a pipelined function, allowing retrieval of script lines one at a time.
   -- Parameters:
   -- ip_schema_name: Optional schema name to filter the metadata script generation.
   -- ip_table_name: Name of the table for which to generate the metadata script.
   -- ip_db_link: Optional database link to access a remote database for metadata script generation.
   -- Returns:
   -- A pipelined table of CLOBs, where each CLOB contains a line of the generated metadata script.
   -- Usage:
   -- SELECT * FROM TABLE(PKG_METADATA_SCRIPT.get_metadata_script('MY_TABLE'));
      FUNCTION get_metadata_script( ip_table_name   IN VARCHAR2
                                  , ip_schema_name  IN VARCHAR2 DEFAULT NULL
                                  , ip_db_link      IN VARCHAR2 DEFAULT NULL )
       RETURN apex_t_clob PIPELINED;
                               
END PKG_METADATA_SCRIPT;

/
