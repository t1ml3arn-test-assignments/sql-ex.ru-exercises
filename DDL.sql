-- Ships db
create table Battles (
    name char(20) primary key,
    date Date not null    
);

create table Outcomes (
    ship char(50)
    , battle char(20) References Battles(name)
    , result char(10) not null
    , primary key (ship, battle)
);

create table Ships (
    name varchar(50) not null
    , class varchar(50) not null
    , launched integer default null
    , primary key (name, class)
);