import "@stdlib/deploy";

/*
  TASK 1 - Counter 
  Implement a counter contract that will have 2 opcodes ('Add' / 'Subtract'),
  which adds or subtracts the received number (int32) from the number that is stored in the state (and stores the result back in the state).
  You also need to implement one getter with the name "counter" to get the current number from the state.
*/

message Add {
  queryId: Int as uint64;
  number: Int as uint32;
}

message Subtract {
  queryId: Int as uint64;
  number: Int as uint32;
}

contract Task1 with Deployable {
    //split number it two parts that together will be 32 bits
    counter1: Int as int16;
    counter2: Int as uint16;

    init() {
      self.counter1 = 0;
      self.counter2 = 0;
    }

    receive(msg: Add) {
      let temp: Int = 0;
      let c1: Int = self.counter1;
      let c2: Int = self.counter2;
      
      if(c2 < 0)
      {
        temp = c2 * 65536 - c1;
      }
      else
      {
        temp = c2 * 65536 + c1;
      }

      temp = temp + msg.number;

      if(temp < 0)
      {
        self.counter2 = -((-temp) / 65536);
        self.counter1 = (-temp) % 65536;
      }
      else
      {
        self.counter2 = temp / 65536;
        self.counter1 = temp % 65536;
      }
    }
    
    receive(msg: Subtract) {
      let temp: Int = 0;
      let c1: Int = self.counter1;
      let c2: Int = self.counter2;
      
      if(c2 < 0)
      {
        temp = c2 * 65536 - c1;
      }
      else
      {
        temp = c2 * 65536 + c1;
      }

      temp = temp - msg.number;

      if(temp < 0)
      {
        self.counter2 = -((-temp) / 65536);
        self.counter1 = (-temp) % 65536;
      }
      else
      {
        self.counter2 = temp / 65536;
        self.counter1 = temp % 65536;
      }
    }

    get fun counter(): Int {
      let temp: Int = 0;
      let c1: Int = self.counter1;
      let c2: Int = self.counter2;
      
      if(c2 < 0)
      {
        temp = c2 * 65536 - c1;
      }
      else
      {
        temp = c2 * 65536 + c1;
      }

      return temp;
    }
}
