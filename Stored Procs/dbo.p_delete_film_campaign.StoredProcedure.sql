/****** Object:  StoredProcedure [dbo].[p_delete_film_campaign]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_film_campaign]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_film_campaign]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_delete_film_campaign]		@campaign_no		integer

as

declare @error          integer,
        @rowcount		integer,
        @rev_count		integer


/*
 * Begin Transaction
 */

begin transaction

delete outpost_playlist_spot_xref where spot_id in (select spot_id from outpost_spot where campaign_no = @campaign_no)

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Spot Xref.', 16, 1) 
	rollback transaction
	return -1
end

delete cinetam_inclusion_settings where inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no)

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Spot Xref.', 16, 1) 
	rollback transaction
	return -1
end


delete cinetam_campaign_targets
   where campaign_no = @campaign_no 

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Spot Xref.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Spot Xref
 */

delete film_spot_xref
  from campaign_spot
 where campaign_spot.campaign_no = @campaign_no and
		 campaign_spot.spot_id = film_spot_xref.spot_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Spot Xref.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Spot Xref
 */
delete inclusion_spot_xref
  from inclusion_spot
 where inclusion_spot.campaign_no = @campaign_no and
		 inclusion_spot.spot_id = inclusion_spot_xref.spot_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Spot Xref.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Certificate Item
 */
delete certificate_item
  from campaign_spot
 where campaign_spot.campaign_no = @campaign_no and
		 campaign_spot.spot_id = certificate_item.spot_reference

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Certificate Item.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Spot Liability
 */

delete spot_liability
  from campaign_spot
 where campaign_spot.campaign_no = @campaign_no and	
   	 campaign_spot.spot_id = spot_liability.spot_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Spot Liability.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Plan Complex
 */
delete film_plan_complex
  from film_plan
 where film_plan.campaign_no = @campaign_no and	
   	 film_plan.film_plan_id = film_plan_complex.film_plan_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Plan Complex.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Plan Dates
 */
delete film_plan_dates
  from film_plan
 where film_plan.campaign_no = @campaign_no and	
   	 film_plan.film_plan_id = film_plan_dates.film_plan_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Plan Dates.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Track
 */
delete film_track
 where film_track.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Track.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Transaction Allocation
 */
delete transaction_allocation
  from campaign_transaction
 where campaign_transaction.campaign_no = @campaign_no and	
   	 (campaign_transaction.tran_id = transaction_allocation.to_tran_id or
   	 campaign_transaction.tran_id = transaction_allocation.from_tran_id)

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Transaction Allocation.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Campaign Spot
 */
delete campaign_spot
 where campaign_spot.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Campaign Spot.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Cinelight Campaign Complex
 */
delete 	cinelight_spot_xref
from	cinelight_spot
where 	cinelight_spot.campaign_no = @campaign_no
and		cinelight_spot.spot_id = cinelight_spot_xref.spot_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_pattern.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Transaction
 */
delete campaign_transaction
 where campaign_transaction.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Slide Transaction.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Statement
 */
delete statement
 where statement.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Statement.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Campaign Movie Archive
 */
delete film_campaign_movie_archive
 where film_campaign_movie_archive.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Movie Archive.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Campaign Spot Archive
 */
delete film_campaign_spot_archive
 where film_campaign_spot_archive.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Spot Archive.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Plan
 */

delete film_plan
 where film_plan.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Plan.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Campaign Pattern
 */
 
delete film_campaign_pattern
 where film_campaign_pattern.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Pattern.', 16, 1) 
	rollback transaction
	return -1
end

delete cinetam_campaign_package_settings where package_id in (select package_id from campaign_package where campaign_no =  @campaign_no)

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Print Package Print Medium
 */
 
delete print_package_medium
  from campaign_package,
		print_package
 where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = print_package.package_id and
	print_package.print_package_id = print_package_medium.print_package_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Print Package.', 16, 1) 
	rollback transaction
	return -1
end


/*
 * Delete Print Package
 */
delete print_package_three_d
  from campaign_package,
		print_package
 where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = print_package.package_id and
	print_package.print_package_id = print_package_three_d.print_package_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Print Package.', 16, 1) 
	rollback transaction
	return -1
end


/*
 * Delete Print Package
 */
delete print_package
  from campaign_package
 where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = print_package.package_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Print Package.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Campaign Audience
 */
delete campaign_audience
  from campaign_package
 where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = campaign_audience.package_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Campaign Audience.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Campaign Category
 */
