/****** Object:  StoredProcedure [dbo].[p_certificate_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_report]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_certificate_report] @complex_id			int,
                                 @screening_date	datetime
as

/*
 * Declare Variables
 */

declare @error     			    		integer,
        @rowcount       	    		integer,
        @group_count					integer,
        @contractor_code	    		char(3),
        @complex_branch		    		char(2),
        @address1						varchar(50),
        @address2						varchar(50),
        @address3						varchar(50),
        @address4						varchar(50),
        @address5						varchar(50),
        @address_category	    		char(3),
		@certificate_group_id_1        	int,
	    @group_no_1			        	smallint,
		@group_name_1		            varchar(60),
		@is_movie_1			        	char(1),
		@certificate_group_id_2        	int,
	    @group_no_2			        	smallint,
		@group_name_2		            varchar(60),
		@is_movie_2			        	char(1),
		@occurence_1					int,
		@occurence_2					int
        
set nocount on

/*
 * Create Temporary Tables
 */

create table #cert_items
(
	certificate_group_id			int						null,
    group_no								smallint				null,
	group_name						varchar(60)		null,
	is_movie								char(1)				null,
	occurence							smallint				null,
	mode										char(1)				null
)

create table #cert_items_n_up
(
	certificate_group_id_1        	int					null,
    group_no_1			        			smallint			null,
	group_name_1						varchar(60)	null,
	is_movie_1			        			char(1)			null,
	occurence_1							smallint			null,
	certificate_group_id_2        	int					null,
    group_no_2			        			smallint			null,
	group_name_2						varchar(60)	null,
	is_movie_2			        			char(1)			null,
	occurence_2							smallint			null,
	mode											char(1)
)

/*
 * Get Certificate Address Information
 */

select	@contractor_code = contractor_code,
				@complex_branch = branch_code
from		complex
where	complex_id = @complex_id

if(@contractor_code = 'Val')
	select @address_category = 'fsc'
else
	select @address_category = 'isc'

select @address1 = address_1,
		 @address2 = address_2,
		 @address3 = address_3,
		 @address4 = address_4,
		 @address5 = address_5
  from branch_address
 where branch_code = @complex_branch and
       address_category = @address_category

/*
 * Insert Certificate Items into Temporary Table
 */

insert  into #cert_items
select  certificate_group.certificate_group_id,
        certificate_group.group_no,
        certificate_group.group_name,
        certificate_group.is_movie,
		0,
		'M'
  from  certificate_group,
        certificate_item
 where  certificate_group.complex_id = @complex_id and
		certificate_group.screening_date = @screening_date and 
        certificate_group.certificate_group_id = certificate_item.certificate_group and
        certificate_item.item_show = 'Y' and 
        left(group_name, 13) <> 'Cinema Screen'
group by certificate_group.certificate_group_id,
        certificate_group.group_no,
        certificate_group.group_name,
       certificate_group.is_movie

select @group_count = @@rowcount

/*
 * Insert Certificate Items for Groups with No Bookings
 */

insert into #cert_items
SELECT     	dbo.certificate_group.certificate_group_id,
			dbo.certificate_group.group_no, 
			MIN(dbo.certificate_group.group_name),
			MIN(dbo.certificate_group.is_movie),
			0,
			'M'
FROM        dbo.certificate_group 
			LEFT OUTER JOIN dbo.certificate_item ON dbo.certificate_group.certificate_group_id = dbo.certificate_item.certificate_group
WHERE     	(dbo.certificate_group.complex_id = @complex_id) 
AND 		(dbo.certificate_group.screening_date = @screening_date) and 
        left(group_name, 13) <> 'Cinema Screen'
GROUP BY 	dbo.certificate_group.certificate_group_id, dbo.certificate_group.group_no
HAVING      (COUNT(dbo.certificate_item.certificate_item_id) = 0)

select @rowcount = @@rowcount
select @group_count = @group_count + @rowcount

