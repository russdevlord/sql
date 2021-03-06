/****** Object:  StoredProcedure [dbo].[p_add_bonus_spot_liability]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_add_bonus_spot_liability]
GO
/****** Object:  StoredProcedure [dbo].[p_add_bonus_spot_liability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_add_bonus_spot_liability]		@billing_period		datetime

as

declare		@error					int,
			@spot_liability_id		int,
			@spot_id				int,
			@complex_id				int,
			@liability_type			int,
			@allocation_id			int,
			@creation_period		datetime,
			@origin_period			datetime,
			@release_period			datetime,
			@spot_amount			money,
			@cinema_amount			money,
			@cinema_rent			money,
			@cancelled				int,
			@original_liability		int
			
set nocount on

declare		spot_csr cursor forward_only for 
select		spot_id,
			charge_rate,
			cinema_rate,
			complex_id,
			benchmark_end
from		campaign_spot,
			film_screening_date_xref 
where		campaign_spot.screening_date = film_screening_date_xref.screening_date
and			spot_status = 'X' 
and			spot_id not in (select spot_id from v_spot_util_liab) 
and			campaign_spot.screening_date >= '27-dec-2012'
and			campaign_no not in (select campaign_no from film_Campaign where campaign_type > 4) 
and			billing_period <= @billing_period
group by	spot_id,
			charge_rate,
			cinema_rate,
			complex_id,
			benchmark_end
order by	spot_id
for			read only

begin transaction

open spot_csr
fetch spot_csr into @spot_id, @spot_amount, @cinema_amount, @complex_id, @origin_period
while (@@fetch_status = 0)
begin

			execute @error = p_get_sequence_number 'spot_liability', 5, @spot_liability_id OUTPUT
			if(@error !=0)
			begin
				rollback transaction
				raiserror ('Error getting seq no', 16, 1)
				return -1
			end
                
			/*
			 * Insert Liability Record
			 */
		
			insert into spot_liability (
						spot_liability_id,
						spot_id,
						complex_id,
						liability_type,
						allocation_id,
						creation_period,
						origin_period,
						release_period,
						spot_amount,
						cinema_amount,
						cinema_rent,
						cancelled,
						original_liability	 ) values (
						@spot_liability_id,
						@spot_id,
						@complex_id,
						1,
						null,
						@origin_period,
						@origin_period,
						@origin_period,
						@spot_amount,
						@cinema_amount,
						0,
						0,
						0)
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				raiserror ('Error inserting liab', 16, 1)
				return -1
			end

	fetch spot_csr into @spot_id, @spot_amount, @cinema_amount, @complex_id, @origin_period
end

commit transaction
return 0
GO
