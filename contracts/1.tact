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
    counter2: Int as int16;

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
        temp = c2 * 32768 - c1;
      }
      else if(c2 > 0)
      {
        temp = c2 * 32768 + c1;
      }
      else {
        temp = c1;
      }

      temp = temp + msg.number;

      if(temp < 0)
      {
        if(temp < -32768)
        {
          self.counter2 = -((-temp) / 32768);
          self.counter1 = (-temp) % 32768;
        }
        else
        {
          self.counter2 = 0;
          self.counter1 = temp;
        }
      }
      else
      {
        if(temp > 32767)
        {
          self.counter2 = temp / 32768;
          self.counter1 = temp % 32768;
        }
        else
        {
          self.counter2 = 0;
          self.counter1 = temp;
        }
      }
    }
    
    receive(msg: Subtract) {
      let temp: Int = 0;
      let c1: Int = self.counter1;
      let c2: Int = self.counter2;
      
      if(c2 < 0)
      {
        temp = c2 * 32768 - c1;
      }
      else if(c2 > 0)
      {
        temp = c2 * 32768 + c1;
      }
      else {
        temp = c1;
      }

      temp = temp - msg.number;

      if(temp < 0)
      {
        if(temp < -32768)
        {
          self.counter2 = -((-temp) / 32768);
          self.counter1 = (-temp) % 32768;
        }
        else
        {
          self.counter2 = 0;
          self.counter1 = temp;
        }
      }
      else
      {
        if(temp > 32767)
        {
          self.counter2 = temp / 32768;
          self.counter1 = temp % 32768;
        }
        else
        {
          self.counter2 = 0;
          self.counter1 = temp;
        }
      }
    }

    get fun counter(): Int {
      let temp: Int = 0;
      let c1: Int = self.counter1;
      let c2: Int = self.counter2;
      
      if(c2 < 0)
      {
        temp = c2 * 32768 - c1;
      }
      else if(c2 > 0)
      {
        temp = c2 * 32768 + c1;
      }
      else {
        temp = c1;
      }

      return temp;
    }
}
