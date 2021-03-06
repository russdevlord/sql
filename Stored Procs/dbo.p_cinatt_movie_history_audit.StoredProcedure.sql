/****** Object:  StoredProcedure [dbo].[p_cinatt_movie_history_audit]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_movie_history_audit]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_movie_history_audit]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cinatt_movie_history_audit] @screening_date    datetime
as

                           

declare @error							integer,
	     @sqlstatus					integer,
        @errorode							integer,
        @complex_id					integer,
        @complex_name				varchar(50),
        @movie_id						integer,
        @movie_name					varchar(50),
        @mh_csr_open					tinyint,
        @att_count					integer

                                  

  select distinct 
         mh.screening_date, 
         m.movie_id,
         m.long_name,
         c.complex_id,
         c.complex_name,
         c.film_market_no
    from movie_history mh, 
         movie m,
         complex c
   where country = 'A' and
         mh.movie_id = m.movie_id and
         mh.complex_id = c.complex_id and
         mh.screening_date = @screening_date and
         mh.complex_id in (select distinct complex_id from cinema_attendance) and
         not exists
       ( select 1
           from cinema_attendance ca
          where mh.complex_id = ca.complex_id and
                mh.movie_id = ca.movie_id and
                mh.screening_date =  ca.screening_date ) and
          exists 
        ( select 1
           from cinema_attendance ca
          where mh.complex_id = ca.complex_id and
                mh.screening_date =  ca.screening_date)







/*


create table #results
(
   complex_id				integer			null,
	complex_name			varchar(50)		null,
   screening_date			datetime			null,
	movie_id					integer			null,
	movie_name				varchar(50)		null,
)

                            

 declare mh_csr cursor static for
  select distinct 
         mh.screening_date, 
         m.movie_id,
         m.long_name,
         c.complex_id,
         c.complex_name
    from movie_history mh, 
         movie m,
         complex c
   where country = 'A' and
         mh.movie_id = m.movie_id and
         mh.complex_id = c.complex_id and
         mh.screening_date >= '1-JAN-2002' and
         mh.screening_date <= '31-DEC-2002' and
         mh.complex_id in (select distinct complex_id from cinema_attendance) and
         not exists
       ( select 1
           from cinema_attendance ca
          where mh.complex_id = ca.complex_id and
                mh.movie_id = ca.movie_id and
                mh.screening_date =  ca.screening_date ) 
     for read only

                                

select @mh_csr_open = 0

select getdate()                         
 
open mh_csr
select @mh_csr_open = 1
fetch mh_csr into @screening_date, @movie_id, @movie_name, @complex_id, @complex_name
while (@@fetch_status = 0)
begin

	                                                                                        

	select @att_count = 0

	select @att_count = count(movie_id)
     from cinema_attendance
    where complex_id = @complex_id and
          screening_date = @screening_date

	if(@att_count <> 0)
	begin
		
		insert into #results (
		       complex_id,
	          complex_name,
             screening_date,
	          movie_id,
	          movie_name ) values (
             @complex_id,
	          @complex_name,
             @screening_date,
	          @movie_id,
	          @movie_name )

	end

	                            

	fetch mh_csr into @screening_date, @movie_id, @movie_name, @complex_id, @complex_name

end
close mh_csr
select @mh_csr_open = 0

                          

select #results.complex_id, #results.complex_name, #results.screening_date, #results.movie_id, #results.movie_name from #results

select getdate()                  

return 0

                         

error:
	
	if(@mh_csr_open = 1)
	begin
		close mh_csr
		deallocate mh_csr
	end

	return -1


*/
GO
