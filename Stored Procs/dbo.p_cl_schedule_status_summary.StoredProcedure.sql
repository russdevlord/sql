/****** Object:  StoredProcedure [dbo].[p_cl_schedule_status_summary]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_schedule_status_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_schedule_status_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  PROC [dbo].[p_cl_schedule_status_summary] @campaign_no 	   integer	  
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
         @product_desc          varchar(100)

/*
 * Create Results Table
 */
 
create table #results 
(
	campaign_no		    varchar(6)		    null,
	product_desc		varchar(100)		null,
	display_group		smallint		    null,
	display_order		smallint		    null,
	label				varchar(50)		    null,
    value				money				null,
    charge				money				null,
    makegood			money				null,
	number				integer				null
)

/*
 * Get Product Desc
 */

select @product_desc = product_desc
  from film_campaign
 where campaign_no = @campaign_no

/*
 * Calculate 'Scheduled' spot totals
 */
 
insert into #results
select convert(varchar(6),@campaign_no),
       @product_desc,
       1,
       1,
       'Active',
	   isnull(sum(rate),0),
	   isnull(sum(charge_rate),0),
	   isnull(sum(makegood_rate),0),
	   count(charge_rate)
  from cinelight_spot
 where campaign_no = @campaign_no and
	   spot_status = 'A'


/*
 * Calculate 'Scheduled' spot totals
 */
 
insert into #results
select convert(varchar(6),@campaign_no),
       @product_desc,
       2,
       2,
       'Allocated',
	   isnull(sum(rate),0),
	   isnull(sum(charge_rate),0),
	   isnull(sum(makegood_rate),0),
	   count(charge_rate)
  from cinelight_spot
 where campaign_no = @campaign_no and
	   spot_status = 'X'

/*
 * Calculate 'Standby' spot totals
 */
 
insert into #results
select convert(varchar(6),@campaign_no),
       @product_desc,
       2,
       3,
       'Unallocated',
	   isnull(sum(rate),0),
	   isnull(sum(charge_rate),0),
	   isnull(sum(makegood_rate),0),
	   count(charge_rate)
  from cinelight_spot
 where campaign_no = @campaign_no and
	   spot_status = 'U'

/*
 * Calculate 'Contra' spot totals
 */
 
insert into #results
select convert(varchar(6),@campaign_no),
       @product_desc,
       2,
       4,
       'No Show',
	   isnull(sum(rate),0),
	   isnull(sum(charge_rate),0),
	   isnull(sum(makegood_rate),0),
	   count(charge_rate)
  from cinelight_spot
 where campaign_no = @campaign_no and
	   spot_status = 'N'
	   
/*
 * Calculate 'Makeup' spot totals
 */
 
insert into #results
select convert(varchar(6),@campaign_no),
       @product_desc,
       2,
       5,
       'Rev Unalloc',
	   isnull(sum(rate),0),
	   isnull(sum(charge_rate),0),
	   isnull(sum(makegood_rate),0),
	   count(charge_rate)
  from cinelight_spot
 where campaign_no = @campaign_no and
	   spot_status = 'R'	   

/*
 * Calculate 'Bonus' spot totals
 */
 
insert into #results
select convert(varchar(6),@campaign_no),
       @product_desc,
       3,
       6,
       'On Hold',
	   isnull(sum(rate),0),
	   isnull(sum(charge_rate),0),
	   isnull(sum(makegood_rate),0),
	   count(charge_rate)
  from cinelight_spot
 where campaign_no = @campaign_no and
	   spot_status = 'H'

/*
 * Calculate 'No Charge' spot totals
 */
 
insert into #results
select convert(varchar(6),@campaign_no),
       @product_desc,
       3,
       7,
       'Cancelled',
	   isnull(sum(rate),0),
	   isnull(sum(charge_rate),0),
	   isnull(sum(makegood_rate),0),
	   count(charge_rate)
  from cinelight_spot
 where campaign_no = @campaign_no and
	   spot_status = 'C'

/*
 * Calculate 'Goodwill' spot totals
 */
 
insert into #results
select convert(varchar(6),@campaign_no),
       @product_desc,
       3,
       8,
       'Deleted',
	   isnull(sum(rate),0),
	   isnull(sum(charge_rate),0),
	   isnull(sum(makegood_rate),0),
	   count(charge_rate)
  from cinelight_spot
 where campaign_no = @campaign_no and
	   spot_status = 'D'



/*
 * Calculate 'Manual' spot totals
 */
 
insert into #results
select convert(varchar(6),@campaign_no),
       @product_desc,
       4,
       9,
       'Proposed',
	   isnull(sum(rate),0),
	   isnull(sum(charge_rate),0),
	   isnull(sum(makegood_rate),0),
	   count(charge_rate)
  from cinelight_spot
 where campaign_no = @campaign_no and
	   spot_status = 'P'

/*
 * Return Result Set
 */
 
select campaign_no,
	   product_desc,
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
