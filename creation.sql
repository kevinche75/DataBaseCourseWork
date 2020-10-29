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

create table if not exists company (
  name varchar(30) primary key,
  type comp_type
);

create table if not exists employee (
  passport_no char(10) primary key,
  company varchar(30) references company (name) on delete cascade not null,
  name varchar(30) not null,
  second_name varchar(30) not null,
  third_name varchar(30),
  position varchar(20) not null,
  check ( passport_no ~ '[0-9]{10}' )
);

create table if not exists aircraft (
  id varchar(10) primary key,
  location varchar(4),
  owner_id varchar(30) references company(name) on delete set null,
  model varchar(30) not null
);


create table if not exists flight (
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

create table if not exists reception_schedule (
  id serial primary key,
  employee_id char(10) references employee(passport_no) on delete set null,
  flight_id int references flight(id) on delete cascade,
  reception_number smallint not null,
  start_time timestamptz not null,
  finish_time timestamptz not null,
  check ( reception_number > 0 and start_time < finish_time)
);

create table if not exists gate_schedule (
  id serial primary key,
  employee_id char(10) references employee(passport_no) on delete set null,
  flight_id int references flight(id) on delete cascade,
  gate_number smallint not null,
  start_time timestamptz not null,
  finish_time timestamptz not null,
  check ( gate_number > 0  and start_time < finish_time)
);

create table if not exists crew (
  employee_id char(10) references employee(passport_no) on delete set null,
  flight_id int references flight(id) on delete cascade,
  primary key (employee_id,
               flight_id)
);


create table if not exists passenger(
  passport_no char(10) primary key ,
  name varchar(30) not null,
  second_name varchar(30) not null,
  third_name varchar(30),
  birthday date not null,
  check (birthday<current_date),
  check ( passport_no ~ '[0-9]{10}' )
);
create table if not exists booking(
  id serial primary key,
  total_amount integer,
  time_limit timestamptz,
  contact_data text,
  check(total_amount>0)
);
create table if not exists seat(
  id serial primary key,
  number varchar(3) not null,
  flight_id integer not null,
  class seat_class not null,
  foreign key(flight_id) references flight(id),
  check ( number ~ '[A-Z]{1}[0-9]{2}' )
);
create table if not exists ticket(
  id serial primary key,
  passenger_id char(10) ,
  seat_id integer not null,
  amount float not null,
  book_id integer,
  registered boolean not null default false,
  foreign key(book_id) references booking(id),
  foreign key(passenger_id) references passenger(passport_no) on delete set null ,
  foreign key (seat_id) references seat(id) on delete cascade,
  check(amount>0)
);

create table if not exists baggage(
  id serial primary key,
  ticket_id integer not null,
  total_weight real,
  max_weight real not null,
  status baggage_status,
  foreign key(ticket_id) references ticket(id) on delete cascade,
  check (total_weight>0 and max_weight>0)
);

create table if not exists relax_room_booking(
  id serial primary key,
  ticket_id integer not null,
  class room_class not null,
  foreign key(ticket_id) references ticket(id) on delete cascade
);

create table if not exists trip_price (
company_name varchar(30) references company(name) on delete cascade,
departure_airport varchar(4) not null,
arrival_airport varchar(4) not null,
price int not null,
check ( price > 0 ),
primary key (company_name, departure_airport, arrival_airport, price)
);

create index on trip_price(company_name, departure_airport, arrival_airport);
create index on flight(id);
create index on passenger(name,second_name,third_name);
create index on passenger using hash(passport_no);
create index on ticket(amount);
create index on baggage(max_weight);