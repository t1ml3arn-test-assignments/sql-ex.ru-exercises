## 14

Найти производителей, которые выпускают более одной модели, при этом все выпускаемые производителем модели являются продуктами одного типа.
Вывести: maker, type

```sql
Select maker, type
 from product
 where
  maker in (
    -- производители, у которых все модели
    -- являются продуктами одного типа
    select maker from product
      group by maker
      having count(distinct type) = 1
  )
 group by maker, type
 having
  count(model) > 1
```

| maker  |  type   |
|--------|---------|
| D      | Printer |

## 24

Перечислите номера моделей любых типов, имеющих самую высокую цену по всей имеющейся в базе данных продукции.

```sql
with mp as (
  select model, price from pc
  union
  select model, price from printer
  union
  select model, price from laptop
)
select model from mp where price = (select max(price) from mp)
```

| model |
|-------|
|  1750 |

## 25

Найдите производителей принтеров, которые производят ПК с наименьшим объемом RAM и с самым быстрым процессором среди всех ПК, имеющих наименьший объем RAM. Вывести: Maker

```sql
with M as (
select maker from product p
where
  model in (
  -- model with MIN ram AND
  -- MAX speed in MIN ram models
    select model from pc
    where
      ram=(select min(ram) from pc)
      and speed=(
        -- max speed from pc with minimum RAN
        select max(speed) from pc
        where ram=(select min(ram) from pc)
      )
  )
)
select distinct maker from product
where type='Printer' and maker in (select maker from M)
```

| maker |
|-------|
| A     |
| E     |

## 26

Найдите среднюю цену ПК и ПК-блокнотов, выпущенных производителем A (латинская буква). Вывести: одна общая средняя цена.

```sql
with M as (
  select model, price from pc
  union all
  select model, price from laptop
)
select avg(M.price) "avg price"
  from product p join M on p.model=M.model
where p.maker='A'
```

| avg price |
|-----------|
|  754.1666 |

## 28

Используя таблицу `Product`, определить количество производителей, выпускающих по одной модели.

```sql
select count(q.cm) "count of makers" from (
  select count(model) cm from product
  group by maker
  having count(model)=1
) q
```

| count of makers |
|-----------------|
|               1 |

## 29

В предположении, что приход и расход денег на каждом пункте приема фиксируется не чаще одного раза в день [т.е. первичный ключ (пункт, дата)], написать запрос с выходными данными (пункт, дата, приход, расход). Использовать таблицы `Income_o` и `Outcome_o`.

```sql
select
  isnull(i.point, o.point) point
  , isnull(i.date, o.date) [date]
  , inc
  , out
  from income_o i full outer join outcome_o o 
    on i.date=o.date and i.point=o.point
```

| point  |          date            |    inc      |    out     |
|--------|--------------------------|-------------|------------|
|     1  | 2001-03-14 00:00:00.000  | NULL        | 15348.0000 |
|     1  | 2001-03-22 00:00:00.000  | 15000.0000  | NULL       |
|     1  | 2001-03-23 00:00:00.000  | 15000.0000  | NULL       |
|     1  | 2001-03-24 00:00:00.000  | 3400.0000   | 3663.0000  |
|     1  | 2001-03-26 00:00:00.000  | NULL        | 1221.0000  |
|     1  | 2001-03-28 00:00:00.000  | NULL        | 2075.0000  |
|     1  | 2001-03-29 00:00:00.000  | NULL        | 2004.0000  |
|     1  | 2001-04-11 00:00:00.000  | NULL        | 3195.0400  |
|     1  | 2001-04-13 00:00:00.000  | 5000.0000   | 4490.0000  |
|     1  | 2001-04-27 00:00:00.000  | NULL        | 3110.0000  |
|     1  | 2001-05-11 00:00:00.000  | 4500.0000   | 2530.0000  |
|     2  | 2001-03-22 00:00:00.000  | 10000.0000  | 1440.0000  |
|     2  | 2001-03-24 00:00:00.000  | 1500.0000   | NULL       |
|     2  | 2001-03-29 00:00:00.000  | NULL        | 7848.0000  |
|     2  | 2001-04-02 00:00:00.000  | NULL        | 2040.0000  |
|     3  | 2001-09-13 00:00:00.000  | 11500.0000  | 1500.0000  |
|     3  | 2001-09-14 00:00:00.000  | NULL        | 2300.0000  |
|     3  | 2001-10-02 00:00:00.000  | 18000.0000  | NULL       |
|     3  | 2002-09-16 00:00:00.000  | NULL        | 2150.0000  |

