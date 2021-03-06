## 47

Пронумеровать строки из таблицы `Product` в следующем порядке: имя производителя в порядке убывания числа производимых им моделей (при одинаковом числе моделей имя производителя в алфавитном порядке по возрастанию), номер модели (по возрастанию).
Вывод: номер в соответствии с заданным порядком, имя производителя (maker), модель (model)

```sql
select
  ROW_NUMBER() OVER(ORDER BY count desc, maker asc, model asc) rownum
  , maker
  , model
  from (
    -- tmp table with count of models for each maker
    select
      count(model) over(partition by maker) as count
      , p.*
    from product p
  ) p
```

| rownum  | maker  | model |
|---------|--------|-------|
|     10  | E      |  2112 |
|     11  | E      |  2113 |
|     12  | B      |  1121 |
|     13  | B      |  1750 |
|     14  | D      |  1288 |
|     15  | D      |  1433 |
|     16  | C      |  1321 |
|      1  | A      |  1232 |
|      2  | A      |  1233 |
|      3  | A      |  1276 |
|      4  | A      |  1298 |
|      5  | A      |  1401 |
|      6  | A      |  1408 |
|      7  | A      |  1752 |
|      8  | E      |  1260 |
|      9  | E      |  1434 |

## 47 (NEW)

Определить страны, которые потеряли в сражениях все свои корабли.

```sql
with sh as (
  select c.country, s.name from classes c join ships s on c.class=s.class
  union
  select c.country, o.ship from outcomes o join classes c on c.class=o.ship
),
shs as(
  -- number of sunked ships
  select
    country
    , count(*) as total
  from sh
    left join outcomes o on sh.name=o.ship
  where result = 'sunk'
  group by country
),
sht as (
  -- total number of ships
  select
    country
    , count(*) as total
  from sh
  group by country
)
select x.country from sht x join shs y on x.country=y.country
where x.total=y.total

-- another solution
with sh as (
  select c.country, s.name from classes c join ships s on c.class=s.class
  union
  select c.country, o.ship from outcomes o join classes c on c.class=o.ship
)
, a as (
  select
    country, name
    , case
        when result='sunk' then 1
        else 0
      end as sunk
  from sh left join outcomes o on o.ship=sh.name
)
select country from a
group by country
having count(distinct name)=sum(sunk)
```

## 48

Найдите классы кораблей, в которых хотя бы один корабль был потоплен в сражении.

```sql
select distinct c.class from outcomes o
  left join ships s on o.ship = s.name
  join classes c on (o.ship=c.class or s.class=c.class)
where result = 'sunk'
```

|  class   |
|----------|
| Bismarck |
| Kongo    |

## 49

Найдите названия кораблей с орудиями калибра 16 дюймов (учесть корабли из таблицы `Outcomes`).

```sql
select name from ships s join classes c on s.class=c.class
where bore=16
union
select ship from outcomes o join classes c on o.ship=c.class
where bore=16

-- one more solution (more effective)
select
  name
  from (
    select name, class from ships
    union
    select ship, ship from outcomes
  ) q
  join classes c on q.class=c.class
  where bore=16
```

|      name      |
|----------------|
| Iowa           |
| Missouri       |
| New Jersey     |
| North Carolina |
| South Dakota   |
| Washington     |
| Wisconsin      |

## 50

Найдите сражения, в которых участвовали корабли класса Kongo из таблицы `Ships`.

```sql
select distinct battle from outcomes o
  join ships s on o.ship=s.name
  join classes c on c.class=s.class
where c.class='Kongo'
```

|   battle    |
|-------------|
| Guadalcanal |

## 51

Найдите названия кораблей, имеющих наибольшее число орудий среди всех имеющихся кораблей такого же водоизмещения (учесть корабли из таблицы `Outcomes`).

```sql
with sh as (
  -- все корабли и их классы
  select name, class from ships
  union
  select ship, ship from outcomes
)
select
  name
  from sh join classes c on sh.class=c.class
  where numguns >= all(
    select ci.numguns from classes ci
      where ci.displacement=c.displacement
      -- это на случай (из подсказки) что может быть класс корабля,
      -- но при том самого корабля может не быть в бд
        and ci.class in (select sh.class from sh)
    )
```

