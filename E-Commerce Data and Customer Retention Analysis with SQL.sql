

/*
		E-COMMERCE DATA AND CUSTOMER RETENTİON ANALYSİS WİTH SQL

	You have to create a database and import into the given e_commerce_data.csv file.
	Bir veritabanı oluşturmanız ve verilen e_commerce_data.csv dosyasına aktarmanız gerekir
*/
CREATE DATABASE ecommerce;

USE ecommerce;

--	1.	Find the top 3 customers who have the maximum count of orders.
--	1.	En fazla sipariş sayısına sahip ilk 3 müşteriyi bulun

SELECT	TOP 3 Cust_ID, Customer_Name, COUNT (DISTINCT Ord_ID) AS count_orders
FROM		e_commerce_data
GROUP BY	Cust_ID, Customer_Name
ORDER BY	count_orders DESC


--	2.	Find the customer whose order took the maximum time to get shipping.
--	2.	Siparişinin kargoya verilmesi en fazla zaman alan müşteriyi bulun

SELECT	Ord_ID, Customer_Name, DaysTakenForShipping
FROM	e_commerce_data
WHERE	DaysTakenForShipping = (SELECT	MAX(DaysTakenForShipping)
								FROM	e_commerce_data
								)


--	3.	Count the total number of unique customers in January and how many of them came back again in the each one months of 2011.
--	3.	Ocak ayındaki toplam benzersiz müşteri sayısını ve bunların kaçının 2011'in her bir ayında tekrar geldiğini sayın.

--	Ocak 2011'de sipariş veren benzersiz müşteri sayısı
SELECT	COUNT (DISTINCT Cust_ID) AS Unique_Customers_January
FROM	e_commerce_data
WHERE	YEAR(Order_Date) = 2011
		AND MONTH(Order_Date ) = 1

--	 Ocak ayında sipariş verenlerin, 2011 yılı boyunca her ay sipariş veren müşterilerinin sayısı
SELECT COUNT(DISTINCT Cust_ID) AS Returning_Customers
FROM (
	SELECT	Cust_ID
	FROM	e_commerce_data
	WHERE	YEAR(Order_Date) = 2011
	GROUP BY Cust_ID
	HAVING	COUNT(DISTINCT MONTH(Order_Date)) = 12
) AS cust;

--	Ocak ayında sipariş veren benzersiz müşterilerin her ay için bu müşteri sayısı
WITH T1 AS (
		SELECT	Cust_ID
		FROM	e_commerce_data
		WHERE	YEAR(Order_Date) = 2011
		AND		MONTH(Order_Date ) = 1
)
SELECT	MONTH(Order_Date) AS ORD_MONTH, COUNT(DISTINCT A.Cust_ID) CNT_CUST
FROM	e_commerce_data A, T1 
WHERE	A.Cust_ID = T1.Cust_ID
		AND	YEAR(Order_Date) = 2011
GROUP BY MONTH(Order_Date)


--	4.	Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID.
--	4.	Her kullanıcı için ilk satın alma ile üçüncü satın alma arasında geçen süreyi Müşteri Kimliğine göre artan sırada döndüren bir sorgu yazın

WITH T1 AS (
			SELECT	Cust_ID, Ord_ID, Order_Date,
					DENSE_RANK() OVER(PARTITION BY Cust_ID ORDER BY Order_Date) AS Order_Number
			FROM	e_commerce_data
), T2 AS (
			SELECT	Cust_ID, Ord_ID, Order_Date,
					DENSE_RANK() OVER(PARTITION BY Cust_ID ORDER BY Order_Date) AS Order_Number
			FROM	e_commerce_data
)
SELECT	DISTINCT T1.Cust_ID,
		DATEDIFF(day, T1.Order_Date, T2.Order_Date) AS Days_Between_First_And_Third_Order
FROM	T1 INNER JOIN T2
		ON T1.Cust_ID = T2.Cust_ID
WHERE	T1.Order_Number = 1 AND T2.Order_Number = 3
ORDER BY 1


--	5.	Write a query that returns customers who purchased both product 11 and product 14, as well as the ratio of these products to the total number of products purchased by the customer.
--	5.	Hem 11. ürünü hem de 14. ürünü satın alan müşterileri ve bu ürünlerin müşteri tarafından satın alınan toplam ürün sayısına oranını döndüren bir sorgu yazın

	
WITH T1 AS (
SELECT	Cust_ID,
		SUM(Order_Quantity) total_orders,
		SUM(CASE WHEN Prod_ID = 'Prod_11' THEN Order_Quantity ELSE 0 END) P11_quantity,
		SUM(CASE WHEN Prod_ID = 'Prod_14' THEN Order_Quantity  ELSE 0 END) P14_quantity
FROM e_commerce_data
GROUP BY
		Cust_ID
HAVING
		SUM(CASE WHEN Prod_ID = 'Prod_11' THEN 1 END) IS NOT NULL
		AND
		SUM(CASE WHEN Prod_ID = 'Prod_14' THEN 1 END) IS NOT NULL
)
SELECT	*, CAST(1.0*P11_quantity/total_orders AS DECIMAL(3,2))  AS P11_RATIO ,
		CAST(1.0*P14_quantity/total_orders AS DECIMAL(3,2))AS P14_RATIO
FROM T1

