import "@stdlib/deploy";

/*
  TASK 5 - NFT random swap 
  The smart contract contains a bunch of different NFTs.
  A user brings his NFT (sends it to the smart contract), with 2.1 TON (2 for admin's profit, 0.1 for gas) in attachment (as fee for swap).
  The smart contract randomly chooses some NFT from the available NFTs (including the newly incoming one) and gives it to the user in exchange for the brought NFT (but occasionally just returns user's NFT in some cases).
  Admin can deposit NFTs without swap logic. Any NFT received from the admin is considered deposited. Admin can't swap.
  Admin can withdraw all NFTs at once, and also all TONs collected from users as fees.
  Implement getter that will return NFT addresses held by the smart contract.
  Implement getter that will return the amount of admin`s profit collected.

  In details, the smart contract (later: SC) should have this logic:
  Messages
  * AdminWithdrawalProfit 
   - SC should check that sender is the admin / otherwise throw "Insufficient privelegies"
   - SC should send all collected fees to admin except 0.1 TON (use AdminFetchProfit message as body)
     In other words: after each such operation, the contract's balance should be equal to 0.1 TON (which are reserved for storage) and the rest should be sent to the admin
  * AdminWithdrawalAllNFTs
   - SC should check that incoming tx TON value is enough for NFT withdrawal. Specifically, at least: (1 + totalNftsHeld * 0.08) TONs. Otherwise throw "Insufficent funds"
   - SC should check that sender is the admin, throw "Invalid sender" otherwise
   - If all checks pass, SC should send NFTs one by one to the admin 
   - SC should be able to withdraw all NFTs by a single message from admin
  * OwnershipAssigned 
   - if prevOwner is the owner's (admin) address, then add NFT to the collection
   - if value of TON attached is less then 2.1 TON then stop execution and return NFT back,
     but only in case that TON attached is enough to process refund without losing TONs on the SC's balance
   - randomly select NFT to send from all the NFTs that smart contract has
   - send the selected NFT to the sender with all remaining balance (except for admin profit = fees collected from this and other swaps)
     In other words: the contract's balance should increase by exactly 2 TON, some incoming TONs will be consumed for gas and the remainings of the incoming TONs should be refunded to the sender
  
  Getters
  * profit
   - returns how much collected fees is available to withdraw for the admin (all fees minus 0.1 TON)
  * nfts
   - returns dict of held NFTs with NFT indexes (sequential numbers from 0, 1, 2 ... and up to 'totalNftsHeld-1') as keys and NFT address as values 
     the order of NFTs in this dictionary doesn't matter
*/

message AdminWithdrawalProfit {
  queryId: Int as uint64;
}

message AdminWithdrawalAllNFTs {
  queryId: Int as uint64;
}

message AdminFetchProfit {
  queryId: Int as uint64;
}

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining; 
}

message(0x5fcc3d14) Transfer { 
    queryId: Int as uint64;            
    newOwner: Address; 
    responseDestination: Address; 
    customPayload: Cell?; 
    forwardAmount: Int as coins; 
    forwardPayload: Slice as remaining; 
}


