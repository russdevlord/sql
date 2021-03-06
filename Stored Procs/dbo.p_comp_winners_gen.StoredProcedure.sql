/****** Object:  StoredProcedure [dbo].[p_comp_winners_gen]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_comp_winners_gen]
GO
/****** Object:  StoredProcedure [dbo].[p_comp_winners_gen]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_comp_winners_gen] @slide_competition_id	integer
as

declare @error          			integer,
        @rowcount					integer,
        @competition_scope			char(1),
        @no_of_winners				integer,
        @winner_no					integer,
        @competition_entry_id		integer,
        @country_code				char(1),
        @branch_code				char(2),
        @service_rep				integer

/*
 * Create Temporary Tables
 */
create table #correct_entries (
   competition_entry_id				integer		null,
   campaign_no						char(7)		null,
   random_order						float		null
)

/*
 * Reset 
 */
update competition_entry
   set competition_entry.winner_no = 0
 where competition_entry.slide_competition_id = @slide_competition_id

/*
 * Get Competition parameters
 */
select @competition_scope = competition.competition_scope,
       @no_of_winners = competition.no_of_winners
  from competition
 where competition.slide_competition_id = @slide_competition_id

/*
 * Select Interim Winners
 */
insert into #correct_entries
  select competition_entry.competition_entry_id,
         competition_entry.campaign_no,
         0
    from competition,
         competition_entry
   where competition.slide_competition_id = competition_entry.slide_competition_id and
         competition_entry.interim_winner_no > 0
group by competition_entry.competition_entry_id,
		 competition_entry.campaign_no

/*
 * Set the random order of Entries
 */
declare correct_entries_csr cursor static for
 select competition_entry_id
   from #correct_entries
order by competition_entry_id asc
for read only

open correct_entries_csr
fetch correct_entries_csr into @competition_entry_id
while (@@fetch_status = 0)
begin
   update #correct_entries
      set random_order = rand()
    where competition_entry_id = @competition_entry_id

   fetch correct_entries_csr into @competition_entry_id
end
close correct_entries_csr
deallocate correct_entriess_csr

if @competition_scope = 'G'
begin
   /*
    * Global Competition Scope
    */
   select @winner_no = 0

	   declare global_scope_csr cursor static for
	 select #correct_entries.competition_entry_id
	   from #correct_entries
	order by #correct_entries.random_order asc
	for read only

	open global_scope_csr
   fetch global_scope_csr into @competition_entry_id
   while ((@@fetch_status = 0) and (@winner_no < @no_of_winners))
   begin
      select @winner_no = @winner_no + 1

      update competition_entry
         set winner_no = @winner_no
       where competition_entry_id = @competition_entry_id

      fetch global_scope_csr into @competition_entry_id
   end
   close global_scope_csr
	deallocate global_scope_csr
end
else if @competition_scope = 'C'
begin
   /*
    * Country Competition Scope
    */

	declare country_csr cursor static for
	 select country_code
	   from country
	order by country_name
	for read only

   open country_csr
   fetch country_csr into @country_code
   while (@@fetch_status = 0)
   begin
      select @winner_no = 0

		declare country_scope_csr cursor static for
		 select #correct_entries.competition_entry_id
		   from #correct_entries,
		        slide_campaign,
		        branch
		  where #correct_entries.campaign_no = slide_campaign.campaign_no and
		        slide_campaign.branch_code = branch.branch_code and
		        branch.country_code = @country_code
		order by #correct_entries.random_order asc
		for read only

      open country_scope_csr
      fetch country_scope_csr into @competition_entry_id
      while ((@@fetch_status = 0) and (@winner_no < @no_of_winners))
      begin
         select @winner_no = @winner_no + 1

         update competition_entry
            set winner_no = @winner_no
          where competition_entry_id = @competition_entry_id

         fetch country_scope_csr into @competition_entry_id
      end
      close country_scope_csr
		deallocate country_scope_csr
      fetch country_csr into @country_code
   end
   close country_csr
	deallocate country_csr
end
else if @competition_scope = 'B'
begin
   /*
    * Branch Competition Scope
    */
	declare branch_csr cursor static for
	 select branch_code
	   from branch
	order by branch_name
	for read only

   open branch_csr
   fetch branch_csr into @branch_code
   while (@@fetch_status = 0)
   begin
      select @winner_no = 0

		declare branch_scope_csr cursor static for
		 select #correct_entries.competition_entry_id
		   from #correct_entries,
		        slide_campaign
		  where #correct_entries.campaign_no = slide_campaign.campaign_no and
		        slide_campaign.branch_code = @branch_code
		order by #correct_entries.random_order asc
		for read only

      open branch_scope_csr
      fetch branch_scope_csr into @competition_entry_id
      while ((@@fetch_status = 0) and (@winner_no < @no_of_winners))
      begin
         select @winner_no = @winner_no + 1

         update competition_entry
            set winner_no = @winner_no
          where competition_entry_id = @competition_entry_id

         fetch branch_scope_csr into @competition_entry_id
      end
      close branch_scope_csr
	 deallocate branch_scope_csr
      fetch branch_csr into @branch_code
   end
   close branch_csr
	deallocate branch_csr
end
else if @competition_scope = 'R'
begin
   /*
    * Service Rep Competition Scope
    */

	declare service_rep_csr cursor static for
	 select distinct service_rep
	   from slide_campaign
	order by service_rep
	for read only

   open service_rep_csr
   fetch service_rep_csr into @service_rep
   while (@@fetch_status = 0)
   begin
      select @winner_no = 0

      
		declare service_rep_scope_csr cursor static for
		 select #correct_entries.competition_entry_id
		   from #correct_entries,
		        slide_campaign
		  where #correct_entries.campaign_no = slide_campaign.campaign_no and
		        slide_campaign.service_rep = @service_rep
		order by #correct_entries.random_order asc
		for read only

	open service_rep_scope_csr
      fetch service_rep_scope_csr into @competition_entry_id
      while ((@@fetch_status = 0) and (@winner_no < @no_of_winners))
      begin
         select @winner_no = @winner_no + 1

         update competition_entry
            set winner_no = @winner_no
          where competition_entry_id = @competition_entry_id

         fetch service_rep_scope_csr into @competition_entry_id
      end
      close service_rep_scope_csr
		deallocate service_rep_scope_csr
      fetch service_rep_csr into @service_rep
   end
   close service_rep_csr
	deallocate service_rep_csr
end

/*
 * Select
 */

  select competition_entry.competition_entry_id,
         competition_entry.campaign_no,
         competition_entry.winner_no
    from competition_entry
   where competition_entry.winner_no > 0
order by competition_entry.winner_no

return 0
GO
