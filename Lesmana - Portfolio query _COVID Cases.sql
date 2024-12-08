/*

Hi! I am,
	Name: Lesmana Adhe Wijaya
	Age : 22 Years old
I am a fresh graduate student majoring in International Relations studies in UIN Syarif Hidayatullah Jakarta.
Currently, I am developing a skillset related to data analysis in which I have already managed to learn Excel, SQL, and Tableau. 

*/

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------ABOUT THE PROJECT-------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

/*

Project name	:	COVID-19 Cases
Source			:	COVID-19 data by Our World in Data (https://catalog.ourworldindata.org/garden/covid/latest/compact/compact.csv)
Excel Source	:	https://drive.google.com/drive/folders/1xQucvhMOk8HYvmVAi4wIChMxAlGeDyA7?usp=sharing

This is a COVID-19 Cases data exploration project. The data source is downloaded and labeled as 'compact' data by Our World in Data because it has a complete set
of COVID-19 cases report. The data then got cleared up in Excel into a proper table by deleting unwanted columns and replacing non-usable value.
For the usability in the SQL, the table is splitted into two tables, that is
				Table1 = Covid_Portfolio.dbo.Covid_Death
				Table2 = Covid_Portfolio.dbo.Covid_Vaccination
After querying, some query results the transfered into Excel to get cleared up before it's imported into Tableau (public).

Query result (Excel)	: https://drive.google.com/drive/folders/1Te29nHmlvCPiBWWWfQPcHhhpqgFJjh76?usp=sharing
Tableau Visualization	: https://public.tableau.com/views/Lesmana-Portfolio_COVIDCases/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

*/

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------DATA EXPLORATION--------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------


SELECT country, date, population, new_cases, new_deaths
FROM Covid_Portfolio..Covid_Death
--WHERE date = '2020-10-01';

SELECT country, date, new_tests, new_vaccinations
FROM Covid_Portfolio..Covid_Vaccination;


SELECT Dea.country, Dea.date, Dea.population, Dea.new_cases, Dea.new_deaths, Vax.new_tests, Vax.new_vaccinations 
FROM Covid_Portfolio..Covid_Death AS Dea
INNER JOIN Covid_Portfolio..Covid_Vaccination AS Vax
	ON Dea.country = Vax.country AND Vax.date = Dea.date;

-- replace 0 value to NULL value

UPDATE Covid_Portfolio..Covid_Death
SET new_cases = NULL, new_deaths = NULL, total_cases = NULL, total_deaths = NULL
WHERE new_cases = 0 OR new_deaths = 0 OR total_cases = 0 OR total_deaths = 0;

SELECT *
FROM Covid_Portfolio..Covid_Vaccination
ORDER BY 1, 2;


SELECT country, SUM (new_cases) AS Total_Case
FROM Covid_Portfolio..Covid_Death
GROUP BY country
ORDER BY Total_Case DESC;


---------------------------------------Cases and deaths--------------------------------------------------------------------------------------------------------

				---- Death per cases percentage ----

SELECT	Dea.country, Dea.date, Dea.population, Dea.total_deaths, Dea.total_cases,
		(Dea.total_deaths/Dea.total_cases)*100 AS Mortality_Rate
FROM Covid_Portfolio..Covid_Death AS Dea
ORDER BY 1, 2;

SELECT	MAX (population) AS Total_Population, 
		MAX (total_cases) AS Total_Cases, 
		MAX (total_deaths) AS Total_Deaths,
		(MAX (total_deaths)/ MAX (total_cases))*100 AS Mortality_Rate
FROM Covid_Portfolio..Covid_Death


				---- Cases vs population by country ----

SELECT	Dea.country, Dea.date, Dea.population, Dea.total_cases,
		(Dea.total_cases/Dea.population) * 100 AS Case_Per_Population
