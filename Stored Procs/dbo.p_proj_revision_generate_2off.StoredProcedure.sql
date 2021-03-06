/****** Object:  StoredProcedure [dbo].[p_proj_revision_generate_2off]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_proj_revision_generate_2off]
GO
/****** Object:  StoredProcedure [dbo].[p_proj_revision_generate_2off]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE     PROC [dbo].[p_proj_revision_generate_2off]	@campaign_no	int, @revision_no int , @user_id int
with recompile
as

/*
 * Declare Variables
 */

declare     @error_num           int
declare		@revision_category	int
declare		@revision_id			int
declare		@default_comment		varchar (255)
declare		@confirm_date			datetime
declare		@revision_type 		smallint


SELECT @default_comment = 'System Generated Revision'

if ( @user_id > 1 )
begin 
	SELECT @revision_category = 2
	SELECT @revision_type = 3
end

if ( @user_id = 1 )
begin 
	SELECT @revision_category = 1
	SELECT @revision_type = 4
end

if ( @revision_no != 0 )
begin
	SELECT @revision_id =  max ( revision_id ) 
		FROM campaign_revision
		WHERE campaign_revision.campaign_no = @campaign_no
			AND campaign_revision.revision_no = @revision_no;
end

if ( @revision_no = 0 )
begin
	SELECT @revision_no = isnull ( max ( revision_no ) + 1  , 1 )
		FROM campaign_revision
		WHERE campaign_revision.campaign_no = @campaign_no;
end

if ( @revision_no = 1 )
begin
	SELECT @confirm_date = IsNull ( max ( event_date ) , GetDate() )
	FROM film_campaign_event 
	WHERE film_campaign_event.event_type = 'C'
	AND film_campaign_event.campaign_no = @campaign_no;

	SELECT @revision_type = 1
	
end

if ( @revision_no != 1 )
begin
	SELECT @confirm_date = GetDate()
end

/* Create temporary tables for latest values */

CREATE TABLE #work_revision 
(		flag char(3) NOT NULL,
		campaign_no int NOT NULL, 
		confirmation_date datetime NULL, 
		revision_transaction_type smallint NOT NULL,
		revenue_period datetime NOT NULL,
		billing_date datetime NULL,
		value money NOT NULL,
		cost money NOT NULL,
		units int NOT NULL,
		makegood money NOT NULL,
		revenue money NOT NULL
);

CREATE TABLE #delta_revision (
	revision_no int NULL,
	campaign_no int NOT NULL, 
	revision_transaction_type smallint NOT NULL,
	revenue_period datetime NOT NULL,
	billing_date datetime NULL,
	value money NOT NULL,
	cost money NOT NULL,
	units int NOT NULL,
	makegood money NOT NULL,
	revenue money NOT NULL)


/* Inserts to temporary table */

/* 2. Film TakeOut */
/*changed*/
INSERT #work_revision
SELECT 	'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = min (inclusion.start_date),
			revision_transaction_type = 2, /* Film Takeout */
			inclusion_spot.revenue_period,
			inclusion_spot.screening_date,   
			value = 0,   
			cost = SUM ( inclusion_spot.takeout_rate * - 1),  
			units = count(*),
         makegood = 0,   
			revenue = SUM ( inclusion_spot.takeout_rate * - 1)

FROM 	inclusion_spot  , inclusion 
WHERE	inclusion.campaign_no = @campaign_no
 AND  inclusion.inclusion_id = inclusion_spot.inclusion_id
 AND 	inclusion_spot.spot_status != 'P'
 AND 	inclusion.inclusion_category = 'F'

GROUP BY inclusion_spot.campaign_no,
			inclusion_spot.revenue_period,
			inclusion_spot.screening_date;

/* 5. DMG TakeOut */
/*changed*/
INSERT #work_revision
SELECT 	'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = min(inclusion.start_date),
			revision_transaction_type = 5, /* DMG Takeout */
			inclusion_spot.revenue_period ,
			inclusion_spot.screening_date,   
			value = 0,   
			cost = SUM ( inclusion_spot.takeout_rate * - 1),   
			units = count(*),
         makegood = 0,   
			revenue = SUM ( inclusion_spot.takeout_rate * - 1)

