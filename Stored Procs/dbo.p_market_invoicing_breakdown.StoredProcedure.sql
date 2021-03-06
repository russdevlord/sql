/****** Object:  StoredProcedure [dbo].[p_market_invoicing_breakdown]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_market_invoicing_breakdown]
GO
/****** Object:  StoredProcedure [dbo].[p_market_invoicing_breakdown]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE    PROC [dbo].[p_market_invoicing_breakdown] @campaign_no	integer
    
as

declare		@product_desc 				varchar(100),
					@market_no						integer,
					@market_desc					varchar(50),
					@charge_rate					decimal(18,2),
					@media_product_id			integer,
					@screening_date				datetime,
					@screening_month			varchar(30),
					@screening_period			varchar(30),
					@billing_period					datetime

create table #screening_summary
(	
	market_no		 				int,
	market_desc					varchar(50),
	charge_rate					decimal(18,2),
	media_product_id			integer, 
	screening_date				datetime,
	screening_month			varchar(30),
	screening_period			varchar(30),
	billing_period					datetime
)

declare		market_csr cursor static for
select			distinct fm.film_market_no, 
					film_market_desc,
					op.media_product_id
from			outpost_spot spot,
					film_market fm,
					outpost_venue cmpl,
					outpost_player op,
					outpost_player_xref opx
where			spot.outpost_panel_id = opx.outpost_panel_id 
and				opx.player_name = op.player_name
and 				cmpl.market_no = fm.film_market_no
and				spot.campaign_no = @campaign_no
and				cmpl.outpost_venue_id = op.outpost_venue_id
union
select			distinct fm.film_market_no, 
					film_market_desc,
					10
from			inclusion_spot spot,
					film_market fm,
					outpost_venue cmpl
where			spot.outpost_venue_id = cmpl.outpost_venue_id
and 				cmpl.market_no = fm.film_market_no
and				spot.campaign_no = @campaign_no
and				inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 18)
order by		fm.film_market_no


declare			screening_date_csr cursor static for
select				distinct screening_date, billing_period
from				outpost_spot spot
where				spot.campaign_no = @campaign_no 
and					spot.spot_status not in ('D') 
and					spot.spot_type not in ('B')

open market_csr
fetch market_csr into @market_no, @market_desc, @media_product_id
while(@@fetch_status = 0)
begin

	open screening_date_csr
	fetch screening_date_csr into @screening_date, @billing_period
	while(@@fetch_status = 0)
	begin
		
		if @media_product_id != 10
		begin			
			select			@charge_rate = isnull(sum(spot.charge_rate),0) 
			from			outpost_spot spot,
								outpost_venue cmpl,
								outpost_player_xref opx,
								outpost_player op
			where			spot.campaign_no = @campaign_no 
			and				spot.outpost_panel_id = opx.outpost_panel_id 
			and				opx.player_name = op.player_name 
			and				op.outpost_venue_id = cmpl.outpost_venue_id 
			and				cmpl.market_no = @market_no 
			and				op.media_product_id = @media_product_id 
			and				spot.spot_status not in ('D')
			and				spot.screening_date = @screening_date
			and				spot.billing_period = @billing_period
		end
				 
		if @media_product_id = 10
		begin 
			select			@charge_rate = isnull(sum(spot.charge_rate),0)
			from			inclusion_spot spot,   
								outpost_venue cmpl,
								inclusion inc
			where			spot.outpost_venue_id = cmpl.outpost_venue_id 
			and				spot.campaign_no = @campaign_no 
			and				cmpl.market_no = @market_no 
			and				spot.spot_status not in ('D') 
			and				inc.inclusion_id = spot.inclusion_id 
			and				inc.inclusion_type = 18
			and				spot.screening_date = @screening_date
			and				spot.billing_period = @billing_period
		end
			
		select			@screening_month = (DateName( month , DateAdd( month , period_no , -1))),
							@screening_period = (convert(char(6), start_date, 106) + ' - ' + convert(char(6), end_date, 106))
	    from			accounting_period
	    where			@billing_period = end_date
	

		insert into #screening_summary
		(	market_no,
			market_desc,
			charge_rate,
			media_product_id, 
			screening_date,
			screening_month,
			screening_period,
			billing_period
		) 
		values 
		(	@market_no,
			@market_desc,
			@charge_rate,
			@media_product_id, 
			@screening_date,
			@screening_month,
			@screening_period,
			@billing_period
		) 
			
		fetch screening_date_csr into @screening_date, @billing_period
			
	end 
		
	close screening_date_csr
		
	fetch market_csr into @market_no, @market_desc, @media_product_id
end 
	
deallocate market_csr 
deallocate screening_date_csr

select			market_no,
					market_desc,
					ISNULL( SUM(charge_rate), 0) as charge_rate,
					mp.media_product_id,
					mp.media_product_desc,
					screening_month,
					screening_period,
					max(YEAR(billing_period)) as year,
					billing_period
from			#screening_summary, media_product mp
WHERE		#screening_summary.media_product_id = mp.media_product_id
GROUP BY	market_no,
					market_desc,
					mp.media_product_id,
					mp.media_product_desc,
					screening_month,
					screening_period,
					billing_period
order by		media_product_desc, 
					market_no,
					billing_period
GO
