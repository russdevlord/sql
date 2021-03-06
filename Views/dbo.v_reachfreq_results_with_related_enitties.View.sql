/****** Object:  View [dbo].[v_reachfreq_results_with_related_enitties]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_reachfreq_results_with_related_enitties]
GO
/****** Object:  View [dbo].[v_reachfreq_results_with_related_enitties]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_reachfreq_results_with_related_enitties] 
as
select res.result_id, complex_id, cinetam_reporting_demographics_id
from cinetam_reachfreq_results res
inner join	cinetam_reachfreq_results_mkt_xref resmkt on res.result_id = resmkt.result_id
inner join complex cplx on cplx.film_market_no = resmkt.film_market_no
inner join cinetam_reachfreq_results_fsd_xref resdate on res.result_id = resdate.result_id
group by  res.result_id,  complex_id, cinetam_reporting_demographics_id
GO
