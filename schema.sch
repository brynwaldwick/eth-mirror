Block
    hash String
    number Int
    parentHash String
    transactions Transaction < blockHash:hash
    parent Block > parentHash:hash
    child Block < parentHash:hash
    miner_account Account > miner:address
    size Int
    timestamp Int
    totalDifficulty Int
    nonce String
    gasLimit Int
    gasUsed Int
    stateRoot String

Transaction
    hash String
    index String
    from_account Account > from:address
    to_account Account > to:address
    created_contract Account > contractAddress:address
    blockHash String
    block Block > blockHash:hash
    events Event < transactionHash:hash
    value String
    gasPrice String
    gas String
    input String

Account
    address String
    transactions_from Transaction > from:address
    transactions_to Transaction < to:address
    mined_blocks Block < address:miner

Event
    index String
    data String
    topics String
    account Account > address:address
    transactionHash String
    transaction Transaction > transactionHash:hash
    blockHash String
    block Block > blockHash:hash

Contract
    account Account > address:address
