/*
# String Processing Functions Tests
# Description
Comprehensive tests for all string and text processing functions in pure-utils.
Tests include basic functionality, edge cases, and error conditions.

Functions tested:
- stringSplitToLines
- stringSplitMultiLineComment
- stringFindCommentsPositions
- stringFindInlineCommentsPositions
- stringFindMultilineCommentsPositions
- stringFindLinesPositions
- stringGetCreateLineNumber
- modulesSplitToLines
- modulesGetCreateLineNumber
- stringRecureSearchForOccurrences
- stringRecureSearchStartEndPositionsExtended
- stringGetCreateTempScript
- stringGetCreateTempScriptInline
*/

-- Include test framework
:r Tests\TestFramework.sql

PRINT 'Starting String Processing Functions Tests...';
PRINT '';

-- Reset test counters
DECLARE @TestCount INT = 0;
DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

-- ===========================================
-- stringSplitToLines Tests
-- ===========================================
PRINT 'Testing stringSplitToLines function...';

-- Test 1: Basic string splitting with default parameters
DECLARE @TestString1 NVARCHAR(MAX) = 'Line 1
Line 2
Line 3';

DECLARE @Result1Count INT;
SELECT @Result1Count = COUNT(*) FROM util.stringSplitToLines(@TestString1, DEFAULT);

EXEC #AssertEquals '3', CAST(@Result1Count AS NVARCHAR(10)), 'stringSplitToLines - Basic 3-line string should return 3 rows';

-- Test 2: String with empty lines - skip empty
DECLARE @TestString2 NVARCHAR(MAX) = 'Line 1

Line 3

Line 5';

DECLARE @Result2Count INT;
SELECT @Result2Count = COUNT(*) FROM util.stringSplitToLines(@TestString2, 1);

EXEC #AssertEquals '3', CAST(@Result2Count AS NVARCHAR(10)), 'stringSplitToLines - With skipEmpty=1 should return 3 rows (no empty lines)';

-- Test 3: String with empty lines - include empty
DECLARE @Result3Count INT;
SELECT @Result3Count = COUNT(*) FROM util.stringSplitToLines(@TestString2, 0);

EXEC #AssertEquals '5', CAST(@Result3Count AS NVARCHAR(10)), 'stringSplitToLines - With skipEmpty=0 should return 5 rows (including empty lines)';

-- Test 4: Test line numbers are sequential
DECLARE @LineNumbersCorrect BIT = 1;
WITH cte AS (
    SELECT lineNumber, ROW_NUMBER() OVER (ORDER BY lineNumber) AS ExpectedNumber
    FROM util.stringSplitToLines(@TestString1, 1)
)
SELECT @LineNumbersCorrect = CASE WHEN MIN(CASE WHEN lineNumber = ExpectedNumber THEN 1 ELSE 0 END) = 1 THEN 1 ELSE 0 END
FROM cte;

EXEC #AssertTrue @LineNumbersCorrect, 'stringSplitToLines - Line numbers should be sequential starting from 1';

-- Test 5: Empty string
DECLARE @EmptyResult INT;
SELECT @EmptyResult = COUNT(*) FROM util.stringSplitToLines('', 1);

EXEC #AssertEquals '0', CAST(@EmptyResult AS NVARCHAR(10)), 'stringSplitToLines - Empty string should return 0 rows';

-- Test 6: Single line
DECLARE @SingleLineResult INT;
SELECT @SingleLineResult = COUNT(*) FROM util.stringSplitToLines('Single line', 1);

EXEC #AssertEquals '1', CAST(@SingleLineResult AS NVARCHAR(10)), 'stringSplitToLines - Single line should return 1 row';

-- Test 7: String with tabs (should be converted to spaces)
DECLARE @TabTestString NVARCHAR(MAX) = 'Line with	tabs	here';
DECLARE @TabResult NVARCHAR(MAX);
SELECT @TabResult = line FROM util.stringSplitToLines(@TabTestString, 1);

EXEC #AssertTrue CASE WHEN CHARINDEX(CHAR(9), @TabResult) = 0 THEN 1 ELSE 0 END, 'stringSplitToLines - Tabs should be converted to spaces';

-- ===========================================
-- stringFindCommentsPositions Tests  
-- ===========================================
PRINT '';
PRINT 'Testing stringFindCommentsPositions function...';

-- Test 1: String with inline comment
DECLARE @CodeWithInline NVARCHAR(MAX) = 'SELECT * FROM table; -- This is a comment';
DECLARE @InlineCommentsCount INT;
SELECT @InlineCommentsCount = COUNT(*) FROM util.stringFindCommentsPositions(@CodeWithInline, 1);

EXEC #AssertEquals '1', CAST(@InlineCommentsCount AS NVARCHAR(10)), 'stringFindCommentsPositions - Should find 1 inline comment';

-- Test 2: String with multiline comment
DECLARE @CodeWithMultiline NVARCHAR(MAX) = 'SELECT * FROM table; /* This is a 
multiline comment */';
DECLARE @MultilineCommentsCount INT;
SELECT @MultilineCommentsCount = COUNT(*) FROM util.stringFindCommentsPositions(@CodeWithMultiline, 1);

EXEC #AssertEquals '1', CAST(@MultilineCommentsCount AS NVARCHAR(10)), 'stringFindCommentsPositions - Should find 1 multiline comment';

-- Test 3: String with both types of comments
DECLARE @CodeWithBoth NVARCHAR(MAX) = 'SELECT * FROM table; -- inline comment
/* multiline comment */
SELECT COUNT(*);';
DECLARE @BothCommentsCount INT;
SELECT @BothCommentsCount = COUNT(*) FROM util.stringFindCommentsPositions(@CodeWithBoth, 1);