## 30

В предположении, что приход и расход денег на каждом пункте приема фиксируется произвольное число раз (первичным ключом в таблицах является столбец code), требуется получить таблицу, в которой каждому пункту за каждую дату выполнения операций будет соответствовать одна строка.
Вывод: `point`, `date`, суммарный расход пункта за день (`out`), суммарный приход пункта за день (`inc`). Отсутствующие значения считать неопределенными (`NULL`).

```sql
select
 isnull(i.point, o.point) point
  , isnull(i.date, o.date) date
  , sum(o.out) outcome
  , sum(i.inc) income
  from income i
  full join outcome o
    on i.point=o.point and i.date=o.date and i.code=o.code
  group by isnull(i.point, o.point), isnull(i.date, o.date)
```

| point  |          date            |  outcome    |   income   |
|--------|--------------------------|-------------|------------|
|     1  | 2001-03-14 00:00:00.000  | 15348.0000  | NULL       |
|     1  | 2001-03-22 00:00:00.000  | NULL        | 30000.0000 |
|     1  | 2001-03-23 00:00:00.000  | NULL        | 15000.0000 |
|     1  | 2001-03-24 00:00:00.000  | 7163.0000   | 7000.0000  |
|     1  | 2001-03-26 00:00:00.000  | 1221.0000   | NULL       |
|     1  | 2001-03-28 00:00:00.000  | 2075.0000   | NULL       |
|     1  | 2001-03-29 00:00:00.000  | 4010.0000   | NULL       |
|     1  | 2001-04-11 00:00:00.000  | 3195.0400   | NULL       |
|     1  | 2001-04-13 00:00:00.000  | 4490.0000   | 10000.0000 |
|     1  | 2001-04-27 00:00:00.000  | 3110.0000   | NULL       |
|     1  | 2001-05-11 00:00:00.000  | 2530.0000   | 4500.0000  |
|     2  | 2001-03-22 00:00:00.000  | 2880.0000   | 10000.0000 |
|     2  | 2001-03-24 00:00:00.000  | NULL        | 3000.0000  |
|     2  | 2001-03-29 00:00:00.000  | 7848.0000   | NULL       |
|     2  | 2001-04-02 00:00:00.000  | 2040.0000   | NULL       |
|     3  | 2001-09-13 00:00:00.000  | 2700.0000   | 3100.0000  |
|     3  | 2001-09-14 00:00:00.000  | 1150.0000   | NULL       |

Another solution

```sql
with i as (
  select point, date, sum(inc) inc from income
  group by point, date
)
select
 isnull(i.point, o.point) as ppoint
  , isnull(i.date, o.date) as ddate
  , sum(o.out)
  , sum(i.inc)
  from i
  full join (
    select point, date, sum(out) out from outcome
    group by point, date
  ) o on i.point=o.point and i.date=o.date
  group by isnull(i.point, o.point), isnull(i.date, o.date)
```

## 32

Одной из характеристик корабля является половина куба калибра его главных орудий (`mw`). С точностью до 2 десятичных знаков определите среднее значение `mw` для кораблей каждой страны, у которой есть корабли в базе данных.

