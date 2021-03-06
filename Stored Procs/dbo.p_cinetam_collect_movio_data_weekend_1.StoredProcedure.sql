/****** Object:  StoredProcedure [dbo].[p_cinetam_collect_movio_data_weekend_1]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_collect_movio_data_weekend_1]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_collect_movio_data_weekend_1]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinetam_collect_movio_data_weekend_1]	@screening_date		datetime,
																								@country_code			char(1)

as

declare		@error						int

set nocount on

begin transaction

/*
* Delete Existing Movio Staging Information
*/

delete		movio_data_weekend
where		session_time between @screening_date and dateadd(ss, -1, dateadd(wk, 1, @screening_date))
and			country_code = @country_code

select @error = @@error				
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Error deleting existing core movio data weekend from CinVendo staging table', 16, 1)
	return -1
end	

/*
 * insert rows from loyalty database
 */


if @country_code = 'A'
begin
	insert into	movio_data_weekend
	select			membership_id,
						movie_code,
						FilmName,
						SessionTime,
						person_ageSupplied,
						RealAge,
						person_gender,
						complex_name,
						country_code,
						sum(unique_transactions) as trans,
						adult_tickets,
						child_tickets,
						screening_date
	from (			select			m.membership_id,
											f.movie_code,
											rtrim(f.movie_name)  as FilmName,
											ti.transactionItem_sessionTime as SessionTime,
											p.person_ageSupplied,
											case when isnull(person_gender,'') <> '' then person_gender else gender end as person_gender,
											c.complex_name,
											'A' as country_code,
											count(distinct ti.transactionItem_transactionid) as unique_transactions, 
											0.0 as adult_tickets, 
											0.0 as child_tickets,
											@screening_date as screening_date,
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
									END + '-01' /*+  case when person_birthdayDate <=0 then null else person_birthdayDate end*/),t.transaction_time ) as RealAge
						from				[LOYALTYAU.DB.HOYTS.NET.AU].[VISTALOYALTY].[dbo].[cognetic_data_transaction] t with (nolock) inner join 
											[LOYALTYAU.DB.HOYTS.NET.AU].[VISTALOYALTY].[dbo].[cognetic_members_membership] m  with (nolock) on t.transaction_membershipid = m.membership_id inner join
											[LOYALTYAU.DB.HOYTS.NET.AU].[VISTALOYALTY].[dbo].[cognetic_core_person] p with (nolock) on m.membership_personid = p.person_id inner join 
											[LOYALTYAU.DB.HOYTS.NET.AU].[VISTALOYALTY].[dbo].[cognetic_data_transactionItem] ti with (nolock)  on t.transaction_id = ti.transactionItem_transactionid left join
											[LOYALTYAU.DB.HOYTS.NET.AU].[VISTALOYALTY].[dbo].[cognetic_rules_movie] f  with (nolock) on ti.transactionItem_movieid = f.movie_id inner join
											[LOYALTYAU.DB.HOYTS.NET.AU].[VISTALOYALTY].[dbo].[cognetic_campaigns_complex] c  with (nolock)on t.transaction_complexid = c.complex_id inner join
											[LOYALTYAU.DB.HOYTS.NET.AU].[VISTALOYALTY].[dbo].[cognetic_data_item] i  with (nolock) on  ti.transactionItem_itemid = i.item_id inner join
											[LOYALTYAU.DB.HOYTS.NET.AU].[VISTALOYALTY].[dbo].[cognetic_data_itemclass] itc  with (nolock) on  itc.itemclass_id = i.item_itemclassid left outer join
											[LOYALTYAU.DB.HOYTS.NET.AU].[VISTALOYALTY].[dbo].[tblHoytsGenderByName] hoyname  with (nolock) on rtrim(ltrim(lower(hoyname.name))) = rtrim(ltrim(lower(p.person_firstName))) 
						where			m.membership_clubid = 9
						and				i.item_itemclassid in (3,6)
						and				ti.transactionItem_sessionTime between @screening_date and dateadd(ss, -1, dateadd(dd, 4, @screening_date))
						and				m.membership_id is not null
						and				f.movie_code is not null
						and				f.movie_name is not null
						and				ti.transactionItem_sessionTime is not null
						and				p.person_ageSupplied is not null
						and				isnull(p.person_centuryOfBirth,'') <> ''
						and				isnull(p.person_yearOfBirth,'') <> ''
						and				isnull(p.person_birthdayMonth, '') <> ''
						and				isnull(p.person_birthdayDate,'') <> ''
												and				p.person_centuryOfBirth in (19,20)
						group by		m.membership_id,
											f.movie_code,
											f.movie_name,
											ti.transactionItem_sessionTime,
											p.person_ageSupplied,
											p.person_gender,
											c.complex_name,
											person_centuryOfBirth,
											person_yearOfBirth,
											person_birthdayMonth,
											person_birthdayDate,
											t.transaction_time,
											hoyname.gender) as temp_table
	where			realage is not null		
	and				isnull(person_gender,'') <> '' 	
	group by		membership_id,
						movie_code,
						FilmName,
						SessionTime,
						person_ageSupplied,
						RealAge,
						person_gender,
						complex_name,
						country_code,
						adult_tickets,
						child_tickets,
						screening_date
					


	select @error = @@error				
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: Error inserting core movio data into CinVendo staging table', 16, 1)
		return -1
	end	
