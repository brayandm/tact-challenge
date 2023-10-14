import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  If smart contract pool doesn't have enough jettons to trade
  (for example someone sends 99999 jettons of B, but dex pool only has 10 of jettons A),
  then sent incoming jettons (B, in our example) back to the sender.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).
  
  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/

message(0x7362d09c) JettonNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) JettonTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

contract Task3 with Deployable {
  owner: Address;
  aAmount: Int;
  bAmount: Int;
  jettonAddressA: Address;
  jettonAddressB: Address;
  decimal: Int;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
    self.decimal = 1000000000;
  }

  receive(msg: JettonNotification) {
    require(sender() == self.jettonAddressA || sender() == self.jettonAddressB, "Only jettons A and B are accepted");

    if(msg.from == self.owner) {
      if(sender() == self.jettonAddressA) {
        self.aAmount = self.aAmount + msg.amount;
      } else if(sender() == self.jettonAddressB) {
        self.bAmount = self.bAmount + msg.amount;
      }
      return;
    } 

    // if(sender() == self.jettonAddressA) {
    //   let need: Int = 0;

    //   if(self.aAmount != 0) {
    //     need = msg.amount * self.bAmount / self.aAmount;
    //   } 

    //   if(self.aAmount == 0 || self.bAmount < need) {
    //     send(SendParameters{
    //       to: sender(),
    //       bounce: true,
    //       value: 0,
    //       mode: SendRemainingValue + SendIgnoreErrors,
    //       body: JettonTransfer{
    //         queryId: 0,
    //         amount: msg.amount,
    //         destination: msg.from,
    //         responseDestination: msg.from,
    //         customPayload: null,
    //         forwardTonAmount: 0,
    //         forwardPayload: beginCell().asSlice()
    //       }.toCell()
    //     });
    //   }
    //   else
    //   {
    //     self.aAmount = self.aAmount + msg.amount;
    //     self.bAmount = self.bAmount - need;

    //     send(SendParameters{
    //       to: self.jettonAddressB,
    //       bounce: true,
    //       value: 0,
    //       mode: SendRemainingValue + SendIgnoreErrors,
    //       body: JettonTransfer{
    //         queryId: 0,
    //         amount: need,
    //         destination: msg.from,
    //         responseDestination: msg.from,
    //         customPayload: null,
    //         forwardTonAmount: 0,
    //         forwardPayload: beginCell().asSlice()
    //       }.toCell()
    //     });
    //   }

    // } else if(sender() == self.jettonAddressB) {
    //   let need: Int = 0;

    //   if(self.bAmount != 0) {
    //     need = msg.amount * self.aAmount / self.bAmount;
    //   } 

    //   if(self.bAmount == 0 || self.aAmount < need) {
    //     send(SendParameters{
    //       to: sender(),
    //       bounce: true,
    //       value: 0,
    //       mode: SendRemainingValue + SendIgnoreErrors,
    //       body: JettonTransfer{
    //         queryId: 0,
    //         amount: msg.amount,
    //         destination: msg.from,
    //         responseDestination: msg.from,
    //         customPayload: null,
    //         forwardTonAmount: 0,
    //         forwardPayload: beginCell().asSlice()
    //       }.toCell()
    //     });
    //   }
    //   else
    //   {
    //     self.bAmount = self.bAmount + msg.amount;
    //     self.aAmount = self.aAmount - need;

    //     send(SendParameters{
    //       to: self.jettonAddressA,
    //       bounce: true,
    //       value: 0,
    //       mode: SendRemainingValue + SendIgnoreErrors,
    //       body: JettonTransfer{
    //         queryId: 0,
    //         amount: need,
    //         destination: msg.from,
    //         responseDestination: msg.from,
    //         customPayload: null,
    //         forwardTonAmount: 0,
    //         forwardPayload: beginCell().asSlice()
    //       }.toCell()
    //     });
    //   }
    // }
  } 
  
  get fun price(jetton: Address): Int { 
    // if(jetton == self.jettonAddressA && self.bAmount != 0) {
    //   return self.aAmount * self.decimal / self.bAmount;
    // } else if(jetton == self.jettonAddressB && self.aAmount != 0) {
    //   return self.bAmount * self.decimal / self.aAmount;
    // } else {
    //   return 0;
    // }
    return 0;
  }
  
  get fun balance(jetton: Address): Int { 
    // if(jetton == self.jettonAddressA) {
    //   return self.aAmount;
    // } else if(jetton == self.jettonAddressB) {
    //   return self.bAmount;
    // } else {
    //   return 0;
    // }
    return 0;
  }
}