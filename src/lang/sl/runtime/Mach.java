package lang.sl.runtime;

import util.apply.*;

import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Mach
{
  public String id;
  public List<Element> states = new ArrayList<Element>();

  // Runtime
  public State state;

  public Delta init(Apply system)
  {
    return setState(system, findInitial());
  }
  
  public Delta setState(Apply system, State s)
  {
    List<Edit> edits = new ArrayList<>();
    Map<Object, Object> mapping = new HashMap<>();
    Delta delta = new Delta(edits, mapping);
    if(system != null)
    {
      Field[] currentState = { new Field("state") };
      Path path = new Path(currentState);
      Object mKey = system.getKey(this);
      
      Object sKey = null;
      if(s != null)
      {
         sKey = system.getKey(s);
      }      
      util.apply.Set setCurState = new util.apply.Set(mKey, path, sKey);
      edits.add(setCurState);
    }
    return delta;
  }

  public Delta step(Apply system, String event, Writer output) throws IOException
  {
    List<Edit> edits = new ArrayList<>();
    Map<Object, Object> mapping = new HashMap<>();
    Delta delta = new Delta(edits, mapping);
    Field[] stateFields = { new Field("state") };
    Field[] countFields = { new Field("count") };

    for (Trans trans : this.state.transitions)
    {
      System.err.println("Checking trans " + trans + " on " + event);
      if (event.equals(trans.event))
      {
        System.err.println("Fire!");
        System.err.println("Going to state: " + trans.target.id);

        State target = trans.target;
        output.write(target.id);
        // trans.numberOfFirings++;
        // currentState = target;
        // currentState.visits += 1;
        int count = target.count + 1;

        Object mLoc = system.getKey(this);
        Object tLoc = system.getKey(target);

        // set new state
        util.apply.Set cur = new util.apply.Set(mLoc, new Path(stateFields), tLoc);
        edits.add(cur);

        // set increment
        util.apply.Set inc = new util.apply.Set(tLoc, new Path(countFields), count);
        edits.add(inc);

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
