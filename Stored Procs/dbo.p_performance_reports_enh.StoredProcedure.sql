/****** Object:  StoredProcedure [dbo].[p_performance_reports_enh]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_performance_reports_enh]
GO
/****** Object:  StoredProcedure [dbo].[p_performance_reports_enh]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_performance_reports_enh]     	@report_type		char(1),
											@country			char(1),
											@start_date		datetime,
											@end_date			datetime,
											@count				integer,
											@sort_type   	char(1),
											@branch_code		char(1)
as
set nocount on 
/*
 * Declare Variables
 */

declare		@ranking		integer,
			@campaign_no	integer,
			@package_id		integer,
			@id_value		integer,
			@description	varchar(50),
			@value			money,
			@volume			integer,
			@counter		integer,
			@total_value	money,
			@total_volume	integer,
			@check_count	integer,
			@other_desc		varchar(50),
			@break			tinyint,
			@result_value	money,
			@result_volume	integer

/*
 * Create Work Table
 */

create table #work_table
(
	id_value			integer				null,
	description		   	varchar(100)		null,
	value				money				null,
	volume				integer				null
)

/*
 * Create Results Table
 */

create table #results
(  
	ranking				integer				null,
	id_value			integer				null,
	description		   	varchar(100)		null,
	value				money				null,
	volume				integer				null
)

select @total_value = 0,
       @total_volume	= 0

/*
 * Cursor get all Campaigns
 */

    declare     perf_csr cursor static forward_only for
    select      cr.campaign_no,
                0,
                sum(rt.cost),
                sum(rt.units)
    from        campaign_revision cr,
                revision_transaction rt,
                film_campaign fc,
			    branch b
    where       fc.branch_code = b.branch_code
    and         b.country_code = @country
    and         rt.billing_Date between @start_date and @end_date
    and         cr.campaign_no = fc.campaign_no
    and         cr.revision_id = rt.revision_id
    group by    cr.campaign_no
    order by    cr.campaign_no
    for read only
/*
 * Loop Campaigns
 */
open perf_csr
fetch perf_csr into @campaign_no, @package_id, @value, @volume
while (@@fetch_status=0)
begin

	/*
     * Add to Totals
     */

	select @total_value = @total_value + @value
	select @total_volume	= @total_volume + @volume

	/*
 	 * Get Client Information
 	 */	

	if (@report_type = 'C')
	begin
		select 	@id_value = c.client_id,
				@description = c.client_name,
				@other_desc = 'Other Advertisers'
		from 	client c,
				film_campaign fc			    
		where 	fc.campaign_no = @campaign_no and
				c.client_id = fc.client_id 
	end

	if (@report_type = 'A')
	begin
		select 	@id_value = a.agency_id,
				@description = a.agency_name,
				@other_desc = 'Other Agencies'
		from 	agency a, 
				film_campaign fc
		where 	fc.campaign_no = @campaign_no and
				a.agency_id = fc.agency_id
	end
	
	if (@report_type = 'P')
	begin
        select  @id_value = product_category_id,
                @description = product_category_desc,
				@other_desc = 'Other Product Categories' 
        from    product_category 
        where   product_category_id in (select max(product_category) from campaign_package where campaign_no = @campaign_no)
	end
		
	if (@report_type = 'D')
	begin
		select 	@id_value = cp.client_product_id,
				@description = cp.client_product_desc,
				@other_desc = 'Other Client Products'
		from 	client_product cp,
				film_campaign fc			    
		where 	fc.campaign_no = @campaign_no and
				cp.client_product_id = fc.client_product_id 
	end

	if (@report_type = 'G')
	begin
		select 	@other_desc = 'No/Other Client Groups'

		select 	@id_value = cg.client_group_id,
				@description = cg.client_group_desc
		from 	client c,
				film_campaign fc,
				client_group cg
		where 	fc.campaign_no = @campaign_no
		and		c.client_id = fc.client_id 
		and		c.client_group_id = cg.client_group_id
	end

	/*
     * Write to work_table
 	 */

	select 	@check_count = count(id_value)
	from 	#work_table
	where 	id_value = @id_value
	
	if(@check_count = 1)
	begin
		update 	#work_table
		set 	value = value + @value,
				volume = volume + @volume
		where 	id_value = @id_value
	end
	else
	begin
		insert into #work_table (
		id_value,
		description,
		value,
		volume ) values (
		@id_value,
		@description,
		@value,
		@volume )	
	end

	/*
     * Fetch Next
     */

	fetch perf_csr into @campaign_no, @package_id, @value, @volume
end

close perf_csr
DEALLOCATE perf_csr

/*
 * Loop For Results
 */

select 	@counter = 0,
		@break = 0,
		@result_value = 0,
		@result_volume = 0
		 
if (@sort_type = 'V')
begin
	/*
	 * Retrieve data from #work_table order by Value
	 */
	declare 	work_csr cursor static for
	select 		id_value,
				description,
				value,
				volume 
	from 		#work_table
	order by 	value desc
	for 		read only
end
else
begin
	/*
	 * Retrieve data from #work_table order by Volume
	 */
	
	declare 	work_csr cursor static for
	select 		id_value,
				description,
				value,
				volume 
	from 		#work_table
	order by 	volume desc
	for 		read only
end

open work_csr
while(@break = 0) and (@counter < @count)
begin
	fetch work_csr into @id_value, @description, @value, @volume
	if(@@fetch_status = 0)
	begin
	
		/*
		 * Calculate Result Totals
		 */
		
		select 	@result_value = @result_value + @value,
				@result_volume = @result_volume + @volume,
				@counter = @counter + 1		
		
		insert into #results ( ranking,
					id_value,
					description,
					value,
					volume ) values (
					@counter,
					@id_value,
					@description,
					@value,
					@volume )						
	end
	else
	begin
		select @break = 1
	end
end

/*
 * Close Cursor
 */

close work_csr
deallocate work_csr
		
/*
 * Combine Remaining Entries
 */

select @total_value = @total_value - @result_value,
       @total_volume = @total_volume - @result_volume

insert into #results values(null, null, @other_desc, @total_value, @total_volume)

select 	ranking,
		id_value,
		description,
		value,
		volume 
from 	#results

/*
 * Return Success
 */

return 0
GO
