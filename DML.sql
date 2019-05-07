-- DML 19 task tests
insert into Battles values 
('B1', 41) -- B1
,('B2', 42) -- B2
,('B3', 43) -- B3
,('B4', 44) -- B4
,('B5', 45) -- B5
;

insert into Outcomes (ship, battle, result) 
values
('A', 'B1','ok')
,('A', 'B2','damaged')
,('B', 'B3','damaged')
,('B', 'B4','sunk')
,('C', 'B3','damaged')
,('D', 'B5','damaged')
,('E', 'B4','ok')
;
