## 62

Посчитать остаток денежных средств на всех пунктах приема **на начало дня 15/04/01** для базы данных с отчетностью не чаще одного раза в день.

```sql
select
  sum(coalesce(inc,0))-sum(coalesce(out,0)) as remain
  from income_o i
  full join outcome_o o on i.date=o.date and i.point=o.point
  where coalesce(i.date,o.date) < '2001-04-15'
```

|  remain   |
|-----------|
| 6575.9600 |

## 63

Определить имена разных пассажиров, когда-либо летевших на одном и том же месте более одного раза.

```sql
select name from passenger
where id_psg in (
  select
    p.id_psg
    from pass_in_trip p
    group by p.id_psg, p.place
    having count(*) > 1
)
```

|      name      |
|----------------|
| Bruce Willis   |
| Mullah Omar    |
| Nikole Kidman  |

## 64

Используя таблицы `Income` и `Outcome`, для каждого пункта приема определить дни, когда был приход, но не было расхода и наоборот.
Вывод: пункт, дата, тип операции (inc/out), денежная сумма за день.

```sql
select
  coalesce(i.point,o.point) as point
  ,coalesce(i.date,o.date) as date
  ,CASE WHEN sum(inc) is not null
        THEN 'inc' ELSE 'out'
   END as operation
  ,CASE WHEN sum(inc) is not null
        THEN sum(inc)
        ELSE sum(out)
    END as money
  from income i
  full join outcome o on i.date=o.date and i.point=o.point
  group by coalesce(i.point,o.point), coalesce(i.date,o.date)
  having sum(inc) is null OR sum(out) is null
order by 1,2
```

| point  |          date            | operation  |   money    |
|--------|--------------------------|------------|------------|
|     1  | 2001-03-14 00:00:00.000  | out        | 15348.0000 |
|     1  | 2001-03-22 00:00:00.000  | inc        | 30000.0000 |
|     1  | 2001-03-23 00:00:00.000  | inc        | 15000.0000 |
|     1  | 2001-03-26 00:00:00.000  | out        |  1221.0000 |
|     1  | 2001-03-28 00:00:00.000  | out        |  2075.0000 |
|     1  | 2001-03-29 00:00:00.000  | out        |  4010.0000 |
|     1  | 2001-04-11 00:00:00.000  | out        |  3195.0400 |
|     1  | 2001-04-27 00:00:00.000  | out        |  3110.0000 |
|     2  | 2001-03-24 00:00:00.000  | inc        |  3000.0000 |
|     2  | 2001-03-29 00:00:00.000  | out        |  7848.0000 |
|     2  | 2001-04-02 00:00:00.000  | out        |  2040.0000 |
|     3  | 2001-09-14 00:00:00.000  | out        |  1150.0000 |

## 65

Пронумеровать уникальные пары `{maker, type}` из `Product`, упорядочив их следующим образом:

- имя производителя (`maker`) по возрастанию;
- тип продукта (`type`) в порядке PC, Laptop, Printer.

Если некий производитель выпускает несколько типов продукции, то выводить его имя только в первой строке;
остальные строки для ЭТОГО производителя должны содержать пустую строку символов ('').

```sql
select
  row_number() over(order by maker) as num
  -- Выводим {maker} только если
  -- это первая строка
  ,CASE WHEN mnum=1 THEN maker
    ELSE ''
  END as maker
  ,type
  from (
    select
    -- Нумеруем {maker, type} для каждого {maker}
    row_number() over(partition by maker order by maker, ord) as mnum
    ,maker
    ,type
    from (
      -- Выбираем уникальные {maker, type},
      -- а также создаем доп. столбец {ord}
      -- для требуемой сортировки
    select
      distinct maker, type
      ,CASE WHEN LOWER(type)='pc' then 1
            WHEN LOWER(type)='laptop' then 2
            ELSE 3
      END as ord
      from product
    ) as mto
  ) as mtn
```

| num  | maker  |  type   |
|------|--------|---------|
|   1  | A      | PC      |
|   2  |        | Laptop  |
|   3  |        | Printer |
|   4  | B      | PC      |
|   5  |        | Laptop  |
|   6  | C      | Laptop  |
|   7  | D      | Printer |
|   8  | E      | PC      |
|   9  |        | Printer |