FROM Covid_Portfolio..Covid_Death AS Dea
INNER JOIN Covid_Portfolio..Covid_Vaccination AS Vax
	ON Dea.country = Vax.country AND Dea.date = Vax.date
ORDER BY 1, 2;


-- #tempt table out of it
-- create and insert into 

DROP TABLE IF EXISTS #temp_Case_Population0
CREATE TABLE #temp_Case_Population0 (
	Country NVARCHAR (150),
	Date DATE,
	Population FLOAT,
	Total_Cases FLOAT,
	New_Cases FLOAT,
	New_Deaths FLOAT,
	Case_Per_Population FLOAT
);

INSERT INTO #temp_Case_Population0
SELECT	Dea.country, Dea.date, Dea.population, Dea.total_cases, Dea.new_cases, Dea.new_deaths,
		(Dea.total_cases/Dea.population) * 100 AS Case_Per_Population
FROM Covid_Portfolio..Covid_Death AS Dea
INNER JOIN Covid_Portfolio..Covid_Vaccination AS Vax
	ON Dea.country = Vax.country AND Dea.date = Vax.date
ORDER BY 1, 2;

SELECT *
FROM #temp_Case_Population0;

SELECT	Country, Date, Population, Total_Cases, (Total_Cases/Population) * 100 AS Case_Population_Percent
FROM #temp_Case_Population0
ORDER BY 1, 2;


				---- Total cases vs population by country ----

SELECT country, population, SUM (New_Cases) AS Total_Case, (SUM (New_Cases) / Population) * 100 AS Total_Cases_Population_Percent
FROM #temp_Case_Population0
GROUP BY Country, Population
ORDER BY Total_Cases_Population_Percent DESC;


				---- Cases per population by date ----

SELECT country, population, date, 
	MAX (total_cases) AS Total_Case_Per_Day,
	(Max (total_cases) / population) * 100 AS Cases_Per_Population
FROM Covid_Portfolio..Covid_Death
WHERE 
		country <> 'Africa' AND
		country <> 'Asia' AND
		country <> 'Europe' AND
		country <> 'North America' AND
		country <> 'South America' AND
		country <> 'Oceania' AND
		country NOT LIKE '%-income%' AND
		country NOT LIKE '%Olymp%' AND
		country NOT LIKE '%World%'
GROUP BY country, population, date
ORDER BY 1, 2;


-- or -- using MAX instead of  SUM
-- because there is already a 'World' data in the [country] in which is summing all data

SELECT Country, Population, MAX (Total_Cases) As Total_Cases, MAX ((Total_Cases)/Population) * 100 AS Total_Cases_Per_Pop_Percent
FROM #temp_Case_Population0
GROUP BY Country, Population
ORDER BY Total_Cases_Per_Pop_Percent DESC;


				---- Rank country based on cases per population percentage ----

DROP TABLE IF EXISTS #temp_Case_Population1
SELECT 
	RANK () OVER (PARTITION BY Country ORDER BY Country) AS Numb, 
	Country, 
	Population, 
	MAX (Total_Cases) As Total_Cases, 
	MAX ((Total_Cases)/Population) * 100 AS Total_Cases_Per_Pop_Percent
INTO #temp_Case_Population1
FROM #temp_Case_Population0
WHERE Country NOT LIKE '%Asia%' AND 
	Country NOT LIKE '%World%' AND	
	Country  <> 'Africa' AND
	Country NOT LIKE '%Europe%' AND
	Country NOT LIKE '%country%' AND
	Country NOT LIKE '%income%' AND
	Country NOT LIKE '%Olympics%' AND
	Country <> 'North America' AND
	Country <> 'South America'
GROUP BY Country, Population;


SELECT	RANK () OVER (PARTITION BY Numb ORDER BY Total_Cases_Per_Pop_Percent DESC) AS Cases_Rank,
		Country, Population, Total_Cases, Total_Cases_Per_Pop_Percent
