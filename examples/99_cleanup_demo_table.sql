WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT Dropping demo metadata table...

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

PROMPT Demo metadata table dropped.

