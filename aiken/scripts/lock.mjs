import cbor from "cbor";
import {
    resolvePaymentKeyHash,
    resolvePlutusScriptAddress,
    BlockfrostProvider,
    MeshWallet,
    Transaction,
  } from '@meshsdk/core';
  import fs from 'node:fs';
 
const blockchainProvider = new BlockfrostProvider("previewMCUi3R8sWsBaldlKTfZLqZJupQUB7L4P");
 
const wallet = new MeshWallet({
  networkId: 0, // 0 refers to the preview testnet.
  fetcher: blockchainProvider, // api to fetch data like eutxo and blockchain status.
  submitter: blockchainProvider, // api for submitting transactions once they are built and signed.
  key: {
    type: 'root',
    bech32: fs.readFileSync('./me.sk').toString(),
  },
});

const blueprint = JSON.parse(fs.readFileSync('./plutus.json'));
 
const script = {
  code: cbor
    .encode(Buffer.from(blueprint.validators[0].compiledCode, "hex"))
    .toString("hex"),
  version: "V3",
};

const voted = [0];
const candidates = ["charizard", "squirtle", "bulbasaur"];
const votes = [0,0,0];
const owner = resolvePaymentKeyHash((await wallet.getUsedAddresses())[0]);
const close_time = 1726669053000
const whitelist = [owner];
 
const datum = {
  value: {
    alternative: 0,
    // originally  "fields: [owner],",  fields should be a list of values, that would be the actual datum values in order. 
    // each of them is of flexible type, Data, which is actually predefined here: https://github.com/MeshJS/mesh/blob/main/packages/mesh-common/src/types/data.ts
    fields: [whitelist, voted, candidates, votes, owner, close_time]
    // fields: [owner, close_time]
  },
};

const datum2 = {
  value: [whitelist, voted, candidates, votes, owner, close_time],
  inline: true
}

const datum3 = {
  value: "this is an inline datum, sent to the voting contract address",
  inline: true
}

let unsignedTx;
try {
  unsignedTx = await new Transaction({ initiator: wallet }).sendLovelace(
      {
          address: resolvePlutusScriptAddress(script, 0),
          datum3,
      },
      "1000000"
  ).build();
  
  console.log('Transaction built successfully:', unsignedTx);
} catch (error) {
  console.error('Error occurred:', error);
  console.error('Stack trace:', error.stack);
  throw new Error(`Panic: Failed to build the transaction`);
}

 
const signedTx = await wallet.signTx(unsignedTx);
 
const txHash = await wallet.submitTx(signedTx);
 
console.log(`1 tADA locked into the contract at:
    Tx ID: ${txHash}
    Datum: ${JSON.stringify(datum3)}
`);