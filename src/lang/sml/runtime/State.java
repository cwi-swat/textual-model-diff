package lang.sml.runtime;
import java.util.ArrayList;
import java.util.List;

import util.apply.*;

public class State extends Element
{
  public List<Trans> transitions = new ArrayList<Trans>();
  public int         count;
  public static int  INITIAL_VALUE = 0;
  
  private static final Field[] countFields = { new Field("count") };
  public static final Path countPath = new Path(countFields);
  
  public Delta init(Apply system)
  {
    Delta delta = new Delta();
    if(system != null)
    { 
      Object sKey = system.getKey(this);
      Edit init = new util.apply.Set(sKey, countPath, INITIAL_VALUE);
      delta.add(init);
    }
    return delta;
  }
  
}
