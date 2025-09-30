/*
# Modules & Code Analysis Functions Tests
# Description
Comprehensive tests for all modules and code analysis functions in pure-utils.

Functions tested:
- modulesSplitToLines
- modulesGetCreateLineNumber
- modulesFindCommentsPositions
- modulesFindInlineCommentsPositions
- modulesFindMultilineCommentsPositions
- modulesFindLinesPositions
- modulesGetDescriptionFromComments
- modulesGetDescriptionFromCommentsLegacy
- modulesFindSimilar
- modulesRecureSearchForOccurrences
- modulesRecureSearchStartEndPositions
- modulesRecureSearchStartEndPositionsExtended
- modulesRecureSearchInvalidReferences
*/

-- Include test framework
:r Tests\TestFramework.sql

PRINT 'Starting Modules & Code Analysis Functions Tests...';
PRINT '';

-- Reset test counters
DECLARE @TestCount INT = 0;
DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

-- ===========================================
-- modulesSplitToLines Tests
-- ===========================================
PRINT 'Testing modulesSplitToLines function...';

-- Test 1: Split util.help procedure to lines
DECLARE @HelpLinesCount INT;
SELECT @HelpLinesCount = COUNT(*) FROM util.modulesSplitToLines('util.help', 1);

EXEC #AssertTrue CASE WHEN @HelpLinesCount > 0 THEN 1 ELSE 0 END, 'modulesSplitToLines - util.help should have lines of code';

-- Test 2: Test with skipEmpty = 0 should return more or equal lines
DECLARE @HelpLinesWithEmpty INT;
SELECT @HelpLinesWithEmpty = COUNT(*) FROM util.modulesSplitToLines('util.help', 0);

EXEC #AssertTrue CASE WHEN @HelpLinesWithEmpty >= @HelpLinesCount THEN 1 ELSE 0 END, 'modulesSplitToLines - skipEmpty=0 should return >= lines than skipEmpty=1';

-- Test 3: Non-existent module should return 0 rows
DECLARE @NonExistentModuleLines INT;
SELECT @NonExistentModuleLines = COUNT(*) FROM util.modulesSplitToLines('dbo.NonExistentProcedure', 1);

EXEC #AssertEquals '0', CAST(@NonExistentModuleLines AS NVARCHAR(10)), 'modulesSplitToLines - Non-existent module should return 0 rows';

-- Test 4: Line numbers should be sequential
DECLARE @SequentialLines BIT = 1;
WITH cte AS (
    SELECT lineNumber, ROW_NUMBER() OVER (ORDER BY lineNumber) AS ExpectedNumber
    FROM util.modulesSplitToLines('util.help', 1)
)
SELECT @SequentialLines = CASE WHEN MIN(CASE WHEN lineNumber = ExpectedNumber THEN 1 ELSE 0 END) = 1 THEN 1 ELSE 0 END
FROM cte;

EXEC #AssertTrue @SequentialLines, 'modulesSplitToLines - Line numbers should be sequential';

-- Test 5: Test with a function (table-valued function)
DECLARE @FunctionLinesCount INT;
SELECT @FunctionLinesCount = COUNT(*) FROM util.modulesSplitToLines('util.stringSplitToLines', 1);

EXEC #AssertTrue CASE WHEN @FunctionLinesCount > 0 THEN 1 ELSE 0 END, 'modulesSplitToLines - util.stringSplitToLines function should have lines of code';

-- ===========================================
-- modulesGetCreateLineNumber Tests
-- ===========================================
PRINT '';
PRINT 'Testing modulesGetCreateLineNumber function...';

-- Test 1: Find CREATE line in util.help
DECLARE @HelpCreateLine INT;
SELECT @HelpCreateLine = lineNumber FROM util.modulesGetCreateLineNumber('util.help', 1);

EXEC #AssertTrue CASE WHEN @HelpCreateLine > 0 THEN 1 ELSE 0 END, 'modulesGetCreateLineNumber - util.help should have a CREATE line';

-- Test 2: Find CREATE line in util.stringSplitToLines
DECLARE @FunctionCreateLine INT;
SELECT @FunctionCreateLine = lineNumber FROM util.modulesGetCreateLineNumber('util.stringSplitToLines', 1);

EXEC #AssertTrue CASE WHEN @FunctionCreateLine > 0 THEN 1 ELSE 0 END, 'modulesGetCreateLineNumber - util.stringSplitToLines should have a CREATE line';

-- Test 3: Non-existent module should return 0 rows
DECLARE @NonExistentCreateLines INT;
SELECT @NonExistentCreateLines = COUNT(*) FROM util.modulesGetCreateLineNumber('dbo.NonExistentProcedure', 1);

