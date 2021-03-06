/****** Object:  StoredProcedure [dbo].[p_certificate_report_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_report_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_report_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_certificate_report_sub] 	@complex_id		        int,
                                 	 	@screening_date        	datetime,
									 	@group_no			    int,
										@max_group_no			int,
										@occurence				int

as

SET NOCOUNT ON 

/*
 * Declare Variables
 */

declare @error     			int,
        @rowcount       	int,
        @group_count		int,
        @contractor_code	char(3),
        @complex_branch		char(2),
        @address1			varchar(50),
        @address2			varchar(50),
        @address3			varchar(50),
        @address4			varchar(50),
        @address5			varchar(50),
        @address_category	char(3),
        @country_code       char(1),
        @country_count      int

select  @country_code = state.country_code
from    complex with (nolock),
        state with (nolock)
where   complex.complex_id = @complex_id 
and     complex.state_code = state.state_code

/*
 * Create Temporary Tables
 */

create table #cert_items
(
	group_no			    smallint			null,
	group_name		        varchar(60)			null,
	is_movie			    char(1)				null,
	sequence_no		        smallint			null,
	item_comment	        varchar(100)		null,
	campaign_no		        int 				null,
	print_id		        int 				null,
	print_name		        varchar(50)			null,
	duration			    smallint			null,
	sound_format	        char(1)				null,
	print_ratio		        char(1)				null,
    client			        varchar(30)			null,
    times_in		        int 				null,
	print_type              char(1)				null,
    certificate_source      char(1)             null,
	gold_class				char(1)             null,
	premium_cinema			char(1)				null,
	show_category			char(1)				null,
	group_print_medium		char(1)				null,
	group_three_d_type		int					null,
	item_print_medium		char(1)				null,
	item_three_d_type		int					null

)

select @group_count = 0

/*
 * Insert Certificate Items into Temporary Table
 */

insert into #cert_items
SELECT	certificate_group.group_no, 
		certificate_group.group_name, 
		certificate_group.is_movie, 
		certificate_item.sequence_no, 
		certificate_item.item_comment, 
		campaign_spot.campaign_no, 
        (CASE	WHEN film_print.print_id = 1 THEN 10000 
				WHEN film_print.print_id = 10 THEN 10002 
				WHEN film_print.print_id = 12 THEN 10005 
				when film_print.print_id = 13 then 10006 
				when film_print.print_id = 14 then 10007 
				when film_print.print_id = 15 then 10008  
				when film_print.print_id = 16 then 10009 
				when film_print.print_id = 17 then 10010 
				ELSE film_print.print_id end) AS print_id, 
		film_print.print_name, 
		film_print.duration, 
		film_print.sound_format, 
		film_print.print_ratio, 
		NULL,
				(SELECT     COUNT(print_id)
        FROM        certificate_prints
        WHERE       complex_id = certificate_group.complex_id 
        AND         screening_date = certificate_group.screening_date
        AND         print_id = certificate_item.print_id) as times_in,
 		(CASE	WHEN film_print.print_id = 1 THEN 'H' 
 				WHEN film_print.print_id = 10 THEN 'H' 
 				WHEN film_print.print_id = 12 THEN 'H' 
 				when film_print.print_id = 13 then 'H' 
 				when film_print.print_id = 14 then 'H' 
 				when film_print.print_id = 15 then 'H' 
 				when film_print.print_id = 16 then 'H' 
 				when film_print.print_id = 17 then 'H'
 				ELSE film_print.print_type END) AS print_type,
		certificate_item.certificate_source, 
		certificate_group.premium_cinema, 
		certificate_item.premium_cinema, 
		certificate_group.show_category, 
		certificate_group.print_medium, 
		certificate_group.three_d_type, 
		certificate_item.print_medium, 
		certificate_item.three_d_type
FROM	certificate_group  with(nolock) INNER JOIN
		certificate_item  with(nolock) ON certificate_group.certificate_group_id = certificate_item.certificate_group INNER JOIN
		film_print  with(nolock) ON certificate_item.print_id = film_print.print_id LEFT OUTER JOIN
		campaign_spot  with(nolock) ON certificate_item.spot_reference = campaign_spot.spot_id
