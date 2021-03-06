/****** Object:  StoredProcedure [dbo].[p_figures_summary]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_figures_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_figures_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_figures_summary]	@sales_period	datetime
as

/*
 * Declare Procedure Variables
 */

declare @error									integer,
        @rowcount								integer,
        @sales_period_status				varchar(20),
        @sales_period_no					smallint,
        @branch_code							char(2),
        @business_group_no					integer,
        @diary_figures						money,
        @official_figures					money,
        @released_business					money,
        @prev_official_figures			money,
        @held_business						money,
        @held_business_figures			money,
        @held_business_proposals			money,
        @prev_held_business				money,
        @prev_held_business_figures		money,
        @prev_held_business_proposals	money,
        @cancelled_business				money,
        @cancelled_business_figures		money,
        @cancelled_business_proposals	money,
        @prev_cancelled_business			money,
        @prev_cancelled_business_fig	money,
        @prev_cancelled_business_prop	money

/*
 * Create Temporary Tables
 */

create table #summary
(
   country_code				char(1)				null,
   country_name				varchar(30)			null,
   branch_code					char(2)				null,
   branch_name					varchar(50)			null,
   business_group_no			integer				null,
   business_group_desc		varchar(30)			null,
   diary_figures				money					null,
   official_figures			money					null,
   released_business			money					null,
   prev_official_figures	money					null,
   held_business				money					null,
   prev_held_business		money					null,
   cancelled_business		money					null,
   prev_cancelled_business	money					null
)


select @sales_period_status = sales_period.status,
       @sales_period_no = sales_period.sales_period_no
  from sales_period
 where sales_period.sales_period_end = @sales_period

insert into #summary
   ( country_code, country_name, branch_code, branch_name, business_group_no, business_group_desc,
     diary_figures, official_figures, released_business, prev_official_figures, held_business, prev_held_business, cancelled_business, prev_cancelled_business )
   select country.country_code,
          country.country_name,
          branch.branch_code,
          branch.branch_name,
          business_group.business_group_no,
          business_group.business_group_desc,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0
     from country,
          branch,
          business_group
    where country.country_code = branch.country_code

declare summary_csr cursor static for
 select branch_code, business_group_no
   from #summary
order by branch_code, business_group_no
for read only