```sql
with w as (
  select country, name, bore from classes c join ships s on c.class=s.class
  union
  select country, ship, bore from classes c join outcomes o on c.class=o.ship
)
select
  w.country
  , ROUND(AVG(w.bore*w.bore*w.bore*0.5), 2) as weight
  from w
  group by w.country
```

|  COUNTRY    | WEIGHT  |
|-------------|---------|
| Germany     |  1687.5 |
| Gt.Britain  |  1687.5 |
| Japan       | 1886.67 |
| USA         | 1897.78 |

- NOTE из-за приколов с округлением получаем неверное решения для MSSQL. Oracle работает как надо.

### Некоторые проверочные/промежуточные запросы

```sql
-- Классы кораблей без кораблей
select * from ships s
  right join classes c on s.class=c.class
  where s.name is null;

-- Корабли в таблице Outcomes, которых нет в таблице Ships
select * from outcomes o
  left join ships s on o.ship=s.name
  where s.name is null;

-- ?
select * from classes c
  right join (
    select distinct o.ship from outcomes o
    where o.ship not in (select name from ships)
  ) o on c.class=o.ship;

-- ?
select c.* from classes c join ships s on c.class=s.name
union all
select c.* from classes c join outcomes o on c.class=o.ship
  where o.ship not in (select name from ships);
```

### Менее оптимальное решение

```sql
with w as (
  select c.*, s.name from classes c join ships s on c.class=s.class
  union all
  select c.*, o.ship from classes c join (
    select distinct ship from outcomes
      where ship not in (select name from ships)
    ) o on c.class=o.ship
)
select
  w.country
  , ROUND(AVG(w.bore*w.bore*w.bore*0.5), 2) as weight
  from w
  group by w.country
;
```

## 34

По Вашингтонскому международному договору от начала 1922 г. запрещалось строить линейные корабли водоизмещением более 35 тыс.тонн. Укажите корабли, нарушившие этот договор (учитывать только корабли c известным годом спуска на воду). Вывести названия кораблей.

```sql
Select s.name from ships s
  join classes c on s.class=c.class
  where
    s.launched >= 1922
    and c.displacement > 35000
    and type='bb'
```

|      name      |
|----------------|
| Iowa           |
| Missouri       |
| Musashi        |
| New Jersey     |
| North Carolina |
| South Dakota   |
| Washington     |
| Wisconsin      |
| Yamato         |

## 35

В таблице `Product` найти модели, которые состоят только из цифр или только из латинских букв (A-Z, без учета регистра).
Вывод: номер модели, тип модели. (Всё это было бы проще, если бы оно умело в регулярные выражения(?)).

```sql
select model, type from product
 where
  model not like '%[^0-9]%' or model not like '%[^a-z]%'
```

| model  |  type   |
|--------|---------|
|  1121  | PC      |
|  1232  | PC      |
|  1233  | PC      |
|  1260  | PC      |
|  1276  | Printer |
|  1288  | Printer |
|  ...   |         |

### Промежуточная таблица для тестирования решения

```sql
with q as (
  select 'abc' as c union all
  select 'ABC' as c union all
  select 'ABCabc' as c union all
  select '123' as c union all
  select '123abc123' as c union all
  select 'abc123' as c union all
  select '123abc' as c union all
  select '1' as c union all
  select 'a' as c union all
  select NULL as c union all
  select '' as c union all
  select '_' as c union all
  select '%1%' as c union all
  select '1%' as c union all
  select 'abc123abc' as c union all
  select '!!123!! ' as c
)
```

### Памятка

Как перевести синтакс LIKE на человеческий язык

- LIKE %[0-9]% - a string with digits (string contains digits)
- NOT LIKE %[0-9]% a string without digits (string doesnt contain digits)
- NOT LIKE %[^0-9]% - a string only with digits (string does not contain not digits)
- LIKE %[^0-9]% - string countains not digits

## 37

Найдите классы, в которые входит только один корабль из базы данных (учесть также корабли в Outcomes).

