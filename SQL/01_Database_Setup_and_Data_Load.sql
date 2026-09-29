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



-- ============================================================
-- NHS Diagnostic Waiting List Analysis
-- File: 02_Staging_and_Profiling.sql
-- Purpose: Profile and understand the staging dataset
-- ============================================================

USE NHS_Diagnostic;
GO

-- 1. Check reporting period and row distribution
SELECT
    Period,
    COUNT(*) AS Period_Count
FROM Diagnostic_Staging
GROUP BY Period
ORDER BY Period;
GO

-- 2. Count distinct providers and commissioners
SELECT
    COUNT(DISTINCT Provider_Org_Code) AS Distinct_Providers,
    COUNT(DISTINCT Commissioner_Org_Code) AS Distinct_Commissioners
FROM Diagnostic_Staging;
GO

-- 3. Check diagnostic test distribution
SELECT
    Diagnostic_Tests,
    COUNT(*) AS Test_Count
FROM Diagnostic_Staging
GROUP BY Diagnostic_Tests
ORDER BY Test_Count DESC;
GO

-- 4. Review distinct commissioner names
SELECT DISTINCT
    Commissioner_Org_Name
FROM Diagnostic_Staging
ORDER BY Commissioner_Org_Name;
GO

-- 5. Check overall numeric ranges
SELECT
    MIN(_00_01_Week) AS Min_00_01,
    MAX(_00_01_Week) AS Max_00_01,
    MIN(_13_Weeks) AS Min_13Plus,
    MAX(_13_Weeks) AS Max_13Plus,
    MIN(Total_WL) AS Min_Total_WL,
    MAX(Total_WL) AS Max_Total_WL,
    MIN(Total_Activity) AS Min_Total_Activity,
    MAX(Total_Activity) AS Max_Total_Activity
FROM Diagnostic_Staging;
GO



-- ============================================================
-- NHS Diagnostic Waiting List Analysis
-- File: 03_Data_Preparation.sql
-- Purpose: Create the analytical dataset from staging data
-- ============================================================

USE NHS_Diagnostic;
GO

-- 1. Create the analytical table from the staging table
SELECT *
INTO Diagnostic_Clean
FROM Diagnostic_Staging;
GO
    
-- 2. Verify the analytical table was created
SELECT COUNT(*) AS CleanRows
FROM Diagnostic_Clean;
GO



-- ============================================================
-- NHS Diagnostic Waiting List Analysis
-- File: 04_Final_Data_Validation.sql
-- Purpose: Validate data quality before analysis
-- ============================================================

USE NHS_Diagnostic;
GO

-- 1. Check provider records with missing parent organisation
SELECT
    Provider_Org_Code,
    Provider_Org_Name,
    Provider_Parent_Org_Code,
    Provider_Parent_Name,
    COUNT(*) AS Row_Count
FROM Diagnostic_Clean
WHERE Provider_Parent_Org_Code IS NULL
   OR Provider_Parent_Name IS NULL
GROUP BY
    Provider_Org_Code,
    Provider_Org_Name,
    Provider_Parent_Org_Code,
    Provider_Parent_Name
ORDER BY Row_Count DESC;
GO

-- 2. Investigate a specific provider with missing parent data
SELECT
    Provider_Org_Code,
    Provider_Org_Name,
    Provider_Parent_Org_Code,
    Provider_Parent_Name,
    COUNT(*) AS Row_Count
FROM Diagnostic_Clean
WHERE Provider_Org_Code = 'RYV'
GROUP BY
    Provider_Org_Code,
    Provider_Org_Name,
    Provider_Parent_Org_Code,
    Provider_Parent_Name
ORDER BY Row_Count DESC;
GO

-- 3. Check commissioners with missing parent organisation data
SELECT
    Commissioner_Org_Code,
    Commissioner_Org_Name,
    Commissioner_Parent_Org_Code,
    Commissioner_Parent_Name,
    COUNT(*) AS Row_Count
FROM Diagnostic_Clean
WHERE Commissioner_Parent_Org_Code IS NULL
   OR Commissioner_Parent_Name IS NULL
GROUP BY
    Commissioner_Org_Code,
    Commissioner_Org_Name,
    Commissioner_Parent_Org_Code,
    Commissioner_Parent_Name
ORDER BY Row_Count DESC;
GO

-- 4. Investigate specific commissioner codes
SELECT
    Commissioner_Org_Code,
    Commissioner_Org_Name,
    Commissioner_Parent_Org_Code,
    Commissioner_Parent_Name,
    COUNT(*) AS Row_Count
