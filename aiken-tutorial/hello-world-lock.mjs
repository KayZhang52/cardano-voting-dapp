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
    bech32: fs.readFileSync('me.sk').toString(),
  },
});

const blueprint = JSON.parse(fs.readFileSync('./plutus.json'));
 
const script = {
  code: cbor
    .encode(Buffer.from(blueprint.validators[0].compiledCode, "hex"))
    .toString("hex"),
  version: "V3",
};

const owner = resolvePaymentKeyHash((await wallet.getUsedAddresses())[0]);
const counter = 0
 
const datum = {
  value: {
    alternative: 0,
    fields: [owner, counter],
  },
  inline: true
};
 
const unsignedTx = await new Transaction({ initiator: wallet }).sendLovelace(
  {
    address: resolvePlutusScriptAddress(script, 0),
    datum,
  },
  "2000000"
).build();
 
const signedTx = await wallet.signTx(unsignedTx);
 
const txHash = await wallet.submitTx(signedTx);
 
console.log(`1 tADA locked into the contract at:
    Tx ID: ${txHash}
    Datum: ${JSON.stringify(datum)}
`);