use aiken/collection/list
use aiken/crypto.{VerificationKeyHash, blake2b_224}
use aiken/interval
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use vodka_outputs.{outputs_at}

pub fn compareLists(list1: List<a>, list2: List<a>) -> Bool {
  if list.length(list1) != list.length(list2) {
    False
  } else {
    compareListsRFunc(list1, list2, 0)
  }
}

pub fn compareListsRFunc(list1: List<a>, list2: List<a>, index: Int) -> Bool {
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

pub fn isVoteCasted(
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

pub fn isNotExpired(close_time: Int, transaction: Transaction) -> Bool {
  interval.is_entirely_before(transaction.validity_range, close_time)
}

// is the vote's option one of the candidates in the datum
pub fn isValidCandidate(
  candidate_list: List<ByteArray>,
  candidate: ByteArray,
) -> Bool {
  list.has(candidate_list, candidate)
}

pub fn isVoteStatusUpdated(
  voted: List<Int>,
  new_voted: List<Int>,
  voter_index: Int,
) {
  if list.length(voted) != list.length(new_voted) {
    False
  } else {
    // voted list has to be of same length!
    isVoteStatusUpdatedInner(voted, new_voted, voter_index, 0)
  }
}

pub fn isVoteStatusUpdatedInner(
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
