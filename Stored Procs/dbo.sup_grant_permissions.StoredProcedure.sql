/****** Object:  StoredProcedure [dbo].[sup_grant_permissions]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[sup_grant_permissions]
GO
/****** Object:  StoredProcedure [dbo].[sup_grant_permissions]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  proc [dbo].[sup_grant_permissions]
as	

declare @grantPermsSql nvarchar(max) = ''
DECLARE @User VARCHAR(25);

SELECT @User = 'Public';

SELECT	@grantPermsSql = @grantPermsSql +
		'GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON [' + t.TABLE_SCHEMA + '].[' + t.TABLE_NAME + '] TO [' + @User + ']; '  + char(13) + char(10)
FROM	INFORMATION_SCHEMA.TABLES t
WHERE	t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_CATALOG, t.TABLE_SCHEMA, t.TABLE_TYPE, t.TABLE_NAME

SELECT	@grantPermsSql = @grantPermsSql +
		'GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON [' + t.TABLE_SCHEMA + '].[' + t.TABLE_NAME + '] TO [' + @User + ']; '  + char(13) + char(10)
FROM	INFORMATION_SCHEMA.TABLES t
WHERE	t.TABLE_TYPE = 'VIEW'
ORDER BY t.TABLE_CATALOG, t.TABLE_SCHEMA, t.TABLE_TYPE, t.TABLE_NAME

-- Table Functions
SELECT	 @grantPermsSql = @grantPermsSql +
		-- 'GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON [' + r.SPECIFIC_SCHEMA + '].[' + r.SPECIFIC_NAME + '] TO [' + @User + ']; '  + char(13) + char(10)
		'GRANT REFERENCES, EXECUTE ON [' + r.SPECIFIC_SCHEMA + '].[' + r.SPECIFIC_NAME + '] TO [' + @User + ']; '  + char(13) + char(10)
FROM	INFORMATION_SCHEMA.ROUTINES r
WHERE	r.ROUTINE_TYPE = 'FUNCTION'
and		DATA_TYPE <> 'TABLE'  -- DYI 2013-04-08
AND		r.SPECIFIC_NAME not like 'find_regular_expression' 
AND		r.SPECIFIC_NAME not like 'isUUID'
AND		r.SPECIFIC_NAME not like 'fn_diagramobjects'
AND		r.SPECIFIC_NAME not like 'Concatenate'
ORDER BY r.SPECIFIC_CATALOG, r.SPECIFIC_SCHEMA, r.ROUTINE_TYPE, r.SPECIFIC_NAME

-- Scalar Functions
SELECT	@grantPermsSql = @grantPermsSql +
		'GRANT REFERENCES, SELECT  ON [' + r.SPECIFIC_SCHEMA + '].[' + r.SPECIFIC_NAME + '] TO [' + @User + ']; '  + char(13) + char(10)
FROM	INFORMATION_SCHEMA.ROUTINES r
WHERE	r.ROUTINE_TYPE = 'FUNCTION'
and		DATA_TYPE = 'TABLE'  -- DYI 2013-04-08
ORDER BY r.SPECIFIC_CATALOG, r.SPECIFIC_SCHEMA, r.ROUTINE_TYPE, r.SPECIFIC_NAME

SELECT	@grantPermsSql = @grantPermsSql +
		'GRANT EXECUTE ON [' + r.SPECIFIC_SCHEMA + '].[' + r.SPECIFIC_NAME + '] TO [' + @User + ']; '  + char(13) + char(10)
FROM	INFORMATION_SCHEMA.ROUTINES r
WHERE	r.ROUTINE_TYPE = 'PROCEDURE'
AND		r.SPECIFIC_NAME not like 'sp_%'
AND		r.SPECIFIC_NAME not like 'sup%'
ORDER BY r.SPECIFIC_CATALOG, r.SPECIFIC_SCHEMA, r.ROUTINE_TYPE, r.SPECIFIC_NAME

EXEC	sp_executesql @grantPermsSql

return 0
GO
