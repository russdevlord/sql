/****** Object:  View [dbo].[v__tap_complex_rank]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v__tap_complex_rank]
GO
/****** Object:  View [dbo].[v__tap_complex_rank]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE view [dbo].[v__tap_complex_rank] (Rank1, Rank2, RankTTL, MT_MIN, MT_MAX, NO_MIN, NO_MAX)
as
SELECT Rank1.Rank1, Rank2.Rank2, RankTTL.RankTTL, MT_MIN, MT_MAX, NO_MIN, NO_MAX
FROM	( VALUES (1,0,3),( 2,4,7),(3,8,11),(4,12,15),(5,16,19),(6,20,100)) AS Rank1(Rank1, MT_MIN, MT_MAX)
CROSS JOIN ( SELECT Rank2, NO_MIN, NO_MAX
			FROM (VALUES (1,0,3),( 2,4,7),(3,8,11),(4,12,15),(5,16,19),(6,20,100)) AS Rank2(Rank2, NO_MIN, NO_MAX)) AS Rank2
CROSS JOIN ( SELECT Rank1, Rank2, RankTTL
			FROM (VALUES (6,6,6),( 6,5,5),(6,4,4),(6,3,3),(6,2,3),(6,1,2),
						(5,6,5),( 5,5,5),(5,4,4),(5,3,3),(5,2,2),(5,1,2),
						(4,6,4),( 4,5,4),(4,4,4),(4,3,3),(4,2,2),(4,1,2),
						(3,6,3),( 3,5,3),(3,4,3),(3,3,3),(3,2,2),(3,1,2),
						(2,6,3),( 2,5,3),(2,4,2),(2,3,2),(2,2,2),(2,1,1),
						(1,6,2),( 1,5,2),(1,4,2),(1,3,2),(1,2,1),(1,1,1)) AS RankTTL(Rank1, Rank2, RankTTL) ) AS RankTTL
WHERE	Rank1.Rank1 = RankTTL.Rank1
AND		Rank2.Rank2 = RankTTL.Rank2


GO
