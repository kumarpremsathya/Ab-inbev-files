/****** Object:  StoredProcedure [dbo].[spGenerateAzureUsersDeltaReport]    Script Date: 4/7/2026 11:49:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

      
CREATE PROCEDURE [dbo].[spGenerateAzureUsersDeltaReport]      
AS      
BEGIN      
 BEGIN TRY      
  IF OBJECT_ID(N'dbo.tblAzureUsersReport', N'U') IS NOT NULL          
  BEGIN      
    declare @json_data varchar(max)      
    set @json_data = (SELECT TOP 1 AzEntraDelta FROM tblAzEntraDelta Order By UpdateTime Desc)      
    MERGE INTO [dbo].[tblAzureUsersReport] AS Target
      USING (
    SELECT        
        UserId,      
        DisplayName,      
        SamAccountName,    
        EmployeeId,    
        Email,      
        OfficeLocation,      
        Description,      
        CASE      
            WHEN [AccountEnabled] = 'true' THEN 'active'      
            WHEN [AccountEnabled] = 'false' THEN 'inactive'      
            ELSE NULL      
        END AS AccountEnabled,      
        JobTitle,      
        GroupType,      
        UserPrincipalName,      
        MailNickname,      
        City,      
        LastPasswordChangeDate,  
        UserType,     
        CreatedDate,      
        CompanyName,      
        MailEnabled,      
        (SELECT '["' + STRING_AGG(REPLACE([Owner],',',''),'","') + '"]'       
         FROM OPENJSON(Owners)      
         WITH ( Owner NVARCHAR(MAX) '$.mail')      
        ) AS Owners,  
        CASE    
            WHEN EmployeeId IS NOT NULL AND EmployeeId <> '<not set>' AND UserPrincipalName LIKE 'ALT%'    
                THEN 'AltAccount'
            WHEN UserPrincipalName LIKE 'BOT%' AND EmployeeId IS NULL
                THEN 'BotAccount'
            WHEN UserPrincipalName LIKE 'SRV%' OR UserPrincipalName LIKE 'Svc%'
                THEN 'ServiceAccount'
            ELSE AccountType    
        END AS AccountType,   
        Department,      
        ManagerName,      
        ManagerId,      
        ManagerEmail,      
        OnPremisesDomain,      
        AppId,      
        AppRoles,      
        LastSigninDate,      
        LastNonInteractiveSignin,      
        Tenant,
        ChangeType            
    FROM OPENJSON(@json_data)      
    WITH      
    (      
        UserId VARCHAR(500) '$.id',      
        DisplayName NVARCHAR(MAX) '$.display_name',      
        SamAccountName VARCHAR(500) '$.sam_account_name',    
        EmployeeId VARCHAR(500) '$.employee_id',    
        Email NVARCHAR(MAX) '$.mail',      
        OfficeLocation NVARCHAR(MAX) '$.office_location',      
        Description VARCHAR(500) '$.description',      
        AccountEnabled VARCHAR(500) '$.account_enabled',      
        JobTitle NVARCHAR(MAX) '$.job_title',      
        GroupType NVARCHAR(MAX) '$.group_types' AS JSON,      
        UserPrincipalName NVARCHAR(MAX) '$.principal_name',      
        MailNickname VARCHAR(500) '$.mail_nickname',      
        City NVARCHAR(MAX) '$.city',      
        LastPasswordChangeDate VARCHAR(500) '$.last_password_change_date_time',      
        UserType VARCHAR(500) '$.user_type',      
        CreatedDate VARCHAR(500) '$.created_date_time',      
        CompanyName NVARCHAR(MAX) '$.company_name',      
        MailEnabled VARCHAR(500) '$.mail_enabled',      
        Owners NVARCHAR(MAX) '$.owners' AS JSON,      
        AccountType VARCHAR(500) '$.account_type',      
        Department NVARCHAR(MAX) '$.department',      
        ManagerName NVARCHAR(MAX) '$.manager_name',      
        ManagerId VARCHAR(500) '$.manager_id',      
        ManagerEmail VARCHAR(500) '$.manager_email',      
        OnPremisesDomain VARCHAR(500) '$.on_premises_domain',      
        AppId VARCHAR(500) '$.app_id',      
        AppRoles NVARCHAR(MAX) '$.app_roles',      
        LastSigninDate VARCHAR(500) '$.last_signin_date',      
        LastNonInteractiveSignin VARCHAR(500) '$.last_non_interactive_signin_date',      
        Tenant VARCHAR(500) '$.tenant',
        ChangeType VARCHAR(500) '$.change_type'              
    )
) AS Source
ON Target.UserId = Source.UserId
WHEN NOT MATCHED BY TARGET AND Source.ChangeType = 'Created' THEN
    INSERT (
        UserId, DisplayName, SamAccountName, EmployeeId, Email, OfficeLocation, Description, AccountEnabled, 
        JobTitle, GroupType, UserPrincipalName, MailNickname, City, LastPasswordChangeDate, UserType, 
        CreatedDate, CompanyName, MailEnabled, Owners, AccountType, Department, ManagerName, ManagerId, 
        ManagerEmail, OnPremisesDomain, AppId, AppRoles, LastSigninDate, LastNonInteractiveSignin, Tenant
    )
    VALUES (
        Source.UserId, Source.DisplayName, Source.SamAccountName, Source.EmployeeId, Source.Email, 
        Source.OfficeLocation, Source.Description, Source.AccountEnabled, Source.JobTitle, Source.GroupType, 
        Source.UserPrincipalName, Source.MailNickname, Source.City, Source.LastPasswordChangeDate, 
        Source.UserType, Source.CreatedDate, Source.CompanyName, Source.MailEnabled, Source.Owners, 
        Source.AccountType, Source.Department, Source.ManagerName, Source.ManagerId, Source.ManagerEmail, 
        Source.OnPremisesDomain, Source.AppId, Source.AppRoles, Source.LastSigninDate, 
        Source.LastNonInteractiveSignin, Source.Tenant
    )
WHEN MATCHED AND Source.ChangeType = 'Deleted' THEN
      DELETE;
  END      
  BEGIN      
   DELETE FROM [dbo].[tblAzEntraDelta] WHERE UpdateTime < DATEADD(MINUTE, -15, GETDATE())      
  END      
 END TRY      
 BEGIN CATCH      
        SELECT        
            ERROR_NUMBER() AS ErrorNumber        
            ,ERROR_SEVERITY() AS ErrorSeverity        
            ,ERROR_STATE() AS ErrorState        
            ,ERROR_PROCEDURE() AS ErrorProcedure        
            ,ERROR_LINE() AS ErrorLine        
            ,ERROR_MESSAGE() AS ErrorMessage;        
    END CATCH      
END;

GO


