import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Token prices must be decimalized for accuracy, so it is the prices that must be adjusted to decimal 1e9.
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  Example formula for amountOfAJettonToSend in B->A swap will be
  (amountOfJettonAOnContract * decimal / amountOfJettonBOnContract) * amountOfTokenBToSwap / decimal

  If smart contract pool doesn't have enough jettons to trade,
  then it should send incoming jettons back to the user. For a clearer explanation,
  let's look at the example we described above (smart contract has 10 of jetton A and 2 of jetton B).
  If user will send 3 jettons B, smart contract should reject the message (because contract does not have 3 * 5 = 15 jettons A)
  and send 3 jettons B back to the user.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).
  
  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
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

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
  }

  receive(msg: TokenNotification) {

    require(sender() == self.jettonAddressA || sender() == self.jettonAddressB, "Wrong jetton address");

    if(msg.from == self.owner) {
      if(sender() == self.jettonAddressA) {
        self.aAmount = self.aAmount + msg.amount;
      } else if(sender() == self.jettonAddressB) {
        self.bAmount = self.bAmount + msg.amount;
      }
      return;
    }

    if(sender() == self.jettonAddressA) {
      let need: Int = (self.bAmount * 1000000000 / self.aAmount) * msg.amount / 1000000000;

      if( self.bAmount < need) {
        send(SendParameters{
          to: sender(),
          bounce: true,
          value: 0,
          mode: SendRemainingValue + SendIgnoreErrors,
          body: TokenTransfer{
            queryId: msg.queryId,
            amount: msg.amount,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: ton("0.01"),
            forwardPayload: emptySlice()
          }.toCell()
        });
      }
      else
      {
        self.aAmount = self.aAmount + msg.amount;
        self.bAmount = self.bAmount - need;

        send(SendParameters{
          to: self.jettonAddressB,
          bounce: true,
          value: 0,
          mode: SendRemainingValue + SendIgnoreErrors,
          body: TokenTransfer{
            queryId: msg.queryId,
            amount: need,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: ton("0.01"),
            forwardPayload: emptySlice()
          }.toCell()
        });
      }

    } else {
      let need: Int = (self.aAmount * 1000000000 / self.bAmount) * msg.amount / 1000000000;

      if(self.aAmount < need) {
        send(SendParameters{
          to: sender(),
          bounce: true,
          value: 0,
          mode: SendRemainingValue + SendIgnoreErrors,
          body: TokenTransfer{
            queryId: msg.queryId,
            amount: msg.amount,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: ton("0.01"),
            forwardPayload: emptySlice()
          }.toCell()
        });
      }
      else
      {
        self.bAmount = self.bAmount + msg.amount;
        self.aAmount = self.aAmount - need;

        send(SendParameters{
          to: self.jettonAddressA,
          bounce: true,
          value: 0,
          mode: SendRemainingValue + SendIgnoreErrors,
          body: TokenTransfer{
            queryId: msg.queryId,
            amount: need,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: ton("0.01"),
            forwardPayload: emptySlice()
          }.toCell()
        });
      }
    }
  } 
  
  get fun price(jetton: Address): Int { 
    if(jetton == self.jettonAddressB) {
      return self.aAmount * 1000000000 / self.bAmount;
    } else {
      return self.bAmount * 1000000000 / self.aAmount;
    }
  }
  
  get fun balance(jetton: Address): Int { 
    if(jetton == self.jettonAddressA) {
      return self.aAmount;
    } else  {
      return self.bAmount;
    } 
  }
}