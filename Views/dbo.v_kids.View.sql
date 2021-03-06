/****** Object:  View [dbo].[v_kids]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_kids]
GO
/****** Object:  View [dbo].[v_kids]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_kids]
as					
select			m.membership_id,
					f.movie_code,
					rtrim(f.movie_name)  as FilmName,
					ti.transactionItem_sessionTime as SessionTime,
					p.person_ageSupplied,
					datediff(year,(p.person_centuryOfBirth + p.person_yearOfBirth + '-' +		CASE person_birthdayMonth 
																																					WHEN 'January' THEN '01'
																																					WHEN 'February' THEN '02'
																																					WHEN 'March' THEN '03'
																																					WHEN 'April' THEN '04'
																																					WHEN 'May' THEN '05'
																																					WHEN 'June' THEN '06'
																																					WHEN 'July' THEN '07'
																																					WHEN 'August' THEN '08'
																																					WHEN 'September' THEN '09'
																																					WHEN 'October' THEN '10'
																																					WHEN 'November' THEN '11'
																																					WHEN 'December' THEN '12'
																																					END + '-' +  case when person_birthdayDate <=0 then null else person_birthdayDate end),
					getdate() ) as RealAge,
					p.person_gender,
					c.complex_name,
					sum(transactionItem_quantity) as item_qty
from			[HOYTPGSQL01.HOYTS.NET.AU\HOYTS01].[VISTALOYALTY].[dbo].[cognetic_data_transaction] t  inner join 
					[HOYTPGSQL01.HOYTS.NET.AU\HOYTS01].[VISTALOYALTY].[dbo].[cognetic_members_membership] m   on t.transaction_membershipid = m.membership_id inner join
					[HOYTPGSQL01.HOYTS.NET.AU\HOYTS01].[VISTALOYALTY].[dbo].[cognetic_core_person] p  on m.membership_personid = p.person_id inner join 
					[HOYTPGSQL01.HOYTS.NET.AU\HOYTS01].[VISTALOYALTY].[dbo].[cognetic_data_transactionItem] ti   on t.transaction_id = ti.transactionItem_transactionid left join
					[HOYTPGSQL01.HOYTS.NET.AU\HOYTS01].[VISTALOYALTY].[dbo].[cognetic_rules_movie] f   on ti.transactionItem_movieid = f.movie_id inner join
					[HOYTPGSQL01.HOYTS.NET.AU\HOYTS01].[VISTALOYALTY].[dbo].[cognetic_campaigns_complex] c  on t.transaction_complexid = c.complex_id inner join
					[HOYTPGSQL01.HOYTS.NET.AU\HOYTS01].[VISTALOYALTY].[dbo].[cognetic_data_item] i   on  ti.transactionItem_itemid = i.item_id inner join
					[HOYTPGSQL01.HOYTS.NET.AU\HOYTS01].[VISTALOYALTY].[dbo].[cognetic_data_itemclass] itc   on  itc.itemclass_id = i.item_itemclassid
where			m.membership_clubid = 9
and				i.item_itemclassid= 3
and				ti.transactionItem_sessionTime  between  '5-sep-2013' and dateadd(ss, -1, dateadd(wk, 1, '5-sep-2013'))
and				m.membership_id is not null
and				f.movie_code is not null
and				f.movie_name is not null
and				ti.transactionItem_sessionTime is not null
and				p.person_ageSupplied is not null
and				p.person_gender is not null
and				isnull(p.person_centuryOfBirth, 0) <> 0
and				isnull(p.person_yearOfBirth, 0) <> 0
--and				isnull(person_birthdayMonth, 0) <> 0
and				isnull(person_birthdayDate, 0) <> 0
group by    m.membership_id,
					f.movie_code,
					f.movie_name,
					ti.transactionItem_sessionTime,
					p.person_ageSupplied,
					p.person_gender,
					c.complex_name,
					person_centuryOfBirth,
					person_yearOfBirth,
					person_birthdayMonth,
					person_birthdayDate					
GO