delete campaign_category
  from campaign_package
 where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = campaign_category.package_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Campaign Category.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Campaign Classification
 */
delete campaign_classification
  from campaign_package
 where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = campaign_classification.package_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Campaign Classification.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Movie Screening Instructions
 */
delete movie_screening_instructions
  from campaign_package
 where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = movie_screening_instructions.package_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Movie Screening Instructions.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Movie Screening Ins Rev
 */
 
delete campaign_package_ins_xref
from campaign_package
where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = campaign_package_ins_xref.package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end

/*
 * Delete Campaign Package Associate
 */
delete campaign_package_associates
from campaign_package
where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = campaign_package_associates.parent_package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Campaign Package Instructions
 */

delete campaign_package_ins_rev
from campaign_package
where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = campaign_package_ins_rev.package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Campaign Classification Rev
 */
 
delete campaign_classification_rev
from campaign_package
where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = campaign_classification_rev.package_id


select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


/*
 * Delete Campaign Category Rev
 */
 
delete campaign_category_rev
from campaign_package
where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = campaign_category_rev.package_id


select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Campaign Audience Rev
 */
 

delete campaign_audience_rev
from campaign_package
where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = campaign_audience_rev.package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete Movie Screening Ins Rev
 */
 
delete movie_screening_ins_rev
from campaign_package
where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = movie_screening_ins_rev.package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


/*
 * Delete Campaign Package Revision
 */
 
delete campaign_package_revision
from campaign_package
where campaign_package.campaign_no = @campaign_no and	
   	 campaign_package.package_id = campaign_package_revision.package_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


/*
 * Delete Film Package
 */
