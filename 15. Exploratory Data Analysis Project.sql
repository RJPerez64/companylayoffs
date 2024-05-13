-- Exploratory Data Analysis

-- Selecting all data from cleaned dataset
SELECT *
FROM layoffs_staging2;

-- Determining the highest number of people laid off and highest percentage by one company in one day
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Looking at companies with a laid off percentage of 1 (100%; perhaps bankruptcy), ordered first by total number of layoffs from most to least...
-- Katerra was the biggest, with over 2400 people
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- ...then by millions of dollars raised by company by most to least
-- Britishvolt, Quibi, Deliveroo Australia, Katerra, and BlockFi are the Top 5 (all with at least $1 billion raised)
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Looking into the total and average layoffs by each company (having the most layoffs could be from just one day or multiple)
-- Amazon has the most total layoffs, but Google has the highest average layoffs (12000 people in one day)
SELECT company, SUM(total_laid_off) AS total_layoffs, AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
GROUP BY company
ORDER BY total_layoffs DESC;

-- Looking at the start and end dates of these layoffs
-- March 11, 2020 to March 6, 2023
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Looking at total and average layoffs by each industry
-- Hardware had the highest average (over 10 layoffs)
SELECT industry, SUM(total_laid_off) AS total_layoffs, AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
GROUP BY industry
ORDER BY avg_layoffs DESC;

-- Total layoffs shows Consumer, Retail, Other, and Transportation with at least 30000 layoffs and averaging over 300 per row
SELECT industry, SUM(total_laid_off) AS total_layoffs, AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_layoffs DESC;

-- Average layoffs shows Netherlands, Sweden, and China with high counts of multiple layoffs
SELECT country, SUM(total_laid_off) AS total_layoffs, AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
GROUP BY country
ORDER BY avg_layoffs DESC;

-- Total layoffs show that US, India, Netherlands, Sweden, and Brazil led way
SELECT country, SUM(total_laid_off) AS total_layoffs, AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
GROUP BY country
ORDER BY total_layoffs DESC;

-- Looking at number of layoffs by year shows 2022 and 2023 had high volume (especially 2023 only covering a few months)
-- 2021 and 2023 had the most average layoffs, making 2023 very bad for workers
SELECT YEAR(`date`), SUM(total_laid_off) AS total_layoffs, AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY YEAR(`date`) DESC;

-- Post-IPO companies had the worst total and average layoffs during this time by far
SELECT stage, SUM(total_laid_off) AS total_layoffs, AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
GROUP BY stage
ORDER BY total_layoffs DESC;

-- Several FAANG companies (Facebook (Meta), Amazon, Alphabet (Google)) make up Top 3, while Salesforce and Microsoft round out Top 5
SELECT company, SUM(total_laid_off) AS total_layoffs, AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
WHERE stage = 'Post-IPO'
GROUP BY company
ORDER BY total_layoffs DESC;

-- Consumer and Other are the industries with companies who had at least 10,000 average layoffs during this time
SELECT company, industry, AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
GROUP BY company, industry
ORDER BY avg_layoffs DESC;

-- Developing a rolling total of layoffs by month throughout this period
-- April and May 2020 were rough, but things really got bad starting in February 2022 going to the end of the data (March 2023)
WITH Rolling_Total AS (
SELECT SUBSTRING(`date`, 1, 7) AS `year_month`,
SUM(total_laid_off) AS total_layoffs,
AVG(total_laid_off) AS avg_layoffs
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `year_month`
ORDER BY `year_month`
)
SELECT `year_month`, total_layoffs,
SUM(total_layoffs) OVER(ORDER BY `year_month`) AS rolling_total
FROM Rolling_Total;

-- Seeing the most layoffs by a single company in a single year
-- Google, Meta, and Amazon were the Top 3, with Amazon appearing again in the Top 10
SELECT company, YEAR(`date`) AS `year`,
SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY company, YEAR(`date`) 
ORDER BY total_layoffs DESC;

-- Pulling up the Top 5 company layoffs each year (with ties kept)
-- Amazon appears twice
WITH Company_Year (company, years, total_layoffs) AS (
SELECT company, YEAR(`date`) AS `year`,
SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY company, YEAR(`date`) 
), Company_Year_Rank AS (
SELECT *,
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_layoffs DESC) AS Ranking
FROM Company_Year)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5
ORDER BY ranking;