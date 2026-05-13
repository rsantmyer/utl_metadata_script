BEGIN
    FOR rec IN (SELECT object_name FROM user_objects WHERE object_type = 'TABLE' AND object_name = 'UTLMS_TEST_OBJECT_ATTRIBUTE')
    LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || rec.object_name || ' PURGE';
    END LOOP;
END;
/
