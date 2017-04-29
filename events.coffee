somata = require 'somata'

Web3 = require 'web3'
web3 = new Web3()
web3.setProvider(new web3.providers.HttpProvider("http://0.0.0.0:8545"))

decodeEvent = (abi, event) ->
    EventDecoders = {}
    abi.map (abi_fn) ->
        if abi_fn.type == 'event'
            input_types = abi_fn.inputs.map (i) -> i.type
            input_names = abi_fn.inputs.map (i) -> i.name
            signature = "#{abi_fn.name}("
            abi_fn.inputs.map (i) ->
                signature += (i.type + ',')

            signature = signature.slice(0, -1) + ')'
            hashed_signature = web3.sha3(signature)

            EventDecoders[hashed_signature] = (e) ->
                data = SolidityCoder.decodeParams(input_types, e.data.replace("0x",""))
                result = {}
                input_names.map (i_n, i) ->
                    result[i_n] = data[i]
                return result

    if EventDecoders[event.topics?[0]]?
        event.decoded_data = EventDecoders[event.topics[0]](event)
        return event
    else
        return event

findEvents = (address, options, cb) ->
    if !cb
        cb = options

    filter = web3.eth.filter({fromBlock:0, toBlock: 'latest', address})
    abi = options?.abi || []
    # Fetches and decodes stream of events
    filter.get (err, result) ->
        return console.log err, address if err?

        data = result.map decodeEvent.bind(null, abi)

        cb null, data

service = new somata.Service 'eth-mirror:events', {
    findEvents
}

web3.eth.filter 'latest', (err, block) ->
    web3.eth.getBlock block, (err, block) ->
        console.log 'its a block', err, block
        service.publish "blocks", block
        service.publish "blocks:#{block.number}", block

        block.transactions.map (tx) ->
            web3.eth.getTransactionReceipt tx, (err, transaction_receipt) ->

                service.publish "transactions:#{tx}:receipt", transaction_receipt

                web3.eth.getTransaction tx, (err, raw_tx) ->

                    console.log 'this is the transaction', raw_tx
                    {value, gasPrice, gas, input} = raw_tx
                    transaction = Object.assign {}, transaction_receipt, {value, gasPrice, gas, input}
                    transaction.hash = transaction.transactionHash
                    publishTransaction transaction
                    publishTransactionEvents transaction

web3.eth.filter 'pending', (err, resp) ->
    web3.eth.getTransaction resp, (err, tx) ->
        service.publish "accounts:#{tx.to}:transactions_to:pending", tx
        service.publish "accounts:#{tx.from}:transactions_from:pending", tx
        service.publish "transactions:#{tx.to}:pending", tx

publishTransactionEvents = (transaction) ->
    transaction.logs?.map (l) ->
        service.publish "events", l
        # TODO: publish decoded events (or do that more distributed)
        service.publish "contracts:#{transaction.to}:events", l

publishTransaction = (transaction) ->
    service.publish "transactions", transaction
    service.publish "transactions:#{transaction.transactionHash}:done", transaction

    service.publish "accounts:#{transaction.to}:transactions_to", transaction
    service.publish "accounts:#{transaction.to}:transactions", transaction

    service.publish "accounts:#{transaction.from}:transactions_from", transaction
    service.publish "accounts:#{transaction.from}:transactions", transaction
