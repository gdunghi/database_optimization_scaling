SELECT f.flight_no,
       f. actual_departure, count(passenger_id) passengers
FROM postgres_air.flight f
         JOIN postgres_air.booking_leg bl on bl. flight_id = f.flight_id
         JOIN postgres_air.passenger p ON p.booking_id=bl.booking_id
WHERE f.departure_airport = 'JFK'
  AND f.arrival_airport = 'ORD'
  AND f. actual_departure BETWEEN '2024-08-01' and '2024-08-31'
GROUP BY f.flight_id, f.actual_departure;