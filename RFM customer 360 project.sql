with customer_statistics as(
select top 100 customerId, 
datediff(day, max(purchase_date),'2022-09-01') as recency, 
round(1.0*count(*)/datediff(year,r.created_date,'2022'),2) as frequency, 
sum(gmv)/datediff(year,r.created_date,'2022') as monetary 
from customer_transaction t
join Customer_Registered r on t.customerid = r.id
group by CustomerID, r.created_date),

customer_rn as(
select *,
row_number() over (order by recency asc) as rn_recency, 
row_number() over (order by frequency asc) as rn_frequency,
row_number() over (order by monetary asc) as rn_monetary
from customer_statistics),
customer_value as(
select *,
case when recency >= min(recency) and recency < (select recency from customer_rn where rn_recency = (select max(rn_recency)*0.25 from customer_rn)) then 1
	when recency >= (select recency from customer_rn where rn_recency = (select max(rn_recency)*0.25 from customer_rn))
		and recency < (select recency from customer_rn where rn_recency = (select max(rn_recency)*0.5 from customer_rn)) then 2
	when recency >= (select recency from customer_rn where rn_recency = (select max(rn_recency)*0.5 from customer_rn))
		and recency < (select recency from customer_rn where rn_recency = (select max(rn_recency)*0.75 from customer_rn)) then 3
	else 4 end R,

case when frequency >= min(frequency) and frequency < (select frequency from customer_rn where rn_frequency = (select max(rn_frequency)*0.25 from customer_rn)) then 1
	when frequency >= (select frequency from customer_rn where rn_frequency = (select max(rn_frequency)*0.25 from customer_rn))
		and frequency < (select frequency from customer_rn where rn_frequency = (select max(rn_frequency)*0.5 from customer_rn)) then 2
	when frequency >= (select frequency from customer_rn where rn_frequency = (select max(rn_frequency)*0.5 from customer_rn))
		and frequency < (select frequency from customer_rn where rn_frequency = (select max(rn_frequency)*0.75 from customer_rn)) then 3
	else 4 end F,
	
case when monetary >= min(monetary) and monetary < (select monetary from customer_rn where rn_monetary = (select max(rn_monetary)*0.25 from customer_rn)) then 1
	when monetary >= (select monetary from customer_rn where rn_monetary = (select max(rn_monetary)*0.25 from customer_rn))
		and monetary < (select monetary from customer_rn where rn_monetary = (select max(rn_monetary)*0.5 from customer_rn)) then 2
	when monetary >= (select monetary from customer_rn where rn_monetary = (select max(rn_monetary)*0.5 from customer_rn))
		and monetary < (select monetary from customer_rn where rn_monetary = (select max(rn_monetary)*0.75 from customer_rn)) then 3
	else 4 end M
from customer_rn
group by customerid, recency, frequency, monetary, rn_recency, rn_frequency, rn_monetary)
select *, concat(r, f, m) as customer_grade,
case 
	when R >= 3 and F >= 3 and M >= 3 then 'Khách hàng VIP'
	when R >= 2 and F >= 3 then 'Khách hàng thân thiết'
	when R >= 3 then 'Khách hàng mới đến'
	when R = 1 and F <= 2 and M <= 2 then 'Khách hàng vãng lai'
else 'Khác' end as segmentation
from customer_value