FROM Diagnostic_Clean
WHERE Commissioner_Org_Code IN ('NONC', 'D4U1Y')
GROUP BY
    Commissioner_Org_Code,
    Commissioner_Org_Name,
    Commissioner_Parent_Org_Code,
    Commissioner_Parent_Name
ORDER BY Row_Count DESC;
GO

-- 5. Check for leading/trailing whitespace
SELECT COUNT(*) AS RowsWithWhitespace
FROM Diagnostic_Clean
WHERE
    Period <> LTRIM(RTRIM(Period))
    OR Provider_Parent_Org_Code <> LTRIM(RTRIM(Provider_Parent_Org_Code))
    OR Provider_Parent_Name <> LTRIM(RTRIM(Provider_Parent_Name))
    OR Provider_Org_Code <> LTRIM(RTRIM(Provider_Org_Code))
    OR Provider_Org_Name <> LTRIM(RTRIM(Provider_Org_Name))
    OR Commissioner_Parent_Org_Code <> LTRIM(RTRIM(Commissioner_Parent_Org_Code))
    OR Commissioner_Parent_Name <> LTRIM(RTRIM(Commissioner_Parent_Name))
    OR Commissioner_Org_Code <> LTRIM(RTRIM(Commissioner_Org_Code))
    OR Commissioner_Org_Name <> LTRIM(RTRIM(Commissioner_Org_Name))
    OR Diagnostic_Tests <> LTRIM(RTRIM(Diagnostic_Tests));
GO

-- 6. Check for negative values
SELECT COUNT(*) AS NegativeValueRows
FROM Diagnostic_Clean
WHERE
    _00_01_Week < 0
    OR _01_02_Weeks < 0
    OR _02_03_Weeks < 0
    OR _03_04_Weeks < 0
    OR _04_05_Weeks < 0
    OR _05_06_Weeks < 0
    OR _06_07_Weeks < 0
    OR _07_08_Weeks < 0
    OR _08_09_Weeks < 0
    OR _09_10_Weeks < 0
    OR _10_11_Weeks < 0
    OR _11_12_Weeks < 0
    OR _12_13_Weeks < 0
    OR _13_Weeks < 0
    OR Total_WL < 0
    OR Waiting_List_Activity < 0
    OR Planned_Activity < 0
    OR Unscheduled_Activity < 0
    OR Total_Activity < 0;
GO

    -- 7. Check for duplicate record combinations
SELECT
    Period,
    Provider_Org_Code,
    Commissioner_Org_Code,
    Diagnostic_Tests,
    COUNT(*) AS Record_Count
FROM Diagnostic_Clean
GROUP BY
    Period,
    Provider_Org_Code,
    Commissioner_Org_Code,
    Diagnostic_Tests
HAVING COUNT(*) > 1
ORDER BY Record_Count DESC;
GO
    
-- 8. Final row count
SELECT COUNT(*) AS Final_Row_Count
FROM Diagnostic_Clean;
GO

-- 9. Check completeness of key analytical fields
SELECT
    COUNT(*) AS Total_Rows,
    COUNT(Diagnostic_Tests) AS Diagnostic_Tests_NonNull,
    COUNT(Total_WL) AS Total_WL_NonNull,
    COUNT(Total_Activity) AS Total_Activity_NonNull,
    COUNT(_13_Weeks) AS Week_13Plus_NonNull
FROM Diagnostic_Clean;
GO

-- 10. Check numeric ranges in final dataset
SELECT
    MIN(Total_WL) AS Min_Total_WL,
    MAX(Total_WL) AS Max_Total_WL,
    MIN(Total_Activity) AS Min_Total_Activity,
    MAX(Total_Activity) AS Max_Total_Activity
FROM Diagnostic_Clean;
GO



-- ============================================================
-- NHS Diagnostic Waiting List Analysis
-- File: 05_EDA_Analysis.sql
-- Purpose: Answer business questions using the validated data
-- ============================================================

USE NHS_Diagnostic;
GO

-- Q1. What is the overall size and structure of the dataset?
SELECT
    COUNT(*) AS Total_Records,
    COUNT(DISTINCT Diagnostic_Tests) AS Diagnostic_Test_Types,
    COUNT(DISTINCT Provider_Org_Code) AS Providers,
    COUNT(DISTINCT Commissioner_Org_Code) AS Commissioners,
    SUM(Total_WL) AS Total_Waiting_List,
    SUM(Total_Activity) AS Total_Activity
FROM Diagnostic_Clean
WHERE Diagnostic_Tests <> 'TOTAL';
GO

