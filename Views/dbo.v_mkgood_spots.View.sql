/****** Object:  View [dbo].[v_mkgood_spots]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_mkgood_spots]
GO
/****** Object:  View [dbo].[v_mkgood_spots]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_mkgood_spots] 
AS

select 	spot_id,
		'O' as spot_table_type,
		spot.charge_rate,
		spot.makegood_rate,
		spot.campaign_no,
        spot.tran_id
from	campaign_spot spot
where	spot_type = 'D'
union all
select 	spot_id,
		'C' as spot_table_type,
		spot.charge_rate,
		spot.makegood_rate,
		spot.campaign_no,
        spot.tran_id
from	cinelight_spot spot
where	spot_type = 'D'
union all
select 	spot_id,
		'I' as spot_table_type,
		spot.charge_rate,
		spot.makegood_rate,
		spot.campaign_no,
        spot.tran_id
from	inclusion_spot spot
where	spot_type = 'D'
and		inclusion_id in (select inclusion_id from inclusion where inclusion_type = 5)
GO
