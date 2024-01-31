

-----------------------------------------------------------------------------------------------------------------------------------------
--1. Query the different columns that make up the table.


SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dataset';




-----------------------------------------------------------------------------------------------------------------------------------------
--2. Calculate the global total cases, total deaths, and reproduction rate per year.


SELECT FORMAT(date,'yyyy') AS Year_, --Query the year only
SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths as INT)) AS TotalDeaths, AVG(CAST(reproduction_rate AS FLOAT))  ReproductionRate
FROM dataset
WHERE continent IS NOT NULL --exclude the continents
GROUP BY FORMAT(date,'yyyy')
ORDER BY Year_ DESC; 

----------------------------------------------------------------------------------------------------------------------------------------
--3. Calculate the global average number of cases (rounded to 2 decimals).

SELECT ROUND(SUM(new_cases) / COUNT(DISTINCT location),2) as Average 
FROM dataset
WHERE continent IS NOT NULL; 

-------------------------------------------------------------------------------------------------------------------
--4.Total deaths for each month of the countries whose name ends in "stan".


SELECT location, FORMAT(date, 'yyyy-MM') as month_, 
SUM(CAST(new_deaths as FLOAT)) as TotalDeaths -- calculate the total of deaths by adding up the new deaths
FROM dataset
WHERE location LIKE '%stan' --Wildcard to filter the countries whose name ends with 'stan'
GROUP BY location, FORMAT(date, 'yyyy-MM')
ORDER BY location;

-------------------------------------------------------------------------------------------------------------------
--5.This query calculates the total deaths per million for each month and for each country.
-- It also assigns, for each country, a rank to each month based on the total deaths per million.
-- Allows to identify the deadliest months for each country. 


WITH MonthlyDeaths AS ( --This CTE calculates the total deaths per million in each month and for each country. 
    SELECT
        location,
        FORMAT(date, 'yyyy-MM') AS month_year, --query only the year and the month
        SUM(CAST(new_deaths_per_million AS FLOAT)) AS total_deaths_per_million
    FROM
        dataset
	WHERE
		continent IS NOT NULL
    GROUP BY
        location,
        FORMAT(date, 'yyyy-MM')
)

SELECT
    location,
    month_year,
    total_deaths_per_million ,
    
	--Assign a rank to each row, considering each country as an independent partition: 
	RANK() OVER (PARTITION BY location ORDER BY total_deaths_per_million DESC) AS MonthRank
FROM
    MonthlyDeaths 
ORDER BY
    location
    ;

-------------------------------------------------------------------------------------------------------------
--6. Calculate the mortality rate for each month for the top 5 countries with the highest GDP and the world.

SELECT location, FORMAT(date, 'yyyy-MM') as fecha, ROUND(SUM(CAST(new_deaths as FLOAT)) / SUM(new_cases) * 100,2) as TasaMortalidad
FROM dataset
WHERE continent IS NOT NULL
AND new_cases <> 0
AND location IN( 

--This subquery identifies the top 5 countries with the highest GDP:
SELECT TOP 5 location 
FROM dataset
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY AVG(population * gdp_per_capita) DESC --order the countries based on the GDP
) 
OR location = 'World'
GROUP BY location, FORMAT(date, 'yyyy-MM') 
ORDER BY location, FORMAT(date, 'yyyy-MM');


-----------------------------------------------------------------------------------------------------
--Queries used for the graphs: 

--7.The query returns the total deaths per million and the GDP per capita  for each country. 
--Using this data, a scatter plot is created to determine if there is a relationship between these two metrics. 
--Graph file name: "Covid scatter plot.twbx"
-- Or access it via the link: https://public.tableau.com/views/Covidscatterplot/Covidscatterplot?:language=es-ES&:display_count=n&:origin=viz_share_link

SELECT location, ROUND(SUM(CAST(new_deaths_per_million as float)),2) as DeathsPerMillon, ROUND(AVG(gdp_per_capita),2) GDPperCapita
FROM dataset
WHERE continent IS NOT NULL
AND new_deaths_per_million IS NOT NULL
AND gdp_per_capita IS NOT NULL
GROUP BY location
ORDER BY DeathsPerMillon DESC;

-------------------------------------------------------------------------------------------------------------------------------
--8.This query returns, for each country, the total percentage of the population that has been infected by Covid.
--Using this data, a map-type graph is generated. File name: "Covid map.twbx"
-- Or access it via the link: https://public.tableau.com/views/Covidmap_17066978208970/Covidmap?:language=es-ES&:display_count=n&:origin=viz_share_link


SELECT location, 
ROUND(SUM(new_cases) / population * 100, 4) as  PercentageInfected --calculate the percentage of the population infected
FROM dataset
WHERE continent IS NOT NULL 
GROUP BY location,population
HAVING SUM(new_cases) / population IS NOT NULL 
ORDER BY PercentageInfected DESC;


--------------------------------------------------------------------------------------------------------------------
--9. This query returns, for the top 10 countries with the highest GDP, the number of new cases per million for each day.
-- Using this data, a time series graph is generated. File name: "Covid time series.twbx"
-- Or access it via the link: https://public.tableau.com/views/Covidtimeseries/Casespermillion?:language=es-ES&:display_count=n&:origin=viz_share_link

SELECT location, date, 
SUM(new_cases_per_million)  as CasesPerMillion
FROM dataset
WHERE continent IS NOT NULL AND new_cases_per_million IS NOT NULL
AND location IN( --this subquery identifies the 10 countries with the highest GDP
SELECT TOP 10 location --SELECT the top 10 results only 
FROM dataset
WHERE continent IS NOT NULL 
GROUP BY location, population
ORDER BY AVG(population * gdp_per_capita) DESC --order the countries based on the GDP
) 
GROUP BY location, date
ORDER BY location, date;

---------------------------------------------------------------------------------------------------------------------
--10. This query calculates the average Human Development Index (HDI) for each continent.
-- Using this data, a bar chart is generated. File name: "HDI bar chart.twbx" 
--Or access it via the link: https://public.tableau.com/views/HDIbarchart/HDIbarchart?:language=es-ES&:display_count=n&:origin=viz_share_link

SELECT continent, 
AVG(human_development_index) AS AverageHDI --calculate the average HDI
FROM dataset
WHERE continent IS NOT NULL AND human_development_index IS NOT NULL --exclude NULL values
GROUP BY continent
ORDER BY AverageHDI DESC
























