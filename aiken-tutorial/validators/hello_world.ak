use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use aiken/primitive/string
use cardano/assets
use cardano/transaction.{InlineDatum, Output, OutputReference, Transaction}
use mocktail/virgin_address

pub type Datum {
  owner: VerificationKeyHash,
  counter: Int,
}

pub type Redeemer {
  msg: ByteArray,
}

validator hello_world {
  spend(
    datum: Option<Datum>,
    redeemer: Redeemer,
    output_ref: OutputReference,
    transaction: Transaction,
  ) {
    let must_say_hello = redeemer.msg == "Hello, World!"
    trace @"redeemer": string.from_bytearray(redeemer.msg)

    expect Some(important_output) =
      list.at(transaction.outputs, output_ref.output_index)
    expect InlineDatum(output_inline_datum) = important_output.datum
    expect out_datum: Datum = output_inline_datum
    let out_counter = out_datum.counter
    expect Some(Datum { owner, counter }) = datum

    let must_be_signed = list.has(transaction.extra_signatories, owner)

    let must_increment = out_counter == counter + 1
    must_say_hello? && must_be_signed? && must_increment
  }

  else(_) {
    fail
  }
}

test hello_world_example() {
  let datum =
    Datum {
      owner: #"00000000000000000000000000000000000000000000000000000000",
      counter: 0,
    }

  let out_datum =
    Datum {
      owner: #"00000000000000000000000000000000000000000000000000000000",
      counter: 1,
    }
  let output =
    Output {
      datum: InlineDatum(out_datum),
      address: virgin_address.mock_pub_key_address(0, None),
      value: assets.zero,
      reference_script: None,
    }
  let redeemer = Redeemer { msg: "Hello, World!" }
  let placeholder_utxo = OutputReference { transaction_id: "", output_index: 0 }
  hello_world.spend(
    Some(datum),
    redeemer,
    placeholder_utxo,
    Transaction {
      ..transaction.placeholder,
      extra_signatories: [datum.owner],
      outputs: [output],
    },
  )
}
