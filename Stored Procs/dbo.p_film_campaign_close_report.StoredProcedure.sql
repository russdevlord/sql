/****** Object:  StoredProcedure [dbo].[p_film_campaign_close_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_close_report]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_close_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_film_campaign_close_report]
as

/*
 * Declare Variables
 */

declare @error								integer,
				@errorode							integer,
				@makeup						datetime,
				@first_name					varchar(30),
				@last_name					varchar(30),
				@campaign_no			integer,
				@product_desc			varchar(100),
				@start_date					datetime,
				@end_date						datetime

/*
 * Create Temporary Table
 */

create table #closures
(
	campaign_no					int,
	product_desc					varchar(100),
	start_date							datetime,
	end_date							datetime,
	makeup_deadline		datetime,
	first_name						varchar(30),
	last_name						varchar(30)
)

/*
 * Create Cursor
 */

declare		campaign_csr cursor static for
select		fc.campaign_no,
					fc.product_desc,
					fc.start_date,
					fc.end_date,
					fc.makeup_deadline,
					sr.first_name,
					sr.last_name
from			film_campaign fc,
					sales_rep sr
where		fc.campaign_status = 'F' 
and				fc.rep_id = sr.rep_id
for				read only

/*
 * Loop Cursor
 */

open campaign_csr
fetch campaign_csr into @campaign_no, @product_desc, @start_date, @end_date, @makeup, @first_name, @last_name
while( @@fetch_status = 0)
begin

	/*
    * Check Campaign
    */

	execute @errorode = p_film_campaign_close_check @campaign_no, 'N'
	if (@errorode=0)
	begin
		insert into #closures values (@campaign_no, @product_desc, @start_date, @end_date, @makeup, @first_name, @last_name)
	end

	/*
    * fetch Next Row
    */

	fetch campaign_csr into @campaign_no, @product_desc, @start_date, @end_date, @makeup, @first_name, @last_name

end
close campaign_csr
deallocate campaign_csr

/*
 * Return Dataset
 */

select * from #closures

/*
 * Return Success
 */

return 0
GO