--
--	Customer Segmentation (Müşteri Segmentasyonu)
--	Categorize customers based on their frequency of visits (Müşterileri ziyaret sıklıklarına göre kategorize edin)


--	1.	Create a “view” that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)
--	1.	Müşterilerin ziyaret günlüklerini aylık olarak tutan bir "görünüm" oluşturun. (Her günlük için üç alan tutulur: Cust_id, Yıl, Ay)

CREATE VIEW Customer_Monthly_Visits AS
SELECT	Cust_ID, YEAR(Order_Date) AS [Year], MONTH(Order_Date) AS [Month]
FROM	e_commerce_data
GROUP BY Cust_ID, YEAR(Order_Date), MONTH(Order_Date);


--	2.	Create a “view” that keeps the number of monthly visits by users. (Show separately all months from the beginning business)
--	2.	Kullanıcıların aylık ziyaret sayısını tutan bir "görünüm" oluşturun. (Başlangıç işinden itibaren tüm ayları ayrı ayrı gösterin)

CREATE VIEW Monthly_Visit_Counts AS
SELECT	Cust_ID, YEAR(Order_Date) AS [Year], MONTH(Order_Date) AS [Month], COUNT(DISTINCT Ord_ID) AS VisitCount
FROM	e_commerce_data
GROUP BY YEAR(Order_Date), MONTH(Order_Date), Cust_ID


--	3.	For each visit of customers, create the previous or next month of the visit as a separate column
--	3.	Müşterilerin her ziyareti için, ziyaretin bir önceki veya "bir sonraki" ayını ayrı bir sütun olarak oluşturun.

CREATE VIEW Customer_Next_Order_Month AS
SELECT	Cust_ID, [Year], [Month],
		LEAD(Month) OVER (PARTITION BY Cust_ID ORDER BY [Year], [Month]) AS Next_Month
FROM Customer_Monthly_Visits


--	4.	Calculate the monthly time gap between two consecutive visits by each customer
--	4.	Her bir müşteri tarafından yapılan iki ardışık ziyaret arasındaki aylık zaman aralığını hesaplayın

CREATE VIEW Monthly_TimeGaps AS
SELECT	A.Cust_ID, A.[Year], A.[Month], A.Next_Month,
		DATEDIFF(MONTH, DATEFROMPARTS(A.[Year], A.[Month], 1), DATEFROMPARTS(LEAD(A.[Year]) OVER (PARTITION BY A.Cust_ID ORDER BY A.[Year], A.[Month]), A.Next_Month, 1)) AS Time_Gap
FROM	Customer_Next_Order_Month A


--	5.	Categorise customers using average time gaps. Choose the most fitted labeling model for you.
--	5.	Ortalama zaman aralıklarını kullanarak müşterileri kategorize edin. Sizin için en uygun etiketleme modelini seçin

SELECT	Cust_ID,
		CASE
			WHEN AVG(Time_Gap) > 4 THEN 'Irregular'
			WHEN AVG(Time_Gap) BETWEEN 0 AND 4 THEN 'Regular'
			WHEN AVG(Time_Gap) IS NULL THEN 'Churn'
		END cust_segment
FROM Monthly_TimeGaps
GROUP BY Cust_ID


--	Month-Wise Retention Rate (Ay Bazında Elde Tutma Oranı)
--	Find month-by-month customer retention ratei since the start of the business
--	İşletmenin başlangıcından bu yana ay bazında müşteri tutma oranını bulun

--	1.	Find the number of customers retained month-wise. (You can use time gaps)
--	1.	Ay bazında elde tutulan müşteri sayısını bulun. (Zaman aralıklarını kullanabilirsiniz)
-- Elde tutulan müşteri sayısı(Önceki ay satın alam işlemi yapıp mevcut ayda da satın alma işlemi yapanlar)

CREATE VIEW Monthly_Customer_Counts AS
SELECT	YEAR(Order_Date) AS [Year],				-- Başlangıcından bu yana her ay satın alma işlemi yapan müşteri sayısı
		MONTH(Order_Date) AS [Month],
		COUNT(DISTINCT Cust_ID) AS Total_Customers
FROM e_commerce_data
GROUP BY YEAR(Order_Date), MONTH(Order_Date)


CREATE VIEW Monthly_Retained_Customer AS
SELECT [Year],[Month], count (DISTINCT Cust_ID) Retained_Cust				-- Ay bazında elde tutulan müşteri sayısı
FROM Monthly_TimeGaps
WHERE Time_Gap = 1
GROUP BY [Year],[Month]


--	2.	Calculate the month-wise retention rate.
--	2.	Ay bazında elde tutma oranını hesaplayın

CREATE VIEW Total_Cust_Retained_Cust AS
SELECT	A.[Year], A.[Month], A.Total_Customers,
		LAG(B.Retained_Cust) OVER (ORDER BY A.[Year], A.[Month]) AS Retained_Cust
FROM	Monthly_Customer_Counts A
		LEFT JOIN Monthly_Retained_Customer B
		ON A.[Year] = B.[Year] AND A.[Month] = B.[Month];

SELECT	[Year], [Month], FORMAT(ROUND(1.0 * Retained_Cust / Total_Customers, 2), 'P', 'en-us') AS Retention_Rate
FROM	Total_Cust_Retained_Cust

