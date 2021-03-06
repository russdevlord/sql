/****** Object:  StoredProcedure [dbo].[p_campaign_print_summary]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_print_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_print_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_campaign_print_summary] 	@campaign_no	integer,
										@print_id		integer

as

/*
 * Create Temporary Table
 */

create table #campaign_prints
(
	campaign_no				integer			null,
	print_id				integer			null,
	print_name				varchar(50)		null,
	requested_prints		integer			null,
	nominal_prints			integer			null,
	prop_prints				integer			null,
	used_flag				char(1)			null,
	print_status			char(1)			null,
	print_type				char(1)			null,
	print_medium			char(1)			null,
	three_d_type			integer			null
)

/*
 * Insert Prints Used by the Campaign
 */

if not @campaign_no is null
begin
	insert 		into #campaign_prints
	select   	fcprints.campaign_no,
				fp.print_id,   
				fp.print_name,   
				sum(IsNull(fcprints.requested_qty,0)),   
				sum(IsNull(fcprints.nominal_qty,0)),   
				sum(IsNull(fcprints.calculated_qty,0)),
				'Y',
				fp.print_status,
				fp.print_type,
				fcprints.print_medium,
				fcprints.three_d_type
	from   		film_print fp,
				film_campaign_prints fcprints
	where   	fp.print_id = fcprints.print_id 
	and			fcprints.campaign_no = @campaign_no 
	and			fp.print_id = @print_id
	group by 	fcprints.campaign_no,
				fp.print_id,   
				fp.print_name,
				fp.print_status,
				fp.print_type,
				fcprints.three_d_type,
				fcprints.print_medium
end
else
begin
	insert 		into #campaign_prints
	select  	null,
				fp.print_id,   
				fp.print_name,   
				0,   
				0,
				0,
				'Y',
				fp.print_status,
				fp.print_type,
				fpmx.print_medium,
				isnull(fp3d.three_d_type, 1)
	from   		film_print fp 	left outer join film_print_three_d_xref fp3d on fp.print_id = fp3d.print_id
			    				left outer join film_print_medium_xref fpmx on fp.print_id = fpmx.print_id
	where   	fp.print_id =  @print_id

end


/*
 * Return the consolidated information 
 */

select 	campaign_no,
		print_id,
		print_name,
		requested_prints,
		prop_prints,
		used_flag,
		print_status,
		print_type,
		print_medium,
		three_d_type,
		nominal_prints
from 	#campaign_prints
GO
