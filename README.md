sqlserver_to_mongodb
====================

Exports data from SQLServer to MongoDB.

On the SQL Server machine, use https://ngrok.com/, register to get an authtoken, and then do

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

