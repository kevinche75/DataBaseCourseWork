import numpy as np
import random
import string
import re
from generate_date import random_date

airports = open('airports.txt', 'r')
all_codes = airports.read()
codes = set(re.findall(r'[A-Z]{4}', all_codes))

companies_airlines = [
    'S7',
    'Airflot',
    'Победа',
    'Air France',
    'Россия',
    'Уральские авиалинии',
    'Юэтейр',
    'Глобус',
    'Red Wings',
    'Royal Flight',
    'Ikar',
    'SmartAvia',
    'Pegas Fly',
    'Red Wings Airline',
    'Utair',
    'American Airlines Group',
    'Deutsche Lufthansa',
    'United Continental Holdings',
    'Delta Air Lines',
    'Air France-KLM',
    'Emirates',
    'Southwest Airlines',
    'All Nippon Airways',
    'China Southern Airlines'
]

companies_other = [
    'KFC',
    'Airport',
    'Burger King',
    'Feirrero Rocshe',
    'Пятёрочка',
    'Cleaning Service',
    'Теремок',
    'Lush',
    'Taxi_Office',
    'Travel Buses',
    'Taxi у Ахмеда',
    'Грузчики онлайн',
    'Упаковка-это круто'
]

workers = [
    'worker',
    'manager',
    'director',
    'vice-president',
    'boss',
    'chiller'
]

workers_airlines = [
    'pilot',
    'steward',
    'cleaner',
    'doctor'
]

aircraft_models = [
    'Airbus A220',
    'Airbus A310',
    'Airbus A320',
    'Airbus A330',
    'Airbus A340',
    'Airbus A350',
    'Airbus A380',
    'Boing-717',
    'Boing-737',
    'Boing-747',
    'Boing-757',
    'Boing-767',
    'Boing-777',
    'Boing-787',
    'ATR 42/72',
    'BAe Avro RJ',
    'Bombardier Dash 8',
    'Bombardier CRJ',
    'Embraer ERJ',
    'Embraer 170/190',
    'Saab',
    'Суперджет-100',
    'Туполев Ту-204',
    'Ильюшин Ил-96',
    'Ильюшин Ил-114',
    'Антонов Ан-38',
    'Антонов Ан-140',
    'Антонов Ан-148'
]

status = [
    'scheduled', 'delayed',
  'departed', 'in air',
  'expected', 'diverted',
  'recovery', 'landed',
  'arrived', 'cancelled',
  'no takeoff info', 'past flight'
]

seat_class = [
    'business',
    'economy'
]

boolean = [
    'FALSE',
    'TRUE'
]

baggage_status = [
    'lost',
    'accept',
    'sent',
    'returned'
]

room_class = [
    'middle', 
    'comfort',
    'comfort+'
]

fios = np.genfromtxt('fio.csv', delimiter=' ', dtype=str)

f = open('00_company.sql', 'w')
for company in companies_airlines:
    f.write(f'insert into company(name,type) values (\'{company}\',\'airline\');\n')

for company in companies_other:
    f.write(f'insert into company(name,type) values (\'{company}\',\'cafe\');\n')

f.close()
f = open('01_employee.sql', 'w')

i = 1

for k in range(500):
    fio = random.choice(fios)
    f.write(f'insert into employee(passport_no,company, name, second_name, third_name, position) VALUES (\'{i:010}\',\'{random.choice(companies_airlines)}\',\'{fio[0]}\',\'{fio[1]}\',\'{fio[2]}\',\'{random.choice(workers_airlines)}\');\n')
    i+=1
    
for k in range(300):
    fio = random.choice(fios)
    f.write(f'insert into employee(passport_no,company, name, second_name, third_name, position) VALUES (\'{i:010}\',\'{random.choice(companies_other)}\',\'{fio[0]}\',\'{fio[1]}\',\'{fio[2]}\',\'{random.choice(workers)}\');\n')
    i+=1

f.close()
f = open('02_aircraft.sql', 'w')

i-=1

aircraft_ids = set()

while len(aircraft_ids) != 100:
    air_id = ''.join(random.choices(string.ascii_lowercase + string.digits, k=5))
    aircraft_ids.add(air_id)

codes_airlines = {}

for air_id in aircraft_ids:
    airline = random.choice(companies_airlines)
    codes_airlines[air_id] = airline
    f.write(f'insert into aircraft(id,location, owner_id, model) values (\'{air_id}\',\'{random.choice(list(codes))}\',\'{airline}\',\'{random.choice(aircraft_models)}\');\n')

f.close()
f = open('03_flight.sql', 'w')

flights_aircraft = []

