--How we are going to work on this data?
--1. First we break the things down by country, and answer the quite basic questions like:
--		-- What is the total number people, cases and deaths.
--2. Then we try to make some analysis by continent, and answer the similar questions there as well.







use Covid_Data;

-- Let's have a look on the table
SELECT * FROM Country;

-- The Column date is detected as datetime, which would consume more space, so let's convert it to Date datatype
-- And we have to change for all the Tables.
ALTER TABLE dbo.Country ALTER COLUMN date DATE;
ALTER TABLE dbo.Death ALTER COLUMN date DATE;
ALTER TABLE dbo.Test ALTER COLUMN date DATE;
ALTER TABLE dbo.Vaccination ALTER COLUMN date DATE;
ALTER TABLE dbo.Death ALTER COLUMN total_deaths int;

-- Now lets begin with the basic data analysis of the data, and ask few questions about the data.

-- 1. How many Countires are there in the data?
SELECT		DISTINCT location
FROM		Country	
ORDER BY	1;
-- The dataset have data from around 244 locations, but there are 195 countries in the world, so we have to analyze why it is like so.
-- And the reason why it matters to us because want to analyze the data and make analysis by country. Also in future it will make more sense while building Reports.
-- The reason that why there are 244 locations is that the location column also contains the continent wise data values in the location column, like Africa, North America, Europe.
-- Let's see how the values looks like for Europe, Asia only
SELECT * 
FROM	Country
WHERE	location IN ('Europe','Asia');

-- We can see that there is no information available in the continent column when the location column contains the continent. So that's the reason.
-- Now we have two options, either we should delete these columns or we should avoid using them from the next time whenever there is any analysis involved w.r.t Location.
-- Let's see how many countries will be there after using this condition
SELECT		DISTINCT  location
FROM		Country
WHERE		continent IS NOT NULL
ORDER BY	1;
-- The data is pretty much clear now, there are around 231 locations now, which is not exactly 195 because some territories of countries are shown as independet countries such as Hong Kong.


-- 2. What is population count of each country in each year? 
SELECT		YEAR(date) AS Year,
			location,
			AVG(population)	AS Popualtion	
FROM		Country
WHERE		continent IS NOT NULL
GROUP BY	YEAR(date),location
ORDER BY	1,2;

-- 3. What is the number of cases in each location?
SELECT		location,
			date,
			total_cases
FROM		Death
WHERE		continent IS NOT NULL
ORDER BY	2,1;


-- 4. What is the total number of deaths in each location?
SELECT		location,
			date,
			total_deaths
FROM		Death
WHERE		continent IS NOT NULL
ORDER BY	2,1;

-- 5. What is the ratio of death to the total number of cases?
SELECT		location,
			date,
			total_cases,
			total_deaths,
			ROUND((total_deaths/total_cases)*100,3) AS Death_Rate
FROM		Death
WHERE		continent IS NOT NULL
ORDER BY	2,1;

-- 6. What is the ratio of Cases to the population and ratio of death to the population?
SELECT		C.location,
			C.date,
			ROUND((D.total_cases/C.population)*100,5) AS Cases_Rate,
			ROUND((D.total_deaths/C.population)*100,9) AS Death_Rate
FROM		Country C JOIN Death D
ON			D.iso_code=C.iso_code AND D.date = C.date
WHERE		C.continent IS NOT NULL
ORDER BY	2,1;

-- The figures look very smaller and some of the values are NULL in the beginning which makes sense, 
-- because during the start the pandemic there were many countries which did not report any Covid cases,
-- and some were reporting fewer cases.


-- Now we are pretty much familiar with the dataset, now let's see how do the same figures looks like by month
-- 7. How do the ratio of death to the total number of cases looks like by each month, and what is the number of cases and deaths?
SELECT		EOMONTH(date) AS Month_end,
			location,
			total_cases,
			total_deaths,
			ROUND((total_deaths/total_cases)*100,3) AS Death_rate_by_month
FROM		Death
WHERE		continent IS NOT NULL
ORDER BY	1,2;

-- After looking at the result I found that there were multiple enteries made for each country on the same day, as we don't have time stamp so we can't fetch
-- the last entry made for a particular country. However, there is another way, we can see that the cases are growing after every successful entry, so we can 
-- take the maximum of that particular day.
SELECT		EOMONTH(date) AS Month_end,
			location,
			MAX(total_cases) AS total_cases,
			MAX(total_deaths) AS total_deaths,
			ROUND((MAX(total_deaths)/MAX(total_cases))*100,3) AS Death_rate
FROM		Death
WHERE		continent IS NOT NULL
GROUP BY	EOMONTH(date),location
ORDER BY	1,2;
	

-- 8. How do the monthly and weekly death growth rate (for the total number of cases) looks like for India, United States, and Brazil (because these were the countries that had the highest number of deaths)?

