USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_consecutivenumbers]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_consecutivenumbers]
(   
    @start int,
    @end  int
) RETURNS TABLE 
RETURN 

select
    x268435456.X
    | x16777216.X
    | x1048576.X
    | x65536.X
    | x4096.X
    | x256.X
    | x16.X
    | x1.X
    + @start
     X
from
(VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15)) as x1(X)
join
(VALUES (0),(16),(32),(48),(64),(80),(96),(112),(128),(144),(160),(176),(192),(208),(224),(240)) as x16(X)
on x1.X <= @end-@start and x16.X <= @end-@start
join
(VALUES (0),(256),(512),(768),(1024),(1280),(1536),(1792),(2048),(2304),(2560),(2816),(3072),(3328),(3584),(3840)) as x256(X)
on x256.X <= @end-@start
join
(VALUES (0),(4096),(8192),(12288),(16384),(20480),(24576),(28672),(32768),(36864),(40960),(45056),(49152),(53248),(57344),(61440)) as x4096(X)
on x4096.X <= @end-@start
join
(VALUES (0),(65536),(131072),(196608),(262144),(327680),(393216),(458752),(524288),(589824),(655360),(720896),(786432),(851968),(917504),(983040)) as x65536(X)
on x65536.X <= @end-@start
join
(VALUES (0),(1048576),(2097152),(3145728),(4194304),(5242880),(6291456),(7340032),(8388608),(9437184),(10485760),(11534336),(12582912),(13631488),(14680064),(15728640)) as x1048576(X)
on x1048576.X <= @end-@start
join
(VALUES (0),(16777216),(33554432),(50331648),(67108864),(83886080),(100663296),(117440512),(134217728),(150994944),(167772160),(184549376),(201326592),(218103808),(234881024),(251658240)) as x16777216(X)
on x16777216.X <= @end-@start
join
(VALUES (0),(268435456),(536870912),(805306368),(1073741824),(1342177280),(1610612736),(1879048192)) as x268435456(X)
on x268435456.X <= @end-@start
WHERE @end >=
    x268435456.X
    | isnull(x16777216.X, 0)
    | isnull(x1048576.X, 0)
    | isnull(x65536.X, 0)
    | isnull(x4096.X, 0)
    | isnull(x256.X, 0)
    | isnull(x16.X, 0)
    | isnull(x1.X, 0)
    + @start

GO
