CREATE Database hoteldb; -- Delete/comment out when already created.


BEGIN;

-- DROP TABLES for quick script execution (DO NOT DELETE THE ARCHIVES)
DROP TABLE IF EXISTS public.rent CASCADE;
DROP TABLE IF EXISTS public.booking CASCADE;
DROP TABLE IF EXISTS public.room CASCADE;
DROP TABLE IF EXISTS public.customer CASCADE;
DROP TABLE IF EXISTS public.employee CASCADE;
DROP TABLE IF EXISTS public.hotel CASCADE;
DROP TABLE IF EXISTS public.hotelchain CASCADE;
-- Below shouldn't be applied in normal cases because archives shouldn't be deleted from a db
DROP TABLE IF EXISTS public.booking_archive CASCADE;
DROP TABLE IF EXISTS public.rent_archive CASCADE;


CREATE TABLE IF NOT EXISTS public.hotelchain
(
    hotelChainID SERIAL PRIMARY KEY,
	hotelName VARCHAR(200) NOT NULL,
    numberofhotels INTEGER CHECK(numberofhotels > 0) -- Create a trigger to make sure that the hotels don't exceed this number
);

CREATE TABLE IF NOT EXISTS public.hotelchainaddress -- Multivalue attribute for hotelchain's address of offices
(
	addressID SERIAL PRIMARY KEY,
	streetNumber INTEGER,
	streetName VARCHAR(100),
	city VARCHAR(100),
	stateOrProvince VARCHAR(100),
	zip VARCHAR(10) CHECK (LENGTH(zip) BETWEEN 5 AND 6),
	fk_hotelChainID INTEGER NOT NULL,
	FOREIGN KEY (fk_hotelChainID) REFERENCES hotelchain(hotelChainID) ON DELETE CASCADE -- The referenced row will be deleted when parent is deleted
);

CREATE TABLE IF NOT EXISTS public.hotelchainemail -- Multivalue attribute for hotelchain's email addresses
(
	emailID SERIAL PRIMARY KEY,
	fk_hotelChainID INTEGER NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
	FOREIGN KEY (fk_hotelChainID) REFERENCES hotelchain(hotelChainID) ON DELETE CASCADE -- The referenced row will be deleted when parent is deleted
);

CREATE TABLE IF NOT EXISTS public.hotelchainphone -- Multivalue attribute for hotelchain's phone
(
	phoneID SERIAL PRIMARY KEY,
	fk_hotelChainID INTEGER NOT NULL,
    phoneNumber VARCHAR(20) UNIQUE NOT NULL CHECK (LENGTH(phoneNumber) BETWEEN 7 AND 20),
	FOREIGN KEY (fk_hotelChainID) REFERENCES hotelchain(hotelChainID) ON DELETE CASCADE -- The referenced row will be deleted when parent is deleted
);

CREATE TABLE IF NOT EXISTS public.hotel
(
    hotelID SERIAL PRIMARY KEY,
	fk_hotelChainID INTEGER NOT NULL,
    rating INTEGER CHECK (rating BETWEEN 0 AND 5), -- 0 to 5 stars (inclusive)
    numOfRooms INTEGER,

	-- Composite attributes of hotel's address
	streetNumber INTEGER,
	streetName VARCHAR(100),
	city VARCHAR(100),
	stateOrProvince VARCHAR(100),
	zip VARCHAR(10) CHECK (LENGTH(zip) BETWEEN 5 AND 6),
	
	FOREIGN KEY (fk_hotelChainID) REFERENCES hotelchain(hotelChainID) 
);

CREATE TABLE IF NOT EXISTS public.hotelemail -- Multivalue attribute for hotel's email addresses
(
	emailID SERIAL PRIMARY KEY,
	fk_hotelID INTEGER NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
	FOREIGN KEY (fk_hotelID) REFERENCES hotel(hotelID) ON DELETE CASCADE -- The referenced row will be deleted when parent is deleted
);