FROM #temp_Case_Population1
ORDER BY Total_Cases_Per_Pop_Percent DESC;


				---- Rank the highest for cases per day ----

SELECT TOP 1 date, SUM (new_cases) AS Cases_Per_Day
FROM Covid_Portfolio..Covid_Death
WHERE 
		country <> 'Africa' AND
		country <> 'Asia' AND
		country <> 'Europe' AND
		country <> 'North America' AND
		country <> 'South America' AND
		country <> 'Oceania' AND
		country NOT LIKE '%-income%' AND
		country NOT LIKE '%Olymp%' AND
		country NOT LIKE '%World%'
GROUP BY date
ORDER BY Cases_Per_Day DESC;

--or

WITH Death_Top1 AS (
	SELECT date, SUM (new_cases) AS Total_Cases
	FROM Covid_Portfolio..Covid_Death
	WHERE country <> 'Africa' AND
		country <> 'Asia' AND
		country <> 'Europe' AND
		country <> 'North America' AND
		country <> 'South America' AND
		country <> 'Oceania' AND
		country NOT LIKE '%-income%' AND
		country NOT LIKE '%Olymp%' AND
		country NOT LIKE '%World%'
	GROUP BY date
)
SELECT *
FROM Death_Top1
WHERE Total_Cases = (
					SELECT MAX (Total_Cases)
					FROM Death_Top1
					);


				---- Death vs cases & population by country ----

SELECT	country, population, MAX (total_cases) AS Total_Cases, 
		MAX ((total_cases)/population) * 100 AS Cases_Per_Population,
		MAX (total_deaths) AS Total_Deaths, MAX (total_deaths / total_cases) * 100 AS Deaths_Per_Cases,
		MAX (total_deaths/population) * 100 AS Death_Per_Population
FROM Covid_Portfolio..Covid_Death
WHERE Country NOT LIKE '%Asia%' AND 
	Country NOT LIKE '%World%' AND	
	Country  <> 'Africa' AND
	Country NOT LIKE '%Europe%' AND
	Country NOT LIKE '%country%' AND
	Country NOT LIKE '%income%' AND
	Country NOT LIKE '%Olympics%' AND
	Country <> 'North America' AND
	Country <> 'SOUTH America'
GROUP BY country, population
ORDER BY Death_Per_Population DESC;


				---- Global population, global death, and percentage ----

DROP TABLE IF EXISTS #temp_Death_Population0
SELECT	country AS Country, population AS Population, MAX (total_cases) AS Total_Cases, 
		MAX ((total_cases)/population) * 100 AS Cases_Per_Population,
		MAX (total_deaths) AS Total_Deaths, MAX (total_deaths / total_cases) * 100 AS Deaths_Per_Cases,
		MAX (total_deaths/population) * 100 AS Death_Per_Population
INTO #temp_Death_Population0
FROM Covid_Portfolio..Covid_Death
WHERE Country NOT LIKE '%Asia%' AND 
	Country NOT LIKE '%World%' AND	
	Country  <> 'Africa' AND
	Country NOT LIKE '%Europe%' AND
	Country NOT LIKE '%country%' AND
	Country NOT LIKE '%income%' AND
	Country NOT LIKE '%Olympics%' AND
	Country <> 'North America' AND
	Country <> 'South America' AND
	country <> 'Oceania'
GROUP BY country, population;


SELECT	--RANK () OVER (ORDER BY Death_Per_Population DESC) AS Death_Rank,
		Country, Population, Total_Cases, Total_Deaths, 
		SUM (Population) OVER () AS Global_Population, 
		SUM (Total_Deaths) OVER () AS Global_Deaths, 
		(SUM (Total_Cases) OVER () / SUM (Population) OVER ())* 100  AS Global_Cases_Per_Population,
		(SUM (Total_Deaths) OVER () / SUM (Population) OVER ())* 100  AS Global_Death_Per_Population