WHERE	(certificate_group.complex_id = @complex_id) 
AND		(certificate_group.screening_date = @screening_date) 
AND		(certificate_item.item_show = 'Y') 
AND		(certificate_group.group_no = @group_no)

select @rowcount = @@rowcount
select @group_count = @group_count + @rowcount

/*
 * Insert Certificate Items for Groups with No Bookings
 */

  insert into #cert_items
  select certificate_group.group_no,
         min(certificate_group.group_name),
         min(certificate_group.is_movie),
         1,
         null,
		 null,
		 null,
         'NO BOOKINGS THIS WEEK',
         0,
         null,
         null,
         null,
         0,
		 null,
         null,
		 min(certificate_group.premium_cinema),
		 null,
		 certificate_group.show_category,
		certificate_group.print_medium,
		certificate_group.three_d_type,
		certificate_item.print_medium,
		certificate_item.three_d_type
FROM	certificate_group  with(nolock) LEFT OUTER JOIN
		certificate_item with(nolock) ON certificate_group.certificate_group_id = certificate_item.certificate_group
WHERE	(certificate_group.complex_id = @complex_id) 
AND		(certificate_group.screening_date = @screening_date) 
AND		(certificate_group.group_no = @group_no)
GROUP BY certificate_group.certificate_group_id, 
		certificate_group.group_no, 
		certificate_group.show_category, 
		certificate_group.print_medium, 
		certificate_group.three_d_type, 
		certificate_item.print_medium, 
		certificate_item.three_d_type
HAVING      (COUNT(certificate_item.certificate_item_id) = 0)

select @rowcount = @@rowcount
select @group_count = @group_count + @rowcount

/*
 * Insert Certificate Items for Groups with No Bookings
 */
 
if @group_count < 1
begin

    if @occurence = 1
    begin
        insert into 	#cert_items
        select 			0,
                        mc.movie_name + ' (' + convert(varchar(5),class.classification_code) + ')',
                        'Y',
                        1,
                        null,
                        null,
                        null,
                        'NO BOOKINGS THIS WEEK',
                        0,
                        null,
                        null,
                        null,
                        0,
                        null,
                        null,
                        movie_history.premium_cinema,
                        null,
                        movie_history.show_category,
                        null,
                        null,
                        null,
                        null
        from 			movie_history with (nolock),
                        movie with (nolock),
                        movie_country mc with (nolock),
                        classification class with (nolock)
        where			movie_history.complex_id = @complex_id 
        and				movie_history.screening_date = @screening_date 
        and				movie_history.movie_id = movie.movie_id  
        and				movie_history.occurence = @occurence 
        and				movie_history.movie_id = @group_no
        and             movie.movie_id = mc.movie_id 
        and			    mc.country_code = @country_code
        and			    mc.classification_id = class.classification_id 
        
        
        select @rowcount = @@rowcount
        
        if @rowcount = 0
        begin
            insert into 	#cert_items
            select 			0,
                            movie.long_name,
                            'Y',
                            1,
                            null,
                            null,
                            null,
                            'NO BOOKINGS THIS WEEK',
                            0,
                            null,
                            null,
                            null,
                            0,
                            null,
                            null,
                            movie_history.premium_cinema,
                            null,
                            movie_history.show_category,
                            null,
                            null,
                            null,
                            null
            from 			movie_history with (nolock),
                            movie with (nolock)
            where			movie_history.complex_id = @complex_id 
            and				movie_history.screening_date = @screening_date 
            and				movie_history.movie_id = movie.movie_id  
            and				movie_history.occurence = @occurence 
            and				movie_history.movie_id = @group_no
            
            select @rowcount = @@rowcount
        end
        
        
        select @group_count = @group_count + @rowcount
    end
    else
    begin
        insert into 	#cert_items
        select 			0,
                        mc.movie_name + ' (' + convert(varchar(5),class.classification_code) + ')' + ' - ' + convert(varchar(2),@occurence),
                        'Y',
                        1,
                        null,
                        null,
                        null,
                        'NO BOOKINGS THIS WEEK',
                        0,
                        null,
                        null,
                        null,
                        0,
                        null,
                        null,
                        movie_history.premium_cinema,
                        null,
                        movie_history.show_category,
                        null,
                        null,
                        null,
                        null
        from 			movie_history with (nolock),
                        movie with (nolock),
                        movie_country mc with (nolock),
                        classification class with (nolock)
        where			movie_history.complex_id = @complex_id 
        and				movie_history.screening_date = @screening_date 
        and				movie_history.movie_id = movie.movie_id  
        and				movie_history.occurence = @occurence 
        and				movie_history.movie_id = @group_no
        and             movie.movie_id = mc.movie_id 
        and			    mc.country_code = @country_code
        and			    mc.classification_id = class.classification_id 
 
        
        select @rowcount = @@rowcount

        if @rowcount = 0
        begin
            insert into 	#cert_items
            select 			0,
                            movie.long_name  + ' - ' + convert(varchar(2),@occurence),
                            'Y',
                            1,
                            null,
                            null,
                            null,
                            'NO BOOKINGS THIS WEEK',
                            0,
                            null,
                            null,
                            null,
                            0,
                            null,
                            null,
                            movie_history.premium_cinema,
                            null,
                            movie_history.show_category,
                            null,
                            null,
                            null,
                            null
            from 			movie_history with (nolock),
                            movie with (nolock)
            where			movie_history.complex_id = @complex_id 
            and				movie_history.screening_date = @screening_date 
            and				movie_history.movie_id = movie.movie_id  
            and				movie_history.occurence = @occurence 
            and				movie_history.movie_id = @group_no
            
            select @rowcount = @@rowcount
        end

        select @group_count = @group_count + @rowcount
    end
