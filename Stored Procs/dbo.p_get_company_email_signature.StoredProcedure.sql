/****** Object:  StoredProcedure [dbo].[p_get_company_email_signature]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_company_email_signature]
GO
/****** Object:  StoredProcedure [dbo].[p_get_company_email_signature]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_get_company_email_signature]		@company_id            int,
																									@sign_line1				varchar(100) OUTPUT,
																									@sign_line2				varchar(100) OUTPUT,
																									@sign_line3				varchar(100) OUTPUT,
																									@sign_line4				varchar(100) OUTPUT,
																									@sign_line5				varchar(100) OUTPUT,
																									@sign_line6				varchar(100) OUTPUT,
																									@sign_line7				varchar(100) OUTPUT,
																									@sign_line8				varchar(100) OUTPUT
as

set nocount on 


declare	@branch_code						char(1),
		        @company_email_address	varchar(150),
				@company_name					varchar(50)

select		@sign_line1 = 'Accounts'

select		@sign_line2 = company_desc,
				@sign_line3 = address_1,
				@sign_line4 = address_2,
				@sign_line5 = address_3,
				@sign_line6 = address_4,
				@sign_line7 = address_5,
				@sign_line8 = website
from		company
where		company_id = @company_id


return 0
GO