```sql
select q.class from (
  select class, name from ships
  union
  select c.class, o.ship from classes c
    join outcomes o on c.class=o.ship
) q
group by q.class
having count(q.class)=1
;
```

|  class   |
|----------|
| Bismarck |

## 39

Найдите корабли, сохранившиеся для будущих сражений; т.е. выведенные из строя в одной битве (damaged), они участвовали в другой, произошедшей позже.

```sql
SELECT
  distinct o.ship
  FROM outcomes o JOIN Battles b ON b.name=o.battle
  WHERE
    o.result = 'damaged'
    and EXISTS(
      SELECT *
      FROM outcomes o2 JOIN Battles b2 ON b2.name=o2.battle
      WHERE
        o2.ship=o.ship
        and b2.date > b.date
    )
```

|    ship    |
|------------|
| California |

Пример плохого условия. "Сохранившиеся для будущих сражений" предполагает по сути ЛЮБОЙ корабль, который участвовал более, чем в 1 сражении. Дальнейшее уточнее условия наконец говорит, что корабль обязательно должен быть поврежден. Т.о. "сохранившиеся для будущих сражений" сбивает с толку и является лишним.

```sql
-- Корабли, которые "сохранились для следующей битвы"
-- (т.е. не обязательно поврежденные)
select ship from outcomes o, battles b
where o.battle=b.name
group by ship
having count(ship) > 1
```

## 41

Для ПК с максимальным кодом из таблицы PC вывести все его характеристики (кроме кода) в два столбца:

- название характеристики (имя соответствующего столбца в таблице PC);
- значение характеристики

- NOTE решение не принимается, "несовпадение данных" (потому, что начальная длина строк в 10 байт оказалась **недостаточной**)

```sql
select fields, nullif(value,'x') value from
(
  Select
    cast(model as NVARCHAR(50)) as model
  , cast (speed as NVARCHAR(50)) as speed
  , cast(ram as NVARCHAR(50)) as ram
  , cast(hd as NVARCHAR(50)) as hd
  , cast(cd as NVARCHAR(50)) as cd
  --, cast(price as NVARCHAR(50)) as price
  , COALESCE(CAST(price as NVARCHAR(50)),'x') as price
  from PC
  where code = (Select max(code) from PC)
) as t
unpivot
(
  value for fields in (model, speed, ram, hd, cd, price)
) as unp
```

| fields  |   A    |
|---------|--------|
| cd      | 50x    |
| hd      | 20     |
| model   | 1233   |
| price   | 970.00 |
| ram     | 128    |
| speed   | 800    |

## 45

Найдите названия всех кораблей в базе данных, состоящие из трех и более слов (например, King George V).
Считать, что слова в названиях разделяются единичными пробелами, и нет концевых пробелов.

```sql
select name from ships where name like '_% _% _%'
union
select ship from outcomes where ship like '_% _% _%'
```

|      name       |
|-----------------|
| Duke of York    |
| King George V   |
| Prince of Wales |

## 46

Для каждого корабля, участвовавшего в сражении при Гвадалканале (Guadalcanal), вывести название, водоизмещение и число орудий.

```sql
with allships as (
  select name, class from ships
  union
  select ship as name, ship as class from outcomes
  where ship not in (select name from ships)
)
select a.name, displacement, numGuns from allships a
  left join classes c on a.class=c.class
  join outcomes o on a.name=o.ship and o.battle='Guadalcanal';

-- More optimal
SELECT
  ship, displacement, numGuns
  FROM Outcomes A
    LEFT JOIN Ships C ON A.ship = C.name
    LEFT JOIN Classes B ON A.ship = B.class OR C.class = B.class
  WHERE battle = 'Guadalcanal'
```

|     name      | displacement  | numGuns |
|---------------|---------------|---------|
| California    |        32000  |      12 |
| Kirishima     |        32000  |       8 |
| South Dakota  |        37000  |      12 |
| Washington    |        37000  |      12 |
