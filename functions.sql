CREATE OR REPLACE FUNCTION flight_insert() RETURNS trigger AS $$
    BEGIN
        NEW.actual_departure := NEW.schedule_departure;
        NEW.actual_arrival := NEW.schedule_arrival;
        RETURN NEW;
    END;$$
LANGUAGE plpgsql;

CREATE TRIGGER flight_insert BEFORE INSERT ON flight FOR
EACH ROW EXECUTE PROCEDURE flight_insert();

create or replace function get_number_available_seats(
    date_ date,
    departure_airport_ varchar(4),
    arrival_airport_ varchar(4)
    ) returns table (
        flight_id int,
        schedule_departure timestamptz,
        schedule_arrival timestamptz,
        seats_number bigint
                    ) as $$
    begin
        return query
            with available_flight as (
                select * from flight where
                                           flight.departure_airport = departure_airport_ and
                                           flight.arrival_airport = arrival_airport_ and
                                           flight.schedule_departure::date = date_
            ), available_seats_number as (
                select seat.flight_id, count(*) as seats_number from seat
                left join ticket t on seat.id = t.seat_id
                where t.id is null
                group by seat.flight_id
                )
            select id, available_flight.schedule_departure, available_flight.schedule_arrival, a.seats_number from available_flight
                inner join available_seats_number a on a.flight_id = id;
    end; $$
    language plpgsql;

select get_number_available_seats('1999-01-08', 'svo', 'led');

create or replace function calc_ticket_price(
    flight_id int,
    seat_number varchar(3)
    ) returns float as $$
    declare
        airport_tax float = 1.05;
        month_tax float = 1.002;
        half_month_tax float = 1.05;
        week_tax float = 1.1;
        economy_tax float = 1.01;
        business_tax float = 1.1;
        result float;
    begin
        with result_price as (
        select price::float*airport_tax as r_price, extract(day from f.schedule_departure - now()) as days, class
        from trip_price as t
        join flight f on
            f.id = flight_id and
            t.arrival_airport = f.arrival_airport and
            t.departure_airport = f.departure_airport or
            t.arrival_airport = f.departure_airport and
            t.departure_airport = f.arrival_airport
        join seat s on f.id = s.flight_id and s.number = seat_number
            ), result_price_1 as (
            select result_price.class, result_price.r_price, case
                when result_price.days > 30 then result_price.r_price*month_tax
                when result_price.days <= 30 and result_price.days > 15 then result_price.r_price*half_month_tax
                when result_price.days <= 15 then result_price.r_price*week_tax
            end as r_price_1
                from result_price
            ), result_price_2 as (
            select result_price_1.class, result_price_1.r_price_1,
            case
                when result_price_1.class = 'economy' then result_price_1.r_price_1*economy_tax
                when result_price_1.class = 'business' then result_price_1.r_price_1*business_tax
            end as price
                from result_price_1
            ) select into result result_price_2.price from result_price_2;
        return result;
    end; $$
language plpgsql;

select calc_ticket_price(1, 'A21');

create or replace function check_booking() returns void as $$
    begin
        start transaction ;
        with delete_id as (
            select booking.id as id from booking where time_limit > now()
        ), delete_0 as (
            delete from ticket where book_id = delete_id.id
        )
            delete from booking where booking.id = delete_id.id;
        commit;
    end; $$
language plpgsql;

create function add_passenger(varchar(30),varchar(30),varchar(30),char(10),date) returns boolean as $$
begin
  if  (select true from  passenger where passport_no=$4) then return true; end if ;
  insert into passenger (passport_no, name, second_name, third_name, birthday)
  values (passport_no, $1, $2, $3, $4);
  return true;
end; $$
language plpgsql;

create function create_ticket(char(10),integer,varchar(3), varchar(30),varchar(30),varchar(30),date) returns boolean as $$
  begin
  if add_passenger($4,$5,$6,$1,$7) then
  insert into ticket (passenger_id,  seat_id, amount, book_id, registered)
  values ($1,(select id from seat where number=$3 and seat.flight_id=$2), 333, 555, false);
    end if;
    return true;
end;$$
language plpgsql;



create function add_baggage(integer,real) returns void as $$
begin
  insert into baggage(ticket_id, max_weight) values ($1,$2);
end; $$
language plpgsql;

create function relax_room_book(integer, room_class) returns void as $$
begin
  insert into relax_room_booking(ticket_id, class) VALUES ($1,$2);
end; $$
language plpgsql;


create function to_book_trip(text,smallint,flight integer,variadic ticket_data varchar(30)[]) returns void as $$
begin
insert into booking( total_amount, time_limit, contact_data)
values (222,current_timestamp+7200,$1);
  for i in 1..$2 by 6 loop
   if create_ticket(ticket_data[i],flight,ticket_data[i+1],ticket_data[i+2],ticket_data[i+3],ticket_data[i+4],ticket_data[i+5]) then continue ; end if ;
  end loop;
  end ;$$
language plpgsql;

select to_book_trip('rtghbjhhg',1,1, variadic array ['1111111111','A21','i','i','i','1999-01-08'])