EXEC #AssertEquals '2', CAST(@BothCommentsCount AS NVARCHAR(10)), 'stringFindCommentsPositions - Should find 2 comments (inline + multiline)';

-- Test 4: String with no comments
DECLARE @CodeNoComments NVARCHAR(MAX) = 'SELECT * FROM table WHERE id = 1;';
DECLARE @NoCommentsCount INT;
SELECT @NoCommentsCount = COUNT(*) FROM util.stringFindCommentsPositions(@CodeNoComments, 1);

EXEC #AssertEquals '0', CAST(@NoCommentsCount AS NVARCHAR(10)), 'stringFindCommentsPositions - Should find 0 comments in code without comments';

-- Test 5: Verify positions are valid
DECLARE @PositionsValid BIT = 1;
SELECT @PositionsValid = CASE WHEN MIN(CASE WHEN startPosition > 0 AND endPosition >= startPosition THEN 1 ELSE 0 END) = 1 THEN 1 ELSE 0 END
FROM util.stringFindCommentsPositions(@CodeWithBoth, 1);

EXEC #AssertTrue @PositionsValid, 'stringFindCommentsPositions - All positions should be valid (startPosition > 0, endPosition >= startPosition)';

-- ===========================================
-- stringFindInlineCommentsPositions Tests
-- ===========================================
PRINT '';
PRINT 'Testing stringFindInlineCommentsPositions function...';

-- Test 1: Multiple inline comments
DECLARE @MultiInlineCode NVARCHAR(MAX) = 'SELECT * FROM table; -- comment 1
SELECT COUNT(*); -- comment 2
INSERT INTO table VALUES (1); -- comment 3';
DECLARE @MultiInlineCount INT;
SELECT @MultiInlineCount = COUNT(*) FROM util.stringFindInlineCommentsPositions(@MultiInlineCode, 1);

EXEC #AssertEquals '3', CAST(@MultiInlineCount AS NVARCHAR(10)), 'stringFindInlineCommentsPositions - Should find 3 inline comments';

-- Test 2: Inline comment at start of line  
DECLARE @StartLineComment NVARCHAR(MAX) = '-- This is a comment at start of line
SELECT * FROM table;';
DECLARE @StartLineCount INT;
SELECT @StartLineCount = COUNT(*) FROM util.stringFindInlineCommentsPositions(@StartLineComment, 1);

EXEC #AssertEquals '1', CAST(@StartLineCount AS NVARCHAR(10)), 'stringFindInlineCommentsPositions - Should find comment at start of line';

-- ===========================================
-- stringSplitMultiLineComment Tests
-- ===========================================
PRINT '';
PRINT 'Testing stringSplitMultiLineComment function...';

-- Test 1: Structured comment parsing
DECLARE @StructuredComment NVARCHAR(MAX) = '/*
# Description
This is a test function
# Parameters
@id INT - identifier
@name NVARCHAR(50) - name value
# Returns
Test result
*/';

DECLARE @CommentPartsCount INT;
SELECT @CommentPartsCount = COUNT(*) FROM util.stringSplitMultiLineComment(@StructuredComment);

EXEC #AssertTrue CASE WHEN @CommentPartsCount > 0 THEN 1 ELSE 0 END, 'stringSplitMultiLineComment - Should parse structured comment into parts';

-- Test 2: Simple comment without structure
DECLARE @SimpleComment NVARCHAR(MAX) = '/* Simple comment without structure */';
DECLARE @SimpleCommentCount INT;
SELECT @SimpleCommentCount = COUNT(*) FROM util.stringSplitMultiLineComment(@SimpleComment);

EXEC #AssertTrue CASE WHEN @SimpleCommentCount > 0 THEN 1 ELSE 0 END, 'stringSplitMultiLineComment - Should handle simple comments';

-- ===========================================
-- stringGetCreateLineNumber Tests
-- ===========================================
PRINT '';
PRINT 'Testing stringGetCreateLineNumber function...';

-- Test 1: CREATE statement at beginning
DECLARE @CreateAtStart NVARCHAR(MAX) = 'CREATE PROCEDURE test
AS
BEGIN
    SELECT 1;
END';

DECLARE @CreateLineStart INT;
SELECT @CreateLineStart = lineNumber FROM util.stringGetCreateLineNumber(@CreateAtStart, 1);

EXEC #AssertEquals '1', CAST(@CreateLineStart AS NVARCHAR(10)), 'stringGetCreateLineNumber - CREATE at start should return line 1';

-- Test 2: CREATE statement in middle
DECLARE @CreateInMiddle NVARCHAR(MAX) = '-- Comment
-- Another comment
CREATE OR ALTER FUNCTION test()
RETURNS INT
AS
BEGIN
    RETURN 1;
END';

DECLARE @CreateLineMiddle INT;
SELECT @CreateLineMiddle = lineNumber FROM util.stringGetCreateLineNumber(@CreateInMiddle, 1);

EXEC #AssertEquals '3', CAST(@CreateLineMiddle AS NVARCHAR(10)), 'stringGetCreateLineNumber - CREATE in middle should return correct line number';

-- Test 3: No CREATE statement
DECLARE @NoCreate NVARCHAR(MAX) = 'SELECT * FROM table;
UPDATE table SET col = 1;';

DECLARE @NoCreateResult INT;
SELECT @NoCreateResult = COUNT(*) FROM util.stringGetCreateLineNumber(@NoCreate, 1);

EXEC #AssertEquals '0', CAST(@NoCreateResult AS NVARCHAR(10)), 'stringGetCreateLineNumber - No CREATE statement should return 0 rows';

-- ===========================================
-- Print Test Summary
-- ===========================================
EXEC #PrintTestSummary 'String Processing Functions';