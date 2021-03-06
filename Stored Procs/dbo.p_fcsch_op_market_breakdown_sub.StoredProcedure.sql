/****** Object:  StoredProcedure [dbo].[p_fcsch_op_market_breakdown_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_fcsch_op_market_breakdown_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_fcsch_op_market_breakdown_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--USE [acceptance]
--GO
--/****** Object:  StoredProcedure [dbo].[p_fcsch_op_market_breakdown_sub]    Script Date: 05/12/2014 10:48:16 ******/
--SET ANSI_NULLS OFF
--GO
--SET QUOTED_IDENTIFIER OFF
--GO

CREATE    PROC [dbo].[p_fcsch_op_market_breakdown_sub] @campaign_no	integer
    
as

/*==============================================================*
 * DESC:- retrieves data required to display an invoice         *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  2   15-Feb-2011 DYI	Added break down by Media Product	*
 *                                                              *
 *==============================================================*/
 
 --drop table #screening_summary
 --declare @campaign_no int
 
 --set @campaign_no = 304582--204573
 


declare @product_desc 			varchar(100),
	@market_no			integer,
	@screened			integer,
	@bonus				integer,
	@screened_not_movie		integer,
	@charge_rate			decimal(18,2),
	@media_product_id		integer,
	@screening_date			datetime,
	@screening_month		varchar(30),
	@screening_period		varchar(30),
	@billing_period			datetime

begin

create table #screening_summary
(	market_no		 	int not null,
	screened			integer null,
	bonus				integer null,
	charge_rate			decimal(18,2) null,
	media_product_id	integer null, 
	screening_date		datetime,
	screening_month		varchar(30),
	screening_period	varchar(30),
	billing_period		datetime
)

select  @product_desc = fc.product_desc
from    film_campaign fc
where   fc.campaign_no = @campaign_no

declare	market_csr cursor static for
select			distinct fm.film_market_no, 
					op.media_product_id
from			outpost_spot spot,
					film_market fm,
					outpost_venue cmpl,
					outpost_player op,
					outpost_player_xref opx
where			spot.outpost_panel_id = opx.outpost_panel_id 
and				opx.player_name = op.player_name
and 			cmpl.market_no = fm.film_market_no
and				spot.campaign_no = @campaign_no
and				cmpl.outpost_venue_id = op.outpost_venue_id
union
select			distinct fm.film_market_no, 
					10
from			inclusion_spot spot,
					film_market fm,
					outpost_venue cmpl
where			spot.outpost_venue_id = cmpl.outpost_venue_id
and 			cmpl.market_no = fm.film_market_no
and				spot.campaign_no = @campaign_no
and				inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 18)
order by		fm.film_market_no

--declare screening date curser
declare	screening_date_csr cursor static for
select distinct screening_date, billing_period
from outpost_spot spot
where spot.campaign_no = @campaign_no and
spot.spot_status not in ('D') /*and
spot.spot_type not in ('B')*/

