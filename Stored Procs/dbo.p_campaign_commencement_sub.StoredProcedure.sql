/****** Object:  StoredProcedure [dbo].[p_campaign_commencement_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_commencement_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_commencement_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC  [dbo].[p_campaign_commencement_sub] 	@campaign_no  	integer


as

declare 	@error  int

	
	insert into #comp_date_prints (
					campaign_no,
					print_id,
					screening_date
					)
		 select  spot.campaign_no,
					ppack.print_id,
					min(spot.screening_date)
			 from campaign_spot spot,
					campaign_package cp,
					print_package ppack,
					complex cplx
			where spot.package_id = cp.package_id and
					cp.package_id = ppack.package_id and
					spot.complex_id = cplx.complex_id and
					spot.campaign_no = @campaign_no and
               spot.campaign_no not in (select campaign_no from #comp_date_prints)
		group by spot.campaign_no,
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
		  select campaign_no,
					print_id,
					min(screening_date)
			 from #comp_date_prints
         where campaign_no not in (select campaign_no from #comp_prints)
		group by campaign_no,
					print_id

			select @error = @@error
			if (@error !=0)
			begin
				goto error
			end
	
return 0

error:

	raiserror ('Error retrieving campaign prints information', 16, 1)
	return -1
GO
