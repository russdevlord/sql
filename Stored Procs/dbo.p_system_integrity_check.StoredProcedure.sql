/****** Object:  StoredProcedure [dbo].[p_system_integrity_check]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_system_integrity_check]
GO
/****** Object:  StoredProcedure [dbo].[p_system_integrity_check]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_system_integrity_check]		@mode			int
as

declare @err_desc						varchar(255),
        @campaign_no					char(7),
        @accrue_amount				    money,
        @billed_amount			        money,
        @credit_amount				    money,
        @ext_count					    int,
        @bill_ext						int,
        @spot_cinema					money,
        @new_tot						money,
        @billed_sound  			        money,
        @credit_sound				    money,
        @sound_accrue				    money,
        @new_sound					    money,
        @sound_rate					    money

create table #errors (
	campaign_no		    char(7)				null,
	error				varchar(255)		null
)

if @mode = 0 or @mode = 1
begin
	/*
	 *  Check Campaign Balances are in sync with their transactions
	 */
	insert into #errors ( campaign_no, error )
	SELECT	CONVERT(char(7), fc.campaign_no), 
			'18) Film Campaign Balances are out of sync with the sum of its transactions: Balance Oustanding $' + CONVERT(varchar(12), fc.balance_outstanding) 
				+ ' Sum of Trans $' + CONVERT(varchar(12), 
			SUM(ct.gross_amount))
	FROM	film_campaign AS fc LEFT OUTER JOIN
			campaign_transaction AS ct ON fc.campaign_no = ct.campaign_no
	GROUP BY fc.campaign_no, 
			fc.balance_outstanding, 
			ct.campaign_no, 
			fc.product_desc
	HAVING	(fc.balance_outstanding <> ISNULL(SUM(ct.gross_amount), 0))end

if @mode = 0 or @mode = 2
begin
	/*
	 *  Check Billing amounts match the spots billed.
	 */
	insert into #errors ( campaign_no, error )
	select convert(char(7),spot.campaign_no),
			 '19) Film billings do not match the amount on spots. Spot Amount for billing $' + convert(varchar(12),sum(spot.charge_rate)) + ' Billing Amount $' + convert(varchar(12),st.nett_amount)
	from 	 campaign_spot spot,
			 campaign_transaction st,
			 film_spot_xref sx,
			 film_campaign sc
	where	 spot.spot_id = sx.spot_id and
			 st.tran_id = sx.tran_id and
			 sc.campaign_no = spot.campaign_no and
			 st.nett_amount <> 0 
	group by sx.tran_id,
				spot.campaign_no,
				st.nett_amount,
				st.tran_id
	having sum(spot.charge_rate) <> st.nett_amount 
end


if @mode = 0 or @mode = 3
begin
	/*
     * Check Trans Xref records exist for billings
     */
	 
	insert into #errors ( campaign_no, error )
	select convert(char(7), sc.campaign_no),
			 '20) Film Transaction Xref records do not exist for the billings on ' + convert(varchar(12),st.tran_date)
	  from campaign_transaction st,
			 film_campaign sc
	 where st.tran_type = 1 and
          st.nett_amount > 0 and 
          sc.campaign_status <> 'X' and 
          sc.campaign_status <> 'Z' and 
			 not exists (select 1 from film_spot_xref where tran_id = st.tran_id) and
			 sc.campaign_no = st.campaign_no
end

if @mode = 0 or @mode = 4
begin
	/*
	 *  Check Xrefs all point at billed or credited spots only.
	 */
   	insert into #errors ( campaign_no, error )
	select distinct convert(char(7), spot.campaign_no),
          '21) Film Billing Xref Points at spots that arent credited or billed.' + convert(varchar(15), spot.spot_id)
	  from film_spot_xref xref,
			 campaign_spot spot
	 where xref.spot_id = spot.spot_id and
			 spot.tran_id is null
end

if @mode = 0 or @mode = 5
begin
	/*
	 *  Check No Film Spot That Should Have been billed are not billed
	 */
     insert into #errors (campaign_no, error)
      select convert(char(7), spot.campaign_no),
            '22) Film Spots that should have been billed which were not billed: ' + convert(varchar(15), spot.billing_period)
	    from campaign_spot spot,
             accounting_period
	   where spot.billing_period = accounting_period.end_date and
			 spot.spot_type <> 'C' and
             (accounting_period.status = 'X' or
             accounting_period.status = 'E')
    group by spot.campaign_no,
             spot.billing_period
    order by spot.campaign_no,
             spot.billing_period            
end

--24 Payments that are not fully allocated
if @mode = 0 or @mode = 6
begin
    insert into #errors (campaign_no, error)
    SELECT	CONVERT(char(7), film_campaign.campaign_no),
			 '24) Statment not created for this end of month'
	FROM	film_campaign LEFT OUTER JOIN
			statement ON film_campaign.campaign_no = statement.campaign_no
	WHERE	(film_campaign.campaign_status = 'L' 
	OR		film_campaign.campaign_status = 'F') 
	AND		(statement.accounting_period = '22-aug-2003')
	GROUP BY film_campaign.campaign_no
	HAVING	(COUNT(statement.statement_id) = 0)
 end

