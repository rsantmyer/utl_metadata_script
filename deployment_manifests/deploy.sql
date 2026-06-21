SET DEFINE ON
DEFINE APPLICATION_NAME = 'UTL_METADATA_SCRIPT'
DEFINE DEPLOY_VERSION_MAJOR = '1'
DEFINE DEPLOY_VERSION_MINOR = '1'
DEFINE DEPLOY_VERSION_PATCH = '0'
DEFINE DEPLOY_COMMIT_HASH = '&&1'

COLUMN CURRENT_SCHEMA       new_value CURRENT_SCHEMA      
SELECT sys_context('USERENV','CURRENT_SCHEMA') AS CURRENT_SCHEMA FROM DUAL;

SPOOL deploy.&&APPLICATION_NAME..&&CURRENT_SCHEMA..log

--PRINT BIND VARIABLE VALUES
SET AUTOPRINT ON                    

--THE START COMMAND WILL LIST EACH COMMAND IN A SCRIPT
REM SET ECHO ON                         

--DISPLAY DBMS_OUTPUT.PUT_LINE OUTPUT
SET SERVEROUTPUT ON                 

--SHOW THE OLD AND NEW SETTINGS OF A SQLPLUS SYSTEM VARIABLE
REM SET SHOWMODE ON                     

--ALLOW BLANK LINES WITHIN A SQL COMMAND OR SCRIPT
--SET SQLBLANKLINES ON                

WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR EXIT FAILURE

--Reason required: CORE 3.0 required for SYSLOG support
EXEC pkg_application.check_min_app_version_p( ip_application_name => 'CORE', ip_min_major_version => 3, ip_min_minor_version => 0, ip_min_patch_version => 0 );

EXEC PKG_APPLICATION.delete_application_p(ip_application_name => '&&APPLICATION_NAME', ip_fail_on_not_found => 'N' );

BEGIN
   pkg_application.begin_deployment_p     
      ( ip_deploy_commit_hash => NVL('&&DEPLOY_COMMIT_HASH', RPAD('0',40,'0') )
      , ip_application_name   => '&&APPLICATION_NAME'
      , ip_major_version      => &&DEPLOY_VERSION_MAJOR
      , ip_minor_version      => &&DEPLOY_VERSION_MINOR
      , ip_patch_version      => &&DEPLOY_VERSION_PATCH
      , ip_deployment_type    => pkg_application.c_deploy_type_initial  --c_deploy_type_minor
      --, ip_redeploy_curr_okay => TRUE
      );
END;
/

BEGIN
   pkg_application.set_deploy_notes_p
   ( ip_application_name => '&&APPLICATION_NAME'
   , ip_notes => 
Q'{1.1.0
* Add get_metadata_script function to PKG_METADATA_SCRIPT, which returns a pipelined table of CLOBs containing the generated metadata script. 
1.0.0
* UTL_METADATA_SCRIPT full/initial deploy
** This application contains utility procedures for working with metadata, such as generating SQL scripts to populate tables in an idempotent way. Useful for adding metadata to repositories.
}'
   );
END;
/

--
EXEC pkg_application.add_dependency_p  (ip_application_name => '&&APPLICATION_NAME', ip_depends_on => 'CORE');
--
--TABLES
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'GT_METADATA_SCRIPT'    , ip_object_type => pkg_application.c_object_type_table);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'GT_METADATA_SCRIPT_FILTER_COL' , ip_object_type => pkg_application.c_object_type_table);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'GT_METADATA_SF_COL_VAL'        , ip_object_type => pkg_application.c_object_type_table);

--PACKAGE SPECS / PACKAGE BODIES
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'PKG_METADATA_SCRIPT'   , ip_object_type => pkg_application.c_object_type_package);
EXEC pkg_application.add_object_p(ip_application_name => '&&APPLICATION_NAME', ip_object_name => 'PKG_METADATA_SCRIPT'   , ip_object_type => pkg_application.c_object_type_package_body);
--
--VALIDATIONS
EXEC pkg_application.validate_dependencies_p(ip_application_name => '&&APPLICATION_NAME');
EXEC pkg_application.validate_obj_privs_p   (ip_application_name => '&&APPLICATION_NAME');
EXEC pkg_application.validate_sys_privs_p   (ip_application_name => '&&APPLICATION_NAME');

--Tables
Prompt Creating Tables
@@../tables/GT_METADATA_SCRIPT.sql
@@../tables/GT_METADATA_SCRIPT_FILTER_COL.sql
@@../tables/GT_METADATA_SF_COL_VAL.sql

--Package Specifications
Prompt Creating Package Specifications
@@../packages/PKG_METADATA_SCRIPT.pks

--Package Bodies
Prompt Creating Package Bodies
@@../packages/PKG_METADATA_SCRIPT.pkb

SET DEFINE ON
EXEC pkg_application.validate_objects_p(ip_application_name => '&&APPLICATION_NAME');
EXEC pkg_application.set_deployment_complete_p(ip_application_name => '&&APPLICATION_NAME');

PROMPT  &&APPLICATION_NAME deployment complete

SPOOL OFF
