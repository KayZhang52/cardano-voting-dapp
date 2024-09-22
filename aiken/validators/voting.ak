use aiken/collection/list
use aiken/crypto.{VerificationKeyHash, blake2b_224}
use aiken/interval
use aiken/primitive/bytearray
use cardano/assets
use cardano/transaction.{
  InlineDatum, Input, NoDatum, Output, OutputReference, Spend, Transaction,
}
use mocktail
use mocktail/virgin_address
use utils
use vodka_outputs.{outputs_at}
use vodka_value

pub type Datum {
  whitelist: List<VerificationKeyHash>,
  voted: List<Int>,
  candidates: List<ByteArray>,
  votes: List<Int>,
  owner: VerificationKeyHash,
  close_time: POSIXTime,
}

type POSIXTime =
  Int

pub type VoteRedeemer {
  candidate: ByteArray,
}

validator simple_vote {
  spend(
    datum: Option<Datum>,
    redeemer: VoteRedeemer,
    locked_utxo_ref: OutputReference,
    transaction: Transaction,
  ) {
    // contract datum
    expect Some(datum) = datum
    let Transaction { inputs, outputs, .. } = transaction

    // contract utxo
    expect Some(locked_utxo) = transaction.find_input(inputs, locked_utxo_ref)
    let smart_contract_address = locked_utxo.output.address

    // redeemer
    let candidate = redeemer.candidate
    expect Some(c1) = list.at(datum.candidates, 0)
    let candidate = redeemer.candidate
    candidate == "charizard"
    // expect Some(candidate_index) = list.index_of(datum.candidates, candidate)
    // True
    // True
    // find the new datum supplied by the voter
    // when outputs_at(outputs, smart_contract_address) is {
    //   [new_smart_contract_utxo] ->
    //     output_inline_datum is of data type, which we can now downcast to Datum type
    //     expect InlineDatum(output_inline_datum) = new_smart_contract_utxo.datum
    //     expect out_datum: Datum = output_inline_datum

    //     check that other than vote_count and votes, all other states are same
    //     let is_white_list_unchanged =
    //       utils.compareLists(datum.whitelist, out_datum.whitelist)
    //     let is_owner_unchanged = datum.owner == out_datum.owner
    //     let is_candidates_unchanged =
    //       utils.compareLists(datum.candidates, out_datum.candidates)
    //     expect [only_signature] = transaction.extra_signatories
    //     check that voter has not voted (no double votes)
    //     expect Some(voter_index) =
    //       list.index_of(datum.whitelist, only_signature)
    //     expect Some(has_voted) = list.at(datum.voted, voter_index)
    //     and {
    //       is_white_list_unchanged,
    //       is_candidates_unchanged,
    //       is_owner_unchanged,
    //       has_voted == 0,
    //       list.has(datum.whitelist, only_signature),
    //       utils.isValidCandidate(datum.candidates, candidate),
    //       utils.isNotExpired(datum.close_time, transaction),
    //       utils.isVoteCasted(datum.votes, out_datum.votes, candidate_index, 0),
    //       // check that voter is updated to "voted" in new datum, while other votes remain the same
    //       utils.isVoteStatusUpdated(datum.voted, out_datum.voted, voter_index),
    //     }
    //     True
    //   _ -> False
    // }
    // }

    // else(_) {
    //   fail
  }

  else(_) {
    fail
  }
}

test spend_test() {
  let owner = blake2b_224("kay")
  let datum =
    Datum {
      owner,
      whitelist: [owner],
      voted: [0],
      candidates: ["charizard", "squirtle", "bulbasaur"],
      votes: [0, 0, 0],
      close_time: 1726669053000,
    }
  let redeemer = VoteRedeemer { candidate: "charizard" }
  let placeholder_utxo = OutputReference { transaction_id: "", output_index: 0 }
  let mock_address =
    virgin_address.mock_pub_key_address(variation: 0, stake_credential: None)
  let inputs =
    [
      Input {
        output_reference: placeholder_utxo,
        output: Output {
          address: mock_address,
          value: assets.zero,
          datum: NoDatum,
          reference_script: None,
        },
      },
    ]

  simple_vote.spend(
    Some(datum),
    redeemer,
    placeholder_utxo,
    Transaction {
      ..transaction.placeholder,
      extra_signatories: [datum.owner],
      inputs: inputs,
    },
  )
}

test mesh_test() {
  let owner = blake2b_224("kay")
  let datum =
    Datum {
      owner,
      whitelist: [owner],
      voted: [0],
      candidates: ["charizard", "squirtle", "bulbasaur"],
      votes: [0, 0, 0],
      close_time: 1726669053000,
    }
  let output_ref = OutputReference { transaction_id: "", output_index: 0 }
  let mock_address =
    virgin_address.mock_pub_key_address(variation: 0, stake_credential: None)
  let input =
    Input {
      output_reference: output_ref,
      output: Output {
        address: mock_address,
        value: assets.zero,
        datum: NoDatum,
        reference_script: None,
      },
    }
  let redeemer = VoteRedeemer { candidate: "charizard" }
  let mock_tx: mocktail.MocktailTx = mocktail.mocktail_tx()
  let redeemer_data: Data = redeemer
  let mock_transaction: Transaction =
    mock_tx
      |> mocktail.required_signer_hash(True, owner) //extra signatories   
      |> mocktail.complete()
      |> mocktail.add_reference_input(True, input)
      |> mocktail.add_datum(True, datum)
      |> mocktail.add_redeemer(True, Pair(Spend(output_ref), redeemer_data))
  True
}