-- Q2. Which diagnostic tests have the highest 
--     total waiting-list volumes?
SELECT
    Diagnostic_Tests,
    SUM(Total_WL) AS Total_Waiting_List
FROM Diagnostic_Clean
WHERE Diagnostic_Tests <> 'TOTAL'
GROUP BY Diagnostic_Tests
ORDER BY Total_Waiting_List DESC;
GO

-- Q3. Which 10 providers have the largest waiting lists?
SELECT TOP 10
    Provider_Org_Code,
    Provider_Org_Name,
    SUM(Total_WL) AS Total_Waiting_List
FROM Diagnostic_Clean
WHERE Diagnostic_Tests <> 'TOTAL'
GROUP BY
    Provider_Org_Code,
    Provider_Org_Name
ORDER BY Total_Waiting_List DESC;
GO

-- Q4. How large is the 13+ week waiting problem overall?
SELECT
    SUM(_13_Weeks) AS Waiting_13Plus_Weeks,
    SUM(Total_WL) AS Total_Waiting_List,
    CAST(
        100.0 * SUM(_13_Weeks) / NULLIF(SUM(Total_WL), 0)
        AS DECIMAL(10,2)
    ) AS Pct_13Plus_Weeks
FROM Diagnostic_Clean
WHERE Diagnostic_Tests <> 'TOTAL';
GO

-- Q5. Which diagnostic tests contribute the largest number
--     of 13+ week waits?
SELECT
    Diagnostic_Tests,
    SUM(_13_Weeks) AS Waiting_13Plus_Weeks
FROM Diagnostic_Clean
WHERE Diagnostic_Tests <> 'TOTAL'
GROUP BY Diagnostic_Tests
ORDER BY Waiting_13Plus_Weeks DESC;
GO

-- Q6. Which diagnostic tests have the highest proportion
--     of their waiting list at 13+ weeks?
SELECT
    Diagnostic_Tests,
    SUM(_13_Weeks) AS Waiting_13Plus_Weeks,
    SUM(Total_WL) AS Total_Waiting_List,
    CAST(
        100.0 * SUM(_13_Weeks) / NULLIF(SUM(Total_WL), 0)
        AS DECIMAL(10,2)
    ) AS Pct_13Plus_Weeks
FROM Diagnostic_Clean
WHERE Diagnostic_Tests <> 'TOTAL'
GROUP BY Diagnostic_Tests
ORDER BY Pct_13Plus_Weeks DESC;
GO

-- Q7. Among providers, how does waiting-list volume
--     compare with activity?
SELECT TOP 10
    Provider_Org_Code,
    Provider_Org_Name,
    SUM(Total_WL) AS Total_Waiting_List,
    SUM(Total_Activity) AS Total_Activity
FROM Diagnostic_Clean
WHERE Diagnostic_Tests <> 'TOTAL'
GROUP BY
    Provider_Org_Code,
    Provider_Org_Name
ORDER BY Total_Waiting_List DESC;
GO

-- Q8. Which providers have the highest
--     waiting-to-activity ratios?
SELECT TOP 10
    Provider_Org_Code,
    Provider_Org_Name,
    SUM(Total_WL) AS Total_Waiting_List,
    SUM(Total_Activity) AS Total_Activity,
    CAST(
        1.0 * SUM(Total_WL) / NULLIF(SUM(Total_Activity), 0)
        AS DECIMAL(10,2)
    ) AS Waiting_to_Activity_Ratio
FROM Diagnostic_Clean
WHERE Diagnostic_Tests <> 'TOTAL'
GROUP BY
    Provider_Org_Code,
    Provider_Org_Name
HAVING SUM(Total_Activity) > 0
ORDER BY Waiting_to_Activity_Ratio DESC;
GO

-- Q9. Which providers have the highest proportion
--     of their waiting list at 13+ weeks?
SELECT TOP 10
    Provider_Org_Code,
    Provider_Org_Name,
    SUM(_13_Weeks) AS Waiting_13Plus_Weeks,
    SUM(Total_WL) AS Total_Waiting_List,
    CAST(
        100.0 * SUM(_13_Weeks) / NULLIF(SUM(Total_WL), 0)
        AS DECIMAL(10,2)
    ) AS Pct_13Plus_Weeks
FROM Diagnostic_Clean
WHERE Diagnostic_Tests <> 'TOTAL'
GROUP BY
    Provider_Org_Code,
    Provider_Org_Name
HAVING SUM(Total_WL) > 0
ORDER BY Pct_13Plus_Weeks DESC;
GO