open market_csr
fetch market_csr into @market_no, @media_product_id
while(@@fetch_status = 0)
begin

	open screening_date_csr
		fetch screening_date_csr into @screening_date, @billing_period
		while(@@fetch_status = 0)
					begin

			if @media_product_id != 10
			begin			
				  select @screened = isnull(count(distinct spot.spot_id),0)
					from outpost_spot spot,
						 outpost_venue cmpl,
						 outpost_player_xref opx,
						 outpost_player op
				   where spot.campaign_no = @campaign_no and
						 spot.outpost_panel_id = opx.outpost_panel_id and
						 opx.player_name = op.player_name and
						 op.outpost_venue_id = cmpl.outpost_venue_id and
						 cmpl.market_no = @market_no and
						 op.media_product_id = @media_product_id and
   						 spot.spot_status not in ('D') and
						 spot.spot_type not in ('B')
						 and spot.screening_date = @screening_date
						 and spot.billing_period = @billing_period

				  select @bonus = isnull(count(distinct spot.spot_id),0)
					from outpost_spot spot,
						 outpost_venue cmpl,
						 outpost_player_xref opx,
						 outpost_player op
				   where spot.campaign_no = @campaign_no and
						 spot.outpost_panel_id = opx.outpost_panel_id and
						 opx.player_name = op.player_name and
						 op.outpost_venue_id = cmpl.outpost_venue_id and
						 cmpl.market_no = @market_no and
						 op.media_product_id = @media_product_id and
   						 spot.spot_status not in ('D') and
						 spot.spot_type in ('B')
						 and spot.screening_date = @screening_date
						 and spot.billing_period = @billing_period
						 
				select	@charge_rate = isnull(sum(spot.charge_rate),0) 
					from outpost_spot spot,
						 outpost_venue cmpl,
						 outpost_player_xref opx,
						 outpost_player op
				   where spot.campaign_no = @campaign_no and
						 spot.outpost_panel_id = opx.outpost_panel_id and
						 opx.player_name = op.player_name and
						 op.outpost_venue_id = cmpl.outpost_venue_id and
						 cmpl.market_no = @market_no and
						 op.media_product_id = @media_product_id and
   						 spot.spot_status not in ('D')
   						 and spot.screening_date = @screening_date
						 and spot.billing_period = @billing_period
				 end
				 
				if @media_product_id = 10
				begin 
				  select @screened = isnull(count(distinct spot.spot_id),0)
					from inclusion_spot spot,
						 outpost_venue cmpl,
						 inclusion inc
				   where spot.campaign_no = @campaign_no and
						 spot.outpost_venue_id = cmpl.outpost_venue_id and
						 cmpl.market_no = @market_no and
   						 spot.spot_status not in ('D') and
						 spot.spot_type not in ('B') and
						inc.inclusion_id = spot.inclusion_id and
						inc.inclusion_type = 18
						and spot.screening_date = @screening_date
						 and spot.billing_period = @billing_period

				  select @bonus = isnull(count(distinct spot.spot_id),0)
					from inclusion_spot spot,
						 outpost_venue cmpl,
						 inclusion inc
				   where spot.campaign_no = @campaign_no and
						 spot.outpost_venue_id = cmpl.outpost_venue_id and
						 cmpl.market_no = @market_no and
   						 spot.spot_status not in ('D') and
						 spot.spot_type in ('B') and
						inc.inclusion_id = spot.inclusion_id and
						inc.inclusion_type = 18
						 and spot.billing_period = @billing_period
						and spot.screening_date = @screening_date

				select	@charge_rate = isnull(sum(spot.charge_rate),0)
				from	inclusion_spot spot,   
						outpost_venue cmpl,
						 inclusion inc
				where	spot.outpost_venue_id = cmpl.outpost_venue_id and  
						spot.campaign_no = @campaign_no and
						cmpl.market_no = @market_no and
   						 spot.spot_status not in ('D') and
						inc.inclusion_id = spot.inclusion_id and
						inc.inclusion_type = 18
						and spot.screening_date = @screening_date
						 and spot.billing_period = @billing_period
				end
				
				select 
			  	@screening_month = (DateName( month , DateAdd( month , period_no , -1))),
				@screening_period = (convert(char(6), start_date, 106) + ' - ' + convert(char(6), end_date, 106))
			    from [accounting_period]
			    where @billing_period = end_date
		

				insert into #screening_summary(market_no, screened, bonus, charge_rate, media_product_id,screening_date, screening_month,screening_period, billing_period) 
				values ( @market_no, @screened, @bonus, @charge_rate, @media_product_id,@screening_date, @screening_month, @screening_period, @billing_period)
				
				fetch screening_date_csr into @screening_date, @billing_period
				
			end 
			
		 close screening_date_csr
				
		fetch market_csr into @market_no, @media_product_id
				
	end 
	
deallocate market_csr 
deallocate screening_date_csr

select	@product_desc as 'product_desc',
		market_no,
		screened = ISNULL( SUM(screened), 0),
		bonus = ISNULL( SUM(bonus), 0),
		charge_rate = ISNULL( SUM(charge_rate), 0),
		mp.media_product_id,
		mp.media_product_desc,
--		screening_date,
		screening_month,
		screening_period,
		max(YEAR(billing_period)) as [year],
		billing_period
from	#screening_summary, media_product mp
WHERE	#screening_summary.media_product_id = mp.media_product_id
GROUP BY	mp.media_product_id, market_no, mp.media_product_desc, screening_month, screening_period, billing_period
order by media_product_desc, market_no, billing_period
end
GO
