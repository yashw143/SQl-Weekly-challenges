select * from sales

select * from menu

---------Case Study Questions---------

--What is the total amount each customer spent at the restaurant?

select customer_id as Customer,SUM(Price) as Total_Amountspent from sales A

inner join menu B on A.product_id = B.product_id	group by customer_id


---How many days has each customer visited the restaurant?

select customer_id as Customer,order_date,count(DATEPART(Day,order_date)) as NoofTimes_visited from sales A

inner join menu B on A.product_id = B.product_id	group by customer_id,order_date

--What was the first item from the menu purchased by each customer?

select  customer_id,product_name from (select  A.customer_id,dense_Rank() over(partition by A.customer_id order by Day(order_date)) as Rank,product_name  from sales A

inner join menu B on A.product_id = B.product_id )As A where Rank =1

----What is the most purchased item on the menu and how many times was it purchased by all customers?

with MostPurchased as(

select product_name,COUNT(product_name) as Totapurchased from sales A

inner join menu B on A.product_id = B.product_id 

group by product_name  
d
)

select  customer_id,count(A.product_id) as Nooftimespurchased  from sales A

inner join menu B on A.product_id = B.product_id

where product_name = (select top 1 product_name from MostPurchased group by product_name order by count(product_name) desc)

group by customer_id

---Which item was the most popular for each customer?


WITH ProductCounts AS (
    SELECT 
        customer_id,
        A.product_id,
        product_name,
        COUNT(*) AS purchase_count
    FROM 
        sales A
		inner join menu B on A.product_id = B.product_id
    GROUP BY 
        customer_id, A.product_id, product_name
),
RankedProducts AS (
    SELECT 
        customer_id,
        product_id,
        product_name,
        purchase_count,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY purchase_count DESC) AS rank
    FROM 
        ProductCounts
)

SELECT 
    customer_id,
    product_id,
    product_name,
    purchase_count
FROM 
    RankedProducts
WHERE 
    rank = 1;
----------
--Which item was purchased first by the customer after they became a member?


with CTE as (
select A.customer_id,A.order_date,A.product_id,B.product_name,B.price,C.join_date,
case when order_date >join_date then 'Orders After Joining' else 'Orders before joining' End as Category


from sales A
inner join menu B on A.product_id = B.product_id
inner join members  C on A.customer_id = C.customer_id ),

FirstpurchasedItems As(
select *,RANK() over(partition by customer_id order by order_date)  as Rank from CTE where Category = 'Orders After Joining')

select customer_id,product_name from FirstpurchasedItems where Rank = 1
-------

---Which item was purchased just before the customer became a member?

with CTE as (
select A.customer_id,A.order_date,A.product_id,B.product_name,B.price,C.join_date,
case when order_date >join_date then 'Orders After Joining' else 'Orders before joining' End as Category


from sales A
inner join menu B on A.product_id = B.product_id
inner join members  C on A.customer_id = C.customer_id ),

FirstpurchasedItems As(
select *,RANK() over(partition by customer_id order by order_date desc)  as Rank from CTE where Category = 'Orders before joining')

--select * from FirstpurchasedItems where Rank = 1

select customer_id,product_name from FirstpurchasedItems where Rank = 1

----What is the total items and amount spent for each member before they became a member?

select count(product_id) as TotalItems_Purchased,sum(price) as Total_price from (select A.customer_id,A.order_date,A.product_id,B.price,B.product_name,
case when order_date >join_date then 'Orders After Joining' else 'Orders before joining' End as Category
from sales A
inner join menu B on A.product_id = B.product_id
inner join members  C on A.customer_id = C.customer_id ) as A where Category = 'Orders before joining'

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have

select customer_id,
sum(case when product_name = 'sushi' then price*20 else price *10 end) TotalPoints 
from sales A
inner join menu B on A.product_id = B.product_id group by customer_id

----------

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
--- how many points do customer A and B have at the end of January?
select A.customer_id,
sum(case when product_name = 'sushi' then price*20 

		when order_date>=join_date then  price *20
		
		else price * 10 end) TotalPoints 
from sales A
inner join menu B on A.product_id = B.product_id
inner join members  C on A.customer_id = C.customer_id  where MONTH(A.order_date)<2 group by A.customer_id 
-------------