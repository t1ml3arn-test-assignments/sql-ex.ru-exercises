## 77

Определить дни, когда было выполнено максимальное число рейсов из
Ростова ('Rostov'). Вывод: число рейсов, дата.

```sql
with q as (
select
  count(distinct t.trip_no) as trip_count
  , pt.date
from trip t, pass_in_trip pt
where t.trip_no=pt.trip_no
      and town_from='Rostov'
group by date
)
select
  trip_count, date
  from q
  where trip_count=(select max(trip_count) from q)
;
```

## 78

Для каждого сражения определить первый и последний день
месяца,
в котором оно состоялось.
Вывод: сражение, первый день месяца, последний
день месяца.

Замечание: даты представить без времени в формате "yyyy-mm-dd".

```sql
select
  name
  -- get previous month, then get its end, then add a day to it
  -- and you get first day of current month
  , DATEADD(day, 1, EOMONTH(DATEADD(month, -1, date))) first_day
  , EOMONTH(date) last_day
from battles;
```

## 79

Определить пассажиров, которые больше других времени провели в полетах.
Вывод: имя пассажира, общее время в минутах, проведенное в полетах

- Получить время полета для каждого пассажира
- Выбрать тех, кто налетал максимальное время

```sql
with pass_time as (
  select
    pt.id_psg
    , SUM(
      CASE when time_out >= time_in
          then datediff(mi, time_out, time_in) + 1440
          else datediff(mi,time_out, time_in)
      end
    ) as trip_time
  from pass_in_trip pt
  join trip t on t.trip_no=pt.trip_no
  group by id_psg
)
select p.name, trip_time
from pass_time pt join passenger p on pt.id_psg=p.id_psg
-- with ALL query takes MORE steps
-- where trip_time>=ALL(select trip_time from pass_time )
-- here using MAX is more efficient than ALL
where trip_time=(select max(trip_time) from pass_time )
;
```

## 80

Найти производителей компьютерной техники, у которых нет моделей ПК, не представленных в таблице PC.

```sql
select distinct maker from product
where maker not in (
  -- makers who has PC models which not in PC table
  select maker from product
  where type='pc' and model not in (select model from pc)
);

-- next solution requieres less operations
select maker from product
except
select maker from product
  where type='pc' and model not in (select model from pc);
```

## 81

Из таблицы `Outcome` получить все записи за тот месяц (месяцы), с учетом года, в котором суммарное значение расхода (out) было максимальным.

- Из даты получить дату в виде год-месяц

```sql
with q as(
  select
    *
    , sum(out) over(
        partition by year(date), month(date)
    ) as month_out
  from Outcome o
)
select code, point, date, out from q
where month_out=(select max(month_out) from q)
;
```

## 82

В наборе записей из таблицы `PC`, отсортированном по столбцу code (по возрастанию) найти среднее значение цены для каждой шестерки подряд идущих ПК.
Вывод: значение code, которое является первым в наборе из шести строк, среднее значение цены в наборе

```sql
with q as (
  select
    code
    , avg(price) over(
        order by code DESC
        rows between 5 preceding and current row
    ) as avg_price
    , row_number() over(order by code ASC) as rownum
  from pc
)
select
  code, avg_price
from q
where rownum <= (select max(rownum)-5 from q)
;

-- costs a little bit less
with tmp as (
  select
    code
    , price
    , row_number() over(order by code ASC) as rownum
  from pc
)
select
  code
  , (select avg(price) from tmp where rownum between a.rownum and a.rownum+5
  ) as avg
from tmp a
where rownum <= (select max(rownum)-5 from q)
```

## 83

Определить названия всех кораблей из таблицы `Ships`, которые удовлетворяют, по крайней мере, комбинации любых четырёх критериев из следующего списка:
numGuns = 8
bore = 15
displacement = 32000
type = bb
launched = 1915
class=Kongo
country=USA

```sql
with q as (
  select
    name
    , case numGuns when 8 then 1 else 0 end as a
    , case bore when 15 then 1 else 0 end as c
    , case displacement when 32000 then 1 else 0 end as b
    , case type when 'bb' then 1 else 0 end as d
    , case launched when 1915 then 1 else 0 end as e
    , case c.class when 'Kongo' then 1 else 0 end as f
    , case country when 'USA' then 1 else 0 end as g
  from ships s, classes c where s.class=c.class
)
select name from q where (a+b+c+d+e+f+g)>=4
```