FROM 	inclusion_spot  , inclusion 
WHERE	inclusion.campaign_no = @campaign_no
 AND  inclusion.inclusion_id = inclusion_spot.inclusion_id
 AND	inclusion_spot.spot_status != 'P'
 AND 	inclusion.inclusion_category = 'D'

GROUP BY inclusion_spot.campaign_no,
			inclusion_spot.revenue_period ,
			inclusion_spot.screening_date;


/* 6. DMG Billing Credits */

INSERT #work_revision
SELECT 	'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = spot_liability.creation_period,
			revision_transaction_type = 6, /* DMG Billing Credits */
			revenue_period = spot_liability.creation_period  ,
			billing_date =( select max ( screening_date ) 
										from film_screening_date_xref fdx
										WHERE fdx.benchmark_end = spot_liability.creation_period),   
			value = sum ( spot_liability.spot_amount ),   
			cost = sum ( spot_liability.spot_amount ),   
			units = 1 ,
         makegood = 0,   
			revenue = SUM ( spot_liability.spot_amount  )

FROM 	campaign_spot  , spot_liability 
WHERE	campaign_spot.campaign_no = @campaign_no

 AND 	campaign_spot.spot_status != 'P'

 AND 	spot_liability.liability_type = 8 
 AND 	campaign_spot.spot_id  = spot_liability.spot_id
GROUP BY campaign_spot.campaign_no,
			spot_liability.creation_period;


/* 8. Cinelight TakeOut */

/*changed*/

INSERT #work_revision
SELECT 	'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = min(inclusion.start_date),
			revision_transaction_type = 8, /* Cinelight Takeout */
			inclusion_spot.revenue_period,
			inclusion_spot.screening_date,   
			value = 0,   
			cost = SUM ( inclusion_spot.takeout_rate * - 1),   
			units = count(*),
         makegood = 0,   
			revenue = SUM ( inclusion_spot.takeout_rate * - 1)

FROM 	inclusion_spot  , inclusion 
WHERE	inclusion.campaign_no = @campaign_no
 AND  inclusion.inclusion_id = inclusion_spot.inclusion_id
 AND	inclusion_spot.spot_status != 'P'
 AND 	inclusion.inclusion_category = 'C'

GROUP BY inclusion_spot.campaign_no,
			inclusion_spot.revenue_period,
			inclusion_spot.screening_date;


/* 9. Cinelight Billing Credits */

INSERT #work_revision
SELECT 	'NEW',
			campaign_no = cinelight_spot.campaign_no,   
			confirmation_date = min(cinelight_spot.screening_date),
			revision_transaction_type = 9, /* Cinelight Billing Credits  */
			revenue_period = cinelight_spot.billing_date ,
			billing_date =( select max ( screening_date ) 
										from film_screening_date_xref fdx
										WHERE fdx.benchmark_end = cinelight_spot_liability.creation_period),   
			value = sum ( cinelight_spot_liability.spot_amount ),   
			cost = sum ( cinelight_spot_liability.spot_amount ),   
			units = 1 ,
         makegood = 0,   
			revenue = SUM ( cinelight_spot_liability.spot_amount  )

FROM 	cinelight_spot  , cinelight_spot_liability
WHERE	cinelight_spot.campaign_no = @campaign_no

 AND 	cinelight_spot.spot_status != 'P'

 AND 	cinelight_spot_liability.liability_type = 13
 AND 	cinelight_spot.spot_id  = cinelight_spot_liability.spot_id
GROUP BY cinelight_spot.campaign_no,
			cinelight_spot_liability.creation_period,
			cinelight_spot.billing_date;


/* 10. Cinemarketing SPOTS */

INSERT #work_revision
SELECT 	'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = min(inclusion.start_date),
			revision_transaction_type = 10, /* Cinemarketing SPOTS  */
			revenue_period = ( 
					SELECT max(benchmark_end) from film_screening_date_xref 
					where film_screening_date_xref.screening_date = inclusion_spot.billing_date ),
			billing_date = inclusion_spot.billing_date,   
			value = sum( rate ),   
			cost = sum ( charge_rate ),   
			units = count(*),
         makegood = 0,   
			revenue = SUM ( inclusion_spot.charge_rate )