end

/*
 * Update Client
 */

update #cert_items
   set client = client.client_short_name
  from film_campaign fc with(nolock),
       client with(nolock)
 where #cert_items.campaign_no = fc.campaign_no and
       fc.client_id = client.client_id

/*
 * Return Result Set
 */

if (@group_count=0)
begin
  select 	CONVERT(DATETIME,@screening_date) as screening_date,
			CONVERT(INT, NULL),
			CONVERT(VARCHAR(60), NULL),
			CONVERT(VARCHAR(1), NULL),
			CONVERT(INT, NULL),
			CONVERT(VARCHAR(100), NULL),
			CONVERT(VARCHAR(50), NULL),
			CONVERT(VARCHAR(10), NULL),
			CONVERT(VARCHAR(1), NULL),
			CONVERT(VARCHAR(1), NULL),
			CONVERT(VARCHAR(30), NULL),
			CONVERT(INT, NULL),
			@group_count,
			CONVERT(VARCHAR(1), NULL),
			CONVERT(INT, NULL),
			CONVERT(VARCHAR(1), NULL),
			CONVERT(VARCHAR(1), NULL),
			CONVERT(VARCHAR(1), NULL),
			CONVERT(INT, NULL),
			CONVERT(VARCHAR(1), NULL),
			CONVERT(VARCHAR(1), NULL),
			CONVERT(INT, NULL),
			CONVERT(VARCHAR(1), NULL),
			CONVERT(INT, NULL)
end
else
begin
  select 	@screening_date as screening_date,
			#cert_items.group_no,
			#cert_items.group_name,
			#cert_items.is_movie,
			#cert_items.sequence_no,
			#cert_items.item_comment,
			#cert_items.print_name,
			convert(varchar(6),#cert_items.duration) + ' sec'  as duration,
			#cert_items.sound_format,
			#cert_items.print_ratio,
			#cert_items.client,
			#cert_items.times_in,
			@group_count as group_count,
			#cert_items.print_type,
			#cert_items.print_id,
			#cert_items.certificate_source,
			#cert_items.gold_class,
			#cert_items.premium_cinema,
			#cert_items.duration as duration_no,
			#cert_items.show_category,
			group_print_medium,
			group_three_d_type,
			item_print_medium,
			item_three_d_type
    from 	#cert_items with (nolock)
order by 	#cert_items.group_no,
         	#cert_items.sequence_no
end

return 0
GO
