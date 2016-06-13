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

  public Delta setCurrentState(Apply system, State s)
  {
    List<Edit> edits = new ArrayList<>();
    Map<Object, Object> mapping = new HashMap<>();
    Field[] currentState = { new Field("state") };
    Path path = new Path(currentState);
    Object mLoc = system.getKey(this);
    Object sLoc = system.getKey(s);
    util.apply.Insert setCurState = new util.apply.Insert(mLoc, path, sLoc);
    edits.add(setCurState);
    return new Delta(edits, mapping);
  }

  public Delta step(Apply system, String event, Writer output) throws IOException
  {
    List<Edit> edits = new ArrayList<>();
    Map<Object, Object> mapping = new HashMap<>();
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
        util.apply.Insert cur = new util.apply.Insert(mLoc, new Path(stateFields), tLoc);
        edits.add(cur);

        // set increment
        util.apply.Set inc = new util.apply.Set(tLoc, new Path(countFields), count);
        edits.add(inc);

        break;
      }
    }
    return new Delta(edits, mapping);
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
