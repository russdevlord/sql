/****** Object:  StoredProcedure [dbo].[p_held_non_trading_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_held_non_trading_report]
GO
/****** Object:  StoredProcedure [dbo].[p_held_non_trading_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_held_non_trading_report]    @country_code	char(1),
                                         @branch_code		char(2)
as
set nocount on 

declare  @country_code_tmp		char(1),
         @branch_code_tmp		char(2)

select @country_code_tmp = country_code
  from country
 where country_code = @country_code

select @branch_code_tmp = branch_code
  from branch
 where branch_code = @branch_code

select @country_code = @country_code_tmp,
       @branch_code = @branch_code_tmp

/*
 * Create Temporary Table
 */

create table #held_non_trading
(
	branch_code							char(2)			null,
	branch_name							varchar(50)		null,
	campaign_no							char(7)			null,
	name_on_slide						varchar(50)		null,
	cost_centre_code					char(2)			null,
	cost_centre_desc					varchar(40)		null,
	gl_code								char(4)			null,
	gl_desc								varchar(40)		null,
	amount								money				null
)

insert into #held_non_trading
select slide_campaign.branch_code,
       branch.branch_name,
       slide_campaign.campaign_no,
       slide_campaign.name_on_slide,
       cost_centre.cost_centre_code,
       cost_centre.cost_centre_desc,
       cost_account.gl_code,
       cost_account.gl_desc,
       sum(non_trading.amount)
  from slide_campaign,
       branch,
       non_trading,
       cost_centre,
       cost_account
 where slide_campaign.branch_code = branch.branch_code and
       slide_campaign.campaign_no = non_trading.campaign_no and
       non_trading.cost_centre_code = cost_centre.cost_centre_code and
       non_trading.gl_code = cost_account.gl_code and
       non_trading.held_active = 'Y' and
       cost_account.hold_account = 'Y' and
       ( branch.country_code = @country_code or @country_code is null ) and
       ( branch.branch_code = @branch_code or @branch_code is null )
group by slide_campaign.branch_code,
       branch.branch_name,
       slide_campaign.campaign_no,
       slide_campaign.name_on_slide,
       cost_centre.cost_centre_code,
       cost_centre.cost_centre_desc,
       cost_account.gl_code,
       cost_account.gl_desc
having sum(non_trading.amount) > 0

/*
 * Return
 */

select * from #held_non_trading
GO
