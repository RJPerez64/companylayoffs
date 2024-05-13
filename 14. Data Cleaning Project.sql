-- Data Cleaning

SELECT *
FROM layoffs;

SELECT COUNT(*)
FROM layoffs;

-- Data Cleaning Process
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or blank values
-- 4. Remove Any Columns

-- Create staging table for cleaning (keep raw table if mistakes made)
CREATE TABLE layoffs_staging
LIKE world_layoffs.layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- 1. Remove Duplicates

-- Checking for duplicates based on table's columns
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Confirming duplicates; need another table to delete duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Creating new table to delete duplicates with row_num column
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Confirm creation of new table
SELECT *
FROM layoffs_staging2;

-- Add values from layoffs_staging from CTE
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
`date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Focus on just the duplicates rows
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Finally delete duplicate rows
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Confirm duplicates have been deleted
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- 2. Standardize the Data

-- Trimming company names
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Check for industries with similar concepts (3 different names for Crypto)

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Standardize to Crypto
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Confirm changes made to Crypto rows
SELECT *
FROM layoffs_staging2
WHERE industry IN ('CryptoCurrency', 'Crypto Currency');

-- See if any duplicates came to be
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Look for issues in location column
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY location;

-- Look for issues in country column (United States with a period)
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY country DESC;

-- Trim . from United States and update table
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE 'United States%';

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- See if any duplicates came to be
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Change Date column data type from Text to Date
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 3. Null Values or blank values

-- Review null and blank values in industry column
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Replace blanks with NULL values to make changes easier
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Check if industry is given for these companies
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- Line up companies with null industry with rows of same company with non-null industry
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Update Null values based on non-null values
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- 4. Remove Any Columns

-- Look to see if any issues regarding total_laid_off and percentage_laid_off
-- These columns will be used a lot in follow-up
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Deleting these rows, since data with null values in these two columns is untrustworthy
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- Drop row_num column, as it's not needed anymore
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;