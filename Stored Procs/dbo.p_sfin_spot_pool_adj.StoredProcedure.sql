/****** Object:  StoredProcedure [dbo].[p_sfin_spot_pool_adj]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_spot_pool_adj]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_spot_pool_adj]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_spot_pool_adj] @spot_id			integer,
                                 @full_adj		char(1),
                                 @adj_amount		money,
				@adj_type		char(1)
as
set nocount on 
/*
 * Declare Valiables
 */ 

declare @error							integer,
	     @sqlstatus					integer,
        @errorode							integer,
        @pool_csr_open				tinyint,
        @spot_pool_id				integer,
        @complex_id					integer,
        @loop							integer,
        @complex_count				integer,
        @complex_amount				money,
        @total_amount				money,
        @pool_tot						money,
        @sound_adj					money,
        @cinema_adj					money,
        @slide_adj					money,
        @total_adj					money,
        @alloc_amount				money,
        @ratio							numeric(15,8)

/*
 * Calculate Totals
 */

select @alloc_amount = @adj_amount

select @pool_tot = isnull(sum(ssp.total_amount),0)
  from slide_spot_pool ssp
 where ssp.spot_id = @spot_id

select @complex_count = isnull(count(distinct ssp.complex_id),0)
  from slide_spot_pool ssp
 where ssp.spot_id = @spot_id

if((@pool_tot - @adj_amount) < 0)
begin
	raiserror ('Spot Pool Adjustment Error. Adjustment amount is too large.', 16, 1)
	return -1
end

/*
 * Initialise Variables
 */

select @pool_csr_open = 0,
       @loop = 0,
	    @sound_adj = 0,
	    @cinema_adj = 0,
	    @slide_adj = 0

/*
 * Begin Transaction
 */

begin transaction

/*
 * Loop Spot Pools
 * ---------------
 * Loop the spot pools distributing either the full amount or a pro-rata
 * of the amount passed in.
 *
 */
 declare pool_csr cursor static for
  select ssp.complex_id,
         isnull(sum(ssp.total_amount),0)
    from slide_spot_pool ssp
   where ssp.spot_id = @spot_id
group by ssp.complex_id
order by ssp.complex_id
     for read only

open pool_csr
select @pool_csr_open = 1
fetch pool_csr into @complex_id, @complex_amount
while (@@fetch_status = 0)
begin

	select @loop = @loop + 1

	/*
    * Calculate Adjustment Amounts
    */

	if(@full_adj = 'Y')
		select @total_adj = @complex_amount * -1
	else
	begin

		if(@complex_count = @loop)
			select @total_adj = @alloc_amount * -1
		else
		begin
			select @ratio = convert(decimal(15,8),(convert(decimal(15,8),@complex_amount) / convert(decimal(15,8),@pool_tot)))
	      select @total_adj = round(@ratio * @alloc_amount,2)
         select @total_adj = @total_adj * -1
		end

		select @alloc_amount = @alloc_amount + @total_adj
		select @pool_tot = @pool_tot - @complex_amount

	end

	/*
    * Get Sequence No for Slide Spot Pool
    */

	execute @errorode = p_get_sequence_number 'slide_spot_pool', 5, @spot_pool_id OUTPUT
	if (@errorode !=0)
	begin
		rollback transaction
		goto error
	end

	/*
    * Create Spot Pool Record
    */

	insert into slide_spot_pool (
          slide_spot_pool_id,
          spot_id,
          complex_id,
          sound_amount,
          cinema_amount,
          slide_amount,
          total_amount,
          spot_pool_type ) values (
	       @spot_pool_id,
			 @spot_id,
			 @complex_id,
			 @sound_adj,
			 @cinema_adj,
			 @slide_adj,
          @total_adj,
			 @adj_type )

	select @error = @@error
	if (@error !=0)
	begin
		rollback transaction
		goto error
	end	

	/*
    * Fetch Next
    */

	fetch pool_csr into @complex_id, @complex_amount

end
close pool_csr
deallocate pool_csr
select @pool_csr_open = 0

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@pool_csr_open = 1)
   begin
		close pool_csr
		deallocate pool_csr
	end

	return -1
GO
