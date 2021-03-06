/****** Object:  View [dbo].[v_cag_active_policy_details]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_cag_active_policy_details]
GO
/****** Object:  View [dbo].[v_cag_active_policy_details]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create VIEW [dbo].[v_cag_active_policy_details]
AS
  SELECT   cap.complex_id 'complex_id',
           ca.agreement_type 'agreement_type',
            (select sum(fixed_amount) 
             from   cinema_agreement_policy
             where  complex_id = cap.complex_id
             and    policy_status_code in ('A', 'N')
             and    revenue_source = 'P'
             and    processing_start_date <= getdate()
             and    isnull(processing_end_date,'1-jan-2050') >= getdate()
             group by complex_id) 'fixed_amount',
             
            (select max(percentage_entitlement) 
             from   cinema_agreement_policy
             where  complex_id = cap.complex_id
             and    policy_status_code in ('A', 'N')
             and    revenue_source = 'F'
             and    processing_start_date <= getdate()
             and    isnull(processing_end_date,'1-jan-2050') >= getdate()
             group by complex_id) 'percentage_entitlement'
    FROM cinema_agreement ca,   
         cinema_agreement_policy  cap
   WHERE cap.cinema_agreement_id = ca.cinema_agreement_id and
         ca.agreement_status = 'A' and
         cap.policy_status_code in ('A', 'N') and
         cap.processing_start_date <= getdate() and
         isnull(cap.processing_end_date,'1-jan-2050') >= getdate()
  group by  cap.complex_id,ca.agreement_type
GO
