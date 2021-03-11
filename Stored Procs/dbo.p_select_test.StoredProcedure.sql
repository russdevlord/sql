USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_select_test]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_select_test]	@accounting_period		datetime

as

select screening_date from film_screening_date_xref where benchmark_end = @accounting_period

return 0
GO
