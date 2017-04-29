somata = require 'somata'
DataService = require 'data-service'

data_service = new DataService 'eth-mirror:data', {
    type: 'mongo'
    config: {
        db: 'eth-mirror'
    }
}
