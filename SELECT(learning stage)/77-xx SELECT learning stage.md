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
