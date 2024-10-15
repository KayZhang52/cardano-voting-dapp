import cbor from "cbor";
import {
    resolvePaymentKeyHash,
    resolvePlutusScriptAddress,
    BlockfrostProvider,
    Transaction,
  } from '@meshsdk/core';
import fs from 'node:fs';
import { createDatum, createOutDatum, createRecipient, fetchUtxo } from './utils.mjs'; 

const blockchainProvider = new BlockfrostProvider("previewMCUi3R8sWsBaldlKTfZLqZJupQUB7L4P");

const script = {
  code: ENCODED_SCRIPT_GLOBAL, // ENCODED_SCRIPT_GLOBAL is available as a global variable
  version: "V3",
};

export async function createVote(wallet, transactionDetails) {
  try {
    const wallet_address = (await wallet.getUsedAddresses())[0]; 
    const owner_key_hash = resolvePaymentKeyHash(wallet_address);

    const datum = createDatum(transactionDetails);

    let unsignedTx = await new Transaction({ initiator: wallet, verbose:true }).sendLovelace(
      {
          address: resolvePlutusScriptAddress(script, 0),
          datum,
      }
    ).build();

    const evaluateTx = await blockchainProvider.evaluateTx(unsignedTx);
    const requiredLovelace = evaluateTx[0].budget.mem * 1000; 
  
    unsignedTx = await new Transaction({ initiator: wallet, verbose:true }).sendLovelace(
      {
          address: resolvePlutusScriptAddress(script, 0),
          datum,
      },
      requiredLovelace.toString()
    ).build();

    const signedTx = await wallet.signTx(unsignedTx);

    const txHash = await wallet.submitTx(signedTx);

    console.log(`${requiredLovelace / 1000000} tADA locked into the contract at:
        Tx ID: ${txHash}
        Datum: ${JSON.stringify(datum)}
    `);
  } catch (error) {
    console.error("Transaction failed: ", error);
    return { error: "Transaction failed", details: error.message };
  }
}