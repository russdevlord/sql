/****** Object:  StoredProcedure [dbo].[p_campaign_complex_prints]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_complex_prints]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_complex_prints]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC  [dbo].[p_campaign_complex_prints] @campaign_no  	integer, 
													@type				integer,
													@print_id		integer

as

declare 	@error  int

begin transaction

/* 
*  if print_id is selected as zero do inserts for all prints for a campaign 
*  if an actual print is selected do the inserts for that print only
*/

if (@print_id = 0)	
begin

	if (@type = 1) or (@type = 2)
	begin

		insert into #comp_date_prints (
				 	campaign_no,
				 	print_id,
				 	screening_date,
			 	 	complex_id,
				 	complex_name,
				 	pack_count )
		  select spot.campaign_no,
				 	ppack.print_id,
		 		 	spot.screening_date,
				 	cplx.complex_id,
				 	min(cplx.complex_name),
				 	count(ppack.print_id)
		 	 from campaign_spot spot,
				 	campaign_package cp,
				 	print_package ppack,
				 	complex cplx
		   where	spot.package_id = cp.package_id and
				 	cp.package_id = ppack.package_id and
		 		 	spot.complex_id = cplx.complex_id and
					spot.campaign_no = @campaign_no 
		group by spot.campaign_no,
					ppack.print_id,
					spot.screening_date,
					cplx.complex_id
		
		  select @error = @@error
		  if ( @error !=0 )
		  begin
				rollback transaction
				raiserror ( 'Error p_campaign_complex_prints', 16, 1) 
				return @error
		  end	
		
		insert into #comp_prints (
					campaign_no,
					print_id,
					start_date,
					complex_id,
					complex_name,
					pack_max )
		  select campaign_no,
					print_id,
					min(screening_date),
					complex_id,
					min(complex_name),
					max(pack_count)
			 from #comp_date_prints
		group by campaign_no,
					print_id,
					complex_id
					
		  select @error = @@error
		  if ( @error !=0 )
		  begin
				rollback transaction
				raiserror ( 'Error p_campaign_complex_prints', 16, 1) 
				return @error 
		  end	
	end
	if (@type = 2)
	begin 

	 	insert into #comp_prints (
					campaign_no,
					print_id,
					start_date,
					complex_id,
					complex_name,
					pack_max )
		  select min(cpack.campaign_no),
					ptran.print_id,
					null,
					ptran.complex_id,
					cplx.complex_name,
					0
			 from campaign_package cpack,
					print_package ppack,
					film_print fp,
					print_transactions ptran,
					complex cplx
			where cpack.campaign_no = @campaign_no and
					cpack.package_id = ppack.package_id and
					ppack.print_id = fp.print_id and
					fp.print_id = ptran.print_id and
					ptran.complex_id is not null and
					not exists (
						 select complex_id 
							from #comp_prints cp
						  where cp.complex_id = ptran.complex_id and
								  cp.print_id = ptran.print_id  ) and
					ptran.complex_id = cplx.complex_id 
		group by ptran.print_id,
					ptran.complex_id,
					cplx.complex_name

		  select @error = @@error
		  if ( @error !=0 )
		  begin
				rollback transaction
				raiserror ( 'Error p_campaign_complex_prints', 16, 1) 
				return @error 
		  end	

		/*
		* Insert Print Transactions for those prints not in schedule at all
		*/

		insert into #comp_prints (
					campaign_no,
					print_id,
					start_date,
					complex_id,
					complex_name,
					pack_max )
		  select min(@campaign_no),
					ptran.print_id,
					null,
					ptran.complex_id,
					cplx.complex_name,
					0
			 from film_print fp,
					print_transactions ptran,
					complex cplx
			where ptran.campaign_no = @campaign_no and
					fp.print_id = ptran.print_id and
					ptran.complex_id is not null and
					not exists (
						 select complex_id 
							from #comp_prints cp
						  where cp.complex_id = ptran.complex_id and
								  cp.print_id = ptran.print_id
								  ) and
					ptran.complex_id = cplx.complex_id 
		group by ptran.print_id,
					ptran.complex_id,
					cplx.complex_name
					
		  select @error = @@error
		  if ( @error !=0 )
		  begin
				rollback transaction
				raiserror ( 'Error p_campaign_complex_prints', 16, 1) 
				return @error
		  end	
	end
