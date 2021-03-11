USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_get_company_email_address]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_get_company_email_address]  @company_id          int,
                                          @email_address    varchar(100) OUTPUT
as

set nocount on 

select @email_address = right(address_5, len(address_5) - 7)  
from company
where company_id = @company_id

return 0
GO
