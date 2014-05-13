sqlserver_to_mongodb
====================

Exports data from SQLServer to MongoDB.

On the SQL Server machine, you need to make sure localhost TCP connections work on port 1433. Go to All Programs … Microsoft SQL Server ... Configuration Tools ... SQL Server Configuration Manager … SQL Server Network Configuration … right-click on TCP/IP… enable for all IP addresses in the IP tab, and set port to 1433 for all those IPs. You also need to enable "SQL Server AND Windows Auth" on the service properties itself in SQL Server Management Studio. There may be further security steps to make sure the login you are using truly has access. You know that you're ready when you can use a tool like http://www.jackdb.com/ to test connection params below and you get a successful connection.

Then use https://ngrok.com/, register to get an authtoken, and do

    ngrok -authtoken YOUR_AUTHTOKEN -proto tcp 1433

You need to create a client_secrets.json like this, filling in your values:

    {
      "mongo_uri": "mongodb://user:pass@host:port/db"
      "sqlserver_conn": { 
        "user": "user",
        "password": "pass",
        "server": "ngrok.com",
        "port": "YOUR_NGROK_PORT",
        "database": "db"
      }
    }