FROM 	inclusion_spot  , inclusion 
WHERE	inclusion.campaign_no = @campaign_no
 AND  inclusion.inclusion_id = inclusion_spot.inclusion_id
 AND	inclusion_spot.spot_status != 'P'
 AND 	inclusion.inclusion_type = 5

GROUP BY inclusion_spot.campaign_no,
			inclusion_spot.billing_date;


/* 11. Cinemarketing Billing Credits */

INSERT #work_revision
SELECT 	'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = min(inclusion_spot_liability.creation_period),
			revision_transaction_type = 11, /* Cinemarketing Billing Credits  */
			revenue_period = inclusion_spot_liability.creation_period ,
			billing_date = ( select max ( screening_date ) 
										from film_screening_date_xref fdx
										WHERE fdx.benchmark_end = inclusion_spot_liability.creation_period ),   
			value = sum ( inclusion_spot_liability.spot_amount ),   
			cost = sum ( inclusion_spot_liability.spot_amount ),   
			units = 1 ,
         makegood = 0,   
			revenue = SUM ( inclusion_spot_liability.spot_amount  )

FROM 	inclusion_spot, inclusion_spot_liability
WHERE	inclusion_spot.campaign_no = @campaign_no

 AND 	inclusion_spot.spot_status != 'P'

 AND 	inclusion_spot_liability.liability_type = 16
 AND 	inclusion_spot.spot_id  = inclusion_spot_liability.spot_id
GROUP BY inclusion_spot.campaign_no,
			inclusion_spot_liability.creation_period;


/* 12. Misc */
/*changed*/
INSERT #work_revision
SELECT 	'NEW',
			campaign_no = inclusion.campaign_no,   
			confirmation_date = min(inclusion.start_date),
			revision_transaction_type = 12, /* Misc */
			inclusion.revenue_period,
			inclusion_spot.billing_date,
			value = SUM ( inclusion.inclusion_qty * inclusion.inclusion_value ),
			cost = SUM (( inclusion.inclusion_qty * inclusion.inclusion_charge ) - inclusion.vm_cost_amount) ,   
			units = 0,
         makegood = 0,   
			revenue = SUM (( inclusion.inclusion_qty * inclusion.inclusion_charge ) - inclusion.vm_cost_amount ) 

FROM 	inclusion_spot  , inclusion 
WHERE	inclusion.campaign_no = @campaign_no
 AND  inclusion_spot.inclusion_id = inclusion.inclusion_id
 AND	inclusion_spot.spot_status != 'P'
 AND 	inclusion.inclusion_category = 'S'
 AND  inclusion.inclusion_format = 'S'
 AND  inclusion.include_revenue = 'Y'

GROUP BY inclusion.campaign_no,
			inclusion.revenue_period,
			inclusion_spot.billing_date;


/* 13. Film Revenue Proxy SPOTS */

INSERT #work_revision
SELECT 	'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = min(inclusion.start_date),
			revision_transaction_type = 13, /* Film Revenue Proxy SPOTS  */
			revenue_period = ( 
					SELECT max(benchmark_end) from film_screening_date_xref 
					where film_screening_date_xref.screening_date = inclusion_spot.billing_date ),
			billing_date = inclusion_spot.billing_date,   
			value = sum( rate ),   
			cost = sum ( charge_rate ),   
			units = count(*),
         makegood = 0,   
			revenue = SUM ( inclusion_spot.charge_rate )

FROM 	inclusion_spot  , inclusion 
WHERE	inclusion.campaign_no = @campaign_no
 AND  inclusion_spot.inclusion_id = inclusion.inclusion_id
 AND  inclusion_spot.spot_status != 'P'

 AND 	inclusion.inclusion_type = 11

GROUP BY inclusion_spot.campaign_no,
			inclusion_spot.billing_date;


/* 16. Cinemarketing TakeOut */
/*changed*/
INSERT #work_revision
SELECT 	'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = min(inclusion.start_date),
			revision_transaction_type = 16, /* Cinemarketing Takeout */
			inclusion_spot.revenue_period,
			billing_date = inclusion_spot.billing_date,   
			value = 0,   
			cost = SUM ( inclusion_spot.takeout_rate * - 1), 
			units = count(*),
         makegood = 0,   
			revenue = SUM ( inclusion_spot.takeout_rate * - 1)

