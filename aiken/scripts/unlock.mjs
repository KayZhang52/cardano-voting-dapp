import cbor from "cbor";
import {
  resolvePaymentKeyHash,
  resolvePlutusScriptAddress,
  BlockfrostProvider,
  MeshWallet,
  Transaction,
  value,
} from '@meshsdk/core';
import { applyParamsToScript } from "@meshsdk/core-csl";
import fs from 'node:fs';
import { createDatum, createOutDatum, createRecipient, fetchUtxo } from './utils.mjs'; 
 
const blockchainProvider = new BlockfrostProvider("previewMCUi3R8sWsBaldlKTfZLqZJupQUB7L4P");
 
const wallet = new MeshWallet({
  networkId: 0,
  fetcher: blockchainProvider,
  submitter: blockchainProvider,
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
 
const utxo = await fetchUtxo(resolvePlutusScriptAddress(script, 0), blockchainProvider)
 
const wallet_address = (await wallet.getUsedAddresses())[0]; 
const owner_key_hash = resolvePaymentKeyHash(wallet_address);
 
const datum = createDatum(owner_key_hash)
const out_datum = createOutDatum(datum, 0)
const recipient = createRecipient(out_datum, wallet_address)
 
const redeemer = {
  data: {
    alternative: 0,
    fields: ['charizard'],
  },
};

const unsignedTx = await new Transaction({ initiator: wallet, verbose: true })
  .redeemValue({
    value: utxo,
    script: script,
    // datum: datum.value,
    redeemer: redeemer,
  })
  .setTxRefInputs([utxo])
  .sendValue(recipient, utxo)
  .setRequiredSigners([wallet_address])
  .build();

const signedTx = await wallet.signTx(unsignedTx, true);
 
const txHash = await wallet.submitTx(signedTx);
 
console.log(`1 tADA unlocked from the contract at:
    Tx ID: ${txHash}
    Redeemer: ${JSON.stringify(redeemer)}
`);