USE [production]
GO
/****** Object:  View [dbo].[v_cinetam_mm_adjustment]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_cinetam_mm_adjustment]
as
select	distinct screening_date, country_code, mm_adjustment
from cinetam_reachfreq_population
GO