## 66

Для всех дней в интервале с 01/04/2003 по 07/04/2003 определить число рейсов из Rostov.
Вывод: дата, количество рейсов

```sql
-- общая таблицы с рейсами из Ростова
-- в заданном интервале дат
select
  *
  from trip t join pass_in_trip pt on t.trip_no=pt.trip_no
  where town_from='Rostov'
        and (date between '01/04/2003' and '07/04/2003')
  order by date asc;

-----------------------
-- Решение (PostgreSQL)

with ds as (
  -- Генерация последовательности дат, для Postgre SQL.
  -- Проблема к преобразованием дат:
  -- синтак вида to_date() выдавал даты с TIMEZONE.
  -- Больше подробностей: https://phili.pe/posts/timestamps-and-time-zones-in-postgresql/
  SELECT generate_series(
           '01/04/2003'::timestamp,
           '07/04/2003'::timestamp,
           '1 day'
  ) as date
)
select
  ds.date
  -- Считаем уникальное время вылета
  , count(distinct time_out)
  from ds
    left join pass_in_trip pt on ds.date=pt.date
    left join trip t on pt.trip_no=t.trip_no
      and town_from='Rostov'
  group by ds.date
```

|        date          | count |
|----------------------|-------|
| 2003-04-01 00:00:00  |     1 |
| 2003-04-02 00:00:00  |     0 |
| 2003-04-03 00:00:00  |     0 |
| 2003-04-04 00:00:00  |     0 |
| 2003-04-05 00:00:00  |     1 |
| 2003-04-06 00:00:00  |     0 |
| 2003-04-07 00:00:00  |     0 |

## 67

Найти количество маршрутов, которые обслуживаются наибольшим числом рейсов.
Замечания.

- A - B и B - A считать РАЗНЫМИ маршрутами.
- Использовать только таблицу Trip

```sql
with q as (
  -- подзапрос считает кол-во рейсов
  -- для каждого направления {town_from, town_to}
  select
    count(*) as c
    from trip
  group by town_from, town_to
)
-- главный запрос считает кол-во направлений
-- которые обслуживаются наибольшим числом рейсов
select count(*) as route_count from q
  where c=(select max(c) from q)
```

| route_count |
|-------------|
|           4 |

## 68

Найти количество маршрутов, которые обслуживаются наибольшим числом рейсов.
Замечания:

- A - B и B - A считать **ОДНИМ И ТЕМ ЖЕ** маршрутом.
- Использовать только таблицу `Trip`

```sql
with rc as (
  select
    count(*) as route_trips
    from trip
  group by
    case when town_from > town_to
          then town_from else town_to
    end
    ,case when town_from < town_to
          then town_from else town_to
    end
)
select count(*) as route_count from rc
where route_trips=(select max(route_trips) from rc);

-- А еще можно сложить town_from и town_to
-- как строки по аналогичному условию.
```

| route_count |
|-------------|
|           2 |

- NOTE динозавра вида `CASE WHEN condition THEN expr1 ELSE expr2 END` можно заменить функцией `IIF()`:

```sql
IIF(condition, true_expr, false_expr)
```

## 69

По таблицам `Income` и `Outcome` для каждого пункта приема найти остатки денежных средств на конец каждого дня,
в который выполнялись операции по приходу и/или расходу на данном пункте.
Учесть при этом, что деньги не изымаются, а остатки/задолженность переходят на следующий день.
Вывод: пункт приема, день в формате "dd/mm/yyyy", остатки/задолженность на конец этого дня.

```sql
with q as (
  select
    isnull(i.point, o.point) point
    , isnull(i.date, o.date) date
    , coalesce(sum(i.inc), 0) - coalesce(sum(o.out), 0) balance
    from income i
    full join outcome o
      on i.point=o.point and i.date=o.date and i.code=o.code
    group by isnull(i.point, o.point), isnull(i.date, o.date)
)
select
  point
    -- 103 means format "dd/mm/yyyy"
  , convert(varchar, date, 103) day
  , sum(balance) over(partition by point order by date RANGE UNBOUNDED PRECEDING) as rem
  from q
order by point,date
;

-- another solution
select DISTINCT
  point
  , convert(varchar, date, 103) day
  , sum(inc) over(partition by point order by date RANGE UNBOUNDED PRECEDING) as rem
  from (
    select point, date, inc from income
    union all
    select point, date, -out from outcome
  ) q
order by point, date
;
```

