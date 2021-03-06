/****** Object:  StoredProcedure [dbo].[p_create_navori_playlist]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_create_navori_playlist]
GO
/****** Object:  StoredProcedure [dbo].[p_create_navori_playlist]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_create_navori_playlist]     @player_name			    varchar(50),
                                        @playlist_name              varchar(100),
                                        @playlist_duration          int,
                                        @media_list                 varchar(4000),
                                        @start_date                 datetime,
                                        @end_date                   datetime,
                                        @force_override             char(1),
					                    @return_information		    varchar(255) OUTPUT

as      

declare @r_code          int

begin distributed transaction

exec @r_code = [172.29.0.13].NavoriDataServerSQL.dbo.p_get_cinelight_screenings     @player_name,
                                                                                    @playlist_name,
                                                                                    @playlist_duration,
                                                                                    @media_list,
                                                                                    @start_date,
                                                                                    @end_date,
                                                                                    @force_override,
					                                                                @return_information OUTPUT

if @r_code = 0 
    commit transaction
else
    rollback transaction
                                                                                        
return @r_code
GO
