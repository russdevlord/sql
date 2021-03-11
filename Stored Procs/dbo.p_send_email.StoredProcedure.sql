USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_send_email]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_send_email]		@email_recipients			varchar(max),
							@email_body					varchar(max),
							@email_subject				varchar(max)

as

EXEC msdb..sp_send_dbmail 
@recipients=@email_recipients,
@subject=@email_subject,
@body=@email_body

return 0
GO
