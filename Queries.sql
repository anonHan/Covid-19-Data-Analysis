--How we are going to work on this data?
--1. First we break the things down by country, and answer the quite basic questions like:
--		-- What is the total number people, cases and deaths.
--2. Then we try to make some analysis by continent, and answer the similar questions there as well.
--3. After that we try to anakyze that how many tests are conducted by each country, how many people were vaccincated, what is the percentage of vaccinated people in each countrym, etc.







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


-- 4. What is the total number of deaths at each location?
SELECT		location,
			date,
			total_deaths
FROM		Death
WHERE		continent IS NOT NULL
ORDER BY	2,1;

select year(date), location,max(population) from country group by location,year(date) order by 2,1;

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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
-- Analysis at Global Level

-- 14. Let's get the Total number of cases and deaths globally by date.
SELECT		date AS Month_end,
			MAX(total_cases) as Cases,
			MAX(cast(total_deaths AS INT)) as Deaths,
			ROUND((MAX(total_deaths)/MAX(total_cases))*100,5) Death_rate
FROM		Death
WHERE		continent IS NOT NULL
GROUP BY	date
ORDER BY    1;

-- 15. Get the Total number of cases and deaths globally by Month.
SELECT		EOMONTH(date) AS Month_end,
			MAX(total_cases) as Cases,
			MAX(total_deaths) as Deaths,
			ROUND((MAX(total_deaths)/MAX(total_cases))*100,5) Death_rate
FROM		Death
GROUP BY	EOMONTH(date)
ORDER BY	1;

-- 16. Get the Total number of cases and deaths globally.
SELECT		MAX(total_cases) as Cases,
			MAX(total_deaths) as Deaths,
			ROUND((MAX(total_deaths)/MAX(total_cases))*100,5) Death_rate
FROM		Death
ORDER BY	1;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Now we try to analyze the Test and Vaccinated tables.

-- If we look at the columns of the Test table, the total_tests, new_tests, total_tests_per_thousand, etc are of type nvarchar, that we don't want, because it will create 
-- issues for us while analyzing the data. So, we should change its data type to int and float.
ALTER TABLE Test ALTER COLUMN total_tests BIGINT;
ALTER TABLE Test ALTER COLUMN new_tests BIGINT;
ALTER TABLE Test ALTER COLUMN total_tests_per_thousand FLOAT;
ALTER TABLE Test ALTER COLUMN new_tests_per_thousand FLOAT;
ALTER TABLE Test ALTER COLUMN new_tests_smoothed INT;
ALTER TABLE Test ALTER COLUMN new_tests_smoothed_per_thousand FLOAT;
ALTER TABLE Test ALTER COLUMN positive_rate FLOAT;
ALTER TABLE Test ALTER COLUMN tests_per_case FLOAT;

-- The same case is in vaccinated table so let's try to convert  its columns as well, but I am only going to convert that seem useful to me now, rest of them we can 
-- convert on the fly.
ALTER TABLE Vaccination ALTER COLUMN total_vaccinations BIGINT;
ALTER TABLE Vaccination ALTER COLUMN people_vaccinated BIGINT;
ALTER TABLE Vaccination ALTER COLUMN people_fully_vaccinated BIGINT;
ALTER TABLE Vaccination ALTER COLUMN total_boosters BIGINT;
ALTER TABLE Vaccination ALTER COLUMN new_vaccinations BIGINT;


-- 17. What is total number of tests conducted by each country?
SELECT		location,
			max(total_tests) AS Total_tests
FROM		Test
WHERE		continent IS NOT NULL
GROUP BY	location
ORDER BY	2 DESC;

select * from test where location = 'india' order by date;
-- China, US and India are the top three countries with the highest number of tests that were conducted, whereas there are some locations for which the data is not available.

-- 18. What is the total number of people who are vaccinated by each country?
SELECT		location,
			MAX(people_vaccinated) AS people_vaccinated,
			MAX(people_fully_vaccinated) AS fully_vaccinated
