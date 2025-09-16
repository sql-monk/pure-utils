

USE model; 
GO
USE model; 
GO
CREATE OR ALTER     FUNCTION [util].[modulesRecureSearchStartEndPositions](@startValue NVARCHAR(32), @endValue NVARCHAR(32))
RETURNS TABLE
AS
RETURN(SELECT object_id, startPosition, endPosition FROM util.modulesRecureSearchStartEndPositionsExtended (@startValue, @endValue, DEFAULT, DEFAULT) );
GO