FROM #temp_Death_Population0
ORDER BY Global_Death_Per_Population DESC;

-- and

SELECT Country, Population, Total_Cases, Total_Deaths,
	(Total_Deaths / Total_Cases) * 100 AS Fatality_Rate,
	(Total_Cases / Population) * 100  AS Cases_Per_Population,
	(Total_Deaths / Population) * 100  AS Death_Per_Population
FROM #temp_Death_Population0
ORDER BY 1;


				---- Deaths per population by date ----

SELECT country, population, date, 
	MAX (total_deaths) AS Total_Deaths_Per_Day,
	(Max (total_deaths) / population) * 100 AS Deaths_per_Population
FROM Covid_Portfolio..Covid_Death
WHERE 
		country <> 'Africa' AND
		country <> 'Asia' AND
		country <> 'Europe' AND
		country <> 'North America' AND
		country <> 'South America' AND
		country <> 'Oceania' AND
		country NOT LIKE '%-income%' AND
		country NOT LIKE '%Olymp%' AND
		country NOT LIKE '%World%'
GROUP BY country, population, date
ORDER BY 1, 2;


				---- Cases and deaths by continents ----

SELECT	country AS Continent, MAX (population) AS Population, MAX (total_cases) AS Total_Cases, MAX (total_deaths) AS Total_Death,
		SUM (Population) OVER () AS Global_Population, 
		(SELECT MAX (total_cases)
		FROM Covid_Portfolio..Covid_Death
		) AS Global_Cases,
		(SELECT MAX (Total_Deaths)
		FROM Covid_Portfolio..Covid_Death) AS Global_Deaths
FROM Covid_Portfolio..Covid_Death
WHERE	country = 'Africa' OR
		country = 'Asia' OR
		country = 'Europe' OR
		country = 'North America' OR
		country = 'South America' OR
		country = 'Oceania'
GROUP BY country, population
ORDER BY 1, 2;

-- or by #temp_table

DROP TABLE IF EXISTS #temp_continent
SELECT	country AS Continent, MAX (population) AS Population, MAX (total_cases) AS Total_Cases, MAX (total_deaths) AS Total_Deaths,
		SUM (Population) OVER () AS Global_Population
INTO #temp_Continent
FROM Covid_Portfolio..Covid_Death
WHERE	country = 'Africa' OR
		country = 'Asia' OR
		country = 'Europe' OR
		country = 'North America' OR
		country = 'South America' OR
		country = 'Oceania'
GROUP BY country, population
ORDER BY 1, 2;

SELECT *
FROM #temp_Continent;


				---- insert global numbers into rows instead of column ----

