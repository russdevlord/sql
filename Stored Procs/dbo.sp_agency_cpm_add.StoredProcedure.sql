/****** Object:  StoredProcedure [dbo].[sp_agency_cpm_add]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[sp_agency_cpm_add]
GO
/****** Object:  StoredProcedure [dbo].[sp_agency_cpm_add]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_agency_cpm_add]
	@existing_agency_id int,
	@new_agency_id int
AS
BEGIN
	IF OBJECT_ID('tempdb..#agencycpm') IS NOT NULL  
		  DROP TABLE #agencycpm  

	;with cte1 as  
	(select * from [dbo].[agency_cpm] where agency_id=@existing_agency_id)   
	select * into #agencycpm from cte1  
 
	;with cte2 as  
	(  
		select @new_agency_id as [agency_id],  
		[cinetam_reporting_demographics_id] as cinetam_reporting_demographics_id,
		[availability_peak_time_id] as [availability_peak_time_id],
		[cinetam_reachfreq_duration_id],
		[cinetam_reachfreq_mode_id],
		[business_unit_id],
		[cpm] from #agencycpm  
	)  
	insert into agency_cpm select * from cte2  
   
END
GO
