----------------Pizza Metrics---------

select name from  sys.tables

---1.How many pizzas were ordered?
 
select count(order_id) as Pizza_Count from customer_orders

---2.How many unique customer orders were made?

select count(distinct order_id) as Unique_customer_orders from customer_orders

---3.How many successful orders were delivered by each runner?
 
select runner_id,count(order_id) as Successful_orders from runner_orders where cancellation is not null group by runner_id  

---4.How many of each type of pizza was delivered?
 
 select count(pizza_id) as NoofPizzadelivered,pizzaname
from (select A.pizza_id,CAST(B.pizza_name as nvarchar(50)) as pizzaname from customer_orders A inner join pizza_names B on A.pizza_id = B.pizza_id ) as A
group by pizzaname

----How many Vegetarian and Meatlovers were ordered by each customer?

select customer_id,count(customer_id) as Customer,pizzaname From (select A.customer_id,CAST(B.pizza_name as nvarchar(50)) as pizzaname from customer_orders A inner join pizza_names B on A.pizza_id = B.pizza_id ) as A
group by customer_id,pizzaname order by   pizzaname

-------What was the maximum number of pizzas delivered in a single order?

select Max(order_count) as Order_count from (select  order_id,count(customer_id) as order_count from customer_orders group by order_id) as A

---For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT customer_id,
       COUNT(CASE WHEN (exclusions IS NOT NULL AND exclusions <> '') 
                     OR (extras IS NOT NULL AND extras <> '') 
                  THEN 1 END) AS Noofchanges,
       COUNT(CASE WHEN (exclusions IS NULL OR exclusions = '') 
                     AND (extras IS NULL OR extras = '') 
                  THEN 1 END) AS Noofnochanges
FROM customer_orders
WHERE order_id IN (SELECT order_id 
                   FROM runner_orders 
                   WHERE cancellation IS NULL OR LEN(cancellation) = 0)
GROUP BY customer_id;
----------

--How many pizzas were delivered that had both exclusions and extras?

select count(pizza_id) as NOOFpizzadelivered from customer_orders where len(exclusions)>=1 and len(extras)>=1

-------
---What was the total volume of pizzas ordered for each hour of the day?

select count(pizza_id) as noofpizzas,Datepart(HOUR,order_time) as Hour from customer_orders group by Datepart(HOUR,order_time)
order by Datepart(HOUR,order_time)
 
 --What was the volume of orders for each day of the week?
 select count(pizza_id) as noofpizzas,Datepart(WEEK,order_time) as Week from customer_orders group by Datepart(WEEK,order_time)
order by Datepart(WEEK,order_time)

-----. Runner and Customer Experience------------------

--How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)


select 
Dateadd(Week,Datediff(Week,'2021-01-01',registration_date),'2021-01-01') as Week1,
count(runner_id) as signups
from runners
group by Dateadd(Week,Datediff(Week,'2021-01-01',registration_date),'2021-01-01')


--What was the average time in minutes it
--took for each runner to arrive at the Pizza Runner HQ to pickup the order?

select  runner_id,Avg(cast(SUBSTRING(duration,1,2) as INT)) as AvgMinutes from
runner_orders where cancellation= '' or cancellation is null
group by runner_id

--Is there any relationship between the
--number of pizzas and how long the order takes to prepare?

select * from runner_orders where order_id = 4

select order_id,count(order_id) as Noofpizzas,
Avg(timetooktopickupinmin) as AVGtimetooktopickupinmin from (select A.order_id,B.order_id as orderidb,A.order_time,B.pickup_time,cancellation,
cast (DATEDIFF(MINUTE,order_time,pickup_time) as Int) as timetooktopickupinmin
from customer_orders A left join runner_orders B
on A.order_id = B.order_id) As A where cancellation = '' or cancellation is null 
group by order_id

--What was the average distance travelled for each customer?

select customer_id,round(AVG(DistanceinKM),2) as DistanceTravelled from (select A.order_id,B.customer_id,distance,
cast(REPLACE(distance,'km','') as float) as DistanceinKM 

from runner_orders A left join customer_orders B on 
A.order_id = B.order_id where cancellation = '' or cancellation is null) as A
group by customer_id

--What was the difference between the longest and shortest delivery times for all orders?

select    Max(minutes) as longestdeliverytime,MIN(minutes) shortesteliverytime,

 Max(minutes) - MIN(minutes) as difference from (select B.order_id,B.order_time,A.pickup_time,
DATEDIFF(MINUTE,order_time,pickup_time) as minutes from runner_orders A
left join customer_orders B on A.order_id = B.order_id
where cancellation = '' or cancellation is null) As A

-----What was the average speed for each runner for each delivery and do you notice any trend for these values?

select order_id,runner_id,round (distance/Minutes,2) as speed from (select order_id,runner_id,cast(replace(distance,'km','') as float) as distance,cast(replace(replace(REPLACE(duration,'minutes',''),'mins',''),'minute','') as Int) as Minutes from runner_orders 

where cancellation = '' or cancellation is null) as A

---What is the successful delivery percentage for each runner?

select  runner_id,sum(case when cancellation = '' or cancellation is null then 1 else 0 end)*100/count(order_id) as successfuldeliverypercentage from runner_orders group by runner_id

----------C. Ingredient Optimisation-----------

--What are the standard ingredients for each pizza?

with cte as(

select A.pizza_id,A.pizza_name,trim(split_toppings.value) as standard from pizza_names A 
inner join pizza_recipes B on A.pizza_id = B.pizza_id 

cross apply 
	string_split(cast(B.toppings as varchar(50)),',') as split_toppings)

