/****** Object:  StoredProcedure [dbo].[p_rpt_cinema_portal_errors]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rpt_cinema_portal_errors]
GO
/****** Object:  StoredProcedure [dbo].[p_rpt_cinema_portal_errors]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_rpt_cinema_portal_errors]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- get header details
	
	SELECT distinct projectionist_comments
       ,projectionist_name
       ,CONVERT(CHAR(12),dateupdated,107) AS dateupdated
       ,ISNULL(HO_processed_flag,'N') AS HO_processed_flag
       ,CASE ISNULL(projectionist_name,'ISNULL') WHEN 'ISNULL' THEN 'N' 
                                                 ELSE 'Y' 
                                                 END AS complex_processed 
		  ,complex_id
		  ,screening_date
	into #header
	FROM screening_confirmations as sc
	inner join (select distinct complex_id, screening_date, certificate_group_id
				from certificate_group
				where screening_date > '20160101' ) as cg on cg.certificate_group_id = sc.certificate_group_id --and complex_id = 1241
	where sc.certificate_item_id = -1 
	and(HO_processed_flag = 'N' or HO_processed_flag is null)
	and projectionist_name is not null
	
	
	-- get errors for cinema based playlists
	
	select h.screening_date, h.complex_id
		, CG.group_name
		 ,CI.sequence_no 
		 ,CG.certificate_group_id
		 ,CG.group_no
		 ,CI.certificate_item_id as certificate_item_id_ci
		 ,CI.item_show as item_show_ci
		 ,FP.print_name
		 ,FP.print_status
		 ,CG.three_d_type as three_d_type_cg
		 ,CI.three_d_type as three_d_type_ci
		 ,CI.premium_cinema
		 ,FP.print_type
		 ,CASE ISNULL(SC.certificate_item_id,0) WHEN 0 THEN 'Y' 
												ELSE 'N' 
												END AS item_shown_sc
												, SC.certificate_item_id as dfgdfg
		 ,ISNULL(SC.projectionist_comments, '') AS projectionist_comments
		 ,SC.certificate_item_id  as certificate_item_id_sc
		 ,ISNULL(SC2.item_shown,'Y') AS GroupShown
		 ,SC2.projectionist_comments AS GroupComments
		 ,ci.print_id
		 ,ci.spot_reference
	 into #cinema_line_items
     from certificate_item CI
     LEFT OUTER JOIN screening_confirmations SC ON CI.certificate_group = SC.certificate_group_id AND CI.certificate_item_id = SC.certificate_item_id
     LEFT OUTER JOIN screening_confirmations SC2 ON CI.certificate_group = SC2.certificate_group_id AND SC2.certificate_item_id = 0,
     film_print FP,
     certificate_group CG
     ,#header as h
     where CG.complex_id = h.complex_id
     and  CG.screening_date = h.screening_date
     and  CG.certificate_group_id = CI.certificate_group
     and  CI.print_id = FP.print_id
     and  CI.item_show = 'Y'
     and CG.group_name not like '%Cinema%'
     and SC.certificate_item_id is not null
     order by h.screening_date desc, h.complex_id, certificate_group, sequence_no 
	
	-- get errors for screen based playlists
	
	select  h.screening_date, h.complex_id
	, CG.group_name
    ,CI.sequence_no
    ,CG.certificate_group_id
    ,CG.group_no
    ,CI.certificate_item_id as certificate_item_id_ci
    ,CI.item_show as item_show_ci
    ,FP.print_name
    ,FP.print_status
     ,CG.three_d_type as three_d_type_cg
     ,CI.three_d_type as three_d_type_ci
    ,CI.premium_cinema
    ,FP.print_type
    ,CASE ISNULL(SC.certificate_item_id,0) WHEN 0 THEN 'Y' 
                                           ELSE 'N' 
                                           END AS item_shown_sc
    ,ISNULL(SC.projectionist_comments,'') AS projectionist_comments
    ,SC.certificate_item_id  as certificate_item_id_sc
    ,ISNULL(SC2.item_shown,'Y') AS GroupShown
    ,SC2.projectionist_comments AS GroupComments 
    ,ci.print_id
	,ci.spot_reference
    into #screen_line_items
    from certificate_item CI 
    LEFT OUTER JOIN screening_confirmations SC ON CI.certificate_group = SC.certificate_group_id AND CI.certificate_item_id = SC.certificate_item_id                          
    LEFT OUTER JOIN screening_confirmations SC2 ON CI.certificate_group = SC2.certificate_group_id AND SC2.certificate_item_id = 0,
    film_print FP,
    certificate_group CG
    ,#header as h
	 where CG.complex_id = h.complex_id
	 and  CG.screening_date = h.screening_date
     and  CG.certificate_group_id = CI.certificate_group 
     and  CI.print_id = FP.print_id 
     and  CI.item_show = 'Y'
     and CG.group_name  like '%Cinema%'
     and SC.certificate_item_id is not null
     order by h.screening_date desc, h.complex_id, certificate_group, sequence_no 
     
     select *
     from (
     
			 select distinct convert(varchar(12), h.dateupdated, 106) as dateupdated, convert(varchar(12), h.screening_date, 106) as screening_date
					,c.complex_name, cp.campaign_no, fc.product_desc, cli.print_id, cp.package_code, convert(varchar(12), cp.start_date, 106) as start_date
					,convert(varchar(12), cp.used_by_date, 106) as used_by_date, cli.GroupComments, h.projectionist_comments, h.projectionist_name, cli.group_name
					,h.screening_date as order_date
			 from #header as h
			 left join #cinema_line_items as cli on h.complex_id = cli.complex_id and h.screening_date = cli.screening_date
			 inner join complex as c on c.complex_id = h.complex_id
			 inner join campaign_spot as spot on cli.spot_reference = spot.spot_id
			 inner join campaign_package as cp on spot.package_id = cp.package_id
			 inner join film_campaign as fc on fc.campaign_no = cp.campaign_no
			 where h.HO_processed_flag = 'N' 
			 and h.complex_processed = 'Y'
			 --order by 2 desc, 3, 4
			 union
				  select distinct convert(varchar(12), h.dateupdated, 106) as dateupdated, convert(varchar(12), h.screening_date, 106) as screening_date
					,c.complex_name, cp.campaign_no, fc.product_desc, sli.print_id, cp.package_code, convert(varchar(12), cp.start_date, 106) as start_date
					,convert(varchar(12), cp.used_by_date, 106) as used_by_date, sli.GroupComments, h.projectionist_comments, h.projectionist_name, sli.group_name
					,h.screening_date as order_date
			 from #header as h
			 left join #screen_line_items as sli on h.complex_id = sli.complex_id and h.screening_date = sli.screening_date
			 inner join complex as c on c.complex_id = h.complex_id
			 inner join campaign_spot as spot on sli.spot_reference = spot.spot_id
			 inner join campaign_package as cp on spot.package_id = cp.package_id
			 inner join film_campaign as fc on fc.campaign_no = cp.campaign_no
			 where h.HO_processed_flag = 'N' 
			 and h.complex_processed = 'Y' ) as  a
     order by order_date desc, complex_name--, campaign_no , package_code, start_date
     
   
END
GO
