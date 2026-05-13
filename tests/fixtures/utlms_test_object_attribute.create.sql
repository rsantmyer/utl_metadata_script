CREATE TABLE UTLMS_TEST_OBJECT_ATTRIBUTE (
    object_type       VARCHAR2(30) NOT NULL,
    object_name       VARCHAR2(100) NOT NULL,
    attribute_name    VARCHAR2(100) NOT NULL,
    attribute_value   VARCHAR2(4000),
    sort_order        NUMBER,
    active_flag       VARCHAR2(1),
    created_dt        DATE DEFAULT SYSDATE,
    CONSTRAINT UTLMS_TEST_OBJECT_ATTRIBUTE_PK
        PRIMARY KEY (object_type, object_name, attribute_name, attribute_value)
);
