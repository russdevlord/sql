/****** Object:  StoredProcedure [dbo].[p_cinelight_campaign_commencement_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_campaign_commencement_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_campaign_commencement_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC  [dbo].[p_cinelight_campaign_commencement_sub] 	@campaign_no  	integer


as

declare 	@error  int

begin transaction
	
insert into #comp_date_prints (
			campaign_no,
			print_id,
			screening_date
			)
select  	spot.campaign_no,
			ppack.print_id,
			min(spot.screening_date)
from 		cinelight_spot spot,
			cinelight_package cp,
			cinelight_print_package ppack
where 		spot.package_id = cp.package_id and
			cp.package_id = ppack.package_id and
			spot.campaign_no = @campaign_no and
			spot.campaign_no not in (select campaign_no from #comp_date_prints)
group by 	spot.campaign_no,
			ppack.print_id 

select @error = @@error
if (@error !=0)
begin
	goto error
end
	
insert into #comp_prints (
			campaign_no,
			print_id,
			start_date 
			)
select 		campaign_no,
			print_id,
			min(screening_date)
from 		#comp_date_prints
where 		campaign_no not in (select campaign_no from #comp_prints)
group by 	campaign_no,
			print_id

select @error = @@error
if (@error !=0)
begin
	goto error
end

commit transaction
return 0

error:

	raiserror ('Error retrieving campaign prints information', 16, 1)
	return -1
GO
