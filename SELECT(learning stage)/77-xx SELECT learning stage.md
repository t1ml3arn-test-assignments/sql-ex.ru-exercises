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

## 84

Для каждой компании подсчитать количество перевезенных пассажиров (если они были в этом месяце) по декадам апреля 2003. При этом учитывать только дату вылета.
Вывод: название компании, количество пассажиров за каждую декаду

```sql
-- первый монстр
-- cost	0.15383219718933
-- operations	51
with q as (
  select
    t.id_comp
    , case
        when day(date) < 11 then 1
        when day(date) < 21 then 2
        when day(date) < 32 then 3
    end as decade
    , count(pt.id_psg) as psg_count
  from pass_in_trip pt
    join trip t on t.trip_no=pt.trip_no
  where year(date)=2003 and month(date)=4
  group by t.id_comp,
    case
      when day(date) < 11 then 1
      when day(date) < 21 then 2
      when day(date) < 32 then 3
    end
)
select
  distinct
  name
  , coalesce((select top 1 psg_count from q where decade=1 and q.id_comp=c.id_comp), 0) as '1'
  , coalesce((select top 1 psg_count from q where decade=2 and q.id_comp=c.id_comp), 0) as '2'
  , coalesce((select top 1 psg_count from q where decade=3 and q.id_comp=c.id_comp), 0) as '3'
from q join company c on c.id_comp=q.id_comp

-- MORE efficient solution
select
  c.name
  , SUM(iif(day(date)<11, 1, 0)) as d1
  , SUM(iif(day(date)<21 and day(date)>10, 1, 0)) as d2
  , SUM(iif(day(date)>20, 1, 0)) as d3
from pass_in_trip pt
  join trip t on pt.trip_no=t.trip_no
  join company c on c.id_comp=t.id_comp
where year(pt.date)=2003 and month(pt.date)=4
group by name
```

## 85

Найти производителей, которые выпускают только принтеры или только PC.
При этом искомые производители PC должны выпускать не менее 3 моделей.

```sql
-- only printer makers
select maker from product where type='printer'
except
select maker from product where type!='printer'
union (
  -- only PC makers with at least 3 models
  select maker from product where type='pc'
  group by maker
  having count(model) >= 3
  except
  select maker from product where type!='pc'
)
```

## 86

Для каждого производителя перечислить в алфавитном порядке с разделителем "/" все типы выпускаемой им продукции.
Вывод: `maker`, `список` типов продукции

```sql
with m as (
  select
    maker
    , max(iif(type='laptop', 'Laptop', char(20))) as lt
    , max(iif(type='pc',  'PC', char(20))) as pc
    , max(iif(type='printer', 'Printer', char(20))) as pr
  from product
  group by maker
)
select
  maker
  , replace(
      replace(
        replace(lt + '/' + pc + '/' + pr, char(20)+'/', ''), '/'+char(20), ''
    ), char(20), ''
  )
  as types
from m
```

## 87

Считая, что пункт самого первого вылета пассажира является местом жительства, найти не москвичей, которые прилетали в Москву более одного раза.
Вывод: имя пассажира, количество полетов в Москву.

```sql
with t as (
  -- passangers and their trips
  select pit.date, id_psg, t.*
  from pass_in_trip pit
  join trip t on pit.trip_no=t.trip_no
)
, fo as (
  -- get first fly date+time
  select id_psg, min(date+time_out) as date_out
  from t group by id_psg
)
, nm as (
  -- those who are not from Moscow
  select fo.id_psg
  from fo join t on fo.date_out=(t.date+t.time_out)
  where town_from!='Moscow'
)
select
  p.name, count(*)
from t join passenger p on t.id_psg=p.id_psg
where town_to='Moscow'
      and t.id_psg in (select * from nm)
group by t.id_psg, p.name
having count(*) > 1
```

## 88

Среди тех, кто пользуется услугами только одной компании, определить имена разных пассажиров, летавших чаще других.
Вывести: имя пассажира, число полетов и название компании.

```sql
with psc as (
  select
    pit.id_psg
    , count(pit.trip_no) as trip_count
    , max(t.id_comp) as id_comp
  from pass_in_trip pit
    join trip t on pit.trip_no=t.trip_no
  group by pit.id_psg
  having count(distinct t.id_comp) = 1
)
select
  p.name, p1.trip_count, c.name
from psc p1
  join company c on p1.id_comp = c.id_comp
  join passenger p on p1.id_psg = p.id_psg
where p1.trip_count = (select max(trip_count) from psc)

```

4 exercises left before moving to the next file!