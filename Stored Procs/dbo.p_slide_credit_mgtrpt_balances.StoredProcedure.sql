/****** Object:  StoredProcedure [dbo].[p_slide_credit_mgtrpt_balances]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_credit_mgtrpt_balances]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_credit_mgtrpt_balances]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_credit_mgtrpt_balances]	@as_branch_code	char(2)
as
set nocount on 
/*
 * Declare Variables
 */

declare		@branch_name		varchar(50)

/*
 * Create Temporary Table
 */

create table #info
(
	sort_order							integer		null,
	description							varchar(30)	null,
	no_accounts							integer		null,
	balance_current					money			null,
	balance_credit						money			null,
	balance_30							money			null,
	balance_60							money			null,
	balance_90							money			null,
	balance_120							money			null,
	balance_outstanding				money			null
)

select @branch_name = branch_name
  from branch
 where branch_code = @as_branch_code

insert into #info (
       sort_order,
       description,
       no_accounts,
       balance_current,
       balance_credit,
       balance_30,
       balance_60,
       balance_90,
       balance_120,
       balance_outstanding )
select 1,
       '0 - 8 Weeks',
       count(*),
       sum(sc.balance_current),
       sum(sc.balance_credit),
       sum(sc.balance_30),
       sum(sc.balance_60),
       null,
       null,
       sum(sc.balance_outstanding)
  from slide_campaign sc
 where sc.is_closed = 'N' and
       sc.balance_outstanding <> 0 and
       sc.balance_90 = 0 and
       sc.balance_120 = 0 and
       sc.branch_code = @as_branch_code
group by sc.branch_code

insert into #info (
       sort_order,
       description,
       no_accounts,
       balance_current,
       balance_credit,
       balance_30,
       balance_60,
       balance_90,
       balance_120,
       balance_outstanding )
select 2,
       '12 - 16 Weeks',
       count(*),
       sum(sc.balance_current),
       sum(sc.balance_credit),
       sum(sc.balance_30),
       sum(sc.balance_60),
       sum(sc.balance_90),
       sum(sc.balance_120),
       sum(sc.balance_outstanding)
  from slide_campaign sc
 where sc.is_closed = 'N' and
       sc.balance_outstanding <> 0 and
       ( sc.balance_90 <> 0 or
         sc.balance_120 <> 0 ) and
       sc.branch_code = @as_branch_code
group by sc.branch_code

/*
 * Return Dataset
 */

select #info.sort_order,
       @as_branch_code as branch_code,
       @branch_name as branch_name,
       #info.description,
       #info.no_accounts,
       #info.balance_current,
       #info.balance_credit,
       #info.balance_30,
       #info.balance_60,
       #info.balance_90,
       #info.balance_120,
       #info.balance_outstanding
  from #info

/*
 * Return
 */

return 0
GO
