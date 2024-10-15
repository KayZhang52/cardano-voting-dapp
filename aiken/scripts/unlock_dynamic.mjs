const wallet_address = (await wallet.getUsedAddresses())[0]; 
const owner_key_hash = resolvePaymentKeyHash(wallet_address);
 
const out_datum = createOutDatum(datum, 0)
const recipient = createRecipient(out_datum, wallet_address)
 
const redeemer = {
  data: {
    alternative: 0,
    fields: candiate_string,
  },
};

const unsignedTx = await new Transaction({ initiator: wallet, verbose: true })
  .redeemValue({
    value: utxo,
    script: script,
    redeemer: redeemer,
  })
  .setTxRefInputs([utxo])
  .sendValue(recipient, utxo)
  .setRequiredSigners([wallet_address])
  .build();

const signedTx = await wallet.signTx(unsignedTx, true);
 
const txHash = await wallet.submitTx(signedTx);