open summary_csr
fetch summary_csr into @branch_code, @business_group_no
while (@@fetch_status = 0)
begin
   select @diary_figures = 0,
          @official_figures = 0,
          @released_business = 0,
          @prev_official_figures = 0,
          @held_business = 0,
          @held_business_figures = 0,
          @held_business_proposals = 0,
          @prev_held_business = 0,
          @prev_held_business_figures = 0,
          @prev_held_business_proposals = 0,
          @cancelled_business = 0,
          @cancelled_business_figures = 0,
          @cancelled_business_proposals = 0,
          @prev_cancelled_business = 0,
          @prev_cancelled_business_fig = 0,
          @prev_cancelled_business_prop = 0

   /*
    * Diary Figures
    */

   select @diary_figures = sum(slide_proposal.comm_period_value)
     from slide_proposal
    where slide_proposal.branch_code = @branch_code and
          slide_proposal.business_group = @business_group_no and
          slide_proposal.creation_period = @sales_period
          

   update #summary
      set #summary.diary_figures = @diary_figures
    where #summary.branch_code = @branch_code and
          #summary.business_group_no = @business_group_no and
          @diary_figures is not null

   /*
    * Official Figures
    */

   select @official_figures = sum(slide_figures.gross_amount)
     from slide_figures
    where ( slide_figures.figure_official = 'Y' or
          ( slide_figures.figure_status = 'R' and
            slide_figures.figure_hold <> 'Y' ) ) and
          slide_figures.branch_code = @branch_code and
          slide_figures.business_group = @business_group_no and
          slide_figures.release_period = @sales_period

   update #summary
      set #summary.official_figures = @official_figures
    where #summary.branch_code = @branch_code and
          #summary.business_group_no = @business_group_no and
          @official_figures is not null

   /*
    * Released Business
    */

   select @released_business = sum(slide_figures.gross_amount)
     from slide_figures
    where ( slide_figures.figure_official = 'Y' or
          ( slide_figures.figure_status = 'R' and
            slide_figures.figure_hold <> 'Y' ) ) and
          slide_figures.release_value > 0 and
          slide_figures.branch_code = @branch_code and
          slide_figures.business_group = @business_group_no and
          slide_figures.release_period = @sales_period

   update #summary
      set #summary.released_business = @released_business
    where #summary.branch_code = @branch_code and
          #summary.business_group_no = @business_group_no and
          @released_business is not null

   /*
    * Official Figures previous periods
    */

   select @prev_official_figures = sum(slide_figures.gross_amount)
     from slide_figures
    where ( slide_figures.figure_official = 'Y' or
          ( slide_figures.figure_status = 'R' and
            slide_figures.figure_hold <> 'Y' ) ) and
          slide_figures.branch_code = @branch_code and
          slide_figures.business_group = @business_group_no and
          slide_figures.release_period = @sales_period and
          slide_figures.creation_period < slide_figures.release_period

   update #summary
      set #summary.prev_official_figures = @prev_official_figures
    where #summary.branch_code = @branch_code and
          #summary.business_group_no = @business_group_no and
          @prev_official_figures is not null

   /*
    * Held Business this period
    */

   select @held_business_figures = sum(slide_figures.gross_amount)
     from slide_figures
    where slide_figures.figure_status = 'R' and
          slide_figures.branch_code = @branch_code and
          slide_figures.business_group = @business_group_no and
          ( ( slide_figures.figure_hold = 'Y' and
              slide_figures.creation_period = slide_figures.release_period and
              slide_figures.release_period = @sales_period ) or
            ( slide_figures.creation_period = @sales_period and
              slide_figures.release_period > @sales_period ) )

   if @held_business_figures is not null
   begin
      select @held_business = @held_business + @held_business_figures
   end

   select @held_business_proposals = sum(slide_proposal.comm_period_value)
     from slide_proposal
    where slide_proposal.branch_code = @branch_code and
          slide_proposal.business_group = @business_group_no and
          ( ( slide_proposal.proposal_lost <> 'Y' and
              slide_proposal.campaign_no is null and
              slide_proposal.creation_period = slide_proposal.campaign_period and
              slide_proposal.campaign_period = @sales_period ) or
            ( slide_proposal.creation_period = @sales_period and
              slide_proposal.campaign_period > @sales_period ) )

   if @held_business_proposals is not null
   begin
      select @held_business = @held_business + @held_business_proposals
   end

   update #summary
      set #summary.held_business = @held_business
    where #summary.branch_code = @branch_code and
          #summary.business_group_no = @business_group_no and
          @held_business is not null

   /*
    * Held Business previous periods
    */

   select @prev_held_business_figures = sum(slide_figures.gross_amount)
     from slide_figures
    where slide_figures.figure_status = 'R' and
          slide_figures.branch_code = @branch_code and
          slide_figures.business_group = @business_group_no and
          ( ( slide_figures.figure_hold = 'Y' and
              slide_figures.creation_period < slide_figures.release_period and
              slide_figures.release_period = @sales_period ) or
            ( slide_figures.creation_period < @sales_period and
              slide_figures.release_period > @sales_period ) )

   if @prev_held_business_figures is not null
   begin
      select @prev_held_business = @prev_held_business + @prev_held_business_figures
   end

   select @prev_held_business_proposals = sum(slide_proposal.comm_period_value)
     from slide_proposal
    where slide_proposal.branch_code = @branch_code and
          slide_proposal.business_group = @business_group_no and
          ( ( slide_proposal.proposal_lost <> 'Y' and
              slide_proposal.campaign_no is null and
              slide_proposal.creation_period < slide_proposal.campaign_period and
              slide_proposal.campaign_period = @sales_period ) or
            ( slide_proposal.creation_period < @sales_period and
              slide_proposal.campaign_period > @sales_period ) )

   if @prev_held_business_proposals is not null
   begin
      select @prev_held_business = @prev_held_business + @prev_held_business_proposals
   end

   update #summary
      set #summary.prev_held_business = @prev_held_business
    where #summary.branch_code = @branch_code and
          #summary.business_group_no = @business_group_no and
          @prev_held_business is not null

   /*
    * Cancelled Business this period
    */

   select @cancelled_business_figures = sum(slide_figures.gross_amount)
     from slide_figures
    where slide_figures.figure_status = 'X' and
          slide_figures.creation_period = slide_figures.release_period and
          slide_figures.branch_code = @branch_code and
          slide_figures.business_group = @business_group_no and
          slide_figures.release_period = @sales_period

   if @cancelled_business_figures is not null
   begin
      select @cancelled_business = @cancelled_business + @cancelled_business_figures
   end

   select @cancelled_business_proposals = sum(slide_proposal.comm_period_value)
     from slide_proposal
    where slide_proposal.proposal_lost = 'Y' and
          slide_proposal.creation_period = slide_proposal.campaign_period and
          slide_proposal.branch_code = @branch_code and
          slide_proposal.business_group = @business_group_no and
          slide_proposal.campaign_period = @sales_period

   if @cancelled_business_proposals is not null
   begin
      select @cancelled_business = @cancelled_business + @cancelled_business_proposals
   end

   update #summary
      set #summary.cancelled_business = @cancelled_business
    where #summary.branch_code = @branch_code and
          #summary.business_group_no = @business_group_no and
          @cancelled_business is not null

   /*
    * Cancelled Business previous periods
    */

   select @prev_cancelled_business_fig = sum(slide_figures.gross_amount)
     from slide_figures
    where slide_figures.figure_status = 'X' and
          slide_figures.creation_period < slide_figures.release_period and
          slide_figures.branch_code = @branch_code and
          slide_figures.business_group = @business_group_no and
          slide_figures.release_period = @sales_period

   if @prev_cancelled_business_fig is not null
   begin
      select @prev_cancelled_business = @prev_cancelled_business + @prev_cancelled_business_fig
   end

   select @prev_cancelled_business_prop = sum(slide_proposal.comm_period_value)
     from slide_proposal
    where slide_proposal.proposal_lost = 'Y' and
          slide_proposal.creation_period < slide_proposal.campaign_period and
          slide_proposal.branch_code = @branch_code and
          slide_proposal.business_group = @business_group_no and
          slide_proposal.campaign_period = @sales_period

   if @prev_cancelled_business_prop is not null
   begin
      select @prev_cancelled_business = @prev_cancelled_business + @prev_cancelled_business_prop
   end

   update #summary
      set #summary.prev_cancelled_business = @prev_cancelled_business
    where #summary.branch_code = @branch_code and
          #summary.business_group_no = @business_group_no and
          @prev_cancelled_business is not null

   fetch summary_csr into @branch_code, @business_group_no
end
close summary_csr
deallocate summary_csr

/*
 * Return
 */

select @sales_period as sales_period,
       @sales_period_status as sales_period_status,
       @sales_period_no as sales_period_no,
       country_code,
       country_name,
       branch_code,
       branch_name,
       business_group_no,
       business_group_desc,
       diary_figures,
       official_figures,
       released_business,
       prev_official_figures,
       held_business,
       prev_held_business,
       cancelled_business,
       prev_cancelled_business
  from #summary
 where diary_figures <> 0 or
       official_figures <> 0 or
       released_business <> 0 or
       prev_official_figures <> 0 or
       held_business <> 0 or
       prev_held_business <> 0 or
       cancelled_business <> 0 or
       prev_cancelled_business <> 0

return 0
GO
