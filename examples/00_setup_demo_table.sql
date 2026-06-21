SET DEFINE OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT Creating demo metadata table...

BEGIN
   FOR rec IN (
      SELECT object_name
        FROM user_objects
       WHERE object_type = 'TABLE'
         AND object_name = 'UTLMS_EXAMPLE_METADATA'
   )
   LOOP
      EXECUTE IMMEDIATE 'DROP TABLE ' || rec.object_name || ' PURGE';
   END LOOP;
END;
/

CREATE TABLE utlms_example_metadata (
   object_type     VARCHAR2(30)   NOT NULL,
   object_name     VARCHAR2(100)  NOT NULL,
   attribute_name  VARCHAR2(100)  NOT NULL,
   attribute_value VARCHAR2(4000) NOT NULL,
   sort_order      NUMBER,
   active_flag     VARCHAR2(1)    DEFAULT 'Y' NOT NULL,
   created_dt      DATE           DEFAULT SYSDATE NOT NULL,
   CONSTRAINT utlms_example_metadata_pk
      PRIMARY KEY (object_type, object_name, attribute_name, attribute_value)
);

INSERT INTO utlms_example_metadata (object_type, object_name, attribute_name, attribute_value, sort_order)
VALUES ('TABLE', 'EMPLOYEES', 'COLUMN_COUNT', '12', 1);

INSERT INTO utlms_example_metadata (object_type, object_name, attribute_name, attribute_value, sort_order)
VALUES ('TABLE', 'EMPLOYEES', 'HAS_PK', 'Y', 2);

INSERT INTO utlms_example_metadata (object_type, object_name, attribute_name, attribute_value, sort_order)
VALUES ('TABLE', 'CUSTOMERS', 'COLUMN_COUNT', '9', 1);

INSERT INTO utlms_example_metadata (object_type, object_name, attribute_name, attribute_value, sort_order)
VALUES ('TABLE', 'CUSTOMERS', 'HAS_PK', 'Y', 2);

INSERT INTO utlms_example_metadata (object_type, object_name, attribute_name, attribute_value, sort_order)
VALUES ('VIEW', 'EMPLOYEE_SUMMARY', 'COLUMN_COUNT', '5', 1);

INSERT INTO utlms_example_metadata (object_type, object_name, attribute_name, attribute_value, sort_order)
VALUES ('PACKAGE', 'EMPLOYEE_API', 'PROCEDURE_COUNT', '4', 1);

COMMIT;

PROMPT Demo metadata table ready.