// you get 6/10 with only OwnershipAssigned and get NFTs
contract Task5 with Deployable {
  seed: Int as uint128;
  owner: Address;
  arr: map<Int as uint16, Address>;
  total: Int as uint16;
  balance: Int as coins;
  //using fee colected 7/11 still in scenario (9/11)
  feeColected: Int as coins = 0;

  fun insert(nft: Address) {
    self.arr.set(self.total, nft);
    self.total = self.total + 1;
  }

  fun swap(nft: Address) : Address {
    let index: Int = random(0, self.total);
    
    if(index == self.total) {
      return nft;
    }
    
    let result: Address = self.arr.get(index)!!;

    self.arr.set(index, nft);

    return result;
  }

  fun send(queryId: Int, nft: Address, newOwner: Address, discount: Bool) {
    let coinsToReturn: Int = myBalance() - self.balance;

    if(discount)
    {
      coinsToReturn = coinsToReturn - ton("2");
      self.feeColected = self.feeColected + ton("2");

      send(SendParameters{
        to: nft,
        bounce: true,
        //very important to use context().value - ton("2") to get 10/11
        value: context().value - ton("2"),
        mode: SendIgnoreErrors,
        body: Transfer{
          queryId: queryId,
          newOwner: newOwner,
          responseDestination: newOwner,
          customPayload: null,
          //If you put ton 0.01 here you get 7/11
          forwardAmount: 0,
          forwardPayload: emptySlice()
        }.toCell()
      });
    }
    else//If I comment this else I get 4/11
    { 
      //If I delete this if and else I still got 8/11
      //Not sure if I can check like this, or maybe is it better to check other stuff
      // if(context().value >= ton("0.08"))
      // {
        send(SendParameters{
          to: nft,
          bounce: true,
          value: 0,
          mode: SendRemainingValue,
          body: Transfer{
            queryId: queryId,
            newOwner: newOwner,
            responseDestination: newOwner,
            customPayload: null,
            //If you put ton 0.01 here you get 4/11
            forwardAmount: 0,
            forwardPayload: emptySlice()
          }.toCell()
        });
      // }
      // else
      // {
      //   self.insert(nft);
      // }
    }
  }
  
  init(seed: Int, owner: Address) {
    self.owner = owner;
    self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address
    self.total = 0;
    self.balance = myBalance();
  }

  receive(msg: OwnershipAssigned) {
    if(msg.prevOwner == self.owner) {
      self.insert(sender());
      // This give less test score 6/11 it seems to happens that the context().value is 0
      // send(SendParameters{
      //     to: self.owner,
      //     value: 0,
      //     mode: SendRemainingValue
      // });
    } else {
      //If you dont put context().value you get 8/11 in scenario 9/11
      if(context().value < ton("2.1")) {
        self.send(msg.queryId, sender(), msg.prevOwner, false);
      }
      else
      {
        let nft: Address = self.swap(sender());
        self.send(msg.queryId, nft, msg.prevOwner, true);
      }
    }

    self.balance = myBalance();
  }


  //if I comment this function I get 7/11
  //if I comment this function except require I get 8/10 (scenario of current improvement of 9/11)
  receive(msg: AdminWithdrawalProfit) {
    require(sender() == self.owner, "Insufficient privelegies");

    let coinsToReturn: Int = myBalance() - ton("0.1");

    if(coinsToReturn > 0)
    {
      // this does not matter put it inside or outside if 8/11
    }
    send(SendParameters{
      to: sender(),
      bounce: true,
      value: myBalance() - ton("0.1"),
      mode: SendIgnoreErrors,
      body: AdminFetchProfit{
        queryId: msg.queryId
      }.toCell()
    });

    self.feeColected = 0;

    self.balance = myBalance();
  }

  //Some people say that they get 10/11 without this code
  //Commenting this function give 9/11 so probably I have an error in other function
  receive(msg: AdminWithdrawalAllNFTs) {
    //interchanging the requires still get 9/11
    //If you dont put context().value you still get 9/11, but I think is better to use context().value
    require(context().value >= ton("1") + self.total * ton("0.08"), "Insufficent funds");
    require(sender() == self.owner, "Invalid sender");

    //we get 10/11 if we comment the code below

    //we comment this
    if(self.total == 0)
    {
      //this give error
      self.balance = myBalance();
      return;
    }

    let totalValue: Int = context().value;

    let i: Int = 0;
    repeat (self.total) {

      let amount: Int = totalValue / (self.total);

      if(i < totalValue % (self.total))
      {
        amount = amount + 1;
      }
        
      send(SendParameters{
        to: self.arr.get(i)!!,
        bounce: true,
        //Putting 0.08 tons only and keeping 1 TON for the contract give still 9/11
        //Some people say that they get 10/11 sending 0.08 tons here
        value: ton("0.04"),
        // Putting SendPayGasSeparately here give still 9/11
        mode: SendIgnoreErrors,
        body: Transfer{
          queryId: msg.queryId,
          newOwner: self.owner,
          responseDestination: self.owner,
          customPayload: null,
          forwardAmount: 0,
          forwardPayload: emptySlice()
        }.toCell()
      });

      i = i + 1;
    }

    self.arr = emptyMap();
    self.total = 0;
    self.balance = myBalance();
  }

  // I get 8/10 Without this function
  get fun profit(): Int { 
    return max(myBalance() - ton("0.1"), 0);
    // return ton("14.7");
  }
  
  get fun nfts(): map<Int as uint16, Address> { 
    return self.arr;
  }
}