FROM		Vaccination
WHERE		continent IS NOT NULL
GROUP BY	location
ORDER BY	2 DESC;
-- Again China, India and US are on the top in terms of the number of people who are vaccinated by these countries, which is justifiable, because these three are the 
-- countries that hold the large volume of population.

-- Now let's see that what is proportion of population is being injected with anti-infection doses.
-- 19. What percent of masses vaccinated by each country?
SELECT		V.location,
			MAx(population) as total_population,
			ROUND((SUM(V.new_vaccinations)/MAX(C.population))*100,4) AS percentage_of_people_vaccinated,
			ROUND((MAX(V.people_fully_vaccinated)/MAX(C.population))*100,4) AS percentage_of_people_fully_vaccinated
FROM		Vaccination V JOIN Country C
ON			C.iso_code = V.iso_code AND C.date = V.date
WHERE		V.continent IS NOT NULL
GROUP BY	V.location
ORDER BY	3 DESC;
-- We can observe that Gibraltar(an overseas territory of UK and a very small territory), United Arab Emirates, Samoa, Tonga, and Pitcairn have vaccinated 100% 
-- of their population, and there could be two reasons behind that first and foremost is their size of population is quite small and another could be that they
-- are economically strong countries, that can afford to vaccinate their whole population such as UAE. 

-- 20. Get the number of vaccination done over time for India.
SELECT		V.date,	
			V.location,
			SUM(V.new_vaccinations) OVER(PARTITION BY location order by date) AS Vaccinations_given
FROM		Vaccination V
WHERE		V.continent IS NOT NULL AND location='India'
ORDER BY	1 ASC;
-- OR 
-- But the belowe query return the NULL when there are no data for vaccination.
SELECT		V.date,	
			V.location,
			people_vaccinated AS Vaccinations_given
FROM		Vaccination V
WHERE		V.continent IS NOT NULL AND location='India'
ORDER BY	1 ASC;



select * from test;
SELECT * FROM Vaccination ORDER BY date;

-- positive rate
-- Get the highest positive rate of each country.
SELECT		location,
			MAX(positive_rate) AS positive_rate
FROM		Test
WHERE		continent IS NOT NULL
GROUP BY	location
HAVING		MAX(positive_rate) IS NOT NULL
ORDER BY	2 DESC;
-- As we can see that Curacao had the highest positive_rate, so let's dig deeper and see that how much people are there and what year it was.

-- Get the positive_rate, population, date and location and order it by positive_rate in descending order. Analyse the 
SELECT		C.date,
			C.location,
			C.population,
			MAX(positive_rate) AS positive_rate
FROM		Test T JOIN Country C 
ON			C.location = T.location AND C.date = T.date
WHERE		C.continent IS NOT NULL
GROUP BY	C.location, C.date, C.population
HAVING		MAX(positive_rate) IS NOT NULL
ORDER BY	4 DESC;


-- Let's finish here for now, we have made quite good analysis. What we may want now is to go to Power BI Desktop or Tableau Public and start building report and dashboard.
-- I am going to use Power BI desktop in my case. We have two options in Power BI desktop, either we can Import the data directly or we can use DirectQuery.
-- When the data is connected by Import mode we can use Q&A feature of Power BI, which is not possible for DirectQuery and DirectQuery is recommended when the dataset contains
-- millions of rows and is of huge size. However, this dataset is under 50 mb, so we can use Import mode. Additionally, we are going to do a lot of data cleaning in Power BI as
-- well which will decrease the size of the data model as well.
-- Another thing that I want to highlight is that Power BI DirectQuery mode also allows use of SQL queries, which means we can use the SQL query to fetch the data from the database.
-- We may use all the predefined queries from here in Power BI, but we are going to use the same metrics in Power BI desktop as well under import mode and we will see the 
-- facts and figures graphically.
-- GOOD LUCK!