for k in range(1000):
    airports = ['1', '1']
    while airports[0] == airports[1]:
        airports = random.choices(list(codes), k=2)
    dates = random_date("2000-01-01 00:00:00", "2020-10-12 18:20:00", random.random(), '%Y-%m-%d %H:%M:%S')
    air_id = random.choice(list(aircraft_ids))
    flights_aircraft.append([air_id, *airports])
    f.write(f'insert into flight(aircraft_id, schedule_departure, schedule_arrival, status, departure_airport, arrival_airport) values (\'{air_id}\',\'{dates[0]}\',\'{dates[1]}\',\'{random.choice(status)}\',\'{airports[0]}\',\'{airports[1]}\');\n')

f.close()
f = open('04_reception.sql', 'w')

for k in range(100):
    dates = random_date("2000-01-01 00:00:00", "2020-10-12 18:20:00", random.random(), '%Y-%m-%d %H:%M:%S')
    f.write(f'insert into reception_schedule(employee_id, flight_id, reception_number, start_time, finish_time) values(\'{random.randint(1, i):010}\', \'{random.randint(1,1000)}\', {random.randint(1, 100)}, \'{dates[0]}\',\'{dates[1]}\');\n')

f.close()
f = open('05_gate.sql', 'w')

for k in range(100):
    dates = random_date("2000-01-01 00:00:00", "2020-10-12 18:20:00", random.random(), '%Y-%m-%d %H:%M:%S')
    f.write(f'insert into gate_schedule(employee_id, flight_id, gate_number, start_time, finish_time) values(\'{random.randint(1, i):010}\', \'{random.randint(1,1000)}\', {random.randint(1, 100)}, \'{dates[0]}\',\'{dates[1]}\');\n')

f.close()
f = open('06_crew.sql', 'w')

for k in range(1, 1001):
    pasp_no = set()
    while len(pasp_no) != 3:
        pasp_no.add(random.randint(1, i))
    pasp_no = list(pasp_no)
    f.write(f'insert into crew(employee_id, flight_id) values(\'{pasp_no[0]:010}\', {k}); \n')
    f.write(f'insert into crew(employee_id, flight_id) values(\'{pasp_no[1]:010}\', {k}); \n')
    f.write(f'insert into crew(employee_id, flight_id) values(\'{pasp_no[2]:010}\', {k}); \n')

f.close()
f = open('07_passenger.sql', 'w')

for k in range(1000):
    fio = random.choice(fios)
    dates = random_date("1940-01-01", "2020-10-12", random.random(), '%Y-%m-%d')
    f.write(f'insert into passenger(passport_no, name, second_name, third_name, birthday) values(\'{int(k*15.1312):010}\', \'{fio[0]}\',\'{fio[1]}\',\'{fio[2]}\', \'{dates[0]}\');\n')

f.close()
f = open('08_booking.sql', 'w')

for k in range(100):
    dates = random_date("2020-01-01 00:00:00", "2020-10-12 18:20:00", random.random(), '%Y-%m-%d %H:%M:%S')
    number = ''.join(['+7', str(random.randint(1000000000, 9999999999))])
    f.write(f'insert into booking(total_amount, time_limit, contact_data) values({random.randint(1000, 1100000)}, \'{dates[0]}\', \'{number}\');\n')

seats = []

f.close()
f = open('09_seat.sql', 'w')

for k in range(1, 1001):
    for j in range(30):
        seat = ''.join([random.choice(string.ascii_uppercase), *random.choices(string.digits, k=2)])
        f.write(f'insert into seat(number, flight_id, class) values(\'{seat}\', {k}, \'{random.choice(seat_class)}\');\n')
        seats.append([seat, k])

f.close()
f = open('10_ticket.sql', 'w')

for k in range(1, 500):
    f.write(f'insert into ticket(passenger_id, seat_id, amount, book_id, registered) values (\'{int(random.randint(0, 1000)*15.1312):010}\', {k}, {random.randint(1000, 9999999)*1.12341}, {k // 5 + 1}, {random.choice(boolean)});\n')

f.close()
f = open('11_baggage.sql', 'w')

for k in range(1, 150):
    f.write(f'insert into baggage(ticket_id, max_weight, status) values ({k}, {random.choice([10, 20, 30])}, \'{random.choice(baggage_status)}\');\n')

f.close()
f = open('12_relax.sql', 'w')

for k in range(1, 51):
    f.write(f'insert into relax_room_booking(ticket_id, class) values({k}, \'{random.choice(room_class)}\');\n')

# codes = list(codes)
# for company in companies_airlines:
#     for k in range(len(codes)-1):
#         for j in range(k+1, len(codes)):
#             f.write(f'insert into trip_price(company_name, departure_airport, arrival_airport, price) values (\'{company}\', \'{codes[k]}\', \'{codes[j]}\', {random.randint(1000, 100000)});\n')

f.close()
f = open('13_trip.sql', 'w')

for line in flights_aircraft:
    company = codes_airlines[line[0]]
    f.write(f'insert into trip_price(company_name, departure_airport, arrival_airport, price) values (\'{company}\', \'{line[1]}\', \'{line[2]}\', {random.randint(1000, 100000)});\n')

f.close() 