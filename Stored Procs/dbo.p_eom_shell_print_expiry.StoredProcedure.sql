/****** Object:  StoredProcedure [dbo].[p_eom_shell_print_expiry]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_shell_print_expiry]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_shell_print_expiry]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_eom_shell_print_expiry] @accounting_period		datetime
as

/*
 * Declare Variables
 */

declare @error        			integer,
        @rowcount     			integer,
        @errorode						integer,
        @errno						integer,
        @found						tinyint,
        @shell_code				char(7),
        @shell_perm				char(1),
        @screening_date			datetime,
        @shell_expiry_date		datetime,
        @print_count				integer,
        @complex_count			integer,
        @date_count				integer,
        @print_id					integer,
        @campaign_usage			integer,
        @shell_usage				integer

/*
 * Declare Cursors
 */



/*
 * Get Current Screening Date
 */

select @screening_date = screening_date
  from film_screening_dates
 where screening_date_status = 'C'

/*
 * Begin Transaction
 */

begin transaction

/*
 * Expire Shells
 */

 declare shell_csr cursor static for 
  select fs.shell_code,
         fs.shell_permanent,
         fs.shell_expiry_date
    from film_shell fs   
   where fs.shell_expired = 'N'
order by fs.shell_code
     for read only

open shell_csr
fetch shell_csr into @shell_code, @shell_perm, @shell_expiry_date
while(@@fetch_status = 0)
begin

	select @found = 0
	
	/*
    * Check Expiry Date
    */

	if(@shell_expiry_date is not null)
		if(@shell_expiry_date > @screening_date)
			select @found = 1

	/*
    * Check Valid Complexes
    */

	if(@found = 0)
	begin

		select @complex_count = isnull(count(cplx.complex_id),0)
		  from film_shell_xref shell,
				 complex cplx
		 where shell.shell_code = @shell_code and
				 shell.complex_id = cplx.complex_id and
				 cplx.film_complex_status <> 'C' --Closed
	
		if(@complex_count > 0)
			select @found = 1

	end

	/*
    * Count Prints
    */

	if(@found = 0)
	begin

		select @print_count = isnull(count(fsp.print_id),0)
        from film_shell_print fsp
       where fsp.shell_code = @shell_code

		if(@print_count > 0)
			select @found = 1

	end

	/*
    * Check Valid Dates
    */

	if(@shell_perm = 'N' and @found = 0)
	begin

		select @date_count = isnull(count(shell.screening_date),0)
        from film_shell_dates shell
       where shell.shell_code = @shell_code and
             shell.screening_date >= @screening_date

		if(@date_count > 0)
			select @found = 1

	end

	/*
    * Expire Shell
    */

	if(@found = 0)
	begin

		if(@shell_expiry_date is null)
			update film_shell
				set shell_expired = 'Y',
                shell_expiry_date = @accounting_period
			 where shell_code = @shell_code
		else
			update film_shell
				set shell_expired = 'Y'
			 where shell_code = @shell_code

		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			raiserror ('Error : Failed to update film shell.', 16, 1)
			return -1
		end	

	end

	/*
    * Fetch Next
    */

	fetch shell_csr into @shell_code, @shell_perm, @shell_expiry_date

end
close shell_csr
deallocate shell_csr

/*
 * Expire House / Complex Prints
 */

 declare print_csr cursor static for 
  select print_id
    from film_print
   where print_status = 'A' and --Active
       ( print_type = 'H' or --House
         print_type = 'X' )  --Complex
order by print_id
     for read only

open print_csr
fetch print_csr into @print_id
while(@@fetch_status = 0)
begin

	select @campaign_usage = 0,
          @shell_usage = 0,
          @found = 0

	/*
    * Check Other Campaigns
    */

	select @campaign_usage = isnull(count(fcp.print_id),0)
     from film_campaign_prints fcp,
          film_campaign fc
    where fcp.print_id = @print_id and
          fcp.campaign_no = fc.campaign_no and
          fc.campaign_status in ('P','L','F')

	if(@campaign_usage > 0)
		select @found = 1

	/*
    * Check Shell Usage
    */

	if(@found = 0)
	begin

		select @shell_usage = isnull(count(fsp.print_id),0)
		  from film_shell_print fsp,
				 film_shell fs
		 where fsp.print_id = @print_id and
             fsp.shell_code = fs.shell_code and
				 fs.shell_expired = 'N'

		if(@shell_usage = 0)
		begin
			
			update film_print
				set print_status = 'E'
			 where print_id = @print_id
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				raiserror ('Error : Failed to update film print.', 16, 1)
				close print_csr
				return -1
			end	
	
		end

	end
	
	/*
    * Fetch Next
    */

	fetch print_csr into @print_id

end
close print_csr
deallocate print_csr

/*
 * Commit and Return
 */

commit transaction
return 0
GO
