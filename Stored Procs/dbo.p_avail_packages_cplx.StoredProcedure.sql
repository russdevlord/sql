/****** Object:  StoredProcedure [dbo].[p_avail_packages_cplx]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_avail_packages_cplx]
GO
/****** Object:  StoredProcedure [dbo].[p_avail_packages_cplx]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_avail_packages_cplx]  @campaign_no		int,
                                   @complex_id      int,
                                   @screening_date  datetime
as
set nocount on 
declare  @error                         int,
         @package_id                    int,
         @print_id                      int,
         @spots_at_complex              int,
         @print_avail_at_complex        int,
         @add_package                   char(1)

create table #packages
(
package_id          int         not null
)
                                     
  declare package_csr cursor static for 
   select package_id
     from campaign_package
    where used_by_date >= @screening_date
      and campaign_no = @campaign_no
 order by package_id
      for read only 
      
open package_csr
fetch package_csr into @package_id
while(@@fetch_status=0)
begin

    select @add_package = 'Y'
            
    select @spots_at_complex = isnull(count(spot_id),0)
      from campaign_spot
     where campaign_no = @campaign_no
       and package_id = @package_id
       and complex_id = @complex_id
       and screening_date = @screening_date
       and spot_status <> 'U' 
       and spot_status <> 'N'

  declare print_package_csr cursor static for
   select print_id
     from print_package
    where package_id = @package_id
 order by print_id
      for read only
      
    open print_package_csr
    fetch print_package_csr into @print_id
    while(@@fetch_status=0)
    begin

	    select @print_avail_at_complex = IsNull(sum(cinema_qty),0)
	      from print_transactions
	     where (campaign_no = @campaign_no or
		       campaign_no is null) and
			   print_id = @print_id and
			   ptran_status = 'C' and
               complex_id = @complex_id


        if @print_avail_at_complex > @spots_at_complex and @add_package = 'Y'
            select @add_package = 'Y'
        else
            select @add_package = 'N'
            
        fetch print_package_csr into @print_id
    end
    
    close print_package_csr
    deallocate print_package_csr
    
    if @add_package = 'Y'
        insert into #packages (package_id) values (@package_id)
    fetch package_csr into @package_id
end

close package_csr
deallocate package_csr


select cp.package_id,
       cp.package_code,
       cp.package_desc,
       cp.rate,
       cp.prints,
       cp.duration
  from #packages p,
       campaign_package cp    
 where cp.package_id = p.package_id
return 0
GO
