create type comp_type as enum ('airport', 'cafe', 'cleaning', 'airline');

create table company (
  name varchar(30) primary key,
  type comp_type
);

create table employee (
  id serial primary key,
  company varchar(30) references company (name) on delete cascade not null,
  name varchar(30) not null,
  second_name varchar(30) not null,
  third_name varchar(30),
  position varchar(20) not null
);

create table aircraft (
  id varchar(10) primary key,
  location varchar(30),
  owner_id varchar(30) references company(name) on delete set null,
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
  aircraft_id varchar(10) references aircraft(id) on delete cascade,
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
  employee_id int references employee(id) on delete set null,
  flight_id int references flight(id) on delete cascade,
  primary key (employee_id,
               flight_id)
);

create type baggage_status as enum ('lost','accept','sent','returned');
create type seat_class as enum('business','economy');
create type room_class as enum('middle', 'comfort','comfort+');
create table passenger(
  id serial primary key,
  name varchar(30) not null,
  second_name varchar(30) not null,
  third_name varchar(30),
  passport_no char(10) not null,
  birthday date not null,
  check (birthday<now())
);
create table booking(
  id serial primary key,
  book_date timestamp not null,
  total_amount integer,
  time_amount integer,
  contact_data text,
  check(total_amount>0 and time_amount>0),
  check(book_date<now())
);
create table seat(
  id serial primary key,
  number varchar(3) not null,
  flight_id integer not null,
  class seat_class not null,
  foreign key(flight_id) references flight(id)
);
create table ticket(
  id serial primary key,
  passanger_id integer not null,
  flight_id integer not null,
  seat_id integer not null,
  amount integer not null,
  book_id integer not null,
  registered boolean not null,
  foreign key(book_id) references booking(id) on delete cascade,
  foreign key(passanger_id) references passenger(id),
  foreign key (flight_id) references flight(id),
  foreign key (seat_id) references seat(id),
  check(amount>0)
);

create table baggage(
  id serial primary key,
  ticket_id integer not null,
  total_weight real,
  max_weight real not null,
  status baggage_status,
  foreign key(ticket_id) references ticket(id) on delete cascade,
  check (total_weight>0 and max_weight>0)
);

create table relax_room_booking(
  id serial primary key,
  ticket_id integer not null,
  class room_class not null,
  foreign key(ticket_id) references ticket(id) on delete cascade
);

insert into company(name,type) values ('S7','airline');
insert into employee(company, name, second_name, third_name, position) VALUES ('S7','ivanov','ivan','ivamnovi4','pilot');
insert into aircraft (id,location, owner_id, model) values ('a111','Russia','S7','boeing');
insert into flight(aircraft_id, schedule_departure, schedule_arrival,actual_departure,actual_arrival, status, departure_airport, arrival_airport)
values ('a111','1999-01-08 04:05:06','1999-01-08 07:05:06','1999-01-08 04:05:06','1999-01-08 07:05:06','arrived','svo','led');
insert into reception_schedule(employee_id, flight_id, reception_number, start_time, finish_time)
VALUES (1,2,1,'1999-01-08 02:05:06','1999-01-08 03:05:06');
insert into gate_schedule(employee_id, flight_id, gate_number, start_time, finish_time)
VALUES (1,2,2,'1999-01-08 03:05:06','1999-01-08 04:05:06') ;




