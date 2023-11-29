--Plans
select *
from TIL_PLAYGROUND.CS3_FOODIE_FI.plans;
--Subscriptions
select *
from TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS;

--A. Customer Journey Analysis
--Join tables on plan_id
select s.*
      ,p.plan_name
      ,p.price
from TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS s
join TIL_PLAYGROUND.CS3_FOODIE_FI.plans p on p.plan_id=s.plan_id
where customer_id in (1,2,11,13,15,16,18,19);

/* All customers started on a trial basis and out of the 8 customers, foodie -fi lost 2.
Customers:
1.  Started with a trial and downgraded to Basic Monthly after the trial.
2.  Started with a trial and upgraded to the pro annual after the trial.
11. Started with a trial and churned after trial.
13. Started with a trial, downgraded to Basic Monthly after the trial and changed to pro monthly after 3 months.
15. Started with a trial, automatically continued with a pro monthly and churned after a month and 5 days.
16. Started with a trial, downgraded to Basic Monthly after trial and upgraded to pro annual after 4 months and 2 weeks.
18. Started with a trial and automatically continued with a pro monthly.
19. Started with a trial, automatically continued with a pro monthly and upgraded to pro annual after 2 months.
*/

--B. Data Analysis Questions
--1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT CUSTOMER_ID)
    from TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS; --1000
    
--2.What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT date_part('month', start_date) as month, count(customer_id) as no_of_customers 
    from TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS
    where plan_id = 0
    group by 1
    order by 1;

--3.What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT p.plan_name, count(customer_id) as event_count
    from TIL_PLAYGROUND.CS3_FOODIE_FI.plans p
    join  TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s on p.plan_id=s.plan_id
    where date_part('year',start_date)> 2020
    group by 1
    order by 2;

--4.What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
WITH total_table as
(
    SELECT count(distinct customer_id) as total_customers
        FROM TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS
)
,churn_table as
(
    SELECT  count(plan_id) as total_churn
        FROM TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS
        WHERE plan_id = 4
)
    SELECT total_customers
      ,total_churn
      ,round((total_churn/total_customers)*100,1) as churn_percentage
      FROM total_table,churn_table;

--Another way

    SELECT churned_customers
          ,total_customers
          ,round((churned_customers/total_customers)*100,1) as churn_percentage
      FROM
( 
   SELECT count(DISTINCT customer_id) as churned_customers
         ,(SELECT count(DISTINCT customer_id)
               FROM TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS) as total_customers
      FROM TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS 
      WHERE plan_id = 4
);
    
--5.How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
  with cte as 
      (SELECT  *
           ,row_number() over(partition by customer_id order by start_date)as rn
            FROM TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS
            qualify rn=2
           
    )
    select count(plan_id) as test_only_customers
           ,round((test_only_customers/1000)*100,0) test_only_percentage
    from cte 
    where plan_id=4;


--6.What is the number and percentage of customer plans after their initial free trial?
with cte as 
      (SELECT  s.*
               ,p.plan_name
           ,row_number() over(partition by customer_id order by start_date)as rn
            FROM TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS s
            join TIL_PLAYGROUND.CS3_FOODIE_FI.plans p on s.plan_id=p.plan_id
            qualify rn=2
           
    )
    select plan_name
          ,count(plan_id) as test_only_customers
           ,round((test_only_customers/1000)*100,0) test_only_percentage
    from cte 
   -- where plan_id!=4
    group by 1;


--7.What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31? 
--so this uses this date as the last date hence we need to look on and after that date to acsertain the specific plan a customer was on untill that date.
with cte as
(
SELECT  s.*
,row_number() over(partition by customer_id order by start_date desc)as rn
,p.plan_name
            from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
            join TIL_PLAYGROUND.CS3_FOODIE_FI.plans p on s.plan_id=p.plan_id
            where start_date <= '2020-12-31'
)

