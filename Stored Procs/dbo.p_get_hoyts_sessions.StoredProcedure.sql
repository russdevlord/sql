/****** Object:  StoredProcedure [dbo].[p_get_hoyts_sessions]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_hoyts_sessions]
GO
/****** Object:  StoredProcedure [dbo].[p_get_hoyts_sessions]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_get_hoyts_sessions]	@screening_date				datetime

as

declare				@obj								int,
						@surl								varchar(max),
						@response						varchar(max),
						@complex_code				varchar(max),
						@day_date						date

select				@day_date = '18-oct-2017',
						@complex_code = '22PEN'

select		@surl = 'http://hoyauctrl/sessiondata/Session.svc/getalldata?Param1=' + convert(varchar(20), @day_date) + '?Param2=' + @complex_code

exec			sp_OACreate 'MSXML2.ServeXMLHttp', @obj OUT
exec			sp_OAMethod @obj, 'Ppen', NULL, 'Get', @surl, false
exec			sp_OAMethod @obj, 'send'
exec			sp_OAGetProperty @obj, 'responseText', @response OUT

select		@response as response
exec			sp_OADestroy @obj

return 0
GO
