/****** Object:  StoredProcedure [dbo].[p_select_test]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_select_test]
GO
/****** Object:  StoredProcedure [dbo].[p_select_test]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_select_test]	@accounting_period		datetime

as

select screening_date from film_screening_date_xref where benchmark_end = @accounting_period

return 0
GO
