/****** Object:  StoredProcedure [dbo].[p_salesman_booking_listing]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_salesman_booking_listing]
GO
/****** Object:  StoredProcedure [dbo].[p_salesman_booking_listing]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_salesman_booking_listing] 		@s_report           varchar(255) , 
													@rep_id            	int, 
													@team_id			int,
													@branch_code        char(2), 
													@country_code		char(1),
													@d_first            datetime, 
													@d_last             datetime
as

declare     @error_num                  int,
            @scorefile					varchar(64),
            @actual						money,
            @target						money,					
            @value						money,
            @revision_id                int,
            @teams                      varchar(500),
            @team_exists                char(1),
            @figures_split	            char(1),
			@team_name					varchar(100),
			@buss_unit					int,
			@revision_group				int,
			@figure_id					int				
                    			
set nocount on

if @country_code <> ''
	select @branch_code = null

SELECT @buss_unit = 0
SELECT @revision_group = 0

IF ( CHARINDEX ( 'bu=1', @s_report ) > 0 ) SELECT @buss_unit = 1
IF ( CHARINDEX ( 'bu=2', @s_report ) > 0 ) SELECT @buss_unit = 2
IF ( CHARINDEX ( 'bu=3', @s_report ) > 0 ) SELECT @buss_unit = 3
IF ( CHARINDEX ( 'bu=4', @s_report ) > 0 ) SELECT @buss_unit = 4
IF ( CHARINDEX ( 'bu=5', @s_report ) > 0 ) SELECT @buss_unit = 5
IF ( CHARINDEX ( 'bu=9', @s_report ) > 0 ) SELECT @buss_unit = 9
IF ( CHARINDEX ( 'rg=1', @s_report ) > 0 ) SELECT @revision_group = 1
IF ( CHARINDEX ( 'rg=2', @s_report ) > 0 ) SELECT @revision_group = 2
IF ( CHARINDEX ( 'rg=3', @s_report ) > 0 ) SELECT @revision_group = 3
IF ( CHARINDEX ( 'rg=4', @s_report ) > 0 ) SELECT @revision_group = 4
IF ( CHARINDEX ( 'unit=1', @s_report ) > 0 ) SELECT @buss_unit = 1
IF ( CHARINDEX ( 'unit=2', @s_report ) > 0 ) SELECT @buss_unit = 2
IF ( CHARINDEX ( 'unit=3', @s_report ) > 0 ) SELECT @buss_unit = 3
IF ( CHARINDEX ( 'unit=4', @s_report ) > 0 ) SELECT @buss_unit = 4
IF ( CHARINDEX ( 'unit=5', @s_report ) > 0 ) SELECT @buss_unit = 5
IF ( CHARINDEX ( 'unit=9', @s_report ) > 0 ) SELECT @buss_unit = 9
IF ( CHARINDEX ( 'group=1', @s_report ) > 0 ) SELECT @revision_group = 1
IF ( CHARINDEX ( 'group=2', @s_report ) > 0 ) SELECT @revision_group = 2
IF ( CHARINDEX ( 'group=3', @s_report ) > 0 ) SELECT @revision_group = 3
IF ( CHARINDEX ( 'group=4', @s_report ) > 0 ) SELECT @revision_group = 4

/* Create temporary tables for resultsets */
create table #results (
	figure_id			int						not null,
    booking_period      datetime                not null,
    figure_date         datetime                not null,
    rep_id              int                     not null,
    contract_received   char(1)                 not null,
    branch_code         char(1)                 not null,
    campaign_no         int                     not null,
    product_desc        varchar(255)            not null,
    figure_type         char(1)                 not null,
    revision_no         int                     null,
    revision_id         int                     null,
    figures_split       char(1)                 null,
    onscreen            money                   null,
    offscreen           money                   null,
    adjustments         money                   null,
    comment			    varchar(255)            null,
    teams               varchar(500)            null,
	branch_sort			tinyint					not null
)

