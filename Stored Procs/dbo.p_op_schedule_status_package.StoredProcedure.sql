/****** Object:  StoredProcedure [dbo].[p_op_schedule_status_package]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_schedule_status_package]
GO
/****** Object:  StoredProcedure [dbo].[p_op_schedule_status_package]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_op_schedule_status_package] @campaign_no 	   integer
as

/*
 * Declare Variables
 */
 
declare  @errorode					integer,
         @error         		integer,
         @rowcount				integer,
		 @campaign_value 		money,
		 @campaign_cost 		money,
		 @makegood_cost 		money,
		 @standby_value			money,
		 @package_id 			integer,
		 @package_code 			varchar(2),
         @package_desc          varchar(100)

/*
 * Create Results Table
 */
 
create table #results 
(
	package_code		varchar(2)			null,
	package_desc		varchar(100)		null,
	display_group		smallint			null,
	display_order		smallint			null,
	label				varchar(50)		    null,
    value				money				null,
    charge				money				null,
    makegood			money				null,
	number				integer				null
)

/*
 * Declare Cursors
 */
 
 declare package_csr cursor static for
  select package_id, 
	 	 package_code,
         package_desc
    from outpost_package
   where campaign_no = @campaign_no
order by package_code
     for read only

/*
 * Loop Packages
 */
 	
open package_csr
fetch package_csr into @package_id, @package_code, @package_desc
while(@@fetch_status=0)
begin

    /*
     * Calculate "Active" spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           1,
           1,
           "Active",
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate)
	  from outpost_spot
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_status = 'A'

    /*
     * Calculate 'Allocated' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           1,
           2,
           'Allocated',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate)
	  from outpost_spot
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_status = 'X'

    /*
     * Calculate 'Allocated' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           1,
           3,
           "Proposed",
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate)
	  from outpost_spot
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_status = 'P'
	
    /*
     * Calculate 'Unallocated' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           2,
           4,
           'Unallocated',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate)
	  from outpost_spot
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_status = 'U'

    /*
     * Calculate 'No Show' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           2,
           5,
           'No Show',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate)
	  from outpost_spot
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_status = 'N'

    /*
     * Calculate 'Cancelled' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           3,
           6,
           'Cancelled',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate)
	  from outpost_spot
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_status = 'C'
	
    /*
     * Calculate 'On Hold' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           3,
           7,
           'On Hold',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate)
	  from outpost_spot
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_status = 'H'

    /*
     * Calculate 'Deleted' spot totals
     */
     
	insert into #results
	select @package_code,
           @package_desc,
           3,
           8,
           'Deleted',
		   isnull(sum(rate),0),
		   isnull(sum(charge_rate),0),
		   isnull(sum(makegood_rate),0),
		   count(charge_rate)
	  from outpost_spot
	 where campaign_no = @campaign_no and
		   package_id = @package_id and
		   spot_status = 'D'
	
    /*
     * Fetch Next
     */
     
    fetch package_csr into @package_id, @package_code, @package_desc

end

close package_csr
deallocate package_csr

/*
 * Return Result Set
 */
 
select package_code,
	   package_desc,
	   display_group,
	   display_order,
	   label,
       value,
       charge,
       makegood,
	   number
  from #results

return 0
GO