/*
 * Insert Certificate Items for Movie History Entries with No Advertising Allowed
 */

  insert into #cert_items
  select 0,
         movie.movie_id,
         movie.long_name,
         'N',
		 movie_history.occurence,
		'M' 
    from movie_history,
		movie
      where movie_history.complex_id = @complex_id and
		 movie_history.screening_date = @screening_date and
		 movie.movie_id = movie_history.movie_id and
         movie_history.advertising_open = 'N' and 
		 /*(certificate_group not in (SELECT     	dbo.certificate_group.certificate_group_id
									FROM        dbo.certificate_group LEFT OUTER JOIN
													dbo.certificate_item ON dbo.certificate_group.certificate_group_id = dbo.certificate_item.certificate_group
									WHERE     	(dbo.certificate_group.complex_id = @complex_id) 
									AND 		(dbo.certificate_group.screening_date = @screening_date)
									GROUP BY 	dbo.certificate_group.certificate_group_id
									HAVING      (COUNT(dbo.certificate_item.certificate_item_id) = 0)) 
		or certificate_group is null)*/
        certificate_group is null
    order by movie.long_name

declare		certificate_group_csr cursor static forward_only for
select		certificate_group_id,
					group_no,
					group_name,
					is_movie,
					occurence
from 			#cert_items
order by	group_name, group_no
for				read only

open certificate_group_csr
fetch certificate_group_csr into @certificate_group_id_1, @group_no_1, @group_name_1, @is_movie_1, @occurence_1
while(@@fetch_status=0)
begin

	fetch certificate_group_csr into @certificate_group_id_2, @group_no_2, @group_name_2, @is_movie_2, @occurence_2
	
	if @@fetch_status<>0
		select @certificate_group_id_2 = null, @group_no_2 = -1, @group_name_2 = null, @is_movie_2 = null, @occurence_2 = null

	select @group_count = 1
		
	insert into #cert_items_n_up
	(certificate_group_id_1,    group_no_1,	group_name_1,	is_movie_1,	occurence_1,	certificate_group_id_2,    group_no_2,	group_name_2,	is_movie_2,	occurence_2, mode	)
	values (@certificate_group_id_1, @group_no_1, @group_name_1, @is_movie_1, @occurence_1, @certificate_group_id_2, @group_no_2, @group_name_2, @is_movie_2,@occurence_2, 'M' )

	fetch certificate_group_csr into @certificate_group_id_1, @group_no_1, @group_name_1, @is_movie_1, @occurence_1
end

deallocate certificate_group_csr

delete #cert_items

/*
 * Insert Certificate Items into Temporary Table
 */

insert  into #cert_items
select  certificate_group.certificate_group_id,
        certificate_group.group_no,
        certificate_group.group_name,
        certificate_group.is_movie,
		0,
		'A'
  from  certificate_group,
        certificate_item
 where  certificate_group.complex_id = @complex_id and
		certificate_group.screening_date = @screening_date and 
        certificate_group.certificate_group_id = certificate_item.certificate_group and
        certificate_item.item_show = 'Y' and 
        left(group_name, 13) = 'Cinema Screen'
group by certificate_group.certificate_group_id,
        certificate_group.group_no,
        certificate_group.group_name,
       certificate_group.is_movie
order by group_no       


/*
 * Insert Certificate Items for Groups with No Bookings
 */

insert into #cert_items
SELECT     	dbo.certificate_group.certificate_group_id,
			dbo.certificate_group.group_no, 
			MIN(dbo.certificate_group.group_name),
			MIN(dbo.certificate_group.is_movie),
			0,
			'A'
FROM        dbo.certificate_group 
			LEFT OUTER JOIN dbo.certificate_item ON dbo.certificate_group.certificate_group_id = dbo.certificate_item.certificate_group
WHERE     	(dbo.certificate_group.complex_id = @complex_id) 
AND 		(dbo.certificate_group.screening_date = @screening_date) and 
        left(group_name, 13) = 'Cinema Screen'
GROUP BY 	dbo.certificate_group.certificate_group_id, dbo.certificate_group.group_no
HAVING      (COUNT(dbo.certificate_item.certificate_item_id) = 0)

declare	certificate_group_csr cursor static forward_only for
select		certificate_group_id,
		    group_no,
			group_name,
			is_movie,
			occurence
from 		#cert_items
order by	group_no, group_name
for			read only

