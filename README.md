# UTL_METADATA_SCRIPT

`UTL_METADATA_SCRIPT` is an Oracle database utility for generating repeatable
SQL scripts from metadata rows already stored in tables. It is useful when
configuration or reference data should be checked into source control as SQL
instead of copied manually between environments.

The package can generate one script for a full table, or split scripts by the
leading columns of a table primary key. Split scripts are handy when a metadata
table stores multiple logical objects and you want one generated SQL file per
object, type, or type/name combination.

## Package Contents

- `dbpm.yaml`: dbpm package manifest.
- `deployment_manifests/`: dbpm install entry points.
- `tables/`: global temporary tables used during script generation.
- `packages/`: `PKG_METADATA_SCRIPT` package spec and body.
- `tests/`: utPLSQL tests and fixture data.
- `examples/`: runnable SQLcl/SQL*Plus examples.

## Requirements

- Oracle Database.
- APEX string types and utilities available to the parsing schema.
- Core `3.0.0` or newer when installing with dbpm.
- SQLcl or SQL*Plus for running install, test, and example scripts.
- utPLSQL v3 for the test suite.

## Install With dbpm

From the repository root:

```sh
dbpm install . --env development
```

To preview the install plan:

```sh
dbpm plan . --mode install
```

The dbpm manifest installs `deployment_manifests/deploy.sql`, which registers
the application as `UTL_METADATA_SCRIPT` version `1.1.0`.

## Basic Usage

For the simplest case, query the pipelined function:

```sql
SELECT column_value AS script_line
  FROM TABLE(PKG_METADATA_SCRIPT.get_metadata_script('MY_METADATA_TABLE'));
```

For more control, use a statement handle:

```sql
VARIABLE stmt_handle NUMBER

EXEC :stmt_handle := PKG_METADATA_SCRIPT.open_handle_f('MY_METADATA_TABLE');
EXEC PKG_METADATA_SCRIPT.gen_meta_script_p(:stmt_handle);
EXEC PKG_METADATA_SCRIPT.gen_data_script_p(:stmt_handle);

SELECT script_name, data_script
  FROM gt_metadata_script
 WHERE statement_handle = :stmt_handle;

EXEC PKG_METADATA_SCRIPT.close_handle(:stmt_handle);
```

To split generated scripts by primary-key columns, call
`add_filter_columns_p` before generating:

```sql
EXEC PKG_METADATA_SCRIPT.add_filter_columns_p(:stmt_handle, 2);
```

The second argument is the number of leading primary-key columns to use. Passing
filter values limits generation to a specific key prefix:

```sql
EXEC PKG_METADATA_SCRIPT.add_filter_columns_p(:stmt_handle, 2, 'TABLE', 'EMPLOYEES');
```

## Examples

The examples create a small demo metadata table, generate scripts from it, and
then clean up the demo object.

Run them from the repository root:

```sql
@examples/00_setup_demo_table.sql
@examples/01_basic_pipelined_function.sql
@examples/02_handle_full_table.sql
@examples/03_break_by_object_type.sql
@examples/04_filter_specific_object.sql
@examples/99_cleanup_demo_table.sql
```

## Tests

Install the package first, then run:

```sh
cd tests
sql -S -L "$DBPM_CONNECT" @run_all.sql
```

The test suite creates and drops its own fixture table.