end

else
begin
	if (@type = 1) or (@type = 2)
	begin

		insert into #comp_date_prints (
					campaign_no,
					print_id,
					screening_date,
					complex_id,
					complex_name,
					pack_count )
		 select  spot.campaign_no,
					ppack.print_id,
					spot.screening_date,
					cplx.complex_id,
					min(cplx.complex_name),
					count(ppack.print_id)
			 from campaign_spot spot,
					campaign_package cp,
					print_package ppack,
					complex cplx
			where spot.package_id = cp.package_id and
					cp.package_id = ppack.package_id and
					spot.complex_id = cplx.complex_id and
					spot.campaign_no = @campaign_no and 
					ppack.print_id = @print_id
		group by spot.campaign_no,
					ppack.print_id,
					spot.screening_date,
					cplx.complex_id
					
		  select @error = @@error
		  if ( @error !=0 )
		  begin
				rollback transaction
				raiserror ( 'Error p_campaign_complex_prints', 16, 1) 
				return @error 
		  end	
					
		insert into #comp_prints (
					campaign_no,
					print_id,
					start_date,
					complex_id,
					complex_name,
					pack_max )
		  select campaign_no,
					print_id,
					min(screening_date),
					complex_id,
					min(complex_name),
					max(pack_count)
	   	 from #comp_date_prints
		group by campaign_no,
					print_id,
					complex_id
					
		  select @error = @@error
		  if ( @error !=0 )
		  begin
				rollback transaction
				raiserror ( 'Error p_campaign_complex_prints', 16, 1) 
				return @error 
		  end	
	end
	if (@type = 2)
	begin 
		insert into #comp_prints (
					campaign_no,
					print_id,
					start_date,
					complex_id,
					complex_name,
					pack_max )
		  select min(cpack.campaign_no),
					ptran.print_id,
					null,
					ptran.complex_id,
					cplx.complex_name,
					0
	 		 from campaign_package cpack,
					print_package ppack,
					film_print fp,
					print_transactions ptran,
					complex cplx
			where cpack.campaign_no = @campaign_no and
					cpack.package_id = ppack.package_id and
					ppack.print_id = fp.print_id and
					fp.print_id = ptran.print_id and
					ptran.complex_id is not null and
					not exists (
						 select complex_id 
							from #comp_prints cp
						  where cp.complex_id = ptran.complex_id and
								  cp.print_id = ptran.print_id  ) and
					ptran.complex_id = cplx.complex_id and
					fp.print_id = @print_id
		group by ptran.print_id,
					ptran.complex_id,
					cplx.complex_name
					
		  select @error = @@error
		  if ( @error !=0 )
		  begin
				rollback transaction
				raiserror ( 'Error p_campaign_complex_prints', 16, 1) 
				return @error 
		  end	
					
		/*
		* Insert Print Transactions for those prints not in schedule at all
		*/
					
		insert into #comp_prints (
					campaign_no,
					print_id,
					start_date,
					complex_id,
					complex_name,
					pack_max )
		  select min(@campaign_no),
					ptran.print_id,
					null,
					ptran.complex_id,
					cplx.complex_name,
					0
			 from film_print fp,
					print_transactions ptran,
					complex cplx
					where ptran.campaign_no = @campaign_no and
					fp.print_id = ptran.print_id and
					ptran.complex_id is not null and
					not exists (
						 select complex_id 
							from #comp_prints cp
						  where cp.complex_id = ptran.complex_id and
								  cp.print_id = ptran.print_id
								  ) and
					ptran.complex_id = cplx.complex_id and
					fp.print_id = @print_id
		group by ptran.print_id,
					ptran.complex_id,
					cplx.complex_name
					
		  select @error = @@error
		  if ( @error !=0 )
		  begin
				rollback transaction
				raiserror ( 'Error p_campaign_complex_prints', 16, 1) 
				return @error 
		  end	
	end
end

commit transaction
return 0
GO
