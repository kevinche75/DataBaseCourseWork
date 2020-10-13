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

  create type baggage_status as enum ('lost','accept','sent','returned');
  create type seat_class as enum('business','economy');
  create type room_class as enum('middle', 'comfort','comfort+');
  create table passenger(
    id serial primary key,
    name varchar(30),
    second_name varchar(30),
    third_name varchar(30),
    passport_no char(10),
    birthday date
  );
  create table booking(
    id serial primary key,
    book_date timestamp,
    total_amount integer,
    time_amount integer,
    contact_data text
    check(total_amount>0 and time_amount>0)
  );
  create table seat(
    id serial primary key,
    number varchar(3),
    flight_id integer,
    class seat_class
  );
create table ticket(
    id serial primary key,
    passanger_id integer,
    flight_id integer,
    seat_id integer,
    amount integer,
    book_id integer,
    registered boolean,
  foreign key(book_id) references booking(id),
  foreign key(passanger_id) references passenger(id),
  foreign key (flight_id) references flight(id),
  foreign key (seat_id) references seat(id),
  check(amount>0)
  );

  create table baggage(
    id serial primary key,
    ticket_id integer,
    total_weight real,
    max_weight real,
    status baggage_status,
    foreign key(ticket_id) references ticket(id),
    check (total_weight>0 and max_weight>0)
  );

  create table relax_room_booking(
    id serial primary key ,
    ticket_id integer,
    class room_class,
    foreign key(ticket_id) references ticket(id)
  )



