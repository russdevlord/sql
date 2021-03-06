/****** Object:  StoredProcedure [dbo].[p_accpac_create_adv_dist]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_accpac_create_adv_dist]
GO
/****** Object:  StoredProcedure [dbo].[p_accpac_create_adv_dist]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_accpac_create_adv_dist] 		@country_code			char(1),
											@business_unit_id		integer,
											@complex_id				integer,
											@accounting_period		datetime,
											@adv_amount				money,
                                            @media_product_id       int
									
as

set nocount on

declare		@error								int,
			--@error									int,
			@gl_code							char(4)

begin transaction

select @gl_code = '10'

if @adv_amount != 0
begin

	insert into accpac_integration..advance_distribution
	(gl_account,
	 date,
	 amount,
	 status,
     country_code) values
	(dbo.f_gl_account(null, @gl_code, @business_unit_id, @complex_id, @media_product_id),
	 @accounting_period,
	 @adv_amount,
	 'N',
     @country_code)

	select @error = @@error
	if @error != 0 
	begin
		raiserror ('Error inserting information into advance_distribution', 16, 1)
		goto error
	end
end


commit transaction
return 0

error:
	rollback transaction
	return -1
GO
