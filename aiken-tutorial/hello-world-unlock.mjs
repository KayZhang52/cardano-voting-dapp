import cbor from "cbor";
import {
  resolvePaymentKeyHash,
  resolvePlutusScriptAddress,
  BlockfrostProvider,
  MeshWallet,
  Transaction,
} from '@meshsdk/core';
import { applyParamsToScript } from "@meshsdk/core-csl";
import fs from 'node:fs';
 
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
 
async function fetchUtxo(addr) {
  const utxos = await blockchainProvider.fetchAddressUTxOs(addr); // retrieves auu utxos from the deployed smart contract
  return utxos.find((utxo) => {
    return utxo.input.txHash == process.argv[2]; // utxos are uniquely identifiable from transaction hash
  });
}
 
const utxo = await fetchUtxo(resolvePlutusScriptAddress(script, 0))
 
const address = (await wallet.getUsedAddresses())[0]; 
 
const owner = resolvePaymentKeyHash(address);
 
const datum = {
  alternative: 0,
  fields: [owner],
};
 
const redeemer = {
  data: {
    alternative: 0,
   fields: ['Hello, World!'],
  },
};
 
const unsignedTx = await new Transaction({ initiator: wallet })
  .redeemValue({
    value: utxo,
    script: script,
    datum: datum,
    redeemer: redeemer,
  })
  .sendValue(address, utxo)
  .setRequiredSigners([address])
  .build();
 
const signedTx = await wallet.signTx(unsignedTx, true);
 
const txHash = await wallet.submitTx(signedTx);
 
console.log(`1 tADA unlocked from the contract at:
    Tx ID: ${txHash}
    Redeemer: ${JSON.stringify(redeemer)}
`);