FROM 	inclusion_spot  , inclusion 
WHERE	inclusion.campaign_no = @campaign_no
 AND  inclusion_spot.inclusion_id = inclusion.inclusion_id
 AND	inclusion_spot.spot_status != 'P'
 AND 	inclusion.inclusion_category = 'I'

GROUP BY inclusion_spot.campaign_no,
			inclusion_spot.revenue_period,
			inclusion_spot.billing_date;

/* 17. DMG Revenue Proxy SPOTS */

INSERT #work_revision
SELECT 	'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = min(inclusion.start_date),
			revision_transaction_type = 17, /* DMG Revenue Proxy SPOTS   */
			revenue_period = ( 
					SELECT max(benchmark_end) from film_screening_date_xref 
					where film_screening_date_xref.screening_date = inclusion_spot.billing_date ),
			billing_date = inclusion_spot.billing_date,   
			value = sum( rate ),   
			cost = sum ( charge_rate ),   
			units = count(*),
         makegood = 0,   
			revenue = SUM ( inclusion_spot.charge_rate )

FROM 	inclusion_spot  , inclusion 
WHERE	inclusion.campaign_no = @campaign_no
 AND  inclusion_spot.inclusion_id = inclusion.inclusion_id
 AND	inclusion_spot.spot_status != 'P'

 AND 	inclusion.inclusion_type = 12

GROUP BY inclusion_spot.campaign_no,
			inclusion_spot.billing_date;


/* 20. Cinelight Revenue Proxy SPOTS */

INSERT #work_revision
SELECT 	'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = min(inclusion.start_date),
			revision_transaction_type = 20, /* Cinelight Revenue Proxy SPOTS  */
			revenue_period = ( 
					SELECT max(benchmark_end) from film_screening_date_xref 
					where film_screening_date_xref.screening_date = inclusion_spot.billing_date ),
			billing_date = inclusion_spot.billing_date,   
			value = sum( rate ),   
			cost = sum ( charge_rate ),   
			units = count(*),
         makegood = 0,   
			revenue = SUM ( inclusion_spot.charge_rate )

FROM 	inclusion_spot  , inclusion 
WHERE	inclusion.campaign_no = @campaign_no
 AND  inclusion_spot.inclusion_id = inclusion.inclusion_id
 AND	inclusion_spot.spot_status != 'P'
 AND 	inclusion.inclusion_type = 13

GROUP BY inclusion_spot.campaign_no,
			inclusion_spot.billing_date;


/* 23. CineMarketing Revenue Proxy SPOTS*/

INSERT #work_revision
SELECT 	'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = min(inclusion.start_date),
			revision_transaction_type = 23, /* CineMarketing Revenue Proxy SPOTS */
			revenue_period = ( 
					SELECT max(benchmark_end) from film_screening_date_xref 
					where film_screening_date_xref.screening_date = inclusion_spot.billing_date ),
			billing_date = inclusion_spot.billing_date,   
			value = sum( rate ),   
			cost = sum ( charge_rate ),   
			units = count(*),
         makegood = 0,   
			revenue = SUM ( inclusion_spot.charge_rate )

FROM 	inclusion_spot  , inclusion 
WHERE	inclusion.campaign_no = @campaign_no
 AND  inclusion_spot.inclusion_id = inclusion.inclusion_id
 AND	inclusion_spot.spot_status != 'P'
 AND 	inclusion.inclusion_type = 14

GROUP BY inclusion_spot.campaign_no,
			inclusion_spot.billing_date;


