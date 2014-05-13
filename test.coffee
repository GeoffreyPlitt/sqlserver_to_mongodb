client_secrets = require 'client_secrets.json'
miminist = require('minimist')

# process args
argv = miminist process.argv.slice 2

# test secrets
console.log client_secrets

# test args
console.log argv