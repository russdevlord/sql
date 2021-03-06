/****** Object:  StoredProcedure [dbo].[p_spots_not_in_bill]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_spots_not_in_bill]
GO
/****** Object:  StoredProcedure [dbo].[p_spots_not_in_bill]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_spots_not_in_bill] 	
as

declare 		@campaign_no			integer,
				@start_date				datetime,
				@end_date				datetime,
				@billing_period		datetime,
				@billing_date			datetime,
				@assosciated_bp		datetime,
				@spot_id					integer,
				@spot_status			char(1),
				@tran_id					integer,
				@spot_type				char(1),
				@charge_rate			money


create table #spot_table
(
	spot_id					integer			null,
	tran_id					integer			null,
	spot_status				char(1)			null,
	spot_type				char(1)			null,
	charge_rate				money				null,
	campaign_no				integer  		null,
	start_date				datetime			null,
	end_date					datetime			null,
	billing_period			datetime			null,
	billing_date			datetime			null,
	assosciated_bp			datetime			null
)

declare spot_csr cursor static for
select	billing_date,
		billing_period,
		campaign_no,
		spot_id,
        spot_status,
        tran_id,
		spot_type,
		charge_rate
from	campaign_spot
for read only

open spot_csr
fetch spot_csr into @billing_date, @billing_period, @campaign_no, @spot_id, @spot_status, @tran_id, @spot_type, @charge_rate

while (@@fetch_status = 0)
begin

	select @assosciated_bp = ap.end_date,
			 @start_date = ap.start_date,
			 @end_date = ap.end_date
	  from accounting_period ap
	 where @billing_date >= ap.start_date and
			 @billing_date <= ap.end_date

	if @billing_period > @assosciated_bp
	begin
		insert into #spot_table
			(
			spot_id,
			tran_id,
			spot_status,
			spot_type,
			charge_rate,
			campaign_no,
			start_date,
			end_date,
			billing_period,
			billing_date,
			assosciated_bp
			) values
			(
			@spot_id,
			@tran_id,
			@spot_status,
			@spot_type,
			@charge_rate,
			@campaign_no,
			@start_date,
			@end_date,
			@billing_period,
			@billing_date,
			@assosciated_bp
			)
	end
		fetch spot_csr into @billing_date, @billing_period, @campaign_no, @spot_id, @spot_status, @tran_id, @spot_type, @charge_rate
	
end

close spot_csr
deallocate spot_csr

select spot_id,
		 tran_id,
		 spot_status,
		 spot_type,
		 charge_rate,
		 campaign_no,
		 billing_date,
		 billing_period,
		 assosciated_bp
  from #spot_table
order by campaign_no,
			billing_date

return 0
GO