-- death_growth_rate, which is nothing but the difference in ratio of deaths reported in the current month and the previous month.
-- We will use CTE for achieving this, and SQL LAG() function to jump back to the previous month.
-- More about LAG() function here: https://www.sqlservertutorial.net/sql-server-window-functions/sql-server-lag-function/
-- As there are multiple countries are ther, so we should create a Stored Procedure in order to avoid writing the same Query for the different Country

-- Monthly Growth rate
EXEC get_monthly_death_growth_rate 'India';
EXEC get_monthly_death_growth_rate 'United States';
EXEC get_monthly_death_growth_rate 'Brazil';

-- Let's dig deeper and see how does the weekly trend looks like.
EXEC get_weekly_death_growth_rate 'India';
EXEC get_weekly_death_growth_rate 'United States';
EXEC get_weekly_death_growth_rate 'Brazil';

-- Cases Growth rate and death growth rate per 10k People.
EXEC get_weekly_cases_growth_rate_per_100k 'India';
EXEC get_weekly_cases_growth_rate_per_100k 'United States';
EXEC get_weekly_cases_growth_rate_per_100k 'Brazil';
-- This is not working properly and have some doubts let's clear it later.


-- 9. Which country had the highest percent of population infected in terms of its population size and which year it was?
SELECT		TOP 20												-- You can skip this Top 10 and can see the whole set of result
			YEAR(D.date) AS Year,
			D.location, MAX(C.population) AS Total_Population, 
			MAX(D.total_cases) AS Number_of_People_Infected, 
			ROUND(MAX((total_cases/population)*100),4) AS Percentage_of_Population_Infected
FROM		Death D JOIN Country C 
ON			D.datE = C.date AND D.iso_code = C.iso_code
WHERE		C.continent IS NOT NULL
GROUP BY	YEAR(D.date), D.location
ORDER BY	Percentage_of_Population_Infected DESC;
-- Faeroe islands had the highest percent of people affected with the virus with 65.5% of the total population in 2022.

-- 10. Which location had the highest percent of death rate ?
SELECT		TOP 20
			YEAR(D.date) AS Year,
			D.location, MAX(C.population) AS Total_Population, 
			MAX(D.total_deaths) AS Number_of_People_Died, 
			ROUND(MAX((total_deaths/population)*100),4) AS Percentage_of_Population_Died
FROM		Death D JOIN Country C 
ON			D.datE = C.date AND D.iso_code = C.iso_code
WHERE		C.continent IS NOT NULL
GROUP BY	YEAR(D.date), D.location
ORDER BY	Percentage_of_Population_Died DESC;

-- Peru reported the highest percent of deaths based upon it's population size, where 0.63% of the population wiped out by the Covid-19. 

---------------------------------------------------------------------------------------------------------
-- Let's see how the figures looks like by continent.

-- 11. Get the total number of cases and deaths in each continent by year?
SELECT		YEAR(date) AS Year,
			location,
			MAX(total_cases) AS Total_cases,
			MAX(total_deaths) AS Total_deaths
FROM		Death
WHERE		continent IS NULL					-- The reason why we are using NULL here is because we want to get the number of cases by continent this time.
GROUP BY	YEAR(date), location
ORDER BY	1,2;

-- 12. Get the highest number of cases by continent.
SELECT		location,
			MAX(total_cases) AS Total_cases
FROM		Death
WHERE		continent IS NULL					
GROUP BY	location
ORDER BY	2 Desc;
-- If we skip the first 2 lcoations, then the highest number of cases are reported in European countries till date followed by Asia and North America (if we consider the continent only).

-- 13. Get the highest number of death by continet.
SELECT		location,
			MAX(total_deaths) AS Total_Deaths
FROM		Death
WHERE		continent IS NULL					
GROUP BY	location
ORDER BY	2 Desc;
-- The highest number of deaths are also reported in the continent of Europe, however it is followed by North America not Asia, making North America the second continent with highest number of fatalities.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Analysis on Global Level

-- 14. Let's get the Total number of cases and deaths now globally by date.
SELECT		date AS Month_end,
			MAX(total_cases) as Cases,
			MAX(cast(total_deaths AS INT)) as Deaths,
			ROUND((MAX(total_deaths)/MAX(total_cases))*100,5) Death_rate
FROM		Death
WHERE		continent IS NOT NULL
GROUP BY	date
ORDER BY    1;

-- 15. Get the Total number of cases and deaths now globally by Month.
SELECT		EOMONTH(date) AS Month_end,
			MAX(total_cases) as Cases,
			MAX(total_deaths) as Deaths,
			ROUND((MAX(total_deaths)/MAX(total_cases))*100,5) Death_rate
FROM		Death
GROUP BY	EOMONTH(date)
ORDER BY	1;

-- 16. Get the Total number of cases and deaths now globally.
SELECTMAX(total_cases) as Cases,
			MAX(total_deaths) as Deaths,
			ROUND((MAX(total_deaths)/MAX(total_cases))*100,5) Death_rate
FROM		Death
ORDER BY	1;

SELECT * FROM Death;
 
select distinct location from Country order by 1;