end 
else if @country_code = 'Z'
begin
	insert into	movio_data_weekend
	select			membership_id,
						movie_code,
						FilmName,
						SessionTime,
						person_ageSupplied,
						RealAge,
						person_gender, 
						complex_name,
						country_code,
						sum(unique_transactions) as trans,
						adult_tickets,
						child_tickets,
						screening_date
	from (			select			m.membership_id,
											f.movie_code,
											rtrim(f.movie_name)  as FilmName,
											ti.transactionItem_sessionTime as SessionTime,
											p.person_ageSupplied,
											case when isnull(person_gender,'') <> '' then person_gender else isnull(gender, '') end as person_gender,
											c.complex_name,
											'Z' as country_code, 
											count(distinct ti.transactionItem_transactionid) as unique_transactions, 
											0.0 adult_tickets, 
											0.0 as child_tickets,
											@screening_date as screening_date,
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
																																											END + '-01' /*+  case when person_birthdayDate <=0 then null else person_birthdayDate end*/),
											t.transaction_time ) as RealAge 
						from				[Loyaltynz.db.hoyts.net.au].[VISTALOYALTY].[dbo].[cognetic_data_transaction] t with (nolock)  inner join 
											[Loyaltynz.db.hoyts.net.au].[VISTALOYALTY].[dbo].[cognetic_members_membership] m   with (nolock) on t.transaction_membershipid = m.membership_id inner join
											[Loyaltynz.db.hoyts.net.au].[VISTALOYALTY].[dbo].[cognetic_core_person] p  with (nolock) on m.membership_personid = p.person_id inner join 
											[Loyaltynz.db.hoyts.net.au].[VISTALOYALTY].[dbo].[cognetic_data_transactionItem] ti with (nolock)  on t.transaction_id = ti.transactionItem_transactionid left join
											[Loyaltynz.db.hoyts.net.au].[VISTALOYALTY].[dbo].[cognetic_rules_movie] f  with (nolock) on ti.transactionItem_movieid = f.movie_id inner join
											[Loyaltynz.db.hoyts.net.au].[VISTALOYALTY].[dbo].[cognetic_campaigns_complex] c  with (nolock)on t.transaction_complexid = c.complex_id inner join
											[Loyaltynz.db.hoyts.net.au].[VISTALOYALTY].[dbo].[cognetic_data_item] i  with (nolock) on  ti.transactionItem_itemid = i.item_id inner join
											[Loyaltynz.db.hoyts.net.au].[VISTALOYALTY].[dbo].[cognetic_data_itemclass] itc with (nolock)  on  itc.itemclass_id = i.item_itemclassid left outer join
											[Loyaltynz.db.hoyts.net.au].[VISTALOYALTY].[dbo].[tblHoytsGenderByName] hoyname  with (nolock) on rtrim(ltrim(lower(hoyname.name))) = rtrim(ltrim(lower(p.person_firstName))) 
						where			m.membership_clubid = 6
						and				(i.item_itemclassid in (30)
						OR				i.item_code in (select distinct i.item_code from [Loyaltynz.db.hoyts.net.au].[VISTALOYALTY].[dbo].[cognetic_data_item] i with (nolock) join 
											[Vistahonz.db.hoyts.net.au].[VISTAHO].[dbo].[tblTicketType] tt with (nolock) on i.item_code collate database_default = tt.TType_strHOCode where tt.ttype_strchild = 'Y')) 
						and				ti.transactionItem_sessionTime between @screening_date and dateadd(ss, -1, dateadd(dd, 4, @screening_date))
						and				m.membership_id is not null
						and				f.movie_code is not null
						and				f.movie_name is not null
						and				ti.transactionItem_sessionTime is not null
						and				p.person_ageSupplied is not null
						and				isnull(p.person_centuryOfBirth,'') <> ''
						and				isnull(p.person_yearOfBirth,'') <> ''
						and				isnull(p.person_birthdayMonth, '') <> ''
						and				isnull(p.person_birthdayDate,'') <> ''
												and				p.person_centuryOfBirth in (19,20)
						group by		m.membership_id,
											f.movie_code,
											f.movie_name,
											ti.transactionItem_sessionTime,
											p.person_ageSupplied,
											p.person_gender,
											c.complex_name,
											person_centuryOfBirth,
											person_yearOfBirth,
											person_birthdayMonth,
											person_birthdayDate,
											t.transaction_time,
											hoyname.gender) as temp_table
where			realage is not null				
and				isnull(person_gender,'') <> '' 
group by		membership_id,
					movie_code,
					FilmName,
					SessionTime,
					person_ageSupplied,
					RealAge,
					person_gender,
					complex_name,
					country_code,
					adult_tickets,
					child_tickets,
					screening_date

	select @error = @@error				
	if @error <> 0
	begin
		rollback transaction
		raiserror ('Error: Error inserting core movio data into CinVendo staging table', 16, 1)
		return -1
	end
end

commit transaction
return 0
GO
