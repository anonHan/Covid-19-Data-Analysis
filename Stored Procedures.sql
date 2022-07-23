
-- Procedure to get the monthly growth rate of deaths against the total number of cases
CREATE PROCEDURE get_monthly_death_growth_rate @loc nvarchar(20)
AS
BEGIN
WITH A AS(
		SELECT		EOMONTH(date) AS Month_end,
					location,								-- we can avoid adding the location if we want
					MAX(total_cases) AS total_cases,
					MAX(total_deaths) AS total_deaths,
					ROUND((MAX(total_deaths)/MAX(total_cases))*100,6) AS Death_rate_by_month
		FROM		Death
		WHERE		location = @loc
		GROUP BY	EOMONTH(date),location
		)
		SELECT		Month_end,
					location,
					total_cases,
					total_deaths,
					Death_rate_by_month,
					CASE 
						WHEN (LAG(Death_rate_by_month,1) OVER (ORDER BY Month_end,location)) IS NULL THEN NULL
					ELSE
						ROUND(Death_rate_by_month - (LAG(Death_rate_by_month,1) OVER (ORDER BY Month_end)),6)
					END AS death_growth_rate
		FROM		A
		ORDER BY	1,2
END;

-- Procedure to get the weekly death growth rate against the total number of cases.
-- To get the week date, I am using the combination of date functions, from the link mentioned below. All the credits goes to author
-- https://www.c-sharpcorner.com/blogs/get-week-start-date-week-end-date-using-sql-server
Go
CREATE PROCEDURE get_weekly_death_growth_rate @loc nvarchar(20)
AS
BEGIN
WITH A AS(
		SELECT		DATEADD(DAY, 2 - DATEPART(WEEKDAY, date),date) AS week_start,
					location,
					MAX(total_cases) AS total_cases,
					MAX(total_deaths) AS total_deaths,
					ROUND((MAX(total_deaths)/MAX(total_cases))*100,6) AS Death_rate_by_week
		FROM		Death
		WHERE		location = @loc
		GROUP BY	DATEADD(DAY, 2 - DATEPART(WEEKDAY, date),date),location
		)
		SELECT		week_start,
					location,				-- we can avoid adding the location if we want
					total_cases,
					total_deaths,
					Death_rate_by_week,
					CASE 
						WHEN (LAG(Death_rate_by_week,1) OVER (ORDER BY week_start,location)) IS NULL THEN NULL
					ELSE
						ROUND(Death_rate_by_week - (LAG(Death_rate_by_week,1) OVER (ORDER BY week_start)),6)
					END AS death_growth_rate
		FROM		A
		ORDER BY	1,2
END;

-- Procedure to get the weekly growth rate in the number of cases for per 10000 people
Go
CREATE PROCEDURE get_weekly_cases_growth_rate_per_100k @loc nvarchar(20)
AS
BEGIN
WITH A AS(
		SELECT		DATEADD(DAY, 2 - DATEPART(WEEKDAY, date),date) AS week_start,
					location,
					MAX(total_cases) AS total_cases,
					MAX(total_deaths) AS total_deaths,
					(MAX(total_deaths)/100000) AS Death_rate_by_week,
					ROUND((MAX(total_cases)/100000),6) AS Cases_rate_by_week
		FROM		Death
		WHERE		location = @loc
		GROUP BY	DATEADD(DAY, 2 - DATEPART(WEEKDAY, date),date),location
		)
		SELECT		week_start,
					location,				-- we can avoid adding the location if we want
					total_cases,
					total_deaths,
					Cases_rate_by_week,
					Death_rate_by_week,
					CASE 
						WHEN (LAG(Cases_rate_by_week,1) OVER (ORDER BY week_start,location)) IS NULL THEN NULL
					ELSE
						ROUND(Cases_rate_by_week - (LAG(Cases_rate_by_week,1) OVER (ORDER BY week_start)),6)
					END AS cases_growth_rate,
					CASE 
						WHEN (LAG(Death_rate_by_week,1) OVER (ORDER BY week_start,location)) IS NULL THEN NULL
					ELSE
						ROUND(Death_rate_by_week - (LAG(Death_rate_by_week,1) OVER (ORDER BY week_start)),6)
					END AS death_growth_rate
		FROM		A
		ORDER BY	1,2
END;




USE Covid_Data;

drop proc get_weekly_cases_growth_rate_per_100k;
