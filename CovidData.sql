-- Select Data that we're going to be using.

SELECT 
    [location],
    [date], 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM 
    PortfolioProject..CovidDeaths
ORDER BY   
    1,2

-- Looking at total cases vs total deaths
-- Shows liklihood of death if you contract covid

SELECT 
    [location],
    [date], 
    total_cases, 
    total_deaths, 
    (total_deaths/total_cases) * 100 as DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE
    location like '%states%'
ORDER BY   
    1,2

ALTER TABLE 
    PortfolioProject.[dbo].[CovidDeaths]
ALTER COLUMN total_cases FLOAT

-- Total cases vs Population
-- Shows what percentage of population got covid.

SELECT 
    [location],
    [date], 
    total_cases, 
    population, 
    (total_cases/population) * 100 as PercentPoplutationInfected
FROM 
    PortfolioProject..CovidDeaths
WHERE
    location like '%states%'
ORDER BY   
    1,2

-- Looking at countries with the highest infection rates?

SELECT 
    [location],
    population,
    MAX(total_cases) as HighestInfectionCount,
    MAX((total_cases/population)) * 100 as PercentPoplutationInfected
FROM 
    PortfolioProject..CovidDeaths
GROUP BY
    [location], population
ORDER BY   
    PercentPoplutationInfected DESC

-- Showing countries with the highest death count per population

SELECT 
    [location],
    MAX(total_deaths) as TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE
    continent is not null
GROUP BY
    [location]
ORDER BY   
    TotalDeathCount DESC

-- Showing continents with the highest death count per population

SELECT 
    [continent],
    MAX(total_deaths) as TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE
    continent is not null
GROUP BY
    [continent]
ORDER BY   
    TotalDeathCount DESC


-- Global Numbers

SELECT
    date,
    SUM(new_cases) as TotalNewCases,
    SUM(cast(new_deaths as float)) as TotalNewDeaths,
    SUM(cast(new_deaths as float))/SUM(new_cases)* 100 as DeathPercentage
FROM
    PortfolioProject..CovidDeaths
WHERE
    continent is not NULL
GROUP BY
    [date]
ORDER BY 
    1,2

-- Looking at total population vs vaccination

SELECT
    dea.continent,
    dea.[location],
    dea.[date],
    dea.population,
    vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinations
FROM
    PortfolioProject..CovidDeaths dea 
JOIN
    PortfolioProject..CovidVaccinations vac 
    ON
    dea.location = vac.[location]
    and dea.date = vac.[date]
WHERE
    dea.continent is not NULL
ORDER BY 
    1,2

-- Using a Common Table Expression

WITH PopvsVac 
    (continent, 
    location, 
    date, 
    population, 
    new_vaccinations, 
    RollingVaccinations)
AS
(
    SELECT
        dea.continent,
        dea.[location],
        dea.[date],
        dea.population,
        vac.new_vaccinations,
        SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinations
    FROM
        PortfolioProject..CovidDeaths dea 
    JOIN
        PortfolioProject..CovidVaccinations vac 
        ON
        dea.location = vac.[location]
        and dea.date = vac.[date]
    WHERE
        dea.continent is not NULL
)
SELECT
    *,
    (cast(RollingVaccinations as float)/population)*100 as VaccinationPercentage
FROM
    PopvsVac

-- Creating views to store data for visualizations later

DROP VIEW IF EXISTS PopvsVac

CREATE VIEW PopvsVac AS
WITH PopvsVac 
    (continent, 
    location, 
    date, 
    population, 
    new_vaccinations, 
    RollingVaccinations)
AS
(
    SELECT
        dea.continent,
        dea.[location],
        dea.[date],
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinations
    FROM
        PortfolioProject..CovidDeaths dea 
    JOIN
        PortfolioProject..CovidVaccinations vac 
        ON
        dea.location = vac.[location]
        and dea.date = vac.[date]
    WHERE
        dea.continent is not NULL
)
SELECT
    *,
    (RollingVaccinations/population)*100 as VaccinationPercentage
FROM
    PopvsVac


DROP VIEW IF EXISTS GlobalDeathPercentage
CREATE VIEW GlobalDeathPercentage AS
SELECT
    date,
    SUM(new_cases) as TotalNewCases,
    SUM(cast(new_deaths as float)) as TotalNewDeaths,
    SUM(cast(new_deaths as float))/SUM(new_cases)* 100 as DeathPercentage
FROM
    PortfolioProject..CovidDeaths
WHERE
    continent is not NULL
GROUP BY
    [date]

DROP VIEW IF EXISTS ContinentDeathCount
CREATE VIEW ContinentDeathCount AS
SELECT 
    [continent],
    MAX(total_deaths) as TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE
    continent is not null
GROUP BY
    [continent]

DROP VIEW IF EXISTS CountryDeathCount
CREATE VIEW CountryDeathCount AS
SELECT 
    [location],
    MAX(total_deaths) as TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE
    continent is not null
GROUP BY
    [location]

DROP VIEW IF EXISTS CountryDeathPercentage
CREATE VIEW CountryDeathPercentage AS
SELECT 
    [location],
    [date], 
    total_cases, 
    total_deaths, 
    (total_deaths/total_cases) * 100 as DeathPercentage
FROM 
    PortfolioProject..CovidDeaths

-- Updating table 
DROP TABLE CovidDeaths
DROP TABLE CovidVaccinations

USE PortfolioProject;
GO
EXEC sp_rename 'Deaths', 'CovidDeaths';

USE PortfolioProject;
GO
EXEC sp_rename 'Vaccinations', 'CovidVaccinations';