USE model; 
GO
CREATE OR ALTER     FUNCTION [util].[modulesFindInlineCommentsPositions](@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(SELECT object_id, startPosition, endPosition FROM util.modulesRecureSearchStartEndPositionsExtended ('--', CHAR (10), 1, @objectId) );
GO

