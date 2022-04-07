--Select the data that will be used

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1, 2 

-- total cases vs total deaths

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Rate
from PortfolioProject..CovidDeaths
where continent is not null
order by 1, 2

-- total cases vs population

select location, date, total_cases, population, (total_cases/population)*100 as Infection_Rate
from PortfolioProject..CovidDeaths
where continent is not null
order by 1, 2

-- highest percentage of population infected by country 

select location, population, MAX(total_cases) as Highest_Infection_Count, MAX((total_cases/population))*100 as Percent_Population_Infected
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by Percent_Population_Infected desc

-- highest percentage of population infected by country 

select location, MAX(cast(total_deaths as int)) as Total_Death_count
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by Total_Death_count desc

-- highest death count by continent

select location, MAX(cast(total_deaths as int)) as Total_Death_count
from PortfolioProject..CovidDeaths
where continent is null and location != 'High income' and location != 'Upper middle income' and location != 'Lower middle income' and location != 'Low income'
group by location
order by Total_Death_count desc

--global numbers
--global death rate
select SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS death_rate
from PortfolioProject..CovidDeaths
where continent is not null
order by 1, 2


--total population vs vaccinations 
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations, SUM(convert(bigint, vaccs.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_vaccine_count
from PortfolioProject..CovidDeaths deaths 
join PortfolioProject..CovidVaccinations vaccs
	on deaths.location = vaccs.location
	and deaths.date = vaccs.date
where deaths.continent is not null
order by 2, 3

--using a cte
--total population vs vaccinations 

with PopVSVac (continent, location, date, population, new_vaccinations, rolling_vaccine_count)
as
(
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations, SUM(convert(bigint, vaccs.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_vaccine_count
from PortfolioProject..CovidDeaths deaths 
join PortfolioProject..CovidVaccinations vaccs
	on deaths.location = vaccs.location
	and deaths.date = vaccs.date
where deaths.continent is not null
)
select *, (rolling_vaccine_count/population)*100 as PopVaccinatedPercentage
from PopVSVac

-- TempTable for calculations on Partition By statement in the previous query

DROP Table if exists #PopVaccinatedPercentage
Create Table #PopVaccinatedPercentage
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_vaccine_count numeric
)

insert into #PopVaccinatedPercentage
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations, SUM(convert(bigint, vaccs.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_vaccine_count
from PortfolioProject..CovidDeaths deaths 
join PortfolioProject..CovidVaccinations vaccs
	on deaths.location = vaccs.location
	and deaths.date = vaccs.date

select *, (rolling_vaccine_count/population)*100
from #PopVaccinatedPercentage


-- storing for later use on visualizations 

create view PopVaccinatedPercentage as
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccs.new_vaccinations, SUM(convert(bigint, vaccs.new_vaccinations)) over (partition by deaths.location order by deaths.location, deaths.date) as rolling_vaccine_count
from PortfolioProject..CovidDeaths deaths 
join PortfolioProject..CovidVaccinations vaccs
	on deaths.location = vaccs.location
	and deaths.date = vaccs.date
where deaths.continent is not null