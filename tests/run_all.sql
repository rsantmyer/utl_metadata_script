--SELECT USER, SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') FROM DUAL;
--GRANT INHERIT PRIVILEGES ON USER ADMIN TO UT3;
set SERVEROUTPUT on SIZE UNLIMITED
set DEFINE OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

prompt Dropping old fixture if exists...
@fixtures/utlms_test_object_attribute.drop.sql

prompt Creating fixture table...
@fixtures/utlms_test_object_attribute.create.sql

prompt Loading fixture data...
@fixtures/utlms_test_object_attribute.load.sql

prompt compiling utplSQL test package...
@utplsql/test_pkg_metadata_script.pks
@utplsql/test_pkg_metadata_script.pkb

prompt Running tests...
exec ut.run('TEST_PKG_METADATA_SCRIPT');

prompt Cleaning up fixture...
@fixtures/utlms_test_object_attribute.drop.sql

exit SUCCESS
