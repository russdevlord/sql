/****** Object:  StoredProcedure [dbo].[sp_reachfrequency_population_mmadjustment_update]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[sp_reachfrequency_population_mmadjustment_update]
GO
/****** Object:  StoredProcedure [dbo].[sp_reachfrequency_population_mmadjustment_update]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_reachfrequency_population_mmadjustment_update]
	 @country_code         char(1),                     	  
	 @screening_date       datetime,                       
	 @mm_adjustment      numeric(6,4)                         
AS
BEGIN
	BEGIN TRY
		Update cinetam_reachfreq_population
		set mm_adjustment=@mm_adjustment
		where screening_date=@screening_date
		and country_code=@country_code	
	END TRY
	BEGIN CATCH  	

		DECLARE @ErMessage NVARCHAR(2048),@ErSeverity INT,@ErState INT 
		SELECT @ErMessage = ERROR_MESSAGE(),@ErSeverity = ERROR_SEVERITY(),@ErState = ERROR_STATE()
		RAISERROR (@ErMessage,@ErSeverity,@ErState )

	END CATCH 
END
GO