insert into #results (
		figure_id,
		booking_period,
		figure_date,
		rep_id,
		contract_received,
		branch_code,
		campaign_no,
		product_desc,
		figure_type,
		revision_no,
		revision_id,
		onscreen,
		offscreen,
		adjustments,
		comment,
		branch_sort
)
SELECT	booking_figures.figure_id, 
		booking_figures.booking_period, 
		booking_figures.figure_date, 
		booking_figures.rep_id, 
		dbo.f_campaign_contract(film_campaign.campaign_no), 
		booking_figures.branch_code, 
		booking_figures.campaign_no, 
		film_campaign.product_desc, 
		booking_figures.figure_type, 
		campaign_revision.revision_no, 
		booking_figures.revision_id, 
		(CASE figure_type WHEN 'A' THEN 0 ELSE CASE revision_group WHEN 1 THEN nett_amount ELSE 0 END END), 
		(CASE figure_type WHEN 'A' THEN 0 ELSE CASE revision_group WHEN 1 THEN 0 ELSE nett_amount END END), 
		(CASE figure_type WHEN 'A' THEN nett_amount ELSE 0 END), 
		booking_figures.figure_comment, 
		branch.sort_order
FROM	booking_figures INNER JOIN
		film_campaign ON booking_figures.campaign_no = film_campaign.campaign_no LEFT OUTER JOIN
		campaign_revision ON booking_figures.revision_id = campaign_revision.revision_id INNER JOIN
		branch ON booking_figures.branch_code = branch.branch_code
WHERE	(booking_figures.revision_group = @revision_group or @revision_group = 0)
and		(film_campaign.business_unit_id = @buss_unit or @buss_unit = 0)
and		booking_figures.booking_period between @d_first and @d_last
and		booking_figures.branch_code in (	select 	branch_code
											from	branch
											where	country_code = @country_code)
and		business_unit_id <> 6
and		revision_group < 50
union
select 	booking_figures.figure_id,
	    booking_figures.booking_period,
	    booking_figures.figure_date,
	    booking_figures.rep_id,
	    dbo.f_campaign_contract(film_campaign.campaign_no),
	    booking_figures.branch_code,
	    booking_figures.campaign_no,
	    film_campaign.product_desc,
	    booking_figures.figure_type,
	    campaign_revision.revision_no,
	    booking_figures.revision_id,
	    (case figure_type when 'A' then 0 else case revision_group when 1 then nett_amount else 0 end end),
	    (case figure_type when 'A' then 0 else case revision_group when 1 then 0 else nett_amount end end),
		(case figure_type when 'A' then nett_amount else 0 end),
	    figure_comment,
		branch.sort_order
FROM	booking_figures INNER JOIN
		film_campaign ON booking_figures.campaign_no = film_campaign.campaign_no LEFT OUTER JOIN
		campaign_revision ON booking_figures.revision_id = campaign_revision.revision_id INNER JOIN
		branch ON booking_figures.branch_code = branch.branch_code
where	(booking_figures.revision_group = @revision_group OR @revision_group = 0)
and		(film_campaign.business_unit_id = @buss_unit or @buss_unit = 0)
and		booking_figures.booking_period between @d_first and @d_last
and		booking_figures.branch_code = @branch_code
and		business_unit_id <> 6
and		revision_group < 50
union
select 	booking_figures.figure_id,
	    booking_figures.booking_period,
	    booking_figures.figure_date,
	    booking_figures.rep_id,
	    dbo.f_campaign_contract(film_campaign.campaign_no),
	    booking_figures.branch_code,
	    booking_figures.campaign_no,
	    film_campaign.product_desc,
	    booking_figures.figure_type,
	    campaign_revision.revision_no,
	    booking_figures.revision_id,
	    (case figure_type when 'A' then 0 else case revision_group when 1 then nett_amount else 0 end end),
	    (case figure_type when 'A' then 0 else case revision_group when 1 then 0 else nett_amount end end),
		(case figure_type when 'A' then nett_amount else 0 end),
	    figure_comment,
		branch.sort_order
