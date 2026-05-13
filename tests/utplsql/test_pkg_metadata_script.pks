CREATE OR REPLACE PACKAGE TEST_PKG_METADATA_SCRIPT AS
--%suite(PKG_METADATA_SCRIPT)

--%beforeeach
   PROCEDURE setup;

--%aftereach
   PROCEDURE teardown;

--%test(No filtering generates metadata and data script)
   PROCEDURE no_filtering;

--%test(level 1 break with no filter)
   PROCEDURE level_1_break_no_filter;

--%test(level 1 break with filter) 
   PROCEDURE level_1_break_with_filter;

--%test(level 2 break with no filter)
   PROCEDURE level_2_break_no_filter;

--%test(level 2 break with level 1 filter) 
   PROCEDURE level_2_break_with_level_1_filter;

--%test(level 2 break with level 1 and level 2 filter) 
   PROCEDURE level_2_break_with_level_1_and_level_2_filter;


END TEST_PKG_METADATA_SCRIPT;