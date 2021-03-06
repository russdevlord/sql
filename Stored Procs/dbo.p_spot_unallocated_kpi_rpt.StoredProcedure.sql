/****** Object:  StoredProcedure [dbo].[p_spot_unallocated_kpi_rpt]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_spot_unallocated_kpi_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_spot_unallocated_kpi_rpt]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_spot_unallocated_kpi_rpt]  @start_date         datetime,
                                        @end_date           datetime
as

declare @error                      int,
        @rep_id                     int,
        @campaign_no                int,
        @product_desc               varchar(100),
        @rep_name                   varchar(61),
        @count_scheduled            int,
        @count_unallocateds         int,
        @count_noshows              int,    
        @total_unallocateds         int,
        @total_noshows              int,    
        @spot_instruction           varchar(100),
        @media_product_desc         varchar(30),
        @media_product_id           int,
        @country_name               varchar(30)
        
/*
 * Declare Temporary Table
 */        
 
create table #kpi
(
    rep_id                  int             null,
    campaign_no             int             null,
    product_desc            varchar(100)    null,
    rep_name                varchar(61)     null,
    count_scheduled         int             null,
    count_unallocateds      int             null,
    count_noshows           int             null,
    total_unallocateds      int             null,
    total_noshows           int             null,    
    spot_instruction        varchar(100)    null,
    media_product_desc      varchar(30)     null,
    country_name            varchar(30)     null
)

 declare kpi_csr cursor static for
  select fc.rep_id,
         convert(varchar(61), convert(varchar(30), sr.first_name) + ' ' + convert(varchar(30), sr.last_name)),
         fc.campaign_no,
         fc.product_desc,
         c.country_name,
         cp.media_product_id
    from film_campaign fc, 
         campaign_spot cs,
         campaign_package cp,
         sales_rep sr,
         branch b,
         country c
   where fc.campaign_no = cs.campaign_no
     and fc.rep_id = sr.rep_id
     and cs.screening_date <= @end_date
     and cs.screening_date >= @start_date
     and fc.branch_code = b.branch_code
     and b.country_code = c.country_code
     and cp.campaign_no = fc.campaign_no
     and cp.campaign_no = cs.campaign_no
     and cp.package_id = cs.package_id
group by fc.rep_id,
         sr.first_name,
         sr.last_name,
         fc.campaign_no,
         fc.product_desc,
         c.country_name,
         cp.media_product_id     
order by fc.rep_id,
         sr.first_name,
         sr.last_name,
         fc.campaign_no,
         fc.product_desc,
         c.country_name      
     for read only
      
open kpi_csr
fetch kpi_csr into   @rep_id, @rep_name, @campaign_no, @product_desc, @country_name, @media_product_id
while(@@fetch_status=0)
begin

    select @media_product_desc = media_product_desc
      from media_product
     where media_product_id = @media_product_id

    select @count_scheduled = count(spot_id)
      from campaign_spot cs,
           campaign_package cp
     where cs.campaign_no = @campaign_no 
       and cs.screening_date <= @end_date
       and cs.screening_date >= @start_date
       and spot_status != 'P'
       and spot_status != 'C'
       and spot_status != 'D'
       and spot_type = 'S'
       and cp.media_product_id = @media_product_id
       and cp.campaign_no = cs.campaign_no
       and cp.package_id = cs.package_id
       
    select @total_unallocateds = count(spot_id)
      from campaign_spot cs,
           campaign_package cp
     where cs.campaign_no = @campaign_no 
       and cs.screening_date <= @end_date
       and cs.screening_date >= @start_date
       and spot_status = 'U'
       and spot_type = 'S'
       and cp.media_product_id = @media_product_id
       and cp.campaign_no = cs.campaign_no
       and cp.package_id = cs.package_id
       
    select @total_noshows  = count(spot_id)
      from campaign_spot cs,
           campaign_package cp
     where cs.campaign_no = @campaign_no 
       and cs.screening_date <= @end_date
       and cs.screening_date >= @start_date
       and spot_status = 'N'
       and spot_type = 'S'
       and cp.media_product_id = @media_product_id
       and cp.campaign_no = cs.campaign_no
       and cp.package_id = cs.package_id

	 declare spot_ins_csr cursor static for
	  select cs.spot_instruction
	    from campaign_spot cs,
	         campaign_package cp
	   where cs.campaign_no = @campaign_no
	     and cs.screening_date <= @end_date
	     and cs.screening_date >= @start_date
	     and spot_instruction != 'No Errors'
	     and spot_instruction is not null
	     and spot_instruction != ''
	     and cp.campaign_no = cs.campaign_no
	     and cp.package_id = cs.package_id
	     and cp.media_product_id = @media_product_id
	group by cs.spot_instruction
	order by cs.spot_instruction
	     for read only
     
    open spot_ins_csr 
    fetch spot_ins_csr into @spot_instruction
    while(@@fetch_status=0)
    begin

        select @count_unallocateds = count(spot_id)
          from campaign_spot cs,
               campaign_package cp
         where cs.campaign_no = @campaign_no 
           and cs.screening_date <= @end_date
           and cs.screening_date >= @start_date
           and spot_status = 'U'
           and spot_type = 'S'
           and spot_instruction = @spot_instruction
           and cp.media_product_id = @media_product_id
           and cp.campaign_no = cs.campaign_no
           and cp.package_id = cs.package_id
           
        select @count_noshows  = count(spot_id)
          from campaign_spot cs,
               campaign_package cp
         where cs.campaign_no = @campaign_no 
           and cs.screening_date <= @end_date
           and cs.screening_date >= @start_date
           and spot_status = 'N'
           and spot_type = 'S'
           and spot_instruction = @spot_instruction
           and cp.media_product_id = @media_product_id
           and cp.campaign_no = cs.campaign_no
           and cp.package_id = cs.package_id
          
        insert into #kpi (
            rep_id,
            campaign_no,
            product_desc,
            rep_name,
            count_scheduled,
            count_unallocateds,
            count_noshows, 
            total_noshows,
            total_unallocateds,
            spot_instruction,
            country_name,
            media_product_desc) values
            (@rep_id,
            @campaign_no,
            @product_desc,
            @rep_name,
            @count_scheduled,
            @count_unallocateds,
            @count_noshows, 
            @total_noshows,
            @total_unallocateds,
            @spot_instruction,
            @country_name,
            @media_product_desc)
            
        fetch spot_ins_csr into @spot_instruction            
    end
    close spot_ins_csr
    deallocate spot_ins_csr

    fetch kpi_csr into   @rep_id, @rep_name, @campaign_no, @product_desc, @country_name, @media_product_id
end

deallocate kpi_csr
        
select * from #kpi order by rep_id, campaign_no          

return 0
GO
