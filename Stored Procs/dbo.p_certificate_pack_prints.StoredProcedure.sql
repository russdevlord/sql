/****** Object:  StoredProcedure [dbo].[p_certificate_pack_prints]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_pack_prints]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_pack_prints]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_certificate_pack_prints] @campaign_no			int,
                                      @package_id			int,
                                      @complex_id			int,
                                      @screening_date		datetime
												 
as

/*
 * Declare Variables
 */

declare @sequence					int,
		@print_id					int,
        @print_name					varchar(50),
        @cinema_prints				int,
		@unalloc_cinema_prints		int,
        @used_prints				int,
        @avail_prints				int,
        @last_print					int,
        @show						char(1),
        @print_spacing				smallint,
        @shell_section				smallint,
		@duration					smallint,
		@print_status				char(1),
		@print_type					char(1),
        @generated          		char(1),
		@print_medium				char(1),
		@three_d_type				integer,
		@digital_only				integer


/*
 * Determine if Complex is digital only
 */

select 	@digital_only = count(print_medium) 
from 	complex_digital_medium 
where 	complex_id in (select complex_id from complex_digital_medium where complex_id = @complex_id and print_medium = 'D')

/*
 * Create Table to Hold Availability Information
 */

create table #prints
(
	sequence_no			smallint			null,
	print_id			int		        	null,
	print_name			varchar(50)	    	null,
	duration			smallint			null,
	print_status		char(1)		    	null,
	print_type			char(1)		    	null,
	print_spacing		smallint			null,
    shell_section		smallint			null,
    cinema_prints		int			        null,
	used_prints			int			        null,
	avail_prints		int		        	null,
	show_print			char(1)		    	null
)

/*
 * Initialise Variables
 */

select 	@cinema_prints = 0,
       	@used_prints = 0,
       	@avail_prints = 0,
       	@last_print = 0,
		@unalloc_cinema_prints = 0

select @generated = certificate_status
  from complex_date
 where complex_id = @complex_id 
   and screening_date = @screening_date


/*
 * Declare Cursors
 */

 declare print_csr cursor static for
  select fp.print_id,
		 fp.print_name,
		 fp.duration,
		 fp.print_status,
		 fp.print_type,
         pp.print_sequence,
         pp.print_spacing,
         pp.shell_section
    from print_package pp,
         film_print fp
   where pp.package_id = @package_id and
		 pp.print_id = fp.print_id
order by fp.print_id ASC,
         pp.print_sequence ASC
     for read only


/*
 * Loop Prints
 */

open print_csr
fetch print_csr into @print_id, @print_name, @duration, @print_status, @print_type, @sequence, @print_spacing, @shell_section
while(@@fetch_status=0)
begin


	select @show = 'N'

	if(@last_print <> @print_id)
	begin

		/*
		 * Calculate Prints in Cinema
		 */

		select @cinema_prints = isnull(sum(cinema_qty),0)
		  from print_transactions pt
		 where campaign_no = @campaign_no and
			   print_id = @print_id and
			   complex_id = @complex_id and
			   (pt.ptran_type = 'A' or
			   pt.ptran_type = 'T' or 
			   pt.ptran_type = 'S' or
			   pt.ptran_type = 'D' or 
			   pt.ptran_type = 'L') and
			   pt.ptran_status = 'C' and
			((@digital_only = 1
			and			print_medium = 'D')
			or			(@digital_only <> 1
			and			print_medium = 'F'))

		select @unalloc_cinema_prints = isnull(sum(cinema_qty),0)
		  from print_transactions pt
		 where campaign_no is null and
			   print_id = @print_id and
			   complex_id = @complex_id and
			   (pt.ptran_type = 'A' or
			   pt.ptran_type = 'T' or 
			   pt.ptran_type = 'S' or
			   pt.ptran_type = 'D' or 
			   pt.ptran_type = 'L') and
			   pt.ptran_status = 'C' and
			((@digital_only = 1
			and			print_medium = 'D')
			or			(@digital_only <> 1
			and			print_medium = 'F'))
		/*
		 * Calculate Prints used
		 */
	
        if @generated = 'G' or @generated = 'E'
		    select @used_prints = isnull(count(ci.print_id),0) 
		      from certificate_item ci,
			       certificate_group cg,
                   campaign_spot spot
		     where ci.certificate_group = cg.certificate_group_id and
                   cg.complex_id = @complex_id and
			       cg.screening_date = @screening_date and
			       ci.item_show = 'Y' and
			       ci.print_id = @print_id and
			       ci.spot_reference = spot.spot_id and
			       spot.campaign_no = @campaign_no
        else if @generated = 'N'
            select @used_prints = max(temp_table.count) from (select count(ppack.print_id) as count
													          from campaign_spot spot,
															       campaign_package cp,
															       print_package ppack
													         where spot.package_id = cp.package_id and
															       cp.package_id = ppack.package_id and
															       ppack.print_id = @print_id and
															       spot.complex_id = @complex_id and
															       spot.campaign_no = @campaign_no and
															       spot.screening_date = @screening_date) as temp_table
        else if @generated = 'U'
            select @used_prints =  @cinema_prints
                    
	
	  /*
       * Calculate Available Prints
       */

		select @avail_prints = @cinema_prints + @unalloc_cinema_prints - @used_prints

	end

	/*
	 * Check available prints and set show flag
	 */
 
	if(@avail_prints <= 0)
		select @avail_prints = 0
	else
		select @show = 'Y'
             

	/*
    * Insert Print
    */

	insert into #prints (
	       sequence_no,
	       print_id,
	       print_name,
		   duration,
		   print_status,
		   print_type,
	       print_spacing,
           shell_section,
           cinema_prints,
	       used_prints,
	       avail_prints,
	       show_print ) values (
           @sequence,
           @print_id,
	       @print_name,
		   @duration,
		   @print_status,
		   @print_type,
	       @print_spacing,
           @shell_section,
           @cinema_prints,
	       @used_prints,
	       @avail_prints,
           @show)

	/*
	 * Fetch Next
	 */

	select @last_print = @print_id
    fetch print_csr into @print_id, @print_name, @duration, @print_status, @print_type, @sequence, @print_spacing, @shell_section
end

close print_csr
deallocate print_csr

/*
 * Return Package Prints Data
 */

select sequence_no,
	   print_id,
	   print_name,
	   duration,
	   print_status,
	   print_type,
	   print_spacing,
       shell_section,
       cinema_prints,
	   used_prints,
	   avail_prints,
	   show_print
  from #prints

/*
 * Return Success
 */

return 0
GO
