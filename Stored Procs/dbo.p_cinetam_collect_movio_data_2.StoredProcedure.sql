USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_collect_movio_data_2]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_collect_movio_data_2]		@screening_date    datetime,
																									@country_code			char(1)

as

declare		@error						int

return 0
GO