| point  |    day      |     rem     |
|--------|-------------|-------------|
|     1  | 14/03/2001  | -15348.0000 |
|     1  | 22/03/2001  |  14652.0000 |
|     1  | 23/03/2001  |  29652.0000 |
|     1  | 24/03/2001  |  29489.0000 |
|     1  | 26/03/2001  |  28268.0000 |
|     1  | 28/03/2001  |  26193.0000 |
|     1  | 29/03/2001  |  22183.0000 |
|     1  | 11/04/2001  |  18987.9600 |
|     1  | 13/04/2001  |  24497.9600 |
|     1  | 27/04/2001  |  21387.9600 |
|     1  | 11/05/2001  |  23357.9600 |
|     2  | 22/03/2001  |   7120.0000 |
|     2  | 24/03/2001  |  10120.0000 |
|     2  | 29/03/2001  |   2272.0000 |
|     2  | 02/04/2001  |    232.0000 |
|     3  | 13/09/2001  |    400.0000 |
|     3  | 14/09/2001  |   -750.0000 |

## 70

Укажите сражения, в которых участвовало по меньшей мере три корабля одной и той же страны.

```sql
select
  distinct battle
  --, country, count(*)
  --, sh.class, sh.name
  from (
    -- все орабли и их классы, которые есть в базе
    select class, name from ships
    union
    select ship, ship from outcomes
  ) as sh
  -- для того, чтобы получить страну
  join classes c on c.class=sh.class
  -- для того, чтобы получить название битвы
  join outcomes o on o.ship=sh.name
group by battle, country
having count(sh.name) >= 3

-- Вариант из учебника, исправленный и принимаемый в кач-ве решения.
-- Подход к запросу иной: каждая таблица с кораблями
-- соединяется с таблицами классов и битв.
SELECT
  DISTINCT battle
  FROM (
    SELECT
      battle, country
      FROM (
        SELECT battle, country
          FROM Outcomes INNER JOIN Classes ON ship = class
          where ship not in (select name from ships)
        UNION ALL
        SELECT battle, country
          FROM Outcomes o
            INNER JOIN Ships s ON o.ship = s.name
            INNER JOIN Classes c ON s.class = c.class
    ) x
    GROUP BY battle, country
    HAVING COUNT(*) >= 3
  ) y;
```

|   battle    |
|-------------|
| Guadalcanal |

## 71

Найти тех производителей ПК, все модели ПК которых имеются в таблице `PC`.

```sql
-- Через существование
select distinct maker from Product p1
where type='PC' and not exists(
  select model from Product p2
  where p1.maker=p2.maker and p2.type='PC' and not exists(
    select model from pc where p2.model=pc.model
  )
);
-- operations: 8


-- Через группировку:
-- кол-во моделей производителя пк в таблице Product
-- равно кол-ву моделей этого же производителя в таблице PC
select
  p.maker
  from Product p left join PC on p.model=pc.model
  where p.type='pc'
group by maker
having count(p.model)=count(pc.model);
-- operations: 7

```

| maker |
|-------|
| A     |
| B     |

## 72

Среди тех, кто пользуется услугами только какой-нибудь одной компании, определить имена разных пассажиров, летавших чаще других.
Вывести: имя пассажира и число полетов.

```sql
with q as (
  select
    pt.id_psg as id
    , count(pt.date) as trip_num
    from pass_in_trip pt join trip t on pt.trip_no=t.trip_no
  group by pt.id_psg
  -- having count(distinct t.id_comp)=1
  having max(t.id_comp)=min(t.id_comp)
)
select name, trip_num
from q join Passenger p on q.id=p.id_psg
where trip_num=(select max(trip_num) from q)
```

|     name      | trip_num |    |   |
|---------------|----------|----|---|
| Michael Caine |          |    | 4 |
| Mullah Omar   |          |    | 4 |

## 73

Для каждой страны определить сражения, в которых не участвовали корабли данной страны.
Вывод: страна, сражение

