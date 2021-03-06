/****** Object:  StoredProcedure [dbo].[p_sfin_non_trading_transfer]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_non_trading_transfer]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_non_trading_transfer]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_non_trading_transfer] @campaign_no		    char(7),
													 @cost_centre	 	    char(2),
													 @cost_account		    char(4),
													 @amount				    money,
													 @tran_date			    datetime,
													 @comment			    varchar(50),
													 @target_campaign_no  char(7),
													 @target_cost_centre	 char(2),
													 @target_cost_account char(4),
													 @batch_item_no	    integer,
													 @payment_source_id	 integer

as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode							int,
        @negative_amount			money,
        @nt_group_no					int
/*
 * Begin Transaction
 */

begin transaction

--Get a group no for the transfer
execute @errorode = p_get_sequence_number 'nt_group_no',5,@nt_group_no OUTPUT
if (@errorode !=0)
begin
	rollback transaction
	return -1
end

select @negative_amount = @amount * -1

exec @errorode = p_sfin_non_trading @campaign_no,
	                              @cost_centre,
                                 @cost_account,
                                 @negative_amount,
                                 @tran_date,
										   @comment,
										   'N',
										   null,
                                 @batch_item_no,
                                 @nt_group_no,
											@payment_source_id
if @errorode != 0
begin
	rollback transaction
	return -1
end


exec @errorode = p_sfin_non_trading @target_campaign_no,
	                              @target_cost_centre,
                                 @target_cost_account,
                                 @amount,
                                 @tran_date,
										   @comment,
										   'N',
										   null,
                                 @batch_item_no,
                                 @nt_group_no,
											@payment_source_id

if @errorode != 0
begin
	rollback transaction
	return -1
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
