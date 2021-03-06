/****** Object:  StoredProcedure [dbo].[p_slide_bill_runout]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_bill_runout]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_bill_runout]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_slide_bill_runout]  @complex_id			integer,
											@screening_date	datetime

as

declare @screening_week			integer,
		  @nett_rate				money,	
		  @complex_list_rate		money,
		  @total_list_rate		money,
		  @campaign_no				char(7),
		  @nos						varchar(100),
		  @bonus_weeks				integer,
		  @pro_rata_cinpor		money,
		  @branch_name				varchar(30),
		  @complex_name			varchar(50)


create table #spot_weekly
(	screening_weeks  	integer		 null,
	nett_amount			money			 null,
	campaign_no			char(7)		 null,
	nos					varchar(100) null,
	bonus_weeks			integer		 null,
	pro_rata				money			 null
)

select @branch_name = branch.branch_name,
		 @complex_name = complex.complex_name
  from branch,
		 complex
 where complex.branch_code = branch.branch_code and
		 complex.complex_id = @complex_id

declare spot_csr cursor static for
select slide_campaign_spot.campaign_no,
		 count(slide_campaign_spot.screening_date),
		 sum(slide_campaign_spot.nett_rate)
  from slide_campaign_spot,
		 slide_campaign_complex
 where screening_date >= @screening_date and
		 slide_campaign_spot.campaign_no =  slide_campaign_complex.campaign_no and
		 slide_campaign_complex.complex_id = @complex_id and
		 slide_campaign_spot.billing_status = 'L'
group by slide_campaign_spot.campaign_no
order by slide_campaign_spot.campaign_no

open spot_csr
fetch spot_csr into @campaign_no, @screening_week, @nett_rate
while(@@fetch_status=0)
begin

	select @total_list_rate = sum(list_rate * orig_screens)
	  from slide_campaign_complex
    where campaign_no = @campaign_no

	select @complex_list_rate = sum(list_rate * orig_screens)
	  from slide_campaign_complex
    where campaign_no = @campaign_no and
			 complex_id = @complex_id

	select @nos = name_on_slide,
			 @bonus_weeks = bonus_period
     from slide_campaign	
	 where campaign_no = @campaign_no

	select @screening_week = @screening_week - @bonus_weeks

	select @nett_rate = isnull(@nett_rate * (@complex_list_rate / @total_list_rate), 0)

	select @pro_rata_cinpor = sum(slide_campaign_spot.nett_rate)
	  from slide_campaign_spot
	 where slide_campaign_spot.screening_date >= @screening_date and
			 slide_campaign_spot.billing_status = 'L' and
			 slide_campaign_spot.campaign_no = @campaign_no

	insert into #spot_weekly
	(screening_weeks,
	nett_amount,
	campaign_no,
	nos,
	bonus_weeks,
	pro_rata) values
	(@screening_week,
	@nett_rate,
	@campaign_no,
	@nos,
	@bonus_weeks,
	@pro_rata_cinpor)
	

	fetch spot_csr into @campaign_no, @screening_week, @nett_rate
end

close spot_csr
deallocate spot_csr

select nett_amount,
		 screening_weeks,
		 campaign_no,
		 nos,
		 bonus_weeks,
	 	 pro_rata,
		 @complex_name,
		 @branch_name
  from #spot_weekly
group by campaign_no

return 0
GO