delete campaign_package
 where campaign_package.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror (  'Error Deleting Campaign Package.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Delete Print Transactions
 */
delete print_transactions
 where print_transactions.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Print Transactions.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Campaign Complex
 */
delete film_campaign_complex
 where film_campaign_complex.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Complex.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Campaign Prints
 */
delete film_campaign_prints
 where film_campaign_prints.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Prints.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Campaign Partition
 */
delete film_campaign_partition
 where film_campaign_partition.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Partition.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Campaign Program History
 */
delete film_program_history
  from film_campaign_program
 where film_campaign_program.campaign_no = @campaign_no and
		 film_program_history.film_campaign_program = film_campaign_program.film_campaign_program_id
	

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Program.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Campaign Program
 */
delete film_campaign_program
 where film_campaign_program.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Program.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Campaign Event
 */
delete film_campaign_event
 where film_campaign_event.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Campaign Event.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Delete Charge
 */
delete film_delete_charge
 where film_delete_charge.origin_campaign = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Delete Charge.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Diary
 */
delete film_diary
 where film_diary.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Diary.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Spot Summary
 */
delete film_spot_summary
 where film_spot_summary.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Spot Summary.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Writeback Liability
 */
delete film_writeback_liability
 where parent_campaign = @campaign_no or
       origin_campaign = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Writeback Liability.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Film Figures
 */
delete film_figures
 where film_figures.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Figures.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Cinelight Campaign Complex
 */
delete cinelight_campaign_complex
 where cinelight_campaign_complex.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_campaign_complex.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Cinelight Campaign Complex
 */
delete cinelight_campaign_print
 where cinelight_campaign_print.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_campaign_print.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Cinelight Campaign Complex
 */
delete cinelight_print_transaction
 where cinelight_print_transaction.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_print_transaction.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Cinelight Campaign Complex
 */
delete cinelight_pattern
 where cinelight_pattern.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_pattern.', 16, 1) 
	rollback transaction
	return -1
end

delete cinelight_package_burst
from	cinelight_package
where 	cinelight_package.campaign_no = @campaign_no
and		cinelight_package.package_id = cinelight_package_burst.package_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror (  'Error Deleting cinelight_pattern.', 16, 1)
	rollback transaction
	return -1
end

delete cinelight_package_intra_pattern
from	cinelight_package
where 	cinelight_package.campaign_no = @campaign_no
and		cinelight_package.package_id = cinelight_package_intra_pattern.package_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_package_intra_pattern.', 16, 1) 
	rollback transaction
	return -1
end


/*
 * Delete Cinelight Campaign Complex
 */
delete 	cinelight_print_package
from	cinelight_package
where 	cinelight_package.campaign_no = @campaign_no
and		cinelight_package.package_id = cinelight_print_package.package_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_pattern.', 16, 1) 
	rollback transaction
	return -1
end

/*
 * Delete Cinelight Campaign Complex
 */
delete 	cinelight_spot_liability
from	cinelight_spot
where 	cinelight_spot.campaign_no = @campaign_no
and		cinelight_spot.spot_id = cinelight_spot_liability.spot_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_pattern.', 16, 1) 
	rollback transaction
	return -1
end


/*
 * Delete Cinelight Campaign Complex
 */
delete cinelight_spot
 where cinelight_spot.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_pattern.', 16, 1) 
	rollback transaction
	return -1
end


/*
 * Delete Cinelight Campaign Complex
 */

delete cinelight_package
 where cinelight_package.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_pattern.', 16, 1) 
	rollback transaction
	return -1
end


delete 	inclusion_spot_liability
from	inclusion_spot
where 	inclusion_spot.campaign_no = @campaign_no
and		inclusion_spot.spot_id = inclusion_spot_liability.spot_id

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_pattern.', 16, 1) 
	rollback transaction
	return -1
end

delete inclusion_spot
 where inclusion_spot.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_pattern.', 16, 1) 
	rollback transaction
	return -1
end

delete inclusion_pattern
 where inclusion_pattern.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting cinelight_pattern.', 16, 1) 
	rollback transaction
	return -1
end

delete inclusion
 where inclusion.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror (  'Error Deleting cinelight_pattern.', 16, 1)
	rollback transaction
	return -1
end

delete film_campaign_reps
 where film_campaign_reps.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reps.', 16, 1) 
	rollback transaction
	return -1
end

delete film_campaign_prop_notes
 where film_campaign_prop_notes.campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Proposal Notes.', 16, 1) 
	rollback transaction
	return -1
end

delete film_campaign_reporting_client
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete smi_report_group_fc_xref
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete smi_report_category_fc_xref
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete statrev_campaign_PERIODS
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete outpost_spot
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete outpost_pattern
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror (  'Error Deleting Film Campaign Reporting Client.', 16, 1)
	rollback transaction
	return -1
end

delete outpost_campaign_panel
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete outpost_package_burst
 where package_id in (select package_id from outpost_package where campaign_no = @campaign_no)

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete outpost_package_intra_pattern
 where package_id in (select package_id from outpost_package where campaign_no = @campaign_no)

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete outpost_print_package
 where package_id in (select package_id from outpost_package where campaign_no = @campaign_no)

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete outpost_package
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete attendance_campaign_estimates
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete film_cinatt_estimates
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror (  'Error Deleting Film Campaign Reporting Client.', 16, 1)
	rollback transaction
	return -1
end

delete attendance_campaign_complex_estimates
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete film_cinatt_estimates_cplx
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end


delete outpost_revision_transaction where revision_id in (select revision_id from campaign_revision where campaign_no = @campaign_no)

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete campaign_revision
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end



delete reach_frequency_parms
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete film_reach_frequency
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete film_delete_charge
 where Parent_campaign = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete film_delete_charge
 where origin_campaign = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete delete_charge
 where source_campaign = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror (  'Error Deleting Film Campaign Reporting Client.', 16, 1)
	rollback transaction
	return -1
end

delete delete_charge
 where destination_campaign = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete cinelight_attendance_digilite_estimates
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete cinelight_attendance_estimates
 where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end

delete client_prospect
where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror (  'Error Deleting Film Campaign Reporting Client.', 16, 1)
	rollback transaction
	return -1
end


delete cinetam_campaign_settings
where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end



delete film_campaign_manual_attendance
where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
	rollback transaction
	return -1
end


/*
 * Delete Film Campaign
 */
 
select @rev_count = count(*) 
from	statrev_campaign_revision
where campaign_no = @campaign_no

select @error = @@error
if ( @error !=0 )
begin
	raiserror ( 'Error checking for revenue.', 16, 1) 
	rollback transaction
	return -1
end

if @rev_count = 0 
begin
	
	delete booking_figures
	where campaign_no = @campaign_no

	select @error = @@error
	if ( @error !=0 )
	begin
		raiserror ( 'Error Deleting Film Campaign Reporting Client.', 16, 1) 
		rollback transaction
		return -1
	end

	delete film_campaign
	 where film_campaign.campaign_no = @campaign_no

	select @error = @@error
	if ( @error !=0 )
	begin
		raiserror ( 'Error Deleting Film Campaign.', 16, 1) 
		rollback transaction
		return -1
	end
end

/*
 * Commit and Return
 */

commit transaction
return 0
GO
