create database Project ;

use Project ;

select * from customer_purchase_data ;

Select CustomerID , count(distinct CustomerName)
from customer_purchase_data 
group by 1 ;

#Normalisation 
create table customers as
select row_number() over(order by purchasedate)+5000 as customerid , customername , country
from customer_purchase_data;

select* from customers ;

CREATE TABLE Products AS
(
	with cte as 
	(
		select distinct productname , productcategory , 
			dense_rank() over(partition by productcategory order by productName)+200 as pid 
			from customer_purchase_data
	)
	select row_number() over(order by productname)+200 as productid ,productname,productcategory 
	from cte
);

select * from products ;

CREATE TABLE Purchase AS 
with cte1 as
(
	SELECT row_number()over(order by purchasedate asc)+5000 as PurchaseID,PurchaseQuantity,PurchasePrice,PurchaseDate,
		cs.customerid,p.ProductID,TransactionID
	FROM customer_purchase_data c 
		join products p 
			on c.productname = p.productname 
		join customers cs 
			on c.customername = cs.customername  AND c.Country=cs.Country
)
select PurchaseID,  PurchaseQuantity, PurchasePrice, PurchaseDate,customerid, ProductID, TransactionID 
from cte1 ;

select * from purchase ;

-- build relationship in between tables 
ALTER TABLE customers
ADD PRIMARY KEY (CustomerID);

ALTER TABLE purchase
ADD PRIMARY KEY (purchaseID);

ALTER TABLE products
ADD PRIMARY KEY (productID);

ALTER TABLE purchase
ADD CONSTRAINT fk FOREIGN KEY (CustomerID)
REFERENCES customers(CustomerID);

ALTER TABLE purchase
ADD CONSTRAINT fk2 FOREIGN KEY (productID)
REFERENCES products(productID);

-- understanding schema datatypes , constraints 

describe customers ;
describe products ;
describe purchase ;

-- Checking null values 

select * from customer_purchase_data 
where TransactionID is null or 
CustomerId is null or
CustomerName is null or 
ProductID is null or 
ProductName is null or 
ProductCategory is null or
PurchaseQuantity is null or 
PurchasePrice is null or 
PurchaseDate is null or 
country is null ;

-- Checking Duplicate data 
Select 
TransactionID ,CustomerId ,CustomerName ,ProductID ,ProductName ,ProductCategory,PurchaseQuantity ,PurchasePrice ,PurchaseDate , country, count(*) 
from customer_purchase_data 
group by TransactionID ,CustomerId ,CustomerName ,ProductID ,ProductName ,ProductCategory,PurchaseQuantity ,PurchasePrice ,PurchaseDate , country
having count(*) > 1 ; 

-- changing data types of purchasedate from text to date  

alter table purchase 
modify PurchaseDate Date ;

-- Aggregation 

-- finding total purchase by each customer

SELECT 
    c.customerid,
    c.customername,
    SUM(p.PurchasePrice) AS total_purchases
FROM
    customers c
        JOIN
    purchase p ON c.customerid = p.customerid
GROUP BY c.customerid , c.customername
ORDER BY c.customerid;

-- total sales per product 

SELECT 
    pd.ProductId,
    pd.productname,
    SUM(pc.PurchasePrice) AS total_sales_per_product
FROM
    products AS pd
        JOIN
    Purchase AS pc ON pd.productid = pc.productid
GROUP BY pd.ProductId , pd.productname
ORDER BY pd.ProductId;

-- 5 top selling product

SELECT 
    pd.ProductId,
    pd.productname,
    round(SUM(pc.PurchasePrice),2) AS total_sales_per_product
FROM
    products AS pd
        JOIN
    Purchase AS pc ON pd.productid = pc.productid
GROUP BY pd.ProductId , pd.productname
ORDER BY total_sales_per_product desc
limit 5 ;

-- top selling product in each category 

WITH ranked_products AS (
    SELECT
        p.productid,
        p.productname,
        p.productcategory,
        SUM(pc.PurchaseQuantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY p.productcategory ORDER BY SUM(pc.PurchaseQuantity) desc) AS rank_in_category
    FROM
        products p
    JOIN
        Purchase pc ON p.productid = pc.productid
    GROUP BY
		p.productid,p.productname,p.productcategory
)
SELECT
    p.productcategory,
    rp.productname,
    rp.total_quantity_sold
FROM
    ranked_products as rp
JOIN
    products as p ON rp.productid =  p.productid
WHERE
    rp.rank_in_category = 1;
    
    
-- Total revenue by year 

SELECT 
    YEAR(PurchaseDate), Round(SUM(PurchasePrice),2) AS total_revenue
FROM
    purchase
GROUP BY YEAR(PurchaseDate)
ORDER BY YEAR(PurchaseDate); 


    