INSERT INTO #delta_revision (
			campaign_no, 
			revision_transaction_type,	
			revenue_period ,	
			billing_date, 
			value,
			cost,
			units,
			makegood,
			revenue)
 ( SELECT #work_revision.campaign_no,
	 #work_revision.revision_transaction_type,   
         #work_revision.revenue_period,   
         #work_revision.billing_date,   
         sum ( #work_revision.value),   
         sum ( #work_revision.cost) ,   
         sum ( #work_revision.units),   
         sum ( #work_revision.makegood),   
         sum ( #work_revision.revenue )  
    FROM #work_revision
GROUP BY #work_revision.campaign_no,
	 #work_revision.revision_transaction_type,   
         #work_revision.revenue_period,   
         #work_revision.billing_date
HAVING   sum ( #work_revision.value) <> 0 OR 
         sum ( #work_revision.cost) <> 0 OR 
         sum ( #work_revision.units) <> 0 OR 
         sum ( #work_revision.makegood) <> 0 OR 
         sum ( #work_revision.revenue )  <> 0);

/* insert existing compaign transactions as a negative value to figure out the delta */


/* Now add required revision transactions 
	The temporary table now contains:
	-	NEW -	the current picture of spots etc
	-	OLD -	revision transactions from previous snapshot as negatives
	The net effect is that if you add all the values up in the 
	temporary table, any none zero value is a change to the cell (row).
	The group by gives you the delta for each row.
	Total Revision Was:	Key A	10, 	Key B 10
	Total Revision s/b:	Key B 10,	Key C 10
	
	Temporary Table:	
		Key A -10 OLD,
		Key B -10 OLD,
		Key B	 10 NEW,
		Key C	 10 NEW

	A group by produces this delta:
		Key A -10
		Key C	 10

	Revision now holds:	Key A: 10
	
*/

DELETE FROM #delta_revision 
WHERE   IsNull( #delta_revision.value , 0 ) = 0 AND
        IsNull( #delta_revision.cost , 0 ) = 0 AND  
        IsNull( #delta_revision.makegood, 0 ) = 0 AND
        IsNull( #delta_revision.revenue, 0 ) = 0;

/* Add new campaign revision records from temporary table */
IF ( IsNull( @revision_id, 0 ) = 0 )
begin
	INSERT INTO campaign_revision  
				( campaign_no,   
				  revision_type,   
				  revision_category,   
				  revision_no,
				  confirmed_by,
				  confirmation_date,
				  comment )  
	  SELECT
				#delta_revision.campaign_no,   
				@revision_type,   
				@revision_category,   
				@revision_no,
				@user_id,
				min(#delta_revision.billing_date),
				@default_comment
		FROM #delta_revision 
		WHERE NOT EXISTS
			( SELECT * FROM campaign_revision
					WHERE campaign_revision.campaign_no = #delta_revision.campaign_no
					  AND campaign_revision.revision_no    =     @revision_no   )
		GROUP BY
					#delta_revision.campaign_no;

  INSERT INTO revision_transaction  
         ( revision_id,   
           revision_transaction_type,   
           revenue_period,   
           billing_date,   
           delta_date,   
           value,   
           cost,   
           units,   
           makegood,   
           revenue )  
	( SELECT
           campaign_revision.revision_id,   
           #delta_revision.revision_transaction_type,   
           #delta_revision.revenue_period,   
			  #delta_revision.billing_date,
           #delta_revision.billing_date,   
           #delta_revision.value,   
           #delta_revision.cost,   
           #delta_revision.units,   
           #delta_revision.makegood,   
           #delta_revision.revenue
		FROM campaign_revision  , #delta_revision
		WHERE  campaign_revision.campaign_no = #delta_revision.campaign_no
		AND campaign_revision.revision_no =   @revision_no);
	
end


IF ( IsNull( @revision_id, 0 ) != 0 )
begin
	 INSERT INTO revision_transaction  
         ( revision_id,   
           revision_transaction_type,   
           revenue_period,   
           billing_date,   
           delta_date,   
           value,   
           cost,   
           units,   
           makegood,   
           revenue )  
	( SELECT
           @revision_id,   
           #delta_revision.revision_transaction_type,   
           #delta_revision.revenue_period,   
           #delta_revision.billing_date,      
           #delta_revision.billing_date,      
           sum ( #delta_revision.value ),   
           sum ( #delta_revision.cost ),   
           sum ( #delta_revision.units ),   
           sum ( #delta_revision.makegood ),   
           sum ( #delta_revision.revenue )
		FROM #delta_revision
		GROUP BY            
			#delta_revision.revision_transaction_type,   
         #delta_revision.revenue_period,   
         #delta_revision.billing_date 
);

end


return 0
GO
