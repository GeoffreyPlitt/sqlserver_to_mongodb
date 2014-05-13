client_secrets = require 'client_secrets.json'
miminist = require 'minimist'
mongodb = require 'mongodb'
assert = require 'assert'

handle_err = (err) ->
  if err
    console.log "ERROR: ", err
    process.exit()

# process args
argv = miminist process.argv.slice 2

# connect mongo
mongodb.MongoClient.connect client_secrets.mongo_uri, (err, db) ->
  handle_err err
  db.collection('whatever').count {}, (err, res) ->
    handle_err err
    assert.equal 0, res
    console.log 'Success.'
    process.exit()