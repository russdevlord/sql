/****** Object:  StoredProcedure [dbo].[p_slide_credit_mgtrpt_nat_bals]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_credit_mgtrpt_nat_bals]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_credit_mgtrpt_nat_bals]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_credit_mgtrpt_nat_bals]	@as_country_code	char(2)
as
set nocount on 
/*
 * Declare Variables
 */

declare		@country_name		varchar(50)

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

select @country_name = country_name
  from country
 where country_code = @as_country_code

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
  from slide_campaign sc,
		 country c,
		 branch b	
 where b.branch_code = sc.branch_code and
	    c.country_code = b.country_code and
	    c.country_code = @as_country_code and 		 
 		 sc.is_closed = 'N' and
       sc.balance_outstanding <> 0 and
       sc.balance_90 = 0 and
       sc.balance_120 = 0 --and
--       sc.country_code = @as_country_code
group by c.country_code
--
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
  from slide_campaign sc,
		 country c,
		 branch b	
 where b.branch_code = sc.branch_code and
	    c.country_code = b.country_code and
	    c.country_code = @as_country_code and 
		 sc.is_closed = 'N' and
       sc.balance_outstanding <> 0 and
       ( sc.balance_90 <> 0 or
         sc.balance_120 <> 0 ) --and
--       sc.country_code = @as_country_code
group by c.country_code
--
/*
 * Return Dataset
 */

select #info.sort_order,
       @as_country_code as country_code,
       @country_name as country_name,
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
