-- ============================================================
-- NHS Diagnostic Waiting List Analysis
-- File: 01_Database_Setup_and_Data_Load.sql
-- Purpose: Create the staging table and load the source CSV
-- ============================================================

USE NHS_Diagnostic;
GO
-- 1. Create staging table
CREATE TABLE Diagnostic_Staging
(
    Period NVARCHAR(40),

    Provider_Parent_Org_Code NVARCHAR(40),
    Provider_Parent_Name NVARCHAR(510),
    Provider_Org_Code NVARCHAR(40),
    Provider_Org_Name NVARCHAR(510),

    Commissioner_Parent_Org_Code NVARCHAR(40),
    Commissioner_Parent_Name NVARCHAR(510),
    Commissioner_Org_Code NVARCHAR(40),
    Commissioner_Org_Name NVARCHAR(510),

    Diagnostic_Tests_Sort_Order INT,
    Diagnostic_Tests NVARCHAR(510),

    _00_01_Week INT,
    _01_02_Weeks INT,
    _02_03_Weeks INT,
    _03_04_Weeks INT,
    _04_05_Weeks INT,
    _05_06_Weeks INT,
    _06_07_Weeks INT,
    _07_08_Weeks INT,
    _08_09_Weeks INT,
    _09_10_Weeks INT,
    _10_11_Weeks INT,
    _11_12_Weeks INT,
    _12_13_Weeks INT,
    _13_Weeks INT,

    Total_WL INT,
    Waiting_List_Activity INT,
    Planned_Activity INT,
    Unscheduled_Activity INT,
    Total_Activity INT
);
GO

-- 2. Load source CSV into staging table
BULK INSERT Diagnostic_Staging
FROM 'C:\Documents\D.A\SQL_Projects\DM01-MAY-2026-full-extract.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    CODEPAGE = '65001'
);
GO

  -- 3. Verify the data load
SELECT COUNT(*) AS TotalRows
FROM Diagnostic_Staging;
GO

SELECT TOP 5 *
FROM Diagnostic_Staging;
GO
