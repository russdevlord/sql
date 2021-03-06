/****** Object:  View [dbo].[v_mgt_revision_transactions]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_mgt_revision_transactions]
GO
/****** Object:  View [dbo].[v_mgt_revision_transactions]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_mgt_revision_transactions]
as

select  revision_tran_id,
        revision_id,
        revision_transaction_type,
        billing_date,
        revenue_period,
        delta_date,
        [value],
        cost,
        units,
        makegood,
        revenue,
        'O' as report_type
from    outpost_revision_transaction

union all

select revision_tran_id,
        revision_id,
        revision_transaction_type,
        billing_date,
        revenue_period,
        delta_date,
        [value],
        cost,
        units,
        makegood,
        revenue,
        'C' as report_type 
from    revision_transaction
GO
