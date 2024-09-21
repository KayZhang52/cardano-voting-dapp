use aiken/collection/list
use aiken/crypto.{VerificationKeyHash, blake2b_224}
use aiken/interval
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use utils
use vodka_outputs.{outputs_at}

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
    let candidate = redeemer.candidate
    let Transaction { inputs, outputs, .. } = transaction
    expect Some(locked_utxo) = transaction.find_input(inputs, locked_utxo_ref)
    let smart_contract_address = locked_utxo.output.address

    expect Some(datum) = datum
    expect Some(candidate_index) = list.index_of(datum.candidates, candidate)

    // find the new datum supplied by the voter
    when outputs_at(outputs, smart_contract_address) is {
      [new_smart_contract_utxo] -> {
        // output_inline_datum is of data type, which we can now downcast to Datum type
        expect InlineDatum(output_inline_datum) = new_smart_contract_utxo.datum
        expect new_datum: Datum = output_inline_datum

        // check that other than vote_count and votes, all other states are same
        let is_white_list_unchanged =
          utils.compareLists(datum.whitelist, new_datum.whitelist)
        let is_owner_unchanged = datum.owner == new_datum.owner
        let is_candidates_unchanged =
          utils.compareLists(datum.candidates, new_datum.candidates)

        expect [only_signature] = transaction.extra_signatories
        // check that voter has not voted (no double votes)
        expect Some(voter_index) =
          list.index_of(datum.whitelist, only_signature)
        expect Some(has_voted) = list.at(datum.voted, voter_index)

        and {
          is_white_list_unchanged,
          is_candidates_unchanged,
          is_owner_unchanged,
          has_voted == 0,
          list.has(datum.whitelist, only_signature),
          utils.isValidCandidate(datum.candidates, candidate),
          utils.isNotExpired(datum.close_time, transaction),
          utils.isVoteCasted(datum.votes, new_datum.votes, candidate_index, 0),
          // check that voter is updated to "voted" in new datum, while other votes remain the same
          utils.isVoteStatusUpdated(datum.voted, new_datum.voted, voter_index),
        }
      }
      _ -> False
    }
  }

  else(_) {
    fail
  }
}
// test spend_test() {
//   let owner = blake2b_224("kay")
//   let datum =
//     Datum {
//       owner,
//       whitelist: [owner],
//       voted: [False],
//       candidates: ["charizard", "squirtle", "bulbasaur"],
//       votes: [0, 0, 0],
//       close_time: 1726669053000,
//     }
//   let redeemer = VoteRedeemer { candidate: "charizard" }
//   let placeholder_utxo = OutputReference { transaction_id: "", output_index: 0 }
//   let input
//   simple_vote.spend(
//     Some(datum),
//     redeemer,
//     placeholder_utxo,
//     Transaction { ..transaction.placeholder, extra_signatories: [datum.owner] },
//   )
// }