|      name       |
|-----------------|
| Bismarck        |
| California      |
| Iowa            |
| Missouri        |
| Musashi         |
| New Jersey      |
| North Carolina  |
| Ramillies       |
| Revenge         |
| Royal Oak       |
| Royal Sovereign |
| South Dakota    |
| Tennessee       |
| Washington      |
| Wisconsin       |
| Yamato          |

## 52

Определить названия всех кораблей из таблицы `Ships`, которые могут быть линейным японским кораблем,
имеющим число главных орудий не менее девяти, калибр орудий менее 19 дюймов и водоизмещение не более 65 тыс.тонн

```sql
select
  s.name
  from ships s
  join classes c on c.class=s.class
  where country='Japan'
    and type='bb' and (numguns>=9 or numguns is null)
    and (bore<19 or bore is null)
    and (displacement<=65000 or displacement is null)
```

|  name   |
|---------|
| Musashi |
| Yamato  |

## 53

Определите среднее число орудий для классов линейных кораблей.
Получить результат с точностью до 2-х десятичных знаков.

- NOTE способ округления и преобразования типов. Функция `ROUND` не применяется.

```sql
select
  cast(avg(numguns*1.0) as numeric(6,2)) as "avg numguns"
  from classes
  where type='bb'
```

| avg numguns |
|-------------|
|        9.67 |

## 54

С точностью до 2-х десятичных знаков определите среднее число орудий всех линейных кораблей (учесть корабли из таблицы `Outcomes`).

