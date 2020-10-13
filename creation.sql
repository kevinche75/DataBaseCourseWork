create type comp_type as enum ('airport', 'cafe', 'cleaning', 'airline');

create table company (
    id serial primary key,
    name varchar(30) not null ,
    type comp_type
);

create table employee (
  id serial primary key,
  company integer references company (id) on delete cascade not null,
  name varchar(30) not null,
  surname varchar(30) not null ,
  patronymic varchar(30),
  position varchar(20) not null
);

create table aircraft (
  id serial primary key,
  location varchar(30),
  owner_id int references company(id) on delete set null,
  model varchar(30) not null
);

create type flight_status as enum (
    'scheduled', 'delayed',
    'departed', 'in air',
    'expected', 'diverted',
    'recovery', 'landed',
    'arrived', 'cancelled',
    'no takeoff info', 'past flight');

create table flight (
    id serial primary key,
    aircraft_id int references aircraft(id) on delete cascade,
    schedule_departure timestamp not null,
    schedule_arrival timestamp not null,
    actual_departure timestamp not null,
    actual_arrival timestamp not null,
    status flight_status not null,
    departure_airport varchar(4) not null,
    arrival_airport varchar(4) not null,
    check ( departure_airport <> arrival_airport )
);

CREATE OR REPLACE FUNCTION flight_insert() RETURNS trigger AS '
    BEGIN
        NEW.actual_departure := NEW.schedule_departure;
        NEW.actual_arrival := NEW.schedule_arrival;
        RETURN NEW;
    END;'
LANGUAGE plpgsql;

CREATE TRIGGER flight_insert BEFORE INSERT ON flight FOR
EACH ROW EXECUTE PROCEDURE flight_insert();

create table reception_schedule (
    id serial primary key,
    employee_id int references employee(id) on delete set null,
    flight_id int references flight(id) on delete cascade,
    reception_number smallint not null,
    start_time timestamp not null,
    finish_time timestamp not null,
    check ( reception_number > 0 )
);

create table gate_schedule (
    id serial primary key,
    employee_id int references employee(id) on delete set null,
    flight_id int references flight(id) on delete cascade,
    gate_number smallint not null,
    start_time timestamp not null,
    finish_time timestamp not null,
    check ( gate_number > 0 )
);

create table crew (
    employee_id int references employee(id) on delete set null ,
    flight_id int references flight(id) on delete cascade,
    primary key (employee_id,
                 flight_id)
);