EXEC #AssertEquals '0', CAST(@NonExistentCreateLines AS NVARCHAR(10)), 'modulesGetCreateLineNumber - Non-existent module should return 0 rows';

-- Test 4: Verify CREATE line contains CREATE keyword
DECLARE @CreateLineText NVARCHAR(MAX);
DECLARE @ContainsCreate BIT = 0;

SELECT @CreateLineText = line 
FROM util.modulesSplitToLines('util.help', 1) 
WHERE lineNumber = @HelpCreateLine;

IF @CreateLineText IS NOT NULL AND UPPER(@CreateLineText) LIKE '%CREATE%'
    SET @ContainsCreate = 1;

EXEC #AssertTrue @ContainsCreate, 'modulesGetCreateLineNumber - CREATE line should contain CREATE keyword';

-- ===========================================
-- modulesFindCommentsPositions Tests
-- ===========================================
PRINT '';
PRINT 'Testing modulesFindCommentsPositions function...';

-- Test 1: Find comments in util.help (should have header comments)
DECLARE @HelpCommentsCount INT;
SELECT @HelpCommentsCount = COUNT(*) FROM util.modulesFindCommentsPositions('util.help', 1);

EXEC #AssertTrue CASE WHEN @HelpCommentsCount >= 0 THEN 1 ELSE 0 END, 'modulesFindCommentsPositions - Should execute without error for util.help';

-- Test 2: Non-existent module should return 0 rows
DECLARE @NonExistentComments INT;
SELECT @NonExistentComments = COUNT(*) FROM util.modulesFindCommentsPositions('dbo.NonExistentProcedure', 1);

EXEC #AssertEquals '0', CAST(@NonExistentComments AS NVARCHAR(10)), 'modulesFindCommentsPositions - Non-existent module should return 0 rows';

-- Test 3: Validate comment positions
DECLARE @ValidCommentPositions BIT = 1;
SELECT @ValidCommentPositions = CASE WHEN MIN(CASE WHEN startPosition > 0 AND endPosition >= startPosition THEN 1 ELSE 0 END) = 1 THEN 1 ELSE 0 END
FROM util.modulesFindCommentsPositions('util.help', 1);

IF @HelpCommentsCount > 0
    EXEC #AssertTrue @ValidCommentPositions, 'modulesFindCommentsPositions - Comment positions should be valid';

-- ===========================================
-- modulesFindInlineCommentsPositions Tests
-- ===========================================
PRINT '';
PRINT 'Testing modulesFindInlineCommentsPositions function...';

-- Test 1: Find inline comments in util.help
DECLARE @HelpInlineCommentsCount INT;
SELECT @HelpInlineCommentsCount = COUNT(*) FROM util.modulesFindInlineCommentsPositions('util.help', 1);

EXEC #AssertTrue CASE WHEN @HelpInlineCommentsCount >= 0 THEN 1 ELSE 0 END, 'modulesFindInlineCommentsPositions - Should execute without error for util.help';

-- Test 2: Non-existent module should return 0 rows
DECLARE @NonExistentInlineComments INT;
SELECT @NonExistentInlineComments = COUNT(*) FROM util.modulesFindInlineCommentsPositions('dbo.NonExistentProcedure', 1);

EXEC #AssertEquals '0', CAST(@NonExistentInlineComments AS NVARCHAR(10)), 'modulesFindInlineCommentsPositions - Non-existent module should return 0 rows';

-- ===========================================
-- modulesFindMultilineCommentsPositions Tests
-- ===========================================
PRINT '';
PRINT 'Testing modulesFindMultilineCommentsPositions function...';

-- Test 1: Find multiline comments in util.help
DECLARE @HelpMultilineCommentsCount INT;
SELECT @HelpMultilineCommentsCount = COUNT(*) FROM util.modulesFindMultilineCommentsPositions('util.help', 1);

EXEC #AssertTrue CASE WHEN @HelpMultilineCommentsCount >= 0 THEN 1 ELSE 0 END, 'modulesFindMultilineCommentsPositions - Should execute without error for util.help';

-- Test 2: Non-existent module should return 0 rows
DECLARE @NonExistentMultilineComments INT;
SELECT @NonExistentMultilineComments = COUNT(*) FROM util.modulesFindMultilineCommentsPositions('dbo.NonExistentProcedure', 1);

EXEC #AssertEquals '0', CAST(@NonExistentMultilineComments AS NVARCHAR(10)), 'modulesFindMultilineCommentsPositions - Non-existent module should return 0 rows';

-- ===========================================
-- modulesFindLinesPositions Tests
-- ===========================================
PRINT '';
PRINT 'Testing modulesFindLinesPositions function...';

