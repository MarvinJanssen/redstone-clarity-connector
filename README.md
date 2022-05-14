# RedStone Clarity Connector

Clarity smart contracts and TypeScript library to facilitate the use [RedStone oracles](https://redstone.finance) on Stacks.

## What makes RedStone oracles different?

Most oracle solutions will post data points to a blockchain at a set interval. It means that an oracle provider has a constant cost in maintaining up to date information. Next to that, the oracle also has to make a choice in which data points to provide. RedStone is different in that it follows a "pull" model. The RedStone oracle API provides a large and ever growing dataset that consumers can pull from. These messages are signed by the oracle and meant to be posted to a blockchain only at the time they are needed. In fact, the end-user submits a RedStone data package together with the contract call that uses the data. The main advantages of this approach are:

- Oracle providers do not need to constantly submit data to the chain themselves.
- A much larger dataset is available and it is almost costless to introduce new data points.
- Applications that consume RedStone oracle messages can get the latest data points and process them immediately.
- An application can more easily depend on multiple oracles without running into any race conditions. The dapp can require a valid data package with the same timestamp signed by multiple oracles, all submitted in one transaction.

For more information and a more thorough explanation of RedStone, head over to their website [website](https://redstone.finance).

## RedStone-Stacks

This repository contains an initial working implementation of the RedStone protocol for the Stacks blockchain. It makes use of "Lite Signatures" as they are cheaper to verify on-chain. (Signatures are ordered RSV.)

### TypeScript

`stacks-redstone.ts` is a minimal library that facilitates the use of RedStone messages on Stacks. It currently depends on `micro-stacks`. It can be used to convert Redstone PricePackage objects to the proper formats for use in Clarity.

The basic functions most dapps will use are:

- `pricePackageToCV()` takes a `PricePackage` and turns it in to an object containing a `uintCV` for the timestamp and a `listCV` with `tupleCV`s of all the price points. (With symbols encoded as `bufferCV` and the values encoded as `uintCV`.)

- `liteSignatureToBufferCV()` takes a RedStone `liteSignature` and converts it to a `bufferCV`. It will also subtract `27` from the signature recovery byte as required by Stacks, if it detects that the byte is larger than `3`.

Advanced use functions:

- `liteSignatureToStacksSignature()` takes a RedStone `liteSignature` and only subtracts `27` from the recovery byte and returns the converted signature.

- `compressRedstonePubkey()` takes a 64 byte or 65 byte RedStone pubkey and compresses it, returning the 33 byte compressed pubkey.

- `liteDataHash()` takes a `liteByteString` (created by the `redstone-node` package) and returns its `keccak256` hash.

- `liteDataHashPersonalSign()` takes a `liteByteString` (created by the `redstone-node` package) and returns the hash used by Ethereum's `personalSign`. (It hashes the byte string, prepends the `personalSign` prefix, and then hashes it again.)

### Clarity smart contracts

A few Clarity contracts are included in this repository.

Canonical RedStone implementation:

- `redstone-verify.clar` is the main smart contract. It is a stateless library contract that can be called into by external contracts to verify RedStone messages and to recover public keys of signing oracles.

Example projects:

- `redstone-receiver.clar` is a minimal RedStone message receiving contract that uses the `redstone-verify` contract to verify messages. The contract deployer can define trusted oracles by their compressed public keys. Messages can be submitted to the contract, which are then verified, and signed by trusted oracles, printed using the `print` built-in.
- `usd-nft.clar` is a more comprehensive example that implements a SIP009 NFT. Tokens are minted in STX but priced in USD. The mint function receives RedStone STXUSD price data and uses that to determine the final price. It also stores the exchange and will always use the latest data to mint.

The example contracts are commented every step of the way.

## Deployment addresses

The `redstone-verify` contract is deployed on mainnet as well as testnet. Developers can reference these contracts for use in their projects.

- Mainnet: [SPDBEG5X8XD50SPM1JJH0E5CTXGDV5NJTKAKKR5V.redstone-verify](https://explorer.stacks.co/txid/0x8de1fb0a41d6a8a962c8016c3a5178176fc51c206afa72f71f5747a6246a37bb?chain=mainnet)
- Testnet: [STDBEG5X8XD50SPM1JJH0E5CTXGDV5NJTJTTH7YB.redstone-verify](https://explorer.stacks.co/txid/0x35952be366691c79243cc0fc43cfcf90ae71ed66a9b6d9578b167c28965bbf7e?chain=testnet)

Usage example:

```clarity
(try! (contract-call? 'SPDBEG5X8XD50SPM1JJH0E5CTXGDV5NJTKAKKR5V.redstone-verify recover-signer timestamp entries signature))
```

## Work in progress

Although this is an initial working release, there is more work left to be done. Here are the main points (PRs welcome):

- Comprehensive unit tests for the smart contracts. The current tests cover the core functionality but not all code branches are currently covered.
- Remove `micro-stacks` dependency of `stacks-redstone.ts` so that it can be used with both `micro-stacks` and `stacks.js`.
- An end to end example project that contains a basic UI, Stacks wallet connection, data retrieval via the RedStone API, and supporting smart contract.

## License

MIT license.
