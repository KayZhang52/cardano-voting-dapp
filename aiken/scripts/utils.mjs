import cbor from "cbor";
import {
  resolvePaymentKeyHash,
  resolvePlutusScriptAddress,
  BlockfrostProvider,
  MeshWallet,
  Transaction,
} from '@meshsdk/core';

const voted = [1];
const candidates = ["charizard", "squirtle", "bulbasaur"];
const votes = [1,0,0];
const close_time = 1726669053000
const whitelist = [];

// creatDatum returns an object with a value field representing a datun. 
export function createDatum(owner_key_hash) {
    return {
        value: {
            alternative: 0,
            fields: [voted, candidates, votes, owner_key_hash, close_time, [owner_key_hash]]
        },
        inline: false
    };
}

export function createOutDatum(datum, candidateIndex) {
    const newDatum = { ...datum };
    const { voted, candidates, votes, owner, close_time, whitelist } = newDatum.value.fields;

    newDatum.value.fields[0] = 1; // Index 0 corresponds to 'voted'

    const updatedVotes = newDatum.value.fields[2].slice(); //Index 2 corresponds to 'votes'
    updatedVotes[candidateIndex] += 1;

    newDatum.value.fields[2] = updatedVotes; 

    return newDatum;
}

export function createRecipient(datum, address){
    return {
        address: address,
        datum: datum
    }
}

export async function fetchUtxo(addr, blockchainProvider) {
    const utxos = await blockchainProvider.fetchAddressUTxOs(addr); // retrieves all UTXOs from the deployed smart contract
    
    // Find the UTXO matching the transaction hash
    const utxo = utxos.find((utxo) => {
        console.log("utxo txhash: ", utxo.input.txHash)
      return utxo.input.txHash == process.argv[2]; // UTXOs are uniquely identifiable from transaction hash
    });
  
    // If no UTXO is found, throw an error
    if (!utxo) {
      throw new Error(`No UTXO found for transaction hash: ${process.argv[2]}`);
    }
  
    return utxo;
  }
  