--25 Spots without spot liability records
if @mode = 0 or @mode = 7
begin
    insert into #errors (campaign_no, error)
	SELECT	CONVERT(char(7), cs.campaign_no), 
			'25) Error Film Spots that have billed with no spot liability records.  Spot Id: ' + CONVERT(varchar(15), cs.spot_id)
	FROM	campaign_spot AS cs INNER JOIN
			film_campaign AS fc ON cs.campaign_no = fc.campaign_no LEFT OUTER JOIN
			spot_liability AS sl ON cs.spot_id = sl.spot_id
	WHERE	(fc.campaign_status <> 'X') 
	AND		(fc.campaign_status <> 'Z') 
	AND		(cs.tran_id IS NOT NULL)
	GROUP BY cs.campaign_no, cs.spot_id
	HAVING	(COUNT(sl.spot_liability_id) = 0)
end

--26 Spots without xref records
if @mode = 0 or @mode = 8
begin
    insert into #errors (campaign_no, error)
	SELECT	CONVERT(char(7), cs.campaign_no),
			'26) Error Film Spots that have billed with no spot xref records.  Spot Id: ' + CONVERT(varchar(15), cs.spot_id) 
	FROM	campaign_spot AS cs INNER JOIN
			film_campaign AS fc ON cs.campaign_no = fc.campaign_no LEFT OUTER JOIN
			film_spot_xref AS fsx ON cs.spot_id = fsx.spot_id
	WHERE	(fc.campaign_status <> 'X') 
	AND		(fc.campaign_status <> 'Z') 
	AND		(cs.tran_id IS NOT NULL)
	GROUP BY cs.campaign_no, cs.spot_id
	HAVING	(COUNT(fsx.tran_id) = 0)
end

--27 Inclusions that haven't been billed
if @mode = 0 or @mode = 9
begin
	insert into #errors (campaign_no, error)
	SELECT	convert(char(7), ft.campaign_no),
			'27) Error Film Inclusions that have not been billed : ' + convert(varchar(12), ft.billing_period) + ' ' + ft.track_desc
	FROM	film_track ft,
			accounting_period ap
	WHERE	ft.billing_period = ap.end_date
	and		(ap.status = 'X'
	or		ap.status = 'E')
	and		ft.tran_id is null
	GROUP BY ft.campaign_no, ft.billing_period, ft.track_desc
end

--29 Film Campaign Balances Balance?
if @mode = 0 or @mode = 10
begin
    insert into #errors (campaign_no, error)
	SELECT	convert(char(7), fc.campaign_no),
            '29) Error Film Campaign balances do not balance.'
	FROM	film_campaign fc
    WHERE	balance_outstanding <> (balance_current + balance_30 + balance_60 + balance_90 + balance_120 + balance_credit)
end

--30 Release period on spot liability
if @mode = 0 or @mode = 11
begin
    insert into #errors (campaign_no, error)
     select convert(char(7), spot.campaign_no),
           '30) Spot Liability Not Released for billing period : ' + convert(varchar(12), spot.billing_period) + ' and spot_id : ' + convert(varchar(15), spot.spot_id)
      from spot_liability sl,
           campaign_spot spot,
           film_screening_dates fsd
     where sl.spot_id = spot.spot_id
       and sl.release_period is null
       and spot.screening_date = fsd.screening_date
       and fsd.screening_date_status = 'X' 
end

--31 Film Spot Summary records exist
if @mode = 0 or @mode = 12
begin
    insert into #errors (campaign_no, error)
	SELECT	'NotCamp', 
			'31) Film Spot Summary Records not generated for : ' + CONVERT(varchar(12), ap.end_date)
	FROM	accounting_period AS ap LEFT OUTER JOIN
			film_spot_summary AS fss ON ap.end_date = fss.accounting_period
	WHERE	(ap.status = 'X')
	OR		(ap.status = 'E')
	GROUP BY ap.end_date
	HAVING	COUNT(fss.accounting_period) = 0
end

--32 Cinema Rent exists for all Film Spot Summary Records
if @mode = 0 or @mode = 13
begin
	insert into #errors (campaign_no, error)
	SELECT convert(char(7), fss.campaign_no),
			'32) Cinema rent does not exists for the this accounting period : ' + convert(varchar(12), fss.accounting_period )
	FROM	film_spot_summary AS fss LEFT OUTER JOIN
			cinema_rent AS cr ON fss.complex_id = cr.complex_id 
			AND  fss.accounting_period = cr.accounting_period
			AND  fss.country_code = cr.country_code
	WHERE	fss.accounting_period >= '30-jul-1999'
	GROUP BY fss.campaign_no,
			fss.accounting_period 
	HAVING	COUNT(cr.cinema_rent_id) = 0
end

if (select count(campaign_no) from #errors) = 0 
begin
	insert #errors values ( null, 'No exceptions found.')
end

select campaign_no,
       error,
       @mode
  from #errors
return 0
GO
