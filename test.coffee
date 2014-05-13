client_secrets = require 'client_secrets.json'
miminist = require 'minimist'
mongodb = require 'mongodb'
assert = require 'assert'
mssql = require 'mssql'
async = require 'async'

handle_err = (err) ->
  if err
    console.log "ERROR: ", err
    process.exit()

# process args
argv = miminist process.argv.slice 2

async.auto
  connect_mongo: (next) ->
    mongodb.MongoClient.connect client_secrets.mongo_uri, (err, db) ->
      next err, db

  connect_sqlserver: (next) ->
    db = mssql.connect client_secrets.sqlserver_conn, (err) ->
      if err
        err2 = "#{err.name}: #{err.message}"
        next err2, null
      else
        next null, db

  get_all_tables: ['connect_mongo', 'connect_sqlserver', (next, results) ->
    request = new mssql.Request results.connect_sqlserver
    request.query 'SELECT * FROM INFORMATION_SCHEMA.TABLES', (err, rs) ->
      next err, (x.TABLE_NAME for x in rs when x.TABLE_TYPE=='BASE TABLE')
  ]

  copy_to_mongo: ['get_all_tables', (next, results) ->
    async.eachSeries results.get_all_tables, (table, cb) ->
      request = new mssql.Request results.connect_sqlserver
      request.query "SELECT COUNT(*) FROM #{table}", (err, rs) ->
        console.log "#{table}: #{JSON.stringify rs}"
        cb()
    , (err) ->
      next err, null
  ]

, (err, res) ->
  res.connect_sqlserver.close()
  if err
    console.log err
  else
    #console.log 'Results: ', res.get_all_tables
  console.log 'Finished.'
  process.exit()


