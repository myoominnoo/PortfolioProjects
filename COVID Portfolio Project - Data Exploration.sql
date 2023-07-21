/* 
Covid 19 Data Exploration
*/

-- 1). Select Data that we are going to be starting with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ForPofolio.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY location, date;

-- 2). Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM ForPofolio.CovidDeaths
ORDER BY location, date;

-- 3). Total Cases vs Population
SELECT location, date, population, total_cases, (total_cases / population)*100 AS PercentPopulationInfected
FROM ForPofolio.CovidDeaths
ORDER BY location, date;

-- 4). Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM ForPofolio.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- 5). Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM ForPofolio.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- 6). BREAKING THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM ForPofolio.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- 7). GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS SIGNED)) AS total_deaths, SUM(CAST(new_deaths AS SIGNED))/SUM(new_cases)*100 AS DeathPercentage
FROM ForPofolio.CovidDeaths
WHERE continent IS NOT NULL;

-- 8). Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM ForPofolio.CovidDeaths dea
JOIN ForPofolio.CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

-- 9). Using CTE to perform Calculation on Partition By in the previous query
WITH PopvsVac AS (
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  FROM
    ForPofolio.CovidDeaths dea
  JOIN
    ForPofolio.CovidVaccinations vac
  ON
    dea.location = vac.location
    AND dea.date = vac.date
  WHERE
    dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentVaccinated
FROM PopvsVac;

-- 10). Using Temp Table to perform Calculation on Partition By in the previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TEMPORARY TABLE #PercentPopulationVaccinated
(
  Continent VARCHAR(255), 
  Location VARCHAR(255),
  Date DATE,
  Population NUMERIC,
  New_vaccinations NUMERIC,
  RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM ForPofolio.CovidDeaths dea
JOIN ForPofolio.CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated;
