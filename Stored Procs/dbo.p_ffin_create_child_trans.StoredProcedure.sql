/****** Object:  StoredProcedure [dbo].[p_ffin_create_child_trans]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_create_child_trans]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_create_child_trans]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_ffin_create_child_trans]   @accounting_period		datetime,
                                        @campaign_no            int,
                                        @parent_tran_id         int,
                                        @tran_date              datetime,
                                        @child_tran_id          int OUTPUT

as

declare		@alloc_date		datetime


select @alloc_date = getdate()

set nocount on

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode						int,
        @track_id					int,
        @track_desc					varchar(255),
        @track_qty					int,
        @track_charge				money,
        @nett_charge				money,
        @tran_code					varchar(5),
        @child_tran_code            varchar(5),
        @track_csr_open				tinyint,
        @tran_id					int,
        @acomm_id                   int,
        @acomm_nett					money,
        @tran_notes                 varchar(255),
        @track_acomm                numeric(6,4),
        @acomm_tran_code            varchar(5),
        @parent_trantype_id         integer,
        @enforce_tran_relationship  char(1),
        @relationship_type          char(1),
        @trantype_desc              varchar(50),
		@account_id					int


        select  @child_tran_code = tt.trantype_code,
                @trantype_desc = tt.trantype_desc + ' (Ref ' + convert(varchar(7),@parent_tran_id) + ')',
                @relationship_type = ttc.relationship_type,
				@account_id = ct.account_id
        from    campaign_transaction ct,
                transaction_type tt,
                transaction_type_children ttc
        where   ct.tran_id = @parent_tran_id
        and     ct.tran_type = ttc.parent_trantype_id
        and     tt.trantype_id = ttc.child_trantype_id

        
        if @relationship_type = 'A' -- A=Agency Commission
		begin

            select  @track_acomm = fc.commission
            from    film_campaign fc
            where   fc.campaign_no = @campaign_no

            select  @nett_charge = isnull(nett_amount,0)
            from    campaign_transaction
            where   tran_id = @parent_tran_id
			
		    select @acomm_nett = round(@nett_charge * @track_acomm,2) * -1

			exec @errorode = p_ffin_create_transaction @child_tran_code,
													@campaign_no,
													@account_id,
												 	@tran_date,
													@trantype_desc,
                                                    null,
													@acomm_nett,
													null,
													'Y',
													@child_tran_id OUTPUT
			if(@errorode !=0)
			begin
				goto error
			end

		   /*
			*	Allocate child tran to parent tran
			*/

			exec @errorode = p_ffin_allocate_transaction @child_tran_id, @parent_tran_id, @acomm_nett, @alloc_date
			if(@errorode !=0)
			begin
				goto error
			end
        end

return 0

/*
 * Error Handler
 */

error:
	 return -1
GO