- NOTE как и в прошлой задаче [54][#54], требуется правильно преобразовать тип числа.

```sql
select
  cast(avg(numguns*1.0) as numeric(6,2)) as "avg numguns"
  from (
    -- все корабли(которые есть в базе) и их классы
    select name, class from ships
    union
    select ship, ship from outcomes
  ) s
  join classes c on s.class=c.class
where type='bb'
```

| avg numguns |
|-------------|
|        9.63 |

## 55

Для каждого класса определите год, когда был спущен на воду первый корабль этого класса. Если год спуска на воду головного корабля неизвестен, определите минимальный год спуска на воду кораблей этого класса. Вывести: класс, год.

```sql
select
  c.class
  , min(launched) "launch year"
  from classes c
  full join ships s on c.class=s.class
  group by c.class
```

|     class       | launch year |
|-----------------|-------------|
| Bismarck        | NULL        |
| Iowa            | 1943        |
| Kongo           | 1913        |
| North Carolina  | 1941        |
| Renown          | 1916        |
| Revenge         | 1916        |
| Tennessee       | 1920        |
| Yamato          | 1941        |

## 56

Для каждого класса определите число кораблей этого класса, потопленных в сражениях. Вывести: класс и число потопленных кораблей.

```sql
select
  class
  , SUM(CASE WHEN result='sunk' THEN 1 ELSE 0 END) as sunks
  from (
    -- все корабли для имеющихся в базе классов кораблей
    select c.class, name from classes c
      left join ships s on c.class=s.class
    union
    select class, ship from classes
      join outcomes on class=ship
  ) as sh
  left join outcomes o on sh.name=o.ship
  group by class
```

|     class       | sunks |
|-----------------|-------|
| Bismarck        |     1 |
| Iowa            |     0 |
| Kongo           |     1 |
| North Carolina  |     0 |
| Renown          |     0 |
| Revenge         |     0 |
| Tennessee       |     0 |
| Yamato          |     0 |

## 57

Для классов, имеющих потери в виде потопленных кораблей и не менее 3 кораблей в базе данных, вывести имя класса и число потопленных кораблей.

```sql
select
  class
  , SUM(CASE WHEN result='sunk' THEN 1 ELSE 0 END) as sunks
  from (
    select c.class, name from classes c
      join ships s on c.class=s.class
    union
    select class, ship from classes 
      join outcomes on class=ship
  ) as sh
  left join outcomes o on sh.name=o.ship
  group by class
  having
    SUM(CASE WHEN result='sunk' THEN 1 ELSE 0 END) > 0
    and (select count(si.name) from (
            select s.name, s.class from ships s
            union
            select o.ship, o.ship from outcomes o
          ) as si
        where si.class = sh.class
        group by si.class
        )>=3
```

| class  | sunks |
|--------|-------|
| Kongo  |     1 |

## 58

Для каждого типа продукции и каждого производителя из таблицы `Product` c точностью до двух десятичных знаков найти процентное отношение числа моделей данного типа данного производителя к общему числу моделей этого производителя.
Вывод: `maker`, `type`, процентное отношение числа моделей данного типа к общему числу моделей производителя

```sql
select distinct
  maker, type
  -- кол-во моделей каждого типа у каждого производителя
  --, count(model) over(partition by maker, type) as mod_type_count
  -- общее число моделей для каждого производителя
  --, count(model) over(partition by maker) as maker_models_total
  , cast(ROUND((
      count(model) over(partition by maker, type))*100.0/
      count(model) over(partition by maker)
    ,2) as NUMERIC(5,2))
      as 'mods of type / mods total, %'
  from (
    select
      pt.maker, pt.type, p.model
      from (
      -- Комбинация(1) всех типов моделей
      -- и всех производителей
        select distinct a.maker, b.type
        from product a, product b
      ) pt
      -- (1) соединяется с моделями.
      -- Если производитель не выпускает какой-то тип продукта
      -- то такая модель будет NULL
      left join product p on pt.maker=p.maker and pt.type=p.type
  ) as p
order by maker, type
```

| maker  |  type    | mods of type / mods total, % |
|--------|----------|------------------------------|
| A      | Laptop   |                        28.57 |
| A      | PC       |                        28.57 |
| A      | Printer  |                        42.86 |
| B      | Laptop   |                        50.00 |
| B      | PC       |                        50.00 |
| B      | Printer  |                          .00 |
| C      | Laptop   |                       100.00 |
| C      | PC       |                          .00 |
| C      | Printer  |                          .00 |
| D      | Laptop   |                          .00 |
| D      | PC       |                          .00 |
| D      | Printer  |                       100.00 |
| E      | Laptop   |                          .00 |
| E      | PC       |                        75.00 |
| E      | Printer  |                        25.00 |

## 59

Посчитать остаток денежных средств на каждом пункте приема
для базы данных с отчетностью не чаще одного раза в день.
Вывод: пункт, остаток.

```sql
select
  coalesce(i.point,o.point) as point
  --,coalesce(i.date,o.date) as date
  --,sum(coalesce(inc,0)) as total_income
  --,sum(coalesce(out,0)) as total_outcome
  ,sum(coalesce(inc,0))-sum(coalesce(out,0)) as remain
  from income_o i
  full join outcome_o o on i.date=o.date and i.point=o.point
group by coalesce(i.point,o.point)
order by 1,2
```

| point  |   remain   |
|--------|------------|
|     1  |  5263.9600 |
|     2  |   172.0000 |
|     3  | 23550.0000 |

## 60

Посчитать остаток денежных средств **на начало дня 15/04/01**
на каждом пункте приема для базы данных с отчетностью
не чаще одного раза в день. Вывод: пункт, остаток.
Замечание. Не учитывать пункты, информации о которых нет до указанной даты.

```sql
select
  coalesce(i.point,o.point) as point
  ,sum(coalesce(inc,0))-sum(coalesce(out,0)) as remain
  from income_o i
  full join outcome_o o on i.date=o.date and i.point=o.point
  -- "на начало дня" значит
  -- ДО УКАЗАННОЙ ДАТЫ (раньше указанной даты)
  where coalesce(i.date,o.date) < '2001-04-15'
group by coalesce(i.point,o.point)
order by 1,2
```

| point  |  remain   |
|--------|-----------|
|     1  | 6403.9600 |
|     2  |  172.0000 |

## 61

Посчитать остаток денежных средств на всех пунктах приема для базы данных с отчетностью не чаще одного раза в день.

```sql
select
  sum(coalesce(inc,0))-sum(coalesce(out,0)) as remain
  from income_o i
  full join outcome_o o on i.date=o.date and i.point=o.point
```

|   remain   |
|------------|
| 28985.9600 |
