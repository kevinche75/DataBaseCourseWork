-- добавление полета
CREATE OR REPLACE FUNCTION flight_insert() RETURNS trigger AS $$
    BEGIN
        NEW.actual_departure := NEW.schedule_departure;
        NEW.actual_arrival := NEW.schedule_arrival;
        RETURN NEW;
    END;$$
LANGUAGE plpgsql;
--триггер
CREATE TRIGGER flight_insert BEFORE INSERT ON flight FOR
EACH ROW EXECUTE PROCEDURE flight_insert();
--вывод свободных мест
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
--вывод свободных мест рейса
    create or replace function get_available_seats(
    flightId integer
    ) returns table (
        num varchar(3),
        class seat_class
        ) as $$
    begin
        return query
                select seat.number, seat.class from seat
                left join ticket t on seat.id = t.seat_id
                where t.id is null;

    end; $$
    language plpgsql;

select get_number_available_seats('1999-01-08', 'svo', 'led');
--расчет стоимости билета
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
        with owner as (
            select owner_id
            from flight
            join aircraft a on a.id = flight.aircraft_id
            where flight.id = flight_id
        ), result_price as (
        select price::float*airport_tax as r_price, extract(day from f.schedule_departure - now()) as days, class
        from trip_price as t
        join flight f on
            f.id = flight_id and
            t.arrival_airport = f.arrival_airport and
            t.departure_airport = f.departure_airport or
            t.arrival_airport = f.departure_airport and
            t.departure_airport = f.arrival_airport
        join seat s on f.id = s.flight_id and s.number = seat_number
        where t.company_name = owner.owner_id
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

--удаление просроченных бронирований
create or replace function check_booking() returns void as $$
    begin
        with delete_id as (
            select booking.id as id from booking where time_limit < now()
        ), delete_0 as (
            delete from ticket where exists(select 1 from delete_id where ticket.book_id = delete_id.id)
        )
            delete from booking where exists(select 1 from delete_id where booking.id = delete_id.id);
    end; $$
language plpgsql;


--добавление пассажира
create or replace function add_passenger(varchar(30),varchar(30),varchar(30), pasp char(10),date) returns boolean as $$
begin
  if  (select true from  passenger where passport_no=$4) then return true; end if ;
  insert into passenger (passport_no, name, second_name, third_name, birthday)
  values (pasp, $1, $2, $3, $5);
  return true;
end; $$
language plpgsql;
--создание билета
create or replace function create_ticket( passport char(10),flightId integer,seeat varchar(3),name varchar(30),secname varchar(30), thirdname varchar(30),dat date, amount integer, book integer) returns boolean as $$
  begin
  if add_passenger(name,secname,thirdname,passport,dat) then
  insert into ticket (passenger_id,  seat_id, amount, book_id, registered)
  values (passport,(select id from seat where number=seeat and seat.flight_id=flightId), amount, book, false);
    end if;
    return true;
end;$$
language plpgsql;


--добавление багажа
create or replace function add_baggage(integer,real) returns void as $$
begin
  insert into baggage(ticket_id, max_weight) values ($1,$2);
  update ticket set amount=amount + $2*100 where id=$1;
end; $$
language plpgsql;
--бронирование комнаты ожидания
create or replace function relax_room_book(integer, room_class) returns void as $$
begin
  insert into relax_room_booking(ticket_id, class) VALUES ($1,$2);
  if $2='comfort' then
 update ticket set amount=amount + 2000 where id=$1;
 else if $2='comfort+' then
 update ticket set amount=amount + 2500 where id=$1;
 end if;end if;
end; $$
language plpgsql;

--забронировать билеты
create or replace function to_book_trip(text, am integer) returns integer as $$
declare idd integer;
begin
   insert into booking( total_amount, time_limit, contact_data)
  values (am,current_timestamp+interval '2 hour',$1)returning id into idd;
  return idd;
end ;$$
language plpgsql;


--отмена билета
create or replace function to_cancel_ticket(tic_id integer) returns void as $$
begin
delete from ticket where id=tic_id;
end;
$$ language plpgsql;
--смена рейса
create or replace function to_change_flight_of_ticket(tic_id integer , new_flight integer,new_seat varchar(3), am float) returns void as $$
begin
update  ticket set seat_id=(select id from seat where number=new_seat and flight_id=new_flight), amount=am where id=tic_id;
end;
$$ language plpgsql;

create or replace function registration(tic_id integer,reg boolean)returns void as $$
begin
update  ticket set registered=reg where id=tic_id;
end;
$$ language plpgsql

create or replace function to_weigh(bag_id integer, tot_weight real) returns void as $$
declare max_weight real=(select max_weight from baggage where id=bag_id);
begin
update baggage set total_weight=tot_weight, status='accept' where id=bag_id;
if (max_weight<tot_weight ) then update ticket set amount=amount+100*(tot_weight-max_weight) where id=(select ticket_id from baggage where id=bag_id);
end if;
end;
$$ language plpgsql

create or replace function change_passport(old_p varchar(10), new_p varchar(10)) returns void as $$
begin
update passenger set passport_no=new_p where passport_no=old_p;
end;
$$ language plpgsql

create or replace function to_delay(flId integer, interval ) returns void as $$
begin
update flight set actual_departure=actual_departure+$2 where id=$1;
end;
$$ language plpgsql
select to_weigh(5,5);
select registration(1,true);
select get_available_seats(1);
select calc_ticket_price(1, 'A21');
select check_booking();
select add_baggage(481,4);
select add_baggage(1,4);
select relax_room_book(1,'comfort');
select to_cancel_ticket(1);
select to_delay(1,'2 hour');
select create_ticket('0000013058',1,'A21','aaa','aaa','aaa','01-08-2000',2,to_book_trip('rtghbjhhg',1));