```sql
-- все варианты страна-битва
select country, name as battle from classes, battles
except
-- только реальные варианты страна-битва
select country, battle
from (
  -- все корабли и их классы, которые есть в бд
  select class, name as ship_name from ships
  union
  select ship, ship from outcomes
) as sh
join Classes c on sh.class=c.class
join Outcomes o on o.ship=sh.ship_name;

-- еще решение (первое, менее оптимальное)
with sh as (
  select class, name from ships
  union
  select ship, ship from outcomes
),
cc as (
  select name, country, battle from Classes c
  left join sh on c.class=sh.class
  join outcomes o on sh.name=o.ship
)
select distinct c.country, b.name
from classes c, battles b
where (
  select count(cc.country) from cc
  where cc.country=c.country and cc.battle=b.name
)=0

```

## 74

Вывести классы всех кораблей России (Russia). Если в базе данных нет классов кораблей России, вывести классы для всех имеющихся в БД стран.
Вывод: страна, класс

```sql  
select
  country, class
  from Classes
  -- We can replace A XOR B operation with this
  -- (A and !B) OR (!A and B)
  where (country='russia' and 'russia'=ANY(select country from Classes))
      OR (country!='russia' and NOT ('russia' = ANY(select country from Classes)))
;

-- more optimal solution
SELECT country, class FROM Classes
WHERE country =
  CASE WHEN EXISTS (
    SELECT class FROM Classes WHERE country = 'Russia'
    ) THEN 'Russia'
      ELSE country
  END
```

## 75

Для каждого корабля из таблицы `Ships` указать название первого по времени сражения из таблицы Battles,
в котором корабль мог бы участвовать после спуска на воду. 

- Если год спуска на воду неизвестен, взять последнее по времени сражение.
- Если нет сражения, произошедшего после спуска на воду корабля, вывести NULL вместо названия сражения.

Считать, что корабль может участвовать во всех сражениях, которые произошли в год спуска на воду корабля.

Вывод: имя корабля, год спуска на воду, название сражения

Замечание: считать, что не существует двух битв, произошедших в один и тот же день. 

```sql
with q as (
  select
    s.name, launched, b.name as b_name
    , rank() over(partition by s.name, launched order by date asc) as num
  from ships s left join battles b on datepart(yyyy,date)>=s.launched
)
select
  name, launched
  ,
    case
      when launched is null
      then (select name from battles where date=(select max(date) from battles))

      when launched is not null and launched>(select datepart(yyyy,max(date)) from battles)
      then NULL

      else b_name
    end
   as battle
from q
where num=1;

-- Чужое решение, простое и более эффективное
with t as (
  select
    name, launched
    , (
      select case when s.launched is null then max(date) else min(date) end
      from Battles
      where datepart(year,date) >= coalesce(s.launched,0)
    ) as date
  from Ships s
)
select t.name,t.launched,b.name
from t
left join Battles b on t.date=b.date;
```

## 76

Определить время, проведенное в полетах, для пассажиров, летавших всегда на разных местах.
Вывод: имя пассажира, время в минутах.

```sql
with pf as(
  -- passangers and their places count
  select id_psg, count(*) as place_count
  from pass_in_trip
  group by id_psg, place
),
pt as(
  -- passangers and their trips
  -- for those who fly always at different places
  select
    pt.id_psg, pt.trip_no
    , ps.name
    , time_out, time_in
    -- see this http://www.sql-tutorial.ru/ru/book_datepart_function.html
    -- to get clue about time calculation
    , CASE when time_out >= time_in
        then time_in-time_out + 1440
        else time_in-time_out
    end as time
  from pass_in_trip pt
  join passenger ps on ps.id_psg=pt.id_psg
  join (
    select
      datepart(hh, time_out)*60 + datepart(mi, time_out) time_out
      , datepart(hh, time_in)*60 + datepart(mi, time_in) time_in
      , trip_no
    from trip t
  ) as t on t.trip_no=pt.trip_no
  -- this can be replaced with MAX() aggregate
  where 1=ALL(select place_count from pf where pf.id_psg=pt.id_psg)
)
select
  name, sum(time) fly_time
from pt
group by id_psg, name
```