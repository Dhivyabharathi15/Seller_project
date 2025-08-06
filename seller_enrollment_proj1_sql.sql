create schema sellerpath1;
use sellerpath1;
show tables;
rename table seller_enrollment_dataset_25k to seller_data;
select * from seller_data limit 10;

set sql_safe_updates = 0;
set sql_safe_updates = 1;

update seller_data set optin_cta_tagged=
case when lower(optin_cta_tagged) IN ('yes', 'y', 'valid') THEN 'valid'
        ELSE 'invalid'
    END;
    
    update seller_data set impression_tag_valid =
    case
    when lower(impression_tag_valid) in ('yes', 'y', 'valid')
    then 'valid'
    else 'invalid'
    end;
    
    select distinct optin_cta_tagged, impression_tag_valid from 
    seller_data;
    
    -- 2. Funnel Drop-off Analysis
    -- Funnel metrics by Platform
    select platform,
    count(*) as total_sellers,
    sum(impressions) as total_impressions,
    sum(clicks) as total_clicks,
    sum(enrolled) as total_enrollments,
    round(sum(clicks)/ nullif(sum(impressions), 0), 4) as click_through_rate,
    round(sum(enrolled)/ nullif(sum(clicks), 0), 4) as enrollment_conversion_rate
    from seller_data
    group by platform;
    
    -- Funnel metrics by category and kind
    select category, kind,
    count(*) as total_sellers,
    sum(impressions) as total_impressions,
    sum(clicks) as total_clicks,
    sum(enrolled) as total_enrolled,
    round(sum(clicks)/nullif(sum(impressions), 0), 4) as click_through_rate,
    round(sum(enrolled)/nullif(sum(clicks), 0), 4) as enrollment_conversion_rate
    from seller_data
    group by category, kind
    order by enrollment_conversion_rate desc;
    
    -- Category Funnel Drop-off Analysis
    select category,
    sum(impressions) as total_impressions,
    sum(clicks) as total_clicks,
    sum(enrolled) as total_enrolled,
    round(sum(clicks) / sum(impressions), 4) as click_through_rate,
    round(sum(enrolled) / sum(clicks), 4) as enrollment_rate
    from seller_data
    group by category
    order by total_impressions desc;
    -- Kind Funnel Drop-off Analysis
select kind,
    sum(impressions) as total_impressions,
    sum(clicks) as total_clicks,
    sum(enrolled) as total_enrolled,
    round(sum(clicks) / sum(impressions), 4) as click_through_rate,
    round(sum(enrolled) / sum(clicks), 4) as enrollment_rate
    from seller_data
    group by kind
    order by total_impressions desc;

-- Drop-off Based on manual_file_ingested
select manual_file_ingested,
sum(impressions) as total_impressions,
sum(clicks) as total_clicks,
sum(enrolled) as total_enrolled,
round(sum(clicks) / sum(impressions), 4) as click_through_rate,
round(sum(enrolled)/ sum(impressions), 4) as enrolled_rate
from seller_data
group by manual_file_ingested
order by total_impressions desc;

-- 3. Tag Validation Check
-- optin_cta_tagged = No
select optin_cta_tagged,
count(*) as total_sellers,
sum(enrolled) as total_enrolled,
round(sum(enrolled) / count(*) * 100, 2) as enrollment_rate_percent
from seller_data
group by optin_cta_tagged;

-- impression_tag_valid = No
select impression_tag_valid,
count(*) as total_sellers,
sum(enrolled) as total_enrolled,
round(sum(enrolled) / count(*)*100,2)as enrollment_rate_percent
from seller_data
group by impression_tag_valid;

-- 3. Combined Tag Analysis
SELECT 
    optin_cta_tagged,
    impression_tag_valid,
    COUNT(*) AS total_sellers,
    SUM(enrolled) AS total_enrolled,
    ROUND(SUM(enrolled) / COUNT(*) * 100, 2) AS enrollment_rate_percent
FROM seller_data
GROUP BY optin_cta_tagged, impression_tag_valid
ORDER BY enrollment_rate_percent ASC;

-- 4. Seller Behavior Insights
-- Assess seller_tenure_months vs enrollment conversion
select
case when seller_tenure_months between 0 and 6 then '0-6 months'
when seller_tenure_months between 7 and 12 then '7-12 months'
when seller_tenure_months between 13 and 24 then '13-24 months'
else '25+ months'
end as tenure_range,
count(*) as total_sellers,
sum(enrolled) as total_enrolled,
round(sum(enrolled) / count(*) *100, 2) as enrollment_rate_precent
from seller_data
group by tenure_range
order by tenure_range;

