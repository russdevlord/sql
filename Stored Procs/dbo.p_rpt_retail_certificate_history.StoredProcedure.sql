/****** Object:  StoredProcedure [dbo].[p_rpt_retail_certificate_history]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rpt_retail_certificate_history]
GO
/****** Object:  StoredProcedure [dbo].[p_rpt_retail_certificate_history]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_rpt_retail_certificate_history]

		@start_date DATETIME
		,@end_date DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --for testing
    
	--DECLARE @start_date DATETIME
	--		,@end_date DATETIME

	--set @start_date = '2015-10-18'
	--set @end_date = '2015-10-25'
	
	--drop table #output
	
	create table #output(
	user_login			varchar(50),
	print_date			date,
	No_of_batches		int,
	total_time_taken	float
	)

	
	DECLARE @login                  varchar(50)
			,@date                  DATE
			,@total_time            decimal(18, 2)
			,@batch_count			int
			,@date_compare1         DATETIME
			,@date_compare2         DATETIME
			,@date_compare_source   DATETIME
			,@time_diff             int
			,@new_batch				bit
			,@loop_count			int

	-- @new_batch key
	--	1 = true
	--	0 = false



	declare		user_csr cursor for
	select distinct login
	from outpost_cert_history
	where screening_date BETWEEN @start_date and @end_date
	--and login = 'sburling'
	order by login

	-- loop over one user at a time
	open user_csr
	fetch user_csr into @login
	while(@@fetch_status = 0)
	BEGIN

			set @new_batch = 1
			set @total_time = 0
			set @batch_count = 0
			-- loop over one day at a time for the selected user
			DECLARE day_csr CURSOR  FOR
			select DISTINCT  cast(print_time as date)
			from outpost_cert_history
			where login = @login
			and screening_date BETWEEN @start_date and @end_date
			order by cast(print_time as date) asc

			open day_csr
			fetch day_csr into @date

			while(@@fetch_status = 0)
			BEGIN
					-- loop over the times for the selected day
					declare compare_csr scroll cursor for
					select distinct convert(varchar(16), print_time, 120)
					from outpost_cert_history
					where login = @login
					and screening_date BETWEEN @start_date and @end_date
					and cast(print_time as date) = @date
					order by convert(varchar(16), print_time, 120) asc

					open compare_csr
					fetch compare_csr into @date_compare_source

					while(@@fetch_status = 0)
					BEGIN

							if @new_batch = 1
							begin
								set @batch_count += 1
								SET @date_compare1 = @date_compare_source
								set @new_batch = 0
								set @date_compare2 = null
								set @loop_count = 0
							end
							else if @new_batch = 0
							begin
								if @date_compare2 is null 
								begin
									set @date_compare2 = @date_compare_source
								end 
								else
								begin
									set @date_compare1 = @date_compare2
									set @date_compare2 = @date_compare_source
								end

								set @time_diff = (select datediff(minute, @date_compare1, @date_compare2))
								
								if @time_diff > 0 and @time_diff <= 5
								begin
									set @total_time += @time_diff
									set @loop_count += 1
								end
								else if @time_diff > 5
								begin							
									set @new_batch = 1
									
									if @loop_count = 0
									begin
										set @total_time = 0.01
									end			
									fetch PRIOR FROM compare_csr into @date_compare_source
								end				
							end
							fetch compare_csr into @date_compare_source
					END
					CLOSE compare_csr
					DEALLOCATE compare_csr
					
					if @loop_count = 0
					begin
						set @total_time = 0.01
					end
					
					insert into #output values(@login, @date, @batch_count, @total_time)
					set @batch_count = 0
					set @total_time = 0
					
					fetch day_csr into @date
			END

			CLOSE day_csr
			DEALLOCATE day_csr
			
			fetch user_csr into @login
	END
	CLOSE user_csr
	DEALLOCATE user_csr


	select * from #output
		
END
GO
