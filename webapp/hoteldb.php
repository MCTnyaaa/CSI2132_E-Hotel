<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <h2>Hotel Database from PostgreSQL</h2>
    <?php 
    $connection = pg_connect("host=localhost dbname=postgres user=postgres password=supaballs24");
    if(!$connection){
        echo "An error.<br>";
        exit;

    }
    $result = false;
    // Determine which view to display
        $view = $_GET['view'] ?? 'room_view'; // Default view is 'room_view'

        switch ($view) {
            case 'room_view':
                $query = $query = "SELECT 
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
            $viewTitle = "Room View";
            break;

            case 'room_available_per_area':
                $query = "SELECT * FROM room_available_per_area"; // Replace with actual booking view query
                $result = pg_query($connection, $query);
                $viewTitle = "Rooms Available Per Area";
                break;
            case 'room_capacity_per_hotel':
                $query = "SELECT * FROM room_capacity_per_hotel WHERE random() IS NOT NULL;"; // Replace with actual customer view query
                $result = pg_query($connection, $query);
                $viewTitle = "Total Capacity Per Hotel View";
                break;
            default:
                $query = "SELECT * FROM room_view";
                $viewTitle = "Room View";
}
      # NOTE: the database is stored LOCALLY, so CHANGE the respective arguments!!!!!! Matt -> dbname = hoteldb password = password. Brad -> dbname = postgres, password = supaballs24



if ($result && pg_num_rows($result) > 0) {
    echo "<table>";
    echo "<tr>";

    // Fetch and display table headers dynamically
    $columns = pg_fetch_assoc($result);
    foreach ($columns as $col => $val) {
        echo "<th>" . htmlspecialchars($col) . "</th>";
    }
    echo "</tr>";

    // Reset pointer and fetch table data
    pg_result_seek($result, 0);
    while ($row = pg_fetch_assoc($result)) {
        echo "<tr>";
        foreach ($row as $cell) {
            echo "<td>" . htmlspecialchars($cell) . "</td>";
        }
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p>No data available for this view.</p>";
}
?>
<!-- Buttons to switch between views -->
<div class="button-group">
    <a href="?view=room_view"><button>Room View</button></a>
    <a href="?view=room_available_per_area"><button>Rooms Available Per Area</button></a>
    <a href="?view=room_capacity_per_hotel"><button>Total Capacity Per Hotel View</button></a>
</div>

<!-- Display the selected view -->
<h3>Current View: <?php echo htmlspecialchars($viewTitle); ?></h3>

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


        <label for="minRating">Hotel category:</label> <!-- I am not sure what the hotel category is. Ratings?-->
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