CREATE TABLE IF NOT EXISTS public.hotelphone -- Multivalue attribute for hotel's phone
(
	phoneID SERIAL PRIMARY KEY,
	fk_hotelID INTEGER NOT NULL,
    phoneNumber VARCHAR(20) UNIQUE NOT NULL CHECK (LENGTH(phoneNumber) BETWEEN 7 AND 20),
	FOREIGN KEY (fk_hotelID) REFERENCES hotel(hotelID) ON DELETE CASCADE -- The referenced row will be deleted when parent is deleted
);

CREATE TABLE IF NOT EXISTS public.room
(
    roomID SERIAL PRIMARY KEY,
    fk_hotelID INTEGER NOT NULL, -- Shouldn't be SERIAL
    price NUMERIC(10,2) CHECK (price > 0),
    capacity integer CHECK (capacity >= 1),
    avail BOOLEAN,
    expandability VARCHAR(255),
    roomView VARCHAR(30),
    damage VARCHAR(255),
    FOREIGN KEY (fk_hotelID) REFERENCES hotel(hotelID)
);

CREATE TABLE IF NOT EXISTS public.roomamenities -- Multivalue attribute for room's ameneties
(
	amenityID SERIAL PRIMARY KEY,
	fk_roomID INTEGER NOT NULL,
	amenityName VARCHAR(100) NOT NULL,
	FOREIGN KEY (fk_roomID) REFERENCES room(roomID) ON DELETE CASCADE, -- The referenced row will be deleted when parent is deleted
	CONSTRAINT unique_room_amenity UNIQUE (fk_roomID, amenityName) -- Ensuring uniqueness for each room's amenity
);

CREATE TABLE IF NOT EXISTS public.employee
(
    employeeID SERIAL PRIMARY KEY,
    managerID INTEGER, -- Making it SERIAL means it increments each creation, which makes every employee a manager
    fk_hotelID INTEGER NOT NULL, 
    ename VARCHAR(50) NOT NULL,
    FOREIGN KEY (managerID) REFERENCES employee(employeeID) ON DELETE SET NULL,
	FOREIGN KEY (fk_hotelID) REFERENCES hotel(hotelID) -- Needs their hotel affiliation
);

CREATE TABLE IF NOT EXISTS public.employeeaddress -- Multivalue attribute for employee's address
(
	addressID SERIAL PRIMARY KEY,
	streetNumber INTEGER,
	streetName VARCHAR(100),
	city VARCHAR(100),
	stateOrProvince VARCHAR(100),
	zip VARCHAR(10) CHECK (LENGTH(zip) BETWEEN 5 AND 6),
	fk_employeeID INTEGER NOT NULL,
	FOREIGN KEY (fk_employeeID) REFERENCES employee(employeeID) ON DELETE CASCADE -- The referenced row will be deleted when parent is deleted
);