select plan_name
      ,count(distinct customer_id) as customer_count
     -- ,(select count(distinct customer_id) from cte)
      ,round((customer_count/(select count(distinct customer_id) from cte))*100,1) customer_count_percentage
from cte
where rn =1
group by 1;

--8.How many customers have upgraded to an annual plan in 2020?

SELECT count(distinct customer_id)
            from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
            join TIL_PLAYGROUND.CS3_FOODIE_FI.plans p on s.plan_id=p.plan_id
            where plan_name in ('pro annual')
            and year(start_date) = '2020';

            
--9.How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with cte as
(
SELECT s.customer_id
      ,s.start_date
      ,p.plan_name
            from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
            join TIL_PLAYGROUND.CS3_FOODIE_FI.plans p on s.plan_id=p.plan_id
           
           where plan_name = 'pro annual' 
           or
           plan_name= 'trial'
) 
,P1 AS 
(
select
customer_id
,trial
,pro_annual
from cte
PIVOT( max(start_date) FOR plan_name IN ('trial', 'pro annual')) AS A
(
customer_id
,trial
,pro_annual
))
SELECT
--customer_id
--,trial 
--,pro_annual 
ROUND(AVG(datediff('day',trial,pro_annual)),0) as AVERAGE_day_duration
FROM P1
where pro_annual is not null
;
            --Another way
with Trial as
(
select customer_id
,start_date as trial_date
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions
where plan_id = 0
)
,ANNUAL AS
(select customer_id 
,start_date as upgrade_date
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions
where plan_id = 3
)
SELECT --trial.customer_id 
--,trial_date
--,upgrade_date
round(avg(datediff('day',trial_date,upgrade_date)),0) as average_day_duration
FROM Trial 
join ANNUAL on Trial.customer_id=Annual.customer_id;


--10.Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with cte as
(
SELECT s.customer_id
      ,s.start_date
      ,p.plan_name
            from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
            join TIL_PLAYGROUND.CS3_FOODIE_FI.plans p on s.plan_id=p.plan_id
           
           where plan_name = 'pro annual' 
           or
           plan_name= 'trial'
) 
,P1 AS 
(
select
customer_id
,trial
,pro_annual
from cte
PIVOT( max(start_date) FOR plan_name IN ('trial', 'pro annual')) AS A
(
customer_id
,trial
,pro_annual
))
SELECT
--customer_id
--,trial 
--,pro_annual 
--,datediff('day',trial,pro_annual) as AVERAGE_day_duration
case 
    when datediff('day',trial,pro_annual) <=30 then '0-30'
    when datediff('day',trial,pro_annual) <=60 then '31-60'
    when datediff('day',trial,pro_annual) <=90 then '61-90'
    when datediff('day',trial,pro_annual) <=120 then '91-120'
    when datediff('day',trial,pro_annual) <=150 then '121-150'
    else 'more than 150'
    end as bin,
    count(*) as bin_count
FROM P1
where pro_annual is not null
group by 1
;

--11.How many customers downgraded from a pro monthly to a basic monthly plan in 2020?



WITH CTE AS
(
select s.customer_id
,s.start_date AS BASIC_DATE
,p.plan_name
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
join TIL_PLAYGROUND.CS3_FOODIE_FI.plans p
on s.plan_id=p.plan_id
where plan_name in ('basic monthly')
AND YEAR(BASIC_DATE)=2020
)
,P1 AS
(select s.customer_id
,s.start_date AS PRO_DATE
,p.plan_name
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
join TIL_PLAYGROUND.CS3_FOODIE_FI.plans p
on s.plan_id=p.plan_id
where plan_name in ('pro monthly')
AND YEAR(PRO_DATE)=2020
)
SELECT COUNT(DISTINCT CTE.CUSTOMER_ID) AS DOWNGRADED_CUSTOMER_COUNT
FROM CTE 
join P1 on CTE.customer_id=P1.customer_id
WHERE PRO_DATE<BASIC_DATE;
    