FROM	booking_figures INNER JOIN
		film_campaign ON booking_figures.campaign_no = film_campaign.campaign_no LEFT OUTER JOIN
		campaign_revision ON booking_figures.revision_id = campaign_revision.revision_id INNER JOIN
		branch ON booking_figures.branch_code = branch.branch_code
where	(booking_figures.revision_group = @revision_group or @revision_group = 0)
and		(film_campaign.business_unit_id = @buss_unit OR @buss_unit = 0)
and		booking_figures.booking_period between @d_first and @d_last
and		booking_figures.figure_id in (	select 	figure_id
										from	booking_figure_team_xref
										where	team_id = @team_id) 
and		business_unit_id <> 6
and		revision_group < 50
union
select 	booking_figures.figure_id,
		booking_figures.booking_period,
		booking_figures.figure_date,
		booking_figures.rep_id,
		dbo.f_campaign_contract(film_campaign.campaign_no),
		booking_figures.branch_code,
		booking_figures.campaign_no,
		film_campaign.product_desc,
		booking_figures.figure_type,
		campaign_revision.revision_no,
		booking_figures.revision_id,
		(case figure_type when 'A' then 0 else case revision_group when 1 then nett_amount else 0 end end),
		(case figure_type when 'A' then 0 else case revision_group when 1 then 0 else nett_amount end end),
		(case figure_type when 'A' then nett_amount else 0 end),
		figure_comment,
		branch.sort_order
FROM	booking_figures INNER JOIN
		film_campaign ON booking_figures.campaign_no = film_campaign.campaign_no LEFT OUTER JOIN
		campaign_revision ON booking_figures.revision_id = campaign_revision.revision_id INNER JOIN
		branch ON booking_figures.branch_code = branch.branch_code
where	(booking_figures.revision_group = @revision_group or @revision_group = 0)
and		(film_campaign.business_unit_id = @buss_unit or @buss_unit = 0)
and		booking_figures.booking_period between @d_first and @d_last
and		booking_figures.rep_id = @rep_id

declare		figure_csr cursor forward_only static for 
select		figure_id,
			revision_id,
			rep_id
from		#results
group by 	figure_id,
			revision_id,
			rep_id

open figure_csr
fetch figure_csr into @figure_id, @revision_id, @rep_id
while(@@fetch_status=0)
begin

	select @teams = ''

	if @revision_id is not null
	begin
	    if (select  sum(cost) 
			from revision_transaction 
			where revision_id = @revision_id) != (select	sum(nett_amount) 
													from	booking_figures 
													where	revision_id = @revision_id and rep_id = @rep_id) 
			update 	#results
			set 	figures_split = 'Y'
			where	rep_id = @rep_id
			and		figure_id = @figure_id
			and		revision_id = @revision_id
	end

	declare		team_csr cursor static forward_only	for
	select 		team_name
	from		booking_figure_team_xref,
				sales_team
	where		figure_id = @figure_id
	and			sales_team.team_id = booking_figure_team_xref.team_id
	order by 	team_name

	open team_csr
	fetch team_csr into @team_name
	while(@@fetch_status=0)
	begin

		if @teams = ''
			select @teams = @teams + @team_name
		else
			select @teams = @teams + ', ' + @team_name

		fetch team_csr into @team_name
	end

	deallocate team_csr
	
	update 	#results
	set 	teams = @teams
	where	figure_id = @figure_id
    
    fetch figure_csr into @figure_id, @revision_id, @rep_id
end

deallocate figure_csr

select      booking_period,
            figure_date,
            rep_id,
            contract_received,
            branch_code,
            campaign_no,
            product_desc,
            figure_type,
            revision_no,
            figures_split,
            sum(onscreen),
            sum(offscreen),
            sum(adjustments),
            comment,
            teams,
			branch_sort
from        #results
group by 	booking_period,
            figure_date,
            rep_id,
            contract_received,
            branch_code,
            campaign_no,
            product_desc,
            figure_type,
            revision_no,
            figures_split,
            comment,
            teams,
			branch_sort
order by    booking_period,
            figure_date,
            branch_sort,
            campaign_no,
            revision_no

return 0
GO
