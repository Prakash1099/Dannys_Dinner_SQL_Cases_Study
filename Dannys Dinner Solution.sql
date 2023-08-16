--

--------------------------------------------------------------------------------------------

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) 
--     they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

--------------------------------------------------------------------------------------------
USE sql_challenges;
--1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id
	,  sum(m.price) total_amount
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id;

/*
Result:
____________________________
|customer_id | total_amount |
|	A    	 |	76			|
|	B   	 |	74			|
|	C    	 |	36	   		|
-----------------------------
*/

--2. How many days has each customer visited the restaurant?

SELECT customer_id	
	,  count(customer_id) noOfDaysVisited
FROM 
	(SELECT DISTINCT customer_id
		,  order_date
	 FROM sales) sales
GROUP BY customer_id;

/* Result
_____________________________________
| customer_id  |  no_of_days_visited |
|			A  |	4				 |
|			B  |	6				 |
|			C  |	2				 |
|______________|_____________________|

*/


--3. What was the first item from the menu purchased by each customer?

WITH first_item(customer_id, product_name, order_date, rnk) as(
SELECT DISTINCT s.customer_id
	,  m.product_name
	,  s.order_date
	,  RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
)

SELECT customer_id	
	,  STRING_AGG(product_name, ',') AS product
FROM first_item
WHERE rnk = 1
GROUP BY customer_id


/* Result
_________________________
|customer_id |  product_id|
|		A	| sushi,curry|
|		B	|	curry	 |
|		C	|	ramen	 |
|___________|____________|

*/

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SElECT TOP 1 s.product_id
	,  m.product_name
	,  COUNT(s.product_id) AS total_numbers
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY count(s.product_id) DESC;


/*ANSWER
___________________________________________
|product_id	| product_name | total_numbers |
|     3		|	ramen	   |	8		   |
|___________|______________|_______________|
*/


-- 5. Which item was the most popular for each customer?
WITH rnk(customer_id, product_name, product_id, cnt, rnk) AS 
(
	SELECT s.customer_id
		,  m.product_name
		,  s.product_id
		,  COUNT(s.product_id) cnt
		,  RANK() OVER(PARTITION BY  s.customer_id  ORDER BY COUNT(s.product_id) DESC) AS rnk
	FROM sales s
	JOIN menu m
	ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name, s.product_id
)
SELECT customer_id
	,  STRING_AGG(product_name, ',') fav_item
FROM rnk
WHERE rnk = 1
GROUP BY customer_id;


/* Result
_______________________________
|customer_id |	product_name   |
|	A		 |		ramen	   |
|	B		 |curry,ramen,sushi|
|	C		 |		ramen	   |
|____________|_________________|  
*/



-- 6. Which item was purchased first by the customer after they became a member?

WITH members_orders(customer_id, order_date, product_name, rnk) AS(
	SELECT s.customer_id
		,  s.order_date
		,  m.product_name
		,  RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) rnk
	FROM sales s
	JOIN menu m
		ON s.product_id = m.product_id
	JOIN members mem
		ON mem.customer_id = s.customer_id
		AND s.order_date >= mem.join_date
)

SELECT customer_id
	,  STRING_AGG(product_name, ',') first_order  -- Just in case if a customer baught multiple items on same day.
FROM members_orders
WHERE rnk = 1
GROUP BY customer_id;


/*Result  NOTE: customer C is not a member 
____________________________
|customer_id | product_name|
|	A		|	curry	   |
|	B		|	sushi	   |
|___________|______________|
*/


-- 7. Which item was purchased just before the customer became a member?

WITH before_member(customer_id, order_date, product_name, rnk) 
AS (
	SELECT s.customer_id
		,  s.order_date
		,  m.product_name
		,  RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) 
	FROM sales s
	JOIN menu m
		ON m.product_id = s.product_id
	JOIN members mem
		ON mem.customer_id = s.customer_id
		AND s.order_date < mem.join_date
)
SELECT customer_id
	,  STRING_AGG(product_name, ',') product_name
FROM before_member
WHERE rnk = 1
GROUP BY customer_id;


/*Result
|---------------------------|
|customer_id| product_name	|
|	A		|  sushi,curry	|
|	B		|	sushi		|
|-----------|---------------|
*/


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id
	,  COUNT(m.product_name) AS total_items
	,  SUM(m.price) AS total_amount
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
JOIN members mem 
	ON mem.customer_id = s.customer_id
	AND s.order_date < mem.join_date
GROUP BY s.customer_id;


/* Result
_________________________________________
|customer_id | total_items |total_amount|
|	A		|	2		  |	25			|
|	B		|	3		  |	40			|
-----------------------------------------
*/

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id
	,   SUM(case WHEN m.product_name = 'sushi'
			THEN m.price * 20 
			ELSE m.price * 10  END) AS total_points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id 
GROUP BY s.customer_id


/* Result
_____________________
|customer_id| points |
|	A		|  860	 |
|	B		|  940	 |
|	C		|  360	 |
|--------------------|
*/

-- 10. In the first week after a customer joins the program (including their join date) 
--		they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id
	,  SUM(CASE WHEN s.order_date BETWEEN mem.join_date AND  DATEADD(day, 6, mem.join_date)
				THEN m.price*20
				ELSE m.price*10 END) AS total_points
FROM sales s
JOIN menu m
	ON m.product_id = s.product_id
JOIN members mem
	ON mem.customer_id = s.customer_id
WHERE DATEPART(month,s.order_date) = 1
GROUP BY s.customer_id


/* Result
_____________________
|customer_id| points |
|	A		|	1270 |
|	B		|	720  |
|---------------------
*/




