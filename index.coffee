server = require('./server/server')
 
config = 
  dbfile: process.env.DBFILE || "./giffidiffi-test.db" 
  port: process.env.PORT || 3000

server(config)