INSERT INTO #temp_Continent VALUES 
('Global_Cases', 
	(SELECT SUM (Population) FROM #temp_Continent) ,
	(SELECT SUM (Total_Cases) FROM #temp_Continent), 
	(SELECT SUM (Total_Deaths) FROM #temp_Continent), 
	(SELECT AVG (Global_Population) FROM #temp_Continent));

SELECT	Continent, Population, Total_Cases, Total_Deaths, 
		(Total_Cases / Population) * 100 AS Case_Per_Pop,
		(Total_Deaths / Total_Cases) * 100 AS Mortality_Rate,
		(Total_Deaths / Population) * 100 AS Death_Per_Pop
FROM #temp_Continent;


				---- Group by date ----

SELECT date, SUM (population) AS Total_Population, SUM (new_cases) AS Case_Per_Day, SUM (new_deaths) AS Death_Per_Day,
	(SUM (new_cases) / SUM (population)) * 100 AS Case_Population_Percent, (SUM (new_deaths) / SUM (population)) * 100 AS Death_Population_Percent
FROM Covid_Portfolio..Covid_Death
WHERE Country NOT LIKE '%Asia%' AND 
	Country NOT LIKE '%World%' AND	
	Country  <> 'Africa' AND
	Country NOT LIKE '%Europe%' AND
	Country NOT LIKE '%country%' AND
	Country NOT LIKE '%income%' AND
	Country NOT LIKE '%Olympics%' AND
	Country <> 'North America' AND
	Country <> 'South America' AND
	country <> 'Oceania'
GROUP BY date
ORDER BY date ASC;






-----------------------------------------Join Tables---------------------------------------------------------------------------------------------------
-----------------------------------------Vaccination---------------------------------------------------------------------------------------------------

				---- Select all ----

SELECT *
FROM Covid_Portfolio..Covid_Death AS Dea
INNER JOIN Covid_Portfolio..Covid_Vaccination AS Vax
	ON Dea.country = Vax.country AND Dea.date = Vax.date
WHERE Dea.Country NOT LIKE '%Asia%' AND 
	Dea.Country NOT LIKE '%World%' AND	
	Dea.Country  <> 'Africa' AND
	Dea.Country NOT LIKE '%Europe%' AND
	Dea.Country NOT LIKE '%country%' AND
	Dea.Country NOT LIKE '%income%' AND
	Dea.Country NOT LIKE '%Olympics%' AND
	Dea.Country <> 'North America' AND
	Dea.Country <> 'South America' AND
	Dea.country <> 'Oceania';


				---- Important only ----

SELECT Dea.country, Dea.date, Dea.population, Dea.new_cases, 
	Dea.total_cases, Vax.new_tests, Vax.total_tests, 
	Vax.new_vaccinations, Vax.total_vaccinations
FROM Covid_Portfolio..Covid_Death AS Dea
INNER JOIN Covid_Portfolio..Covid_Vaccination AS Vax
	ON Dea.country = Vax.country AND Dea.date = Vax.date
WHERE Dea.Country NOT LIKE '%Asia%' AND 
	Dea.Country NOT LIKE '%World%' AND	
	Dea.Country  <> 'Africa' AND
	Dea.Country NOT LIKE '%Europe%' AND
	Dea.Country NOT LIKE '%country%' AND
	Dea.Country NOT LIKE '%income%' AND
	Dea.Country NOT LIKE '%Olympics%' AND
	Dea.Country <> 'North America' AND
	Dea.Country <> 'South America' AND
	Dea.country <> 'Oceania'
ORDER BY 1, 2;


-- #temp tables of vax

DROP TABLE IF EXISTS #temp_Vaccination0
SELECT Dea.country, Dea.date, Dea.population, Dea.new_cases, 
	Dea.total_cases, Vax.new_tests, Vax.total_tests, 
	Vax.new_vaccinations, Vax.total_vaccinations
INTO #temp_Vaccination0
FROM Covid_Portfolio..Covid_Death AS Dea
INNER JOIN Covid_Portfolio..Covid_Vaccination AS Vax
	ON Dea.country = Vax.country AND Dea.date = Vax.date
WHERE Dea.Country NOT LIKE '%Asia%' AND 
	Dea.Country NOT LIKE '%World%' AND	
	Dea.Country  <> 'Africa' AND
	Dea.Country NOT LIKE '%Europe%' AND
	Dea.Country NOT LIKE '%country%' AND
	Dea.Country NOT LIKE '%income%' AND
	Dea.Country NOT LIKE '%Olympics%' AND
	Dea.Country <> 'North America' AND
	Dea.Country <> 'South America' AND
	Dea.country <> 'Oceania'
ORDER BY 1 DESC , 2 DESC;

SELECT *
FROM #temp_Vaccination0;


				---- Case per test percentage per day ----

SELECT country, date, population, total_cases, total_tests,
	(total_cases/total_tests) * 100 AS Case_Per_Test_Percentage
FROM #temp_Vaccination0
ORDER BY 1, 2;


				---- Case per test percentage total by country ----

SELECT country, MAX (total_cases) AS Total_Cases, MAX (total_tests) AS Total_Tests,
	(MAX (total_cases) / MAX (total_tests)) * 100 AS Total_Case_Test_Percentage
FROM #temp_Vaccination0
GROUP BY country
ORDER BY Total_Case_Test_Percentage DESC;


				---- vaccination rate per population by date ----

SELECT country, date, population, total_vaccinations, (total_vaccinations / population) * 100 AS Vax_Rate
FROM #temp_Vaccination0
ORDER BY 1, 2;


				---- total vaccination per population by country ----

SELECT country, MAX (population) AS Population, MAX (total_vaccinations) AS Total_Vax, 
	(MAX (total_vaccinations) / MAX (population)) * 100 AS Total_Vax_Rate
FROM #temp_Vaccination0
GROUP BY country
ORDER BY Total_Vax_Rate DESC;


				---- Vaccination rate per-date by continent ----

-- create #temp_table for continent

DROP TABLE IF EXISTS #temp_Continent2
SELECT Dea.country, Dea.date, Dea.population,  
	Dea.total_cases, Vax.total_vaccinations
INTO #temp_Continent2
FROM Covid_Portfolio..Covid_Death AS Dea
INNER JOIN Covid_Portfolio..Covid_Vaccination AS Vax
	ON Dea.country = Vax.country AND Dea.date = Vax.date
WHERE Dea.country = 'Africa' OR
		Dea.country = 'Asia' OR
		Dea.country = 'Europe' OR
		Dea.country = 'North America' OR
		Dea.country = 'South America' OR
		Dea.country = 'Oceania';

SELECT country, date, population, total_vaccinations, 
	(total_vaccinations / population) * 100 AS Continent_Vax_Rate
FROM #temp_Continent2
ORDER BY 1, 2;


				---- Total vaccinations rate by continent ----

SELECT country, AVG (population) AS Population, MAX (total_vaccinations) AS Vaccinations,
	(MAX (total_vaccinations) / AVG (population)) * 100 AS Total_Vax_Rate
FROM #temp_Continent2
GROUP BY country
ORDER BY 1;


				---- Global vaccinations ----

-- using an existing #temp_table

INSERT INTO #temp_Continent2 VALUES
	('Global',
	NULL,
	(SELECT SUM (Max_Pop) 
					FROM (SELECT country, MAX (population) AS Max_Pop
							FROM #temp_Continent2
							GROUP BY country) AS Maximum_Population),
	(SELECT MAX (total_cases) FROM Covid_Portfolio..Covid_Death),
	NULL,
	(SELECT SUM (Max_Vax) 
		FROM (SELECT country, MAX (total_vaccinations) AS Max_Vax
			FROM #temp_Continent2
			GROUP BY country) AS Maximum_Vax))

SELECT country, MAX (population) AS Population, MAX (total_cases) AS Total_Cases, MAX (total_vaccinations) AS Total_Vaccinations
FROM #temp_Continent2
GROUP BY country
ORDER BY Total_Vaccinations ASC


-- using a new #temp_table

DROP TABLE IF EXISTS #temp_Continent3
SELECT country AS Continent, 
	AVG (population) AS Total_Population, 
	MAX (total_vaccinations) AS Total_Vaccinations
INTO #temp_Continent3
FROM #temp_Continent2
GROUP BY country

SELECT Continent, SUM (Total_Population) OVER () AS Total_Population, SUM (Total_Vaccinations) OVER () AS Total_Vaccinations
FROM #temp_Continent3

INSERT INTO #temp_Continent3 VALUES (
	'Global',
	(SELECT SUM (Total_Population) FROM #temp_Continent3),
	(SELECT SUM (Total_Vaccinations) FROM #temp_Continent3))

SELECT *, (MAX (total_vaccinations) / AVG (Total_Population)) * 100 AS Vax_Rate
FROM #temp_Continent3
GROUP BY Continent, Total_Population, Total_Vaccinations
ORDER BY 3 ASC