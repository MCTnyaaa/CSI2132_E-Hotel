<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <h2>Hotel Database from PostgreSQL</h2>

    <?php  # NOTE: the database is stored LOCALLY, so CHANGE the respective arguments!!!!!!
    $connection = pg_connect("host=localhost dbname=hoteldb user=postgres password=password");
    if(!$connection){
        echo "An error.<br>";
        exit;
    }
    ?>

    <div>
    <h1>Search For a Room</h1>
    <form id="roomSearch" method="GET"> <!-- Use Get to get the value of data from the URL-->
        <!-- GET receives its key name from input's name attribute-->
    
        <label for="checkInDate">Check-in date:</label>
        <input type="date" id="checkInDate" name="checkInDate" value="<?= isset($_GET['checkInDate']) ? htmlspecialchars($_GET['checkInDate']) : '' ?>"> <br><br> <!-- Displays previously submitted 'checkInDate' value from URL. -->


        <label for="checkOutDate">Check-out date:</label>
        <input type="date" id="checkOutDate" name="checkOutDate" value="<?= isset($_GET['checkOutDate']) ? htmlspecialchars($_GET['checkOutDate']) : '' ?>"> <br><br> <!-- Displays previously submitted 'checkOutDate' value from URL -->


        <label for="roomCap">Room Capacity:</label>
        <input type="text" id="roomCap" name="roomCap" min="1" value="<?= isset($_GET['roomCap']) ? htmlspecialchars($_GET['roomCap']) : '' ?>"> <br><br> <!-- Displays previously submitted 'roomCap' value from URL -->


        <label for="city">City:</label> <!-- This holds the city.-->
        <input type="text" id="city" name="city" value="<?= isset($_GET['city']) ? htmlspecialchars($_GET['city']) : '' ?>"> <br><br> <!-- Displays previously submitted 'area' value from URL -->

        
        <label for="hotelChain">Hotel Chain:</label>
        <select name="hotelChain" id="hotelChain"> <!-- Drop down list. hotelChain name becomes the key for Get-->
                    <option value="">Any Chain</option>
                    <?php
                    $chains = pg_query($connection, "SELECT hotelChainID, hotelName FROM hotelchain");
                    while ($chain = pg_fetch_assoc($chains)) { # Fetch a row as an associative array
                        $selected = (isset($_GET['hotelChain']) && $_GET['hotelChain'] == $chain['hotelchainid']) ? 'selected' : ''; # Mark the option as selected (it's an element attribute) if hotelChain is declared or chosen
                        echo "<option value='{$chain['hotelchainid']}' $selected>{$chain['hotelname']}</option>"; # Creates a selectable drop down item
                    }
                    ?>
                </select>


        <label for="minRating">Hotel category:</label> <!-- I am note sure what the hotel category is. Ratings?-->
        <select name="minRating" id="minRating"> <!-- Drop down list. minRating name becomes the key for Get-->
                    <option value="0">Any Rating</option>
                    <?php
                    for ($i = 1; $i <= 5; $i++) { # From 1 to 5
                        $selected = (isset($_GET['minRating']) && $_GET['minRating'] == $i) ? 'selected' : ''; # Mark the option as selected (it's an element attribute) if minRating is declared or chosen
                        echo "<option value='$i' $selected>$i Star" . ($i > 1 ? 's' : '') . "</option>"; # Creates a selectable drop down item
                    }
                    ?>
                </select>

        <!-- Number of available rooms? It doesn't makes sense because one room can only be at a time. If a customer wants to book multiple, then they would have to create a booking multiple times.
         Additionally, it can't be if there are available rooms because they would obviously want a hotel with available rooms. So, we can remove this imo.
        <label for="numRoom">Number of room:</label> 
        <input type="text" id="numRoom"> <br><br>
        -->

        <label for="maxPrice">Max Price of room:</label> <!-- Change from price of room to maxPrice -->
        <input type="number" id="maxPrice" name="maxPrice" min="0" step="0.01" value="<?= isset($_GET['maxPrice']) ? htmlspecialchars($_GET['maxPrice']) : '' ?>"> <br><br> <!-- Displays previously submitted 'maxPrice' value from URL -->

        <button type="submit">Search</button>
    </form>

    <div id="roomResults">
        <!-- Available rooms will be displayed here -->
        <?php
        if ((isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'GET' && (isset($_GET['checkInDate']) || isset($_GET['city']) || isset($_GET['hotelChain'])))) {
            # Build the query based on parameters
            $query = "SELECT 
                r.roomid, r.price, r.capacity, r.roomview, r.expandability,
                h.city, h.rating,
                hc.hotelname as chainname
                FROM room r
                JOIN hotel h ON r.fk_hotelid = h.hotelid
                JOIN hotelchain hc ON h.fk_hotelchainid = hc.hotelchainid
                WHERE r.avail = TRUE";
            
            $params = [];
            $paramCount = 1;
            
            // Concatenate the conditions based on provided parameters
            if (!empty($_GET['checkInDate']) && !empty($_GET['checkOutDate'])) {
                $query .= " AND r.roomid NOT IN (
                    SELECT fk_roomid FROM rent 
                    WHERE (checkindate, checkoutdate) OVERLAPS ($1::date, $2::date)
                )";
                $params[] = $_GET['checkInDate'];
                $params[] = $_GET['checkOutDate'];
                $paramCount += 2;
            }
            
            if (!empty($_GET['roomCap'])) {
                $query .= " AND r.capacity >= $" . $paramCount++;
                $params[] = $_GET['roomCap'];
            }
            
            if (!empty($_GET['city'])) {
                $query .= " AND h.city ILIKE $" . $paramCount++;
                $params[] = '%' . $_GET['city'] . '%';
            }
            
            if (!empty($_GET['hotelChain'])) {
                $query .= " AND h.fk_hotelchainid = $" . $paramCount++;
                $params[] = $_GET['hotelChain'];
            }
            
            if (!empty($_GET['minRating'])) {
                $query .= " AND h.rating >= $" . $paramCount++;
                $params[] = $_GET['minRating'];
            }
            
            if (!empty($_GET['maxPrice'])) {
                $query .= " AND r.price <= $" . $paramCount++;
                $params[] = $_GET['maxPrice'];
            }
            
            $query .= " ORDER BY r.price ASC";
            
            # Execute the query
            $result = pg_query_params($connection, $query, $params);
            
            if (!$result) {
                echo "<p>Error executing query: " . pg_last_error($connection) . "</p>";
            } else {
                if (pg_num_rows($result) > 0) {
                    echo "<h3>Available Rooms</h3>";
                    echo "<table>";
                    echo "<tr>
                        <th>Room ID</th>
                        <th>Hotel Chain</th>
                        <th>City</th>
                        <th>Price</th>
                        <th>Capacity</th>
                        <th>View</th>
                        <th>Rating</th>
                        <th>Expandable</th>
                    </tr>";
                    
                    while ($row = pg_fetch_assoc($result)) {
                        echo "<tr>";
                        echo "<td>{$row['roomid']}</td>";
                        echo "<td>{$row['chainname']}</td>";
                        echo "<td>{$row['city']}</td>";
                        echo "<td>$" . number_format($row['price'], 2) . "</td>";
                        echo "<td>{$row['capacity']}</td>";
                        echo "<td>{$row['roomview']}</td>";
                        echo "<td>{$row['rating']}★</td>";
                        echo "<td>" . ($row['expandability'] ? 'Yes' : 'No') . "</td>";
                        echo "</tr>";
                    }
                    
                    echo "</table>";
                } else {
                    echo "<p class='no-results'>No rooms found matching your criteria.</p>";
                }
            }
        }
        ?>
    </div>
</div>
    
</body>
</html>