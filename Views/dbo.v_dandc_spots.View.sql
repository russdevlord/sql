/****** Object:  View [dbo].[v_dandc_spots]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_dandc_spots]
GO
/****** Object:  View [dbo].[v_dandc_spots]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_dandc_spots] 
AS

select 	spot_id,
		'O' as spot_table_type,
		spot.charge_rate,
		spot.makegood_rate,
		spot.campaign_no,
        spot.tran_id,
		(SELECT  avg_rate 
		FROM     statrev_spot_rates
		WHERE    spot_id = spot.spot_id 
		and		revenue_group in (1,2,3)) AS statrev_spot_rate 
from	campaign_spot spot
where	dandc = 'Y'
union all
select 	spot_id,
		'C' as spot_table_type,
		spot.charge_rate,
		spot.makegood_rate,
		spot.campaign_no,
        spot.tran_id,
		(SELECT  avg_rate 
		FROM     statrev_spot_rates
		WHERE    spot_id = spot.spot_id 
		and		revenue_group = 4) AS statrev_spot_rate 
from	cinelight_spot spot
where	dandc = 'Y'
union all
select 	spot_id,
		'I' as spot_table_type,
		spot.charge_rate,
		spot.makegood_rate,
		spot.campaign_no,
        spot.tran_id,
		(SELECT  avg_rate 
		FROM     statrev_spot_rates
		WHERE    spot_id = spot.spot_id 
		and		revenue_group = 5) AS statrev_spot_rate 
from	inclusion_spot spot
where	dandc = 'Y'
and		inclusion_id in (select inclusion_id from inclusion where inclusion_type in (5))
union all
select 	spot_id,
		'R' as spot_table_type,
		spot.charge_rate,
		spot.makegood_rate,
		spot.campaign_no,
        spot.tran_id,
		(SELECT  avg_rate 
		FROM     statrev_spot_rates
		WHERE    spot_id = spot.spot_id 
		and		revenue_group  in (50,53)) AS statrev_spot_rate 
from	outpost_spot spot
where	dandc = 'Y'
union all
select 	spot_id,
		'W' as spot_table_type,
		spot.charge_rate,
		spot.makegood_rate,
		spot.campaign_no,
        spot.tran_id,
		(SELECT  avg_rate 
		FROM     statrev_spot_rates
		WHERE    spot_id = spot.spot_id 
		and		revenue_group = 51) AS statrev_spot_rate 
from	inclusion_spot spot
where	dandc = 'Y'
and		inclusion_id in (select inclusion_id from inclusion where inclusion_type in (18))
GO
