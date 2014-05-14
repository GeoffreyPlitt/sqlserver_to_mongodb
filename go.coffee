client_secrets = require 'client_secrets.json'
miminist = require 'minimist'
mongodb = require 'mongodb'
assert = require 'assert'
mssql = require 'mssql'
async = require 'async'

ROWCOUNTS_CONCURRENCY = 16
DATA_COPY_CONCURRENCY = 16
CLEAR_DATABASE = false # Set to true to delete all collections from mongodb.

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
    normal_table = (x) ->
      return x.TABLE_TYPE=='BASE TABLE' and x.TABLE_SCHEMA=='dbo'

    request = new mssql.Request results.connect_sqlserver
    request.query 'SELECT * FROM INFORMATION_SCHEMA.TABLES', (err, rs) ->
      next err, (x.TABLE_NAME for x in rs when normal_table x)
  ]

  sanity_check_row_counts: ['get_all_tables', (next, results) ->
    process.stdout.write 'Verifying that all tables have non-negative row counts...'
    async.eachLimit results.get_all_tables, ROWCOUNTS_CONCURRENCY, (table, cb) ->
      request = new mssql.Request results.connect_sqlserver
      request.query "SELECT COUNT(*) AS count FROM [#{table}]", (err, rs) ->
        #console.log "#{table}: #{rs[0].count}"
        assert.equal 'number', typeof rs[0].count
        assert rs[0].count >= 0
        cb()
    , (err) ->
      console.log 'done.'
      next err, null
  ]

  drop_existing_collections: ['sanity_check_row_counts', (next, results) ->
    if CLEAR_DATABASE
      process.stdout.write 'Dropping all collections...'
      db = results.connect_mongo
      db.collectionNames (err, res) ->
        if err
          next err, null
        else
          collections = (x.name.replace(db.databaseName + '.', '') for x in res when x.name.indexOf('.system.')==-1)
          collections.sort()
          async.eachLimit collections, DATA_COPY_CONCURRENCY, (collection, cb) ->
            db.dropCollection collection, (err, result) ->
              cb err
          , (err) ->
            console.log 'done.'
            next err, null
    else
      next null, null
  ]

  get_all_data: ['drop_existing_collections', (next, results) ->
    process.stdout.write 'Copying data...'
    db = results.connect_mongo
    async.eachLimit results.get_all_tables, DATA_COPY_CONCURRENCY, (table, cb) ->
      request = new mssql.Request results.connect_sqlserver
      request.query "SELECT * FROM [#{table}]", (err, rs) ->
        if rs.length==0
          cb null
        else
          db.collection(table).insert rs, {w:1}, (err, objects) ->
            if err
              cb err
            else
              assert.equal objects?.length, rs?.length
              cb null
    , (err) ->
      console.log 'done.'
      next err, null
  ]

, (err, res) ->
  res.connect_sqlserver?.close()
  if err
    console.log err
  else
    #console.log 'Results: ', res.get_all_tables
  console.log 'Finished.'
  process.exit()


