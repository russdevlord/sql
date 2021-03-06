/****** Object:  StoredProcedure [dbo].[p_get_company_email_address]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_company_email_address]
GO
/****** Object:  StoredProcedure [dbo].[p_get_company_email_address]    Script Date: 12/03/2021 10:03:49 AM ******/
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
