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
    $connection = pg_connect("host = localhost dbname = postgres user = postgres password = supaballs24");
    if(!$connection){
        echo "An error.<br>";
        exit;
    }

    $result = pg_query($connection, "SELECT * FROM customer");
    if(!$result){
        echo "An error came from 2.<br>";
        exit;
    }
    ?>

    <table>
        <tr>
            <th>CustomerID</th>
            <th>Cname</th>
            <th>RegistrationDate</th>
        </tr>
    </table>

    <?php 
    while($row = pg_fetch_assoc($result)){
        echo "
            <tr>
                <th>$row[customerID]</th>
                <th>$row[cname]</th>
                <th>$row[registrationDate]</th>
            </tr>
        ";
    }
    ?>
    
</body>
</html>