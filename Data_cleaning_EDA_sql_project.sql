-- SQL CLEANING AND EXPLORATORY DATA ANALYSIS (EDA)
-- This data is records of layoff from companys from 2020-2023

-- To do: 
-- 1. Remove duplicates 
-- 2. Standradize data (trim, standardize spellings etc)
-- 3. Dealing with Blank and Null values
-- 4. Remove rows and columns


select * from layoffs;

-- create a duplicate of the table for changes so that the raw data doesn't change

CREATE TABLE layoffs_dup
LIKE layoffs;

INSERT INTO layoffs_dup
SELECT * FROM layoffs;

-- Remove Duplicates

SELECT company, 
location, 
industry,
total_laid_off, 
percentage_laid_off, 
`date`,stage,funds_raised_millions, country, count(*)
FROM layoffs_dup
group by company, 
location, 
industry,total_laid_off, 
percentage_laid_off, 
`date`,stage,funds_raised_millions, country
Having count(*)>1;

-- Check your output of duplicates

select * from layoffs_dup
where company = 'casper';

-- remove duplicate using row_number()

select * from layoffs_dup;

select *, row_number() over(partition by company, 
location, 
industry,
total_laid_off, 
percentage_laid_off, 
`date`,stage,funds_raised_millions, country) as row_num from layoffs_dup;

WITH duplicates AS
(select *, row_number() over(partition by company, 
location, 
industry,
total_laid_off, 
percentage_laid_off, 
`date`,stage,funds_raised_millions, country) as row_num from layoffs_dup
)
Select * from duplicates
where row_num > 1; 

-- Create a new table with this data and removing duplicates from them

CREATE TABLE `layoffs_dup2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


INSERT INTO layoffs_dup2
select *, row_number() over(partition by company, 
location, 
industry,
total_laid_off, 
percentage_laid_off, 
`date`,stage,funds_raised_millions, country) as row_num from layoffs_dup;

delete
from layoffs_dup2
where row_num > 1;


-- Standardizing Data

-- remove and update unwanted space from column
select company, TRIM(company) 
from layoffs_dup2;

update layoffs_dup2
set company = TRIM(company);

-- check for same spelling written differently
select distinct industry
from layoffs_dup2
order by 1;

-- doing above analysis we found crypto and crypto currency as two different industry 
-- as both are the same industry we will change crypto currency to crypto

SELECT * 
FROM layoffs_dup2
WHERE industry LIKE 'crypto%';

UPDATE layoffs_dup2
SET industry = 'Crypto'
WHERE industry LIKE 'crypto%';

-- similary check multiple columns for data cleaning
-- lets see country column

SELECT DISTINCT country 
FROM layoffs_dup2
ORDER BY 1;

-- Double entry for UNITED STATES 

UPDATE layoffs_dup2
SET country = 'United States'
WHERE country LIKE 'United%';


-- change date format from text to date

SELECT `date`,
STR_TO_DATE(`date`,'%m/%d/%Y')
FROM layoffs_dup2;

UPDATE layoffs_dup2
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');

ALTER TABLE layoffs_dup2
MODIFY COLUMN `date` DATE;

-- populate empty or null industry with its relavent industry 
SELECT * 
FROM layoffs_dup2
WHERE industry LIKE NULL
OR industry ='';

UPDATE layoffs_dup2
SET industry = NULL
WHERE industry ='';

SELECT t1.industry, t2.industry
FROM layoffs_dup2 t1
JOIN layoffs_dup2 t2
   ON t1.company=t2.company
WHERE (t1.industry is null or t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_dup2 t1
JOIN layoffs_dup2 t2
   ON t1.company=t2.company
   SET t1.industry = t2.industry
   WHERE t1.industry IS NULL 
   AND t2.industry IS NOT NULL;
 
-- Delete rows that have null values for total_laid_off and percentage_laid_off

SELECT * 
FROM layoffs_dup2
WHERE total_laid_off is null
and percentage_laid_off is null;

DELETE
FROM layoffs_dup2
WHERE total_laid_off is null
and percentage_laid_off is null;

-- romove unnccesary column
ALTER TABLE layoffs_dup2 
DROP COLUMN row_num; 




-- Exploratory Data Analysis


-- check company total_laid_off each year

SELECT 	company, Year(`date`), SUM(total_laid_off)
FROM layoffs_dup2
GROUP BY company, Year(`date`)
ORDER BY 3 DESC;

SELECT industry, SUM(total_laid_off)
FROM layoffs_dup2
GROUP BY industry
ORDER BY 2 DESC;

SELECT country, SUM(total_laid_off)
FROM layoffs_dup2
GROUP BY country
ORDER BY 2 DESC;


-- rolling of total_laidoff 

WITH rolling_total
AS(SELECT SUBSTRING(`date`,1,7) `Month`, SUM(total_laid_off) as total_off
FROM layoffs_dup2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month` 
ORDER BY `Month` ASC)
SELECT `Month`, total_off, sum(total_off) over(order by `Month`) as rolling_sum
FROM rolling_total;


-- rank top 5 company with highest layoff each year

WITH Company_year 
AS (SELECT company, year(`date`) as `year`, sum(total_laid_off) as total_off
FROM layoffs_dup2
GROUP BY company, `year`),
Company_rank AS
(SELECT *, DENSE_RANK() over(PARTITION BY `year` ORDER BY total_off DESC) ranking
FROM Company_year
WHERE `year` is not null)
SELECT * 
FROM Company_rank
WHERE ranking <= 5;














