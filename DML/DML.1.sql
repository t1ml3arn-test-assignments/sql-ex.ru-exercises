-- 1
/*  Добавить в таблицу PC следующую модель:
    code: 20
    model: 2111
    speed: 950
    ram: 512
    hd: 60
    cd: 52x
    price: 1100  */
sql
insert into pc
values(20, '2111', 950, 512, 60, '52x', 1100);

-- 2
/*  Добавить в таблицу Product следующие продукты производителя Z:
    принтер модели 4003, ПК модели 4001 и блокнот модели 4002   */
insert into product values
('Z', '4003', 'Printer'),
('Z', '4001', 'PC'),
('Z', '4002', 'Laptop')

-- 3
/*  Добавить в таблицу PC модель 4444 с кодом 22, 
    имеющую скорость процессора 1200 и цену 1350.
    Отсутствующие характеристики должны быть восполнены 
    значениями по умолчанию, принятыми для соответствующих столбцов.   */
insert into pc (model, code, speed, price)
values ('4444', 22, 1200, 1350)

-- 4
/*  Для каждой группы блокнотов с одинаковым номером модели 
    добавить запись в таблицу PC со следующими характеристиками:
    код: минимальный код блокнота в группе +20;
    модель: номер модели блокнота +1000;
    скорость: максимальная скорость блокнота в группе;
    ram: максимальный объем ram блокнота в группе *2;
    hd: максимальный объем hd блокнота в группе *2;
    cd: значение по умолчанию;
    цена: максимальная цена блокнота в группе, уменьшенная в 1,5 раза.
    Замечание. Считать номер модели числом.    */
insert into PC
(code, model, speed, ram, hd, price)
select
  min(code)+20 code
  , cast(model as int)+1000 as model
  , max(speed) speed
  , max(ram)*2 ram
  , max(hd)*2 hd
  --, NULL as cd
  , max(price)/1.5 price
  from laptop
  group by model
;

-- 5
/*  Удалить из таблицы PC компьютеры, 
    имеющие минимальный объем диска или памяти.    */
delete from pc
where hd = (select min(hd) from pc)
      OR ram = (select min(ram) from pc)
;

-- 6
/*  Удалить все блокноты, выпускаемые производителями, 
    которые не выпускают принтеры.     */
delete from laptop
where model in (
  -- all models whose makers don't produce printers
  select model from product
  where maker not in (select maker from product where type='Printer')
);

-- 7
/*  Производство принтеров производитель A 
    передал производителю Z. 
    Выполнить соответствующее изменение     */
update product
set maker='Z' where (maker='A' and type='Printer');

-- 8
/*  Удалите из таблицы Ships все корабли, 
    потопленные в сражениях. */
delete from Ships
where name in (
  select ship from outcomes
  where result='sunk'
);

-- 9
/*  Измените данные в таблице Classes так, 
    чтобы калибры орудий измерялись в сантиметрах (1 дюйм=2,5см), 
    а водоизмещение в метрических тоннах (1 метрическая тонна = 1,1 тонны). 
    Водоизмещение вычислить с точностью доцелых. */
update classes
set bore=(bore*2.5)
    , displacement=ROUND(displacement*1.0/1.1, 0)
;

-- 10
/*  Добавить в таблицу PC те модели ПК из Product, 
    которые отсутствуют в таблице PC.

    При этом модели должны иметь следующие характеристики:

    1. Код равен номеру модели плюс максимальный код, 
    который был до вставки.

    2. Скорость, объем памяти и диска, а также скорость CD 
    должны иметь максимальные характеристики 
    среди всех имеющихся в таблице PC.

    3. Цена должна быть средней среди всех ПК, 
    имевшихся в таблице PC до вставки.*/
insert into PC (code, model, speed, ram, hd, cd, price)
select
  cast(model as int) + (select max(code) from pc) as code
  , model
  , (select max(speed) from pc ) as speed
  , (select max(ram) from pc) as ram
  , (select max(hd) from pc) as hd
  -- монстр-преобразователь типов
  , cast(
      (select max(
        -- делаем из скорости целое число
        -- чтобы правильно посчитать MAX
        CAST(substring(cd, 1, LEN(cd)-1) as INT)
      -- делаем обратно строковый тип
      -- чтобы добавить 'x' к значению
      ) from pc) as varchar
    ) + 'x' as cd
  , (select avg(price) from pc) as price
from Product
where 
  type='PC'
  and model not in (select model from PC)
;

-- 11
/*  Для каждой группы блокнотов с одинаковым номером модели 
    добавить запись в таблицу PC со следующими характеристиками:
    код: минимальный код блокнота в группе +20;
    модель: номер модели блокнота +1000;
    скорость: максимальная скорость блокнота в группе;
    ram: максимальный объем ram блокнота в группе *2;
    hd: максимальный объем hd блокнота в группе *2;
    cd: cd c максимальной скоростью среди всех ПК;
    цена: максимальная цена блокнота в группе, уменьшенная в 1,5 раза */
insert into PC
select
  min(code) + 20 as code
  , cast(model as int) + 1000 as model
  , max(speed) as speed
  , max(ram)*2 as ram
  , max(hd)*2 as hd
  , (select 
      concat(MAX(CAST(replace(cd, 'x', '') as INT)), 'x') from pc
  ) as cd
  , max(price)/1.5 as price
from Laptop
group by model
;

-- 12
/*  Добавьте один дюйм к размеру экрана каждого блокнота,
выпущенного производителями E и B, и уменьшите его цену на $100. */
update Laptop
set screen=screen+1,
    price=price-100
where model in (
  select model from product
  where (maker='E' OR maker='B')
        and type='Laptop'
)
;

-- 13
/*  Ввести в базу данных информацию о том, 
    что корабль Rodney был потоплен в битве, произошедшей 25/10/1944, 
    а корабль Nelson поврежден - 28/01/1945.
    Замечание: считать, что дата битвы уникальна в таблице Battles. */
insert into Outcomes
select
  'Rodney' as ship
  , (select distinct name from Battles
     where date='1944-10-25'
  ) as battle
  , 'sunk' as result
union
select
  'Nelson'
  , (select distinct name from Battles
     where date='1945-01-28'
  )
  , 'damaged'
;

-- 14
/*  Удалите классы, имеющие в базе данных менее трех кораблей 
    (учесть корабли из Outcomes). */
delete from Classes
where class in (
  select
    c.class
  from (
    select name, class from Ships
    union
    select ship, ship from Outcomes
  ) as sh
  right join Classes c on c.class=sh.class
  group by c.class
  having count(sh.name)<3
);

-- 15
/*  Из каждой группы ПК с одинаковым номером модели в таблице PC 
    удалить все строки кроме строки 
    с наибольшим для этой группы кодом (столбец code).*/
delete from pc
where code not in (
  select
    max(code)
  from PC
  group by model
)
;

-- 16
/*  Удалить из таблицы Product те модели, 
    которые отсутствуют в других таблицах. */
delete from Product
where model not in (
  select model from pc
  union
  select model from laptop
  union
  select model from printer
)
;

-- 17
/*  Удалить из таблицы PC компьютеры, 
    у которых величина hd попадает в тройку наименьших значений. */
delete from pc
where hd in (
  select top 3 * from (select distinct hd from pc) as p 
  order by hd asc
);

-- 18
/*  Перенести все концевые пробелы, 
    имеющиеся в названии каждого сражения в таблице Battles, 
    в начало названия. */
update Battles
set name=replace(name, rtrim(name), '')+rtrim(name);

-- №
/*  */
