/****** Object:  View [dbo].[v_cinetam_mm_adjustment]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cinetam_mm_adjustment]
GO
/****** Object:  View [dbo].[v_cinetam_mm_adjustment]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_cinetam_mm_adjustment]
as
select	distinct screening_date, country_code, mm_adjustment
from cinetam_reachfreq_population
GO