open certificate_group_csr
fetch certificate_group_csr into @certificate_group_id_1, @group_no_1, @group_name_1, @is_movie_1, @occurence_1
while(@@fetch_status=0)
begin

	fetch certificate_group_csr into @certificate_group_id_2, @group_no_2, @group_name_2, @is_movie_2, @occurence_2
	
	if @@fetch_status<>0
		select @certificate_group_id_2 = null, @group_no_2 = -1, @group_name_2 = null, @is_movie_2 = null, @occurence_2 = null

	select @group_count = 1
	
	insert into #cert_items_n_up
	(certificate_group_id_1,    group_no_1,	group_name_1,	is_movie_1,	occurence_1,	certificate_group_id_2,    group_no_2,	group_name_2,	is_movie_2,	occurence_2, mode	)
	values (@certificate_group_id_1, @group_no_1, @group_name_1, @is_movie_1, @occurence_1, @certificate_group_id_2, @group_no_2, @group_name_2, @is_movie_2,@occurence_2, 'A' )


	fetch certificate_group_csr into @certificate_group_id_1, @group_no_1, @group_name_1, @is_movie_1, @occurence_1
end

deallocate certificate_group_csr

/*
 * Return Result Set
 */

if (@group_count>0)
begin
      SELECT  @screening_date AS screening_date, 
                  cplx.complex_name, 
                  cplx.manager, 
                  cplx.address_1, 
                  cplx.address_2, 
                  CONVERT(varchar(30), cplx.town_suburb) as suburb,
                  cplx.state_code, 
                  cplx.postcode, 
                  cplx.fax, 
                  cplx.certificate_send_method, 
                  cplx.email, 
                  cd.certificate_revision, 
                  @complex_branch,
                  @address1 as 'address1',
                  @address2 as 'address2',
                  @address3 as 'address3',
                  @address4 as 'address4',
                  @address5 as 'address5',
                  #cert_items_n_up.group_no_1, 
                  #cert_items_n_up.group_name_1, 
                  #cert_items_n_up.is_movie_1, 
                  @group_count AS group_count, 
                  cd.certificate_comment, 
                  @contractor_code as contractor_code,
                  bm.branch_message_text, 
                  #cert_items_n_up.certificate_group_id_1, 
                  #cert_items_n_up.occurence_1, 
                  #cert_items_n_up.group_no_2, 
                  #cert_items_n_up.group_name_2, 
                  #cert_items_n_up.is_movie_2, 
                  #cert_items_n_up.certificate_group_id_2, 
                  #cert_items_n_up.occurence_2,
                  #cert_items_n_up.mode
      FROM  	 complex as cplx
                        inner join complex_date AS cd ON cd.complex_id = cplx.complex_id
                        left outer join branch_message AS bm ON cplx.branch_code = bm.branch_code and  bm.message_category_code = 'C'
                  cross join #cert_items_n_up
      WHERE       (cd.complex_id = @complex_id) 
      AND         (cd.screening_date = @screening_date) 
      AND         (cplx.complex_id = @complex_id) 
      ORDER BY    #cert_items_n_up.group_name_1
end
else
begin
      SELECT      @screening_date AS screening_date, 
                  cplx.complex_name, 
                  cplx.manager, 
                  cplx.address_1, 
                  cplx.address_2, 
                  CONVERT(varchar(30), cplx.town_suburb) as suburb,
                  cplx.state_code, 
                  cplx.postcode, 
                  cplx.fax, 
                  cplx.certificate_send_method, 
                  cplx.email, 
                  cd.certificate_revision, 
                  @complex_branch as complex_branch,
                  @address1 as address1,
                  @address2 as address2,
                  @address3 as address3,
                  @address4 as address4,
                  @address5 as address5,
                  NULL as group_no_1, 
                  NULL as group_name_1, 
                  NULL as is_movie_1, 
                  @group_count AS group_count, 
                  cd.certificate_comment, 
                  @contractor_code as contractor_code,
                  bm.branch_message_text, 
				  null as certificate_group_id_1, 
                  null as occurence_1, 
                  null as group_no_2, 
                  null as group_name_2, 
                  null as is_movie_2, 
                  null as certificate_group_id_2, 
                  null as occurence_2,
                  null as mode      
                  FROM        complex_date AS cd 
                    INNER JOIN  complex AS cplx ON cd.complex_id = cplx.complex_id 
                  LEFT OUTER JOIN branch_message AS bm ON cplx.branch_code = bm.branch_code  AND   (bm.message_category_code = 'C')
      WHERE       (cd.complex_id = @complex_id) 
      AND         (cd.screening_date = @screening_date) 
      AND         (cplx.complex_id = @complex_id) 
      
end  

return 0
GO
