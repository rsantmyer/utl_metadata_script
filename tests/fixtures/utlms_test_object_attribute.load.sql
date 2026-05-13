BEGIN
EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
DELETE FROM UTLMS_TEST_OBJECT_ATTRIBUTE;
INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'EMPLOYEES', 'COLUMN_COUNT', '12', 1, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'EMPLOYEES', 'HAS_PK', 'Y', 2, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'EMPLOYEES', 'IS_PARTITIONED', 'N', 3, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'EMPLOYEES', 'NUM_ROWS', '1000000', 3, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'CUSTOMER', 'COLUMN_COUNT', '12', 1, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'CUSTOMER', 'HAS_PK', 'Y', 2, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'CUSTOMER', 'IS_PARTITIONED', 'N', 3, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'CUSTOMER', 'NUM_ROWS', '1234', 4, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'ORDER', 'COLUMN_COUNT', '18', 1, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'ORDER', 'HAS_PK', 'Y', 2, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'ORDER', 'IS_PARTITIONED', 'Y', 3, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('TABLE', 'ORDER', 'NUM_ROWS', '500000', 4, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('VIEW', 'EMPLOYEE_VIEW', 'COLUMN_COUNT', '5', 1, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('VIEW', 'EMPLOYEE_VIEW', 'IS_MATERIALIZED', 'N', 2, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('PACKAGE', 'EMPLOYEE_PKG', 'PROCEDURE_COUNT', '5', 1, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('PACKAGE', 'EMPLOYEE_PKG', 'PROCEDURE_NAME', 'GET_EMPLOYEES', 1, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('PACKAGE', 'EMPLOYEE_PKG', 'PROCEDURE_NAME', 'ADD_EMPLOYEE', 2, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('PACKAGE', 'EMPLOYEE_PKG', 'PROCEDURE_NAME', 'UPDATE_EMPLOYEE', 3, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('PACKAGE', 'EMPLOYEE_PKG', 'PROCEDURE_NAME', 'DELETE_EMPLOYEE', 4, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('PACKAGE', 'EMPLOYEE_PKG', 'PROCEDURE_NAME', 'GET_EMPLOYEE_COUNT', 5, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('VIEW', 'CUSTOMER_SUMMARY', 'COLUMN_COUNT', '8', 1, 'Y');

INSERT INTO UTLMS_TEST_OBJECT_ATTRIBUTE (object_type, object_name, attribute_name, attribute_value, sort_order, active_flag)
VALUES ('PACKAGE', 'BILLING_API', 'PROC_COUNT', '5', 1, 'Y');

COMMIT;
END;
/