-- higher risk rating impact enrollment
SELECT 
    CASE 
        WHEN risk_rating < 2 THEN 'Low Risk (0-1.9)'
        WHEN risk_rating BETWEEN 2 AND 3 THEN 'Moderate Risk (2-3)'
        WHEN risk_rating BETWEEN 3.1 AND 4 THEN 'High Risk (3.1-4)'
        ELSE 'Very High Risk (4.1+)'
    END AS risk_level,
    COUNT(*) AS total_sellers,
    SUM(enrolled) AS total_enrolled,
    ROUND(SUM(enrolled) / COUNT(*) * 100, 2) AS enrollment_rate_percent
FROM seller_data
GROUP BY risk_level
ORDER BY risk_level;

-- Product Preferences by Seller Kind
select
kind, product_opted,
count(*) as seller_count,
sum(enrolled) as total_enrolled,
round(sum(enrolled) / count(*)*100,2) as enrollment_rate_percent
from seller_data
group by kind, product_opted
order by kind, seller_count desc;

-- some Gendrel queries
-- where clasue
select * from seller_proj where category = 'Fashion';

-- order by, limit
select * from seller_proj order by conversion_rate desc limit 5;
    
-- Aggregate funtions
select count(*) as total_sellers from seller_proj;   
select avg(conversion_rate) as avg_conv from seller_proj;
select max(clicks) as max_clicks from seller_proj;

-- group by
select platform, avg(conversion_rate) as avg_conv from seller_proj group by platform;
select category, sum(enrolled) as total_enrolled from seller_proj group by category;

-- filtering goups
select platform, avg(seller_tenure_months) as avg_sell from seller_proj
group by platform
 having avg_sell > 10;

-- Realistic Queries
-- Top Performing Sellers by Conversion Rate
Select seller_id, platform, conversion_rate from seller_proj order by conversion_rate desc limit 10;

-- Daily Clicks Trend
select click_date, sum(clicks) as total_clicks from seller_proj group by click_date order by click_date;

-- Average Conversion Rate per Region
select region, round(avg(conversion_rate), 2) as avg_conversion from seller_proj group by region; 

-- Seller Enrollment Time (in days)
select seller_id, datediff(enrollment_date, click_date) as days_to_enroll from seller_proj where enrollment_date is not null;

-- Seller with Invalid Impressions
select * from seller_proj where impression_tag_valid = 'yes'; -- doubt

-- Risk Rating Distribution
select risk_rating, count(*) as seller_count from seller_proj group by risk_rating;

-- Sellers with High Clicks but low Conversion
select seller_id, clicks, conversion_rate from seller_proj where clicks < 100 and conversion_rate < 1.0;

-- Average Impressions by Platform and Category
select platform, category, round(avg(impressions)) as avg_impressions from seller_proj group by platform, category order by avg_impressions desc;

-- New Sellers with Good Performance
select seller_id, seller_tenure_months, conversion_rate from seller_proj where seller_tenure_months < 6 and conversion_rate < 1;

-- Campaign-wise Enrollment Summary
select campaign_id, count(distinct seller_id) as total_sellers, sum(enrolled) as total_enrolled from seller_proj group by campaign_id order by total_enrolled desc;

-- Seller Performance Classification
select seller_id, conversion_rate,
 case when conversion_rate >= 3 then 'High'
      when conversion_rate >= 1.5 then 'Medium'
      else 'Low'
      end as performance_level from seller_proj;

-- Seller Activity Summary by Region
select region, count(seller_id) as seller_count, avg(impressions) as avg_impressions, avg(clicks) as avg_clicks
from seller_proj group by region;

-- Monthly Enrollment Trend
select date_format(enrollment_date, '%y-%m') as month, count(*) as total_enrolled
from seller_proj where enrollment_date is not null
group by month order by month;

-- New Seller with Good Conversion
select seller_id, seller_tenure_months, conversion_rate from seller_proj
where seller_tenure_months > 6 and conversion_rate < 2.0;

-- Sellers with No Clicks
select * from seller_proj where clicks = 0;

-- Invalid Impression Tagging per Region

select region, count(*) as invalid_count from seller_proj where impression_tag_valid = 'yes'
group by region order by invalid_count desc;
    
