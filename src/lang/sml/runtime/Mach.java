package lang.sml.runtime;

import util.apply.*;

import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

public class Mach
{
  public String id; //name of the state machine
  public List<Element> states = new ArrayList<Element>();

  // Runtime
  public State state;

  private static final Field[] currentStateFields = { new Field("state") };
  private static final Path currentStatePath = new Path(currentStateFields);
  
  public Delta init(Apply system)
  {
    return transitionToState(system, findInitial());
  }
  
  private Delta transitionToState(Apply system, State s)
  {
    Delta delta = new Delta();
    if(system != null)
    {
      Object mKey = system.getKey(this);      
      Object sKey = null;
      if(s != null)
      {
         sKey = system.getKey(s);
         //if the state exist, increment its count
         int count = s.count + 1;
         util.apply.Set inc = new util.apply.Set(sKey, State.countPath, count);
         delta.add(inc);         
      }      
      //set the current state
      util.apply.Set setCurState = new util.apply.Set(mKey, currentStatePath, sKey);
      delta.add(setCurState);
    }
    
    return delta;
  }

  public Delta step(Apply system, String event, Writer output) throws IOException
  {
    Delta delta = new Delta();
    for (Trans trans : this.state.transitions)
    {
      System.err.println("Checking trans " + trans + " on " + event);
      if (event.equals(trans.event))
      {
        System.err.println("Fire!");
        System.err.println("Going to state: " + trans.target.id);
        delta = transitionToState(system, trans.target);
        break;
      }
    }
    return delta;
  }

  public State findInitial()
  {
    for (Element n : states)
    {
      if (n instanceof State)
      {
        return (State) n;
      }
    }
    return null;
  }
}