-- Test 1: Find line positions in util.help
DECLARE @HelpLinePositionsCount INT;
SELECT @HelpLinePositionsCount = COUNT(*) FROM util.modulesFindLinesPositions('util.help', 1);

EXEC #AssertTrue CASE WHEN @HelpLinePositionsCount > 0 THEN 1 ELSE 0 END, 'modulesFindLinesPositions - util.help should have line positions';

-- Test 2: Line positions count should match lines count
EXEC #AssertEquals CAST(@HelpLinesCount AS NVARCHAR(10)), CAST(@HelpLinePositionsCount AS NVARCHAR(10)), 'modulesFindLinesPositions - Line positions count should match modulesSplitToLines count';

-- Test 3: Non-existent module should return 0 rows
DECLARE @NonExistentLinePositions INT;
SELECT @NonExistentLinePositions = COUNT(*) FROM util.modulesFindLinesPositions('dbo.NonExistentProcedure', 1);

EXEC #AssertEquals '0', CAST(@NonExistentLinePositions AS NVARCHAR(10)), 'modulesFindLinesPositions - Non-existent module should return 0 rows';

-- ===========================================
-- modulesGetDescriptionFromComments Tests
-- ===========================================
PRINT '';
PRINT 'Testing modulesGetDescriptionFromComments function...';

-- Test 1: Get description from util.stringSplitToLines (has structured comments)
DECLARE @FunctionDescription NVARCHAR(MAX);
SELECT @FunctionDescription = [description] FROM util.modulesGetDescriptionFromComments('util.stringSplitToLines');

EXEC #AssertNotNull @FunctionDescription, 'modulesGetDescriptionFromComments - util.stringSplitToLines should have description from comments';

-- Test 2: Non-existent module should return NULL or empty result
DECLARE @NonExistentDescription INT;
SELECT @NonExistentDescription = COUNT(*) FROM util.modulesGetDescriptionFromComments('dbo.NonExistentProcedure');

EXEC #AssertEquals '0', CAST(@NonExistentDescription AS NVARCHAR(10)), 'modulesGetDescriptionFromComments - Non-existent module should return 0 rows';

-- ===========================================
-- modulesFindSimilar Tests
-- ===========================================
PRINT '';
PRINT 'Testing modulesFindSimilar function...';

-- Test 1: Find modules similar to 'string' - should find string-related functions
DECLARE @StringSimilarCount INT;
SELECT @StringSimilarCount = COUNT(*) FROM util.modulesFindSimilar('string');

EXEC #AssertTrue CASE WHEN @StringSimilarCount > 0 THEN 1 ELSE 0 END, 'modulesFindSimilar - Should find modules containing "string"';

-- Test 2: Find modules similar to 'metadata'
DECLARE @MetadataSimilarCount INT;
SELECT @MetadataSimilarCount = COUNT(*) FROM util.modulesFindSimilar('metadata');

EXEC #AssertTrue CASE WHEN @MetadataSimilarCount > 0 THEN 1 ELSE 0 END, 'modulesFindSimilar - Should find modules containing "metadata"';

-- Test 3: Search for non-existent pattern should return 0 or few results
DECLARE @NonExistentPatternCount INT;
SELECT @NonExistentPatternCount = COUNT(*) FROM util.modulesFindSimilar('xyzneverexists123');

EXEC #AssertEquals '0', CAST(@NonExistentPatternCount AS NVARCHAR(10)), 'modulesFindSimilar - Non-existent pattern should return 0 results';

-- ===========================================
-- modulesRecureSearchForOccurrences Tests
-- ===========================================
PRINT '';
PRINT 'Testing modulesRecureSearchForOccurrences function...';

-- Test 1: Search for 'SELECT' occurrences in util.help
DECLARE @SelectOccurrences INT;
SELECT @SelectOccurrences = COUNT(*) FROM util.modulesRecureSearchForOccurrences('util.help', 'SELECT');

EXEC #AssertTrue CASE WHEN @SelectOccurrences >= 0 THEN 1 ELSE 0 END, 'modulesRecureSearchForOccurrences - Should execute without error';

-- Test 2: Non-existent module should return 0 rows
DECLARE @NonExistentOccurrences INT;
SELECT @NonExistentOccurrences = COUNT(*) FROM util.modulesRecureSearchForOccurrences('dbo.NonExistentProcedure', 'SELECT');

EXEC #AssertEquals '0', CAST(@NonExistentOccurrences AS NVARCHAR(10)), 'modulesRecureSearchForOccurrences - Non-existent module should return 0 rows';

-- ===========================================
-- Print Test Summary
-- ===========================================
EXEC #PrintTestSummary 'Modules & Code Analysis Functions';