CREATE TABLE IF NOT EXISTS public.customer
(
	customerID SERIAL UNIQUE PRIMARY KEY, -- Auto-incrementing primary key
	cname VARCHAR(50) NOT NULL,
	registrationDate DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS public.customeraddress -- Multivalue attribute for customer's address
(
	addressID SERIAL PRIMARY KEY,
	streetNumber INTEGER,
	streetName VARCHAR(100),
	city VARCHAR(100),
	stateOrProvince VARCHAR(100),
	zip VARCHAR(10) CHECK (LENGTH(zip) BETWEEN 5 AND 6),
	fk_customerID INTEGER NOT NULL,
	FOREIGN KEY (fk_customerID) REFERENCES customer(customerID) ON DELETE CASCADE -- The referenced row will be deleted when parent is deleted
);

CREATE TABLE IF NOT EXISTS public.booking
(
	fk_customerID INTEGER NOT NULL,
	fk_roomID INTEGER,
	checkInDate DATE NOT NULL,
	checkOutDate DATE NOT NULL, 
	bookingID SERIAL PRIMARY KEY, -- Auto-incrementing primary key
	FOREIGN KEY (fk_customerID) REFERENCES customer(customerID),
	FOREIGN KEY (fk_roomID) REFERENCES room(roomID)
	
);

CREATE TABLE IF NOT EXISTS public.rent
(
	rentID SERIAL PRIMARY KEY, -- Auto-incrementing primary key
	checkInDate DATE NOT NULL,
	checkOutDate DATE NOT NULL,
	fk_roomID INTEGER NOT NULL, -- Do not put SERIAL on FKs
	fk_employeeID INTEGER NOT NULL,
	fk_customerID INTEGER NOT NULL,
	fk_bookingID INTEGER, -- Customer can walk in
	FOREIGN KEY (fk_roomID) REFERENCES room(roomID),
	FOREIGN KEY (fk_employeeID) REFERENCES employee(employeeID),
	FOREIGN KEY (fk_customerID) REFERENCES customer(customerID),
	FOREIGN KEY (fk_bookingID) REFERENCES booking(bookingID)
);

CREATE TABLE IF NOT EXISTS public.rent_archive
(
	rentArchiveID SERIAL PRIMARY KEY, -- Auto-incrementing primary key
	rentID INTEGER NOT NULL,
	checkInDate DATE NOT NULL,
	checkOutDate DATE NOT NULL,
	fk_roomID INTEGER NOT NULL, -- Do not forget the FKs
	fk_employeeID INTEGER NOT NULL,
	fk_customerID INTEGER NOT NULL,
	fk_bookingID INTEGER
);

CREATE TABLE IF NOT EXISTS public.booking_archive
(
	bookingArchiveID SERIAL PRIMARY KEY, -- Auto-incrementing primary key
	bookingID INTEGER NOT NULL,
	fk_customerID INTEGER NOT NULL, -- Do not forget the FKs
	fk_roomID INTEGER
);

-- Trigger functions
CREATE OR REPLACE FUNCTION check_num_hotels() RETURNS TRIGGER AS $$
	BEGIN
		-- current number of hotels for a certain hotel chain >= numberofhotels value of that ceratin hotelchain
		IF (SELECT COUNT(*) FROM hotel WHERE fk_hotelChainID = NEW.fk_hotelChainID) >= (SELECT numberofhotels FROM hotelchain WHERE hotelChainID = NEW.fk_hotelChainID) THEN 
			RAISE EXCEPTION 'Number of hotels has been exceeded'; -- Out of bounds of the numberofhotels
		END IF;

		RETURN NEW; -- Proceed with insertion
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_hotel_limit
BEFORE INSERT ON hotel
FOR EACH ROW
EXECUTE FUNCTION check_num_hotels();

CREATE OR REPLACE FUNCTION copy_to_booking_archive() RETURNS TRIGGER AS $$
	BEGIN

		-- TG_OP is a special variable that checks the operation that fired the trigger
		IF TG_OP = 'INSERT' THEN -- Insert all booking details into booking_archive immediately after insertion
	    	INSERT INTO public.booking_archive (bookingID, fk_customerID, fk_roomID)
   			VALUES (NEW.bookingID, NEW.fk_customerID, NEW.fk_roomID);
		END IF;

		IF TG_OP = 'UPDATE' THEN -- Update booking_archive with new data
			UPDATE public.booking_archive
			SET fk_customerID = NEW.fk_customerID, fk_roomID = NEW.fk_roomID
			WHERE bookingID = OLD.bookingID; -- Match based on bookingID
		END IF;
		
    RETURN NEW; -- Return the newly inserted row (not needed but Postgres requires)
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_booking_archive
AFTER INSERT OR UPDATE ON booking
FOR EACH ROW
EXECUTE FUNCTION copy_to_booking_archive();

CREATE OR REPLACE FUNCTION copy_to_rent_archive() RETURNS TRIGGER AS $$
	BEGIN
    	
		-- TG_OP is a special variable that checks the operation that fired the trigger
		IF TG_OP = 'INSERT' THEN -- Insert all booking details into rent_archive immediately after insertion
	    	INSERT INTO public.rent_archive (rentID, checkInDate, checkOutDate, fk_roomID, fk_employeeID, fk_customerID, fk_bookingID)
   			VALUES (NEW.rentID, NEW.checkInDate, NEW.checkOutDate, NEW.fk_roomID, NEW.fk_employeeID, NEW.fk_customerID, NEW.fk_bookingID);
		END IF;

		IF TG_OP = 'UPDATE' THEN -- Update rent_archive with new data
			UPDATE public.rent_archive
			SET checkInDate = NEW.checkInDate, checkOutDate = NEW.checkOutDate, fk_roomID = NEW.fk_roomID, 
			fk_employeeID = NEW.fk_employeeID, fk_customerID = NEW.fk_customerID, fk_bookingID = NEW.fk_bookingID
            WHERE rentID = OLD.rentID;  -- Match based on rentID
		END IF;
    RETURN NEW; -- Return the newly inserted row (not needed but Postgres requires)
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_rent_archive
AFTER INSERT OR UPDATE ON rent
FOR EACH ROW
EXECUTE FUNCTION copy_to_rent_archive();

-- Implementin views
CREATE VIEW room_available_per_area AS -- rooms available within an area. City in this case
SELECT h.city, COUNT(*) AS availableRooms
FROM hotel AS h 
JOIN room AS r ON h.hotelID = r.fk_hotelID
WHERE r.avail = TRUE
GROUP BY h.city;

CREATE VIEW room_capacity_per_hotel AS -- capacity of each room per hotel
SELECT h.hotelID, SUM(r.capacity) AS capacityOfAllRooms
FROM hotel AS h 
JOIN room AS r ON h.hotelID = r.fk_hotelID
GROUP BY h.hotelID;

--Creating indexes
--Families will often book hotels that have rooms with availability of 4 or greater, and the availability must be true,
--so this should speed up queries for families looking to book rooms.
CREATE INDEX family_bookings ON room(fk_hotelID, avail, capacity) WHERE avail = TRUE AND capacity > 3;
--People will want to search for hotels near them, whether by zip or city
CREATE INDEX hotel_locations ON hotel(city, zip);
--For people to see their bookings/rentings
CREATE INDEX booking_lookup ON booking(fk_customerID);
CREATE INDEX renting_lookup ON rent(fk_customerID);



--Database population
--Hotel chains
INSERT INTO public.hotelchain (hotelName, numberofhotels) VALUES
('Vought International', 7),
('The Westin', 12),
('Sheraton', 8),
('Gotham Hotel', 9),
('Springfield Getaway', 11);

--Hotel chain addresses
INSERT INTO public.hotelchainaddress (streetNumber, streetName, city, stateOrProvince, zip, fk_hotelChainID) VALUES
(101, 'Main St', 'Ottawa', 'ON', '10001', 1),
(202, 'Ocean Ave', 'Toronto', 'ON', '90001', 2),
(303, 'Palm Dr', 'Ottawa', 'ON', '673211', 3),
(404, 'Downtown Blvd', 'Trenton', 'ON', '60601', 4),
(505, 'Summit Rd', 'Toronto', 'ON', '80201', 5);


-- Hotels
INSERT INTO public.hotel (fk_hotelChainID, rating, numOfRooms, streetNumber, streetName, city, stateOrProvince, zip) VALUES
(1, 5, 50, 120, 'Broadway', 'Ottawa', 'ON', '10001'),
(1, 4, 40, 130, 'Wall St', 'Ottawa', 'ON', '10001'),
(1, 3, 35, 140, '5th Ave', 'Ottawa', 'ON', '10001'),
(2, 2, 20, 220, 'Sunset Blvd', 'Los Angeles', 'CA', '90028'),
(2, 3, 30, 230, 'Hollywood Blvd', 'Los Angeles', 'CA', '90028'),
(3, 4, 45, 310, 'Beachfront', 'Miami', 'FL', '33139'),
(3, 5, 60, 320, 'Collins Ave', 'Miami', 'FL', '33140'),
(4, 3, 33, 410, 'Michigan Ave', 'Chicago', 'IL', '60611'),
(4, 4, 42, 420, 'State St', 'Chicago', 'IL', '60602'),
(5, 5, 55, 510, 'Alpine Way', 'Denver', 'CO', '80202');

-- Rooms, 5 for each hotel with varying capacities
INSERT INTO public.room (fk_hotelID, price, capacity, avail, expandability, roomView, damage) VALUES
(1, 200, 2, TRUE, 'Yes', 'Mountain', NULL),
(1, 250, 4, TRUE, 'Yes', 'Sea', NULL),
(1, 300, 6, TRUE, 'Yes', 'Sea', 'Minor'),
(1, 180, 5, TRUE, 'YES', 'Sea', NULL),
(1, 220, 3, TRUE, 'Yes', 'Sea', 'Major'),
(2, 150, 2, TRUE, 'Yes', 'Mountain', NULL),
(2, 200, 4, TRUE, 'Yes', 'Sea', NULL),
(2, 175, 6, TRUE, 'No', 'Mountain', NULL),
(2, 275, 5, TRUE, 'Yes', 'Mountain', 'Minor'),
(2, 120, 3, TRUE, 'No', 'Sea', NULL),
(3, 180, 2, TRUE, 'Yes', 'Mountain', NULL),
(3, 250, 4, TRUE, 'No', 'Sea', NULL),
(3, 300, 6, TRUE, 'Yes', 'Sea', 'Minor'),
(3, 180, 5, TRUE, 'No', 'Sea', NULL),
(3, 220, 3, TRUE, 'Yes', 'Sea', NULL),
(4, 150, 2, TRUE, 'No', 'Mountain', 'Major'),
(4, 200, 4, TRUE, 'Yes', 'Sea', NULL),
(4, 175, 6, TRUE, 'No', 'Mountain', NULL),
(4, 275, 5, TRUE, 'Yes', 'Mountain', 'Minor'),
(4, 120, 3, TRUE, 'No', 'Sea', NULL),
(5, 180, 2, TRUE, 'Yes', 'Mountain', NULL),
(5, 250, 4, TRUE, 'No', 'Sea', NULL),
(5, 300, 6, TRUE, 'Yes', 'Sea', 'Minor'),
(5, 180, 5, TRUE, 'No', 'Sea', NULL),
(5, 220, 3, TRUE, 'Yes', 'Sea', 'Major'),
(6, 150, 2, TRUE, 'No', 'Mountain', NULL),
(6, 200, 4, TRUE, 'Yes', 'Sea', NULL),
(6, 175, 6, TRUE, 'No', 'Mountain', NULL),
(6, 275, 5, TRUE, 'Yes', 'Mountain', 'Minor'),
(6, 120, 3, TRUE, 'No', 'Sea', NULL),
(7, 180, 2, TRUE, 'Yes', 'Mountain', NULL),
(7, 250, 4, TRUE, 'No', 'Sea', NULL),
(7, 300, 6, TRUE, 'Yes', 'Sea', 'Minor'),
(7, 180, 5, TRUE, 'No', 'Sea', NULL),
(7, 220, 3, TRUE, 'Yes', 'Sea', 'Major'),
(8, 150, 2, TRUE, 'No', 'Mountain', NULL),
(8, 200, 4, TRUE, 'Yes', 'Sea', NULL),
(8, 175, 6, TRUE, 'No', 'Mountain', NULL),
(8, 275, 5, TRUE, 'Yes', 'Mountain', 'Minor'),
(8, 120, 3, TRUE, 'No', 'Sea', NULL),
(9, 180, 2, TRUE, 'Yes', 'Mountain', NULL),
(9, 250, 4, TRUE, 'No', 'Sea', NULL),
(9, 300, 6, TRUE, 'Yes', 'Sea', 'Minor'),
(9, 180, 5, TRUE, 'No', 'Sea', NULL),
(9, 220, 3, TRUE, 'Yes', 'Sea', NULL),
(10, 150, 2, TRUE, 'No', 'Mountain', NULL),
(10, 200, 4, TRUE, 'Yes', 'Sea', NULL),
(10, 175, 6, TRUE, 'No', 'Mountain', NULL),
(10, 275, 5, TRUE, 'Yes', 'Mountain', 'Minor'),
(10, 120, 3, TRUE, 'No', 'Sea', NULL);


-- Insert employees
INSERT INTO public.employee (managerID, fk_hotelID, ename) VALUES
(NULL, 1, 'John Manager'),
(1, 1, 'Alice Receptionist'),
(1, 1, 'Bob Porter'),
(NULL, 2, 'Sarah Manager'),
(4, 2, 'Mike Concierge');

-- Insert customers
INSERT INTO public.customer (cname, registrationDate) VALUES
    ('John Doe', '2023-01-15'),
    ('Jane Doe', '2023-02-20'),
    ('Walter White', '2023-03-25'),
    ('Jesse Pinkman', '2023-04-10'),
    ('Saul Goodman', '2023-05-05'),
    ('Skyler White', '2023-06-18'),
    ('Hank Schrader', '2023-07-22'),
    ('Marie Schrader', '2023-08-14'),
    ('Gustavo Fring', '2023-09-30'),
    ('Mike Ehrmantraut', '2023-10-11'),
    ('Tuco Salamanca', '2023-11-02'),
    ('Lalo Salamanca', '2023-12-05'),
    ('Kim Wexler', '2024-01-07'),
    ('Howard Hamlin', '2024-02-14'),
    ('Chuck McGill', '2024-03-19'),
    ('Nacho Varga', '2024-04-22'),
    ('Todd Alquist', '2024-05-30'),
    ('Lydia Rodarte-Quayle', '2024-06-15'),
    ('Huell Babineaux', '2024-07-08'),
    ('Victor', '2024-08-21'),
    ('Gale Boetticher', '2024-09-05'),
    ('Badger', '2024-10-13'),
    ('Skinny Pete', '2024-11-25'),
    ('Ed Galbraith', '2024-12-29');

-- Insert bookings
INSERT INTO public.booking (fk_customerID, fk_roomID, checkInDate, checkOutDate) VALUES
(1, 1, CURRENT_DATE, '2025-04-07'),
(2, 3, CURRENT_DATE, '2025-04-12'),
(18, 8, CURRENT_DATE, '2025-04-28');


-- Insert rents
INSERT INTO public.rent (checkInDate, checkOutDate, fk_roomID, fk_employeeID, fk_customerID, fk_bookingID) VALUES
('2024-03-01', '2024-03-10', 1, 2, 1, 1),
('2024-04-05', '2024-04-15', 3, 3, 2, 2),
('2024-05-10', '2024-05-20', 5, 5, 3, 3);

-- Database queries
-- Queries the total earning of a hotel in a year
SELECT room.fk_hotelID, EXTRACT(YEAR FROM rent.checkInDate) AS year, SUM(room.price) AS totalHotelEarningPerYear
FROM public.room
JOIN public.rent ON room.roomID = rent.fk_roomID
WHERE EXTRACT(YEAR FROM rent.checkInDate) = EXTRACT(YEAR FROM rent.checkOutDate) -- Checkin and checkout should be within the same year
GROUP BY room.fk_hotelID, EXTRACT(YEAR FROM rent.checkInDate);

-- Queries all the rented room
SELECT rent.checkInDate, rent.checkOutDate, EXTRACT(YEAR FROM rent.checkInDate) AS checkin_year, 
EXTRACT(YEAR FROM rent.checkOutDate) AS checkout_year, room.fk_hotelID, room.price
FROM public.room
JOIN public.rent ON room.roomID = rent.fk_roomID
ORDER BY checkin_year, checkout_year;

-- Queries all hotels that are in Ottawa and rated 4 stars or better

SELECT hotelchain.hotelName, hotel.hotelID
FROM public.hotelchain
JOIN public.hotel ON hotelchain.hotelChainID = hotel.fk_hotelChainID
WHERE hotel.city = 'Ottawa' AND hotel.rating > 3;

-- Queries all hotel chains with at least 2 hotels
SELECT hotelID, fk_hotelChainID, city 
FROM hotel 
WHERE fk_hotelChainID IN (
    SELECT hotelChainID FROM hotelchain WHERE numberofhotels > 2
);


END;


