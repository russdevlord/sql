/****** Object:  View [dbo].[V_Adex_Tableau_extract]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[V_Adex_Tableau_extract]
GO
/****** Object:  View [dbo].[V_Adex_Tableau_extract]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create View [dbo].[V_Adex_Tableau_extract] AS
select	ar.market_description AS 'Market Date',
		ar.state, 
		ar.buying_group_id,
		ar.agenygrpconsort AS Adex_Buying_Group_name,
		ABG.buying_group_desc,
		ar.agency_group_id,
		ar.agencycategory AS Adex_Agency_group,
		agrp.agency_group_name,
		ar.Agency_id,
		ar.agency AS Adex_Agency_name,
		ag.agency_name,
		ar.client_id,
		cl.client_name,
		ar.advertiser AS Adex_Client_name,
		ar.agencycategory,
	    ar.advertiser,
	    ar.category,
		ar.mtv AS 'MTV 000',
		ar.rtv AS 'RTV 000',
		ar.mpress AS 'Mpress 000',
		ar.rpress AS 'Rpress 000',
		ar.mags AS 'Mags 000',
		ar.radio AS 'Radio 000',
		ar.out_of_home AS 'Out of Home 000',
		ar.cinema AS 'Cinema 000',
		ar.direct_mail AS 'Direct Mail 000'
FROM adex_revenue AR with (nolock)
Left JOIN agency_buying_groups ABG with (nolock)
ON ar.buying_group_id = ABG.buying_group_id
Left JOIN agency_groups AGrp with (nolock)
ON ar.agency_group_id = AGrp.agency_group_id
Left JOIN agency AG with (nolock)
ON ar.agency_id = ag.agency_id
Left Join client cl with (nolock)
ON ar.client_id = cl.client_id
Where state = 'National'

GO
