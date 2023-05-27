SELECT 
    *
FROM
    covid_project.coviddeaths1
ORDER BY 3 , 4;

SELECT 
    cd.location,
    cd.date,
    cd.total_cases,
    cd.new_cases,
    cd.total_deaths,
    cd.population
FROM
    coviddeaths1 cd
ORDER BY 1 ,2;

-- I want to look at total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT cd.location, cd.date,cd.total_cases,cd.total_deaths,(total_deaths/total_cases)*100 as death_percentage
FROM coviddeaths1 cd where cd.location like 'a%'
ORDER BY 1 ,2, 5;

select location, sum(total_cases) as total_case,
sum(total_deaths) as total_deaths,
round(sum(total_cases)/sum(total_deaths)) as death_percentage,
row_number() over(partition by cd.continent) as row_cont
from coviddeaths1 cd where location like 'a%' group by continent, location;

-- I want to look at total cases vs population
-- Shows likelihood of dying if you contract covid in your country
SELECT cd.location, cd.date,cd.total_cases,
cd.population, (cd.total_cases/cd.population)*100 as "percentage_risk/vulnerability" 
FROM coviddeaths1 cd where cd.location like 'a%'
ORDER BY 1 ,2, 5;

-- Countries with Highest Infection Rate compared to Population
SELECT cd.location,cd.population,MAX(total_cases) as 'HighestInfectionCount', MAX((cd.total_cases/cd.population))*100 as "PercentPopulationInfected" 
FROM coviddeaths1 cd 
group by cd.location,cd.population
ORDER BY PercentPopulationInfected desc;

-- Countries with Highest Death Count per Population
select location,max(total_deaths) as TotalDeathCount from coviddeaths1
where continent is not null
group by location
order by TotalDeathCount desc;

/*  BREAKING THINGS DOWN BY CONTINENT */

-- Showing contintents with the highest death count per population
Select continent, MAX(Total_deaths) as TotalDeathCount
From CovidDeaths1
Where continent is not null 
Group by continent
order by TotalDeathCount desc;

-- GLOBAL NUMBERS

Select date,SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
SUM(new_deaths )/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths1
where continent is not null 
Group By date
order by 1,2;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) 
OVER (Partition by dea.Location ) as RollingPeopleVaccinated
-- ,(RollingPeopleVaccinated/population)*100
From CovidDeaths1 dea
Join CovidVaccinations vac
	On dea.location = vac.location
    	and dea.date = vac.date
where dea.continent is not null 
order by 2 desc ,5 desc   ;
-- uding CTE to extract percentage from previous statement
With VacPercentage(Continent, Location,date,population, new_vaccination_per_day, RollingPeopleVaccinated) 
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) 
OVER (Partition by dea.Location ) as RollingPeopleVaccinated
-- ,(RollingPeopleVaccinated/population)*100
From CovidDeaths1 dea
Join CovidVaccinations vac
	On dea.location = vac.location
    	and dea.date = vac.date
where dea.continent is not null 
order by 2 desc ,5 desc)
select *, round((VP.RollingPeopleVaccinated/VP.population)*100) as VaccinationPercentage  
from VacPercentage  as VP
order by 7 desc;

-- Temporary tables
Drop table if exists PercentPopulationVaccinated;
Create Table PercentPopulationVaccinated
(
Continent varchar(255) null,
Location varchar(255) null,
Population double null,
New_vaccinations varchar(255)  null,
RollingPeopleVaccinated double null
);
insert into PercentPopulationVaccinated 
Select dea.continent, dea.location, dea.population, vac.new_vaccinations,
 SUM(vac.new_vaccinations) 
 OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From coviddeaths1 dea
Join covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date;

Select *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

Create View PopulationVaccinationPercentage as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated

From coviddeaths1 dea
Join covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null;

select * from PopulationVaccinationPercentage