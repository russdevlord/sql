/****** Object:  View [dbo].[v_reachfreq_results_screeningdates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_reachfreq_results_screeningdates]
GO
/****** Object:  View [dbo].[v_reachfreq_results_screeningdates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_reachfreq_results_screeningdates] 
as
select  result_id, dateadd(wk, -52, screening_date) as screening_date
from cinetam_reachfreq_results_fsd_xref res
group by  res.result_id, screening_date
GO
