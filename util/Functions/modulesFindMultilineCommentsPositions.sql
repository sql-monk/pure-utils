USE model; 
GO
CREATE OR ALTER     FUNCTION [util].[modulesFindMultilineCommentsPositions](@objectId INT = NULL)
RETURNS TABLE
AS
RETURN(SELECT object_id, startPosition, endPosition FROM util.modulesRecureSearchStartEndPositionsExtended ('/*', '*/', DEFAULT, @objectId) );
GO

