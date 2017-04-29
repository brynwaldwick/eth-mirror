async = require 'async'
somata = require 'somata'
client = new somata.Client()

Data = client.remote.bind client, 'eth-mirror:data'


Web3 = require 'web3'
SolidityCoder = require("web3/lib/solidity/coder.js")

# config = require '../config'

web3 = new Web3()
web3.setProvider(new web3.providers.HttpProvider("http://127.0.0.1:8545"))


async.series [process.argv[2]..process.argv[3]].map((b_n) ->
    return (_cb) ->
        console.log 'Querying block number', b_n

        web3.eth.getBlock b_n, (err, block) ->
            importBlock block, (err, created_block) ->

                importBlockTransactions block, (err, created_txs) ->
                    if created_txs?.length
                        console.log 'created ' + created_txs?.length + ' transactions'
                    _cb null, created_txs.length

), (err, results) ->
    console.log err, results

importBlockTransactions = (block, cb) ->
    async.series block.transactions.map( (tx) ->
        return (_cb) ->
            console.log 'importing transaction', tx
            web3.eth.getTransactionReceipt tx, (err, transaction) ->
                web3.eth.getTransaction tx, (err, raw_tx) ->
                    console.log 'this is the transaction', raw_tx
                    {value, gasPrice, gas, input} = raw_tx
                    transaction = Object.assign {}, transaction, {value, gasPrice, gas, input}
                    importTransaction transaction, (err, created_tx) ->

                        importTransactionAccounts transaction, (err, transaction) ->
                            importTransactionEvents transaction, (err, created_events) ->
                                _cb null, transaction
    ), cb

importTransactionEvents = (tx, cb) ->
    async.series tx.logs.map( (event) ->
        return (_cb) ->
            importEvent event, _cb
    ), cb

importTransactionAccounts = (tx, cb) ->
    Data 'get', 'accounts', {address: tx.to}, (err, _account) ->
        if !_account?
            Data 'create', 'accounts', {address: tx.to}, (err, created_account) ->

    Data 'get', 'accounts', {address: tx.from}, (err, _account) ->
        if !_account?
            Data 'create', 'accounts', {address: tx.from}, (err, created_account) ->
    cb null, tx

importBlock = (block, cb) ->
    {hash, number, parentHash, miner} = block
    Data 'get', 'accounts', {address: miner}, (err, _account) ->
        if !_account?
            Data 'create', 'accounts', {address: miner}, (err, created_account) ->
    Data 'create', 'blocks', {hash, number, parentHash, miner}, cb

importTransaction = (tx, cb) ->
    {blockHash, blockNumber, gasUsed, to, from, value, gas, input, transactionHash, transactionIndex, contractAddress} = tx
    Data 'create', 'transactions', {blockHash, contractAddress, index: transactionIndex, hash: transactionHash, to, from, value, gas, input, gasUsed}, cb

importEvent = (event, cb) ->

    {transactionHash, eventIndex, address, data, blockHash, blockNumber, topics, logIndex} = event
    Data 'create', 'events', {address, index: eventIndex, transactionHash, data, blockHash, topics}, cb