select pizza_id,pizza_name,standard,topping_name from cte 

inner join pizza_toppings C on cte.standard = C.topping_id

 ------------
 --What was the most commonly added extra?

select topping_name,extra,most_used from (select top 1 toppings.value as extra,count(trim(toppings.value))  as most_used from customer_orders A
 cross apply
	string_split(A.extras,',') as toppings
where len(extras)>=1
group by toppings.value
order by count(trim(toppings.value)) desc) as A
inner join pizza_toppings B on A.extra = B.topping_id

----
--What was the most common exclusion?
select topping_name,exclusion,most_used from (select top 1 toppings.value as exclusion,count(trim(toppings.value))  as most_used from customer_orders A
 cross apply
	string_split(A.exclusions,',') as toppings
where len(exclusions)>=1
group by toppings.value
order by count(trim(toppings.value)) desc) as A
inner join pizza_toppings B on A.exclusion = B.topping_id

------------
--Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

select  pizza_name +'  '+ case when exclusions = ''then '' else 'Exclude-' end  +exclusions + case when Extras = '' then '' else ',  Extra ' end  + Extras  as ordernames
from (select order_id,pizza_name,STRING_AGG(Exclusions,',') AS exclusions,
STRING_AGG(Extras,',') AS Extras
From
(
select order_id,cast(pizza_name as varchar(50)) as pizza_name,cast(Isnull(C.topping_name,'') as varchar(50)) as Exclusions,
cast(ISNULL(D.topping_name,'') as varchar(50)) as Extras
from (select order_id,A.pizza_id,B.pizza_name,A.exclusions,A.extras,
exclude_toppings.value as exclusion_topping,trim(extra_toppings.value) as extra_toppings
From customer_orders A
inner join  pizza_names B on A.pizza_id = B.pizza_id

cross apply 
		string_split(A.exclusions,',') as exclude_toppings
cross apply
		string_split(A.extras,',') as extra_toppings
) as data

left join pizza_toppings C on data.exclusion_topping = c.topping_id

left join pizza_toppings D on data.extra_toppings = D.topping_id) as A
group by order_id,pizza_name) as Orders

-------------
			--D. Pricing and Ratings--

--If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges
--for changes - how much money has Pizza Runner made so far if there are no delivery fees?

select * from customer_orders

select * from runner_orders

select 
runner_id,
sum(case when pizza_id =1 then 12 else 10 End) as Money_madeindollars
from customer_orders A
inner join runner_orders B  on A.order_id = B.order_id
where B.cancellation ='' or cancellation is null
group by runner_id

--What if there was an additional $1 charge for any pizza extras?
--Add cheese is $1 extra

select topping_id from pizza_toppings where cast(topping_name as varchar(50)) = 'Cheese'

select *,
case
when pizza_id=1 then 12
when pizza_id =1 and CHARINDEX((select cast(topping_id as varchar(10)) from pizza_toppings where cast(topping_name as varchar(50)) = 'Cheese'),extras)>=1 then 13
when pizza_id=2 then 10
when pizza_id =2 and CHARINDEX((select cast(topping_id as varchar(10)) from pizza_toppings where cast(topping_name as varchar(50)) = 'Cheese'),extras)>=1 then 11
end as TotalPizzacost
from customer_orders
---


--The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert 
--your own data for ratings for each successful customer order between 1 to 5.

create table customerratings
(
rating_id Int Identity(1,1) Primary Key,
customer_id varchar(50),
order_id varchar(30),
rating int
)

insert into  customerratings (customer_id,order_id,rating)
values
('101',1,3),
('101',2,4),
('102',3,2),
('103',4,5),
('104',5,4),
('105',7,5),
('102',8,4),
('104',10,5)
---------

--Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--customer_id
--order_id
--runner_id
--rating
--order_time
--pickup_time
--Time between order and pickup
--Delivery duration
--Average speed
--Total number of pizzas
select customer_id,order_id,runner_id,rating,order_time,pickup_time,
InMinutes as TimebetweenorderandpickupinMInutes,
DurationinMIns as [Delivery duration],DistanceinKM,
Avg(round(DistanceinKM * (60/DurationinMIns),2)) as AVGSpeed,
NoofPizzas as [Total number of pizzas]

from(select A.customer_id,A.order_id,runner_id,c.rating,order_time,pickup_time,

cast(DATEDIFF(MINUTE,order_time,pickup_time) as INT) as InMinutes,
cast(replace(replace(replace(duration,'minutes',''),'mins',''),'minute','') as float) as DurationinMIns,
cast(REPLACE(distance,'km','') as float) as DistanceinKM,
COUNT(pizza_id) as NoofPizzas
from customer_orders A
left join
 runner_orders B on A.order_id = B.order_id
left join customerratings C on A.order_id = C.order_id
where rating is not null
group by A.customer_id,A.order_id,runner_id,rating,order_time,pickup_time,duration,distance
)As Data
group by customer_id,order_id,runner_id,rating,order_time,pickup_time,
InMinutes,
DurationinMIns,DistanceinKM,NoofPizzas

--

--If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled -
--how much money does Pizza Runner have left over after these deliveries?

select runner_id,sum(cost+KMprice) as TotalPrice from (select 
A.order_id,
runner_id,
case when pizza_id = 1 then 12 else 10 End as cost,
cast(REPLACE(distance,'km','') as float) as DistanceinKM,
cast(REPLACE(distance,'km','') as float) * 0.30 as KMprice
from customer_orders A

inner join runner_orders B on A.order_id = B.order_id 

where B.cancellation = '' or B.cancellation is null
) as Data
 ----------