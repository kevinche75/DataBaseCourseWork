create type comp_type as enum ('airport', 'cafe', 'cleaning', 'airline');
create type flight_status as enum (
  'scheduled', 'delayed',
  'departed', 'in air',
  'expected', 'diverted',
  'recovery', 'landed',
  'arrived', 'cancelled',
  'no takeoff info', 'past flight');
create type baggage_status as enum ('lost','accept','sent','returned');
create type seat_class as enum('business','economy');
create type room_class as enum('middle', 'comfort','comfort+');

create table company (
  name varchar(30) primary key,
  type comp_type
);

create table employee (
  passport_no char(10) primary key,
  company varchar(30) references company (name) on delete cascade not null,
  name varchar(30) not null,
  second_name varchar(30) not null,
  third_name varchar(30),
  position varchar(20) not null,
  check ( passport_no ~ '[0-9]{10}' )
);

create table aircraft (
  id varchar(10) primary key,
  location varchar(30),
  owner_id varchar(30) references company(name) on delete set null,
  model varchar(30) not null
);


create table flight (
  id serial primary key,
  aircraft_id varchar(10) references aircraft(id) on delete cascade not null ,
  schedule_departure timestamptz not null,
  schedule_arrival timestamptz not null,
  actual_departure timestamptz,
  actual_arrival timestamptz,
  status flight_status not null,
  departure_airport varchar(4) not null,
  arrival_airport varchar(4) not null,
  check ( departure_airport <> arrival_airport
          and schedule_arrival>schedule_departure
          and actual_arrival>actual_departure)
);

create table reception_schedule (
  id serial primary key,
  employee_id char(10) references employee(passport_no) on delete set null,
  flight_id int references flight(id) on delete cascade,
  reception_number smallint not null,
  start_time timestamptz not null,
  finish_time timestamptz not null,
  check ( reception_number > 0 and start_time < finish_time)
);

create table gate_schedule (
  id serial primary key,
  employee_id char(10) references employee(passport_no) on delete set null,
  flight_id int references flight(id) on delete cascade,
  gate_number smallint not null,
  start_time timestamptz not null,
  finish_time timestamptz not null,
  check ( gate_number > 0  and start_time < finish_time)
);

create table crew (
  employee_id char(10) references employee(passport_no) on delete set null,
  flight_id int references flight(id) on delete cascade,
  primary key (employee_id,
               flight_id)
);


create table passenger(
  passport_no char(10) primary key ,
  name varchar(30) not null,
  second_name varchar(30) not null,
  third_name varchar(30),
  birthday date not null,
  check (birthday<current_date),
  check ( passport_no ~ '[0-9]{10}' )
);
create table booking(
  id serial primary key,
  total_amount integer,
  time_limit integer,
  contact_data text,
  check(total_amount>0
        and time_limit>0)
);
create table seat(
  id serial primary key,
  number varchar(3) not null,
  flight_id integer not null,
  class seat_class not null,
  foreign key(flight_id) references flight(id),
  check ( number ~ '[A-Z]{1}[0-9]{2}' )
);
create table ticket(
  id serial primary key,
  passenger_id char(10) ,
  seat_id integer not null,
  amount integer not null,
  book_id integer,
  registered boolean not null,
  foreign key(book_id) references booking(id),
  foreign key(passenger_id) references passenger(passport_no) on delete set null ,
  foreign key (seat_id) references seat(id) on delete cascade,
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
insert into employee(passport_no,company, name, second_name, third_name, position) VALUES ('1111111111','S7','ivanov','ivan','ivamnovi4','pilot');
insert into aircraft (id,location, owner_id, model) values ('a111','Russia','S7','boeing');
insert into flight(aircraft_id, schedule_departure, schedule_arrival,actual_departure,actual_arrival, status, departure_airport, arrival_airport)
values ('a111','1999-01-08 04:05:06','1999-01-08 07:05:06','1999-01-08 04:05:06','1999-01-08 07:05:06','arrived','svo','led');
insert into reception_schedule(employee_id, flight_id, reception_number, start_time, finish_time)
VALUES ('1111111111',1,18787,'1999-01-08 02:05:06','1999-01-08 03:05:06');
insert into gate_schedule(employee_id, flight_id, gate_number, start_time, finish_time)
VALUES ('1111111111',1,1889,'1999-01-08 03:05:06','1999-01-08 04:05:06') ;
insert into crew(employee_id, flight_id) VALUES ('1111111111',1);
insert into passenger(passport_no,name, second_name, third_name, birthday)
VALUES ('3333333333','petrov','petr','petrovi4','180-01-08');
insert into booking( total_amount, time_limit, contact_data)
values (6,6,'676787');
insert into seat(number, flight_id, class) values ('A21',1,'economy');
insert into ticket(passenger_id, seat_id, amount, book_id, registered)
values ('3333333333',1,12,1,true );
insert into baggage(ticket_id, total_weight, max_weight, status)
values (1,3,3,'lost');
insert into relax_room_booking(ticket_id, class)
values (1,'comfort+');