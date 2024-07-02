-- 1. What canva size is often the most expensive?

select c.*, p.regular_price from canvas_size c
join product_size p on c.size_id = p.size_id::bigint
where p.size_id ~ '^\d+$'
order by regular_price desc
limit 1

-- 2. Delete duplicate records from product_size.

with cte as
	(select *, row_number() over(partition by work_id order by work_id) as rn 
	from product_size)
delete from product_size
where (work_id) in (select work_id from cte where rn > 1);

-- 3. Does museums exist without any painting?

select w.work_id, m.museum_id, m.name from work w
left join museum m on w.museum_id = m.museum_id
where w.museum_id is null

-- 4. Identify the museums which are open on both Sunday and Monday. 
-- Display museum name, city.

-- 1st Aprroach

select m.name, m.city from museum_hours as mh
join museum as m on mh.museum_id = m.museum_id
where day in ('Sunday', 'Monday')
group by m.museum_id, m.name, m.city
having count(distinct mh.day) = 2

-- 2nd Aprroach

select m.name,m.city from museum m
join museum_hours mh1 on m.museum_id = mh1.museum_id
join museum_hours mh2 on m.museum_id = mh2.museum_id
where mh1.day = 'Sunday' and mh2.day = 'Monday'

-- 5. Which museum is open for the longest during a day.
-- Dispay museum name, state and hours open and which day?

select * from (
	select m.name, m.state,
	to_timestamp(close, 'HH:MI PM') - to_timestamp(open, 'HH:MI AM') hours_open, mh.day, 
	dense_rank() over(order by (to_timestamp(close, 'HH:MI PM') - to_timestamp(open, 'HH:MI AM')) desc
	) as rnk
	from museum_hours mh
	join museum m on m.museum_id = mh.museum_id) x
	where x.rnk = 1

-- 6. Display the country with most no of museums and its corresponding cities
-- with most no of museums. 
-- Output 2 seperate columns to mention the country and cities. 
-- If there are multiple value, seperate them with comma.

with cte_country as (
	select country, count(*) as country_count from museum
	group by country
	order by country_count desc
	limit 1
	),
	cte_city as (
	select country, city, count(*) as city_count from museum
	group by city, country
	),
	cte_top_cities as (
	select city from cte_city
	where country = (select country from cte_country)
	order by city_count desc
	)
	
select (select country from cte_country), string_agg(city, ', ') as cities_with_most_museums 
	from cte_top_cities

-- 7. Identify the artist and the museum where the most expensive 
-- and least expensive painting is placed. Display the artist name,
-- sale_price, painting name, museum name, museum city and canvas label

with cte as (
	select *, rank() over(order by sale_price desc) as rnk,
	rank() over(order by sale_price) as rnk_asc 
	from product_size
	)

(select distinct w.name as painting_name, m.name as museum_name,
	c.label, cte.sale_price, a.full_name, m.city from work w 
	join cte on w.work_id = cte.work_id
	join artist a on a.artist_id = w.artist_id
	join museum m on m.museum_id = w.museum_id
	join canvas_size c on c.size_id = cte.size_id::numeric
	where cte.rnk = 1 or cte.rnk_asc = 1
	limit 2)

-- 8. Which artist has the most no of Portraits paintings outside USA?.
-- Display artist name, no of paintings and the artist nationality.

select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;

-- 9. Name the artist and their details who has the largest amount of paintings?

select a.artist_id, a.full_name, a.nationality, a.birth, 
count(*) as paintings_count 
from work w
join artist a on w.artist_id = a.artist_id
group by a.artist_id, a.full_name, a.nationality, a.birth
order by paintings_count desc
limit 1

-- 10.  Who are the top 5 most popular artist? 
-- (Popularity is defined based on most no of paintings done by an artist)

select full_name, nationality, work_count from
	(select w.artist_id, a.full_name, a.nationality, count(w.work_id) as work_count from work w
	join artist a on w.artist_id = a.artist_id
	group by w.artist_id, a.full_name, a.nationality
	order by work_count desc)
limit 5















