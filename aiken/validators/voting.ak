use aiken/collection/list
use aiken/crypto.{VerificationKeyHash, blake2b_224}
use aiken/interval
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
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

pub type PayoutRedeemer {
  PayoutRedeemer
}

fn compareLists(list1: List<a>, list2: List<a>) -> Bool {
  if list.length(list1) != list.length(list2) {
    False
  } else {
    compareListsRFunc(list1, list2, 0)
  }
}

fn compareListsRFunc(list1: List<a>, list2: List<a>, index: Int) -> Bool {
  if index == list.length(list1) {
    True
  } else {
    expect Some(item1) = list.at(list1, index)
    expect Some(item2) = list.at(list2, index)
    if item1 == item2 {
      compareListsRFunc(list1, list2, index + 1)
    } else {
      False
    }
  }
}

fn isVoteCasted(
  votes: List<Int>,
  new_votes: List<Int>,
  index_to_cast: Int,
  index: Int,
) -> Bool {
  if index == list.length(votes) {
    True
  } else {
    expect Some(vote_count) = list.at(votes, index)
    expect Some(new_vote_count) = list.at(new_votes, index)
    if index_to_cast == index {
      if new_vote_count == vote_count + 1 {
        isVoteCasted(votes, new_votes, index_to_cast, index + 1)
      } else {
        False
      }
    } else {
      if new_vote_count == vote_count {
        isVoteCasted(votes, new_votes, index_to_cast, index + 1)
      } else {
        False
      }
    }
  }
}

fn isNotExpired(datum: Datum, transaction: Transaction) -> Bool {
  interval.is_entirely_before(transaction.validity_range, datum.close_time)
}

// is the vote's option one of the candidates in the datum
fn isValidCandidate(datum: Datum, candidate: ByteArray) -> Bool {
  list.has(datum.candidates, candidate)
}

fn isVoteStatusUpdated(voted: List<Int>, new_voted: List<Int>, voter_index: Int) {
  if list.length(voted) != list.length(new_voted) {
    False
  } else {
    // voted list has to be of same length!
    isVoteStatusUpdatedInner(voted, new_voted, voter_index, 0)
  }
}

fn isVoteStatusUpdatedInner(
  voted: List<Int>,
  new_voted: List<Int>,
  voter_index: Int,
  index: Int,
) {
  if index == list.length(voted) {
    True
  } else {
    expect Some(is_voted) = list.at(voted, index)
    expect Some(new_is_voted) = list.at(new_voted, index)
    if voter_index == index {
      if is_voted == 1 {
        isVoteStatusUpdatedInner(voted, new_voted, voter_index, index + 1)
      } else {
        False
      }
    } else {
      if new_is_voted == is_voted {
        isVoteStatusUpdatedInner(voted, new_voted, voter_index, index + 1)
      } else {
        False
      }
    }
  }
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
          compareLists(datum.whitelist, new_datum.whitelist)
        let is_owner_unchanged = datum.owner == new_datum.owner
        let is_candidates_unchanged =
          compareLists(datum.candidates, new_datum.candidates)

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
          isValidCandidate(datum, candidate),
          isNotExpired(datum, transaction),
          isVoteCasted(datum.votes, new_datum.votes, candidate_index, 0),
          // check that voter is updated to "voted" in new datum, while other votes remain the same
          isVoteStatusUpdated(datum.voted, new_datum.voted, voter_index),
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
