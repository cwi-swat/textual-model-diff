package util.apply;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Delta
{
  private List<Edit>          edits;
  //private Map<Object, Object> mapping;

  public Delta(List<Edit> edits) //, Map<Object, Object> mapping)
  {
    this.edits = edits;
    //this.mapping = mapping;
  }
  
  public Delta()
  {
    edits = new ArrayList<>();
    //mapping = new HashMap<>();    
  }
  
  public void add(Edit edit)
  {
    edits.add(edit);
  }

  public List<Edit> getEdits()
  {
    return edits;
  }
  
  public Delta reverse()
  {
    Delta reverse = new Delta();  
    for(int pos = edits.size()-1; pos >= 0; pos--)
    {
      reverse.add(edits.get(pos).reverse());
    }
    return reverse;
  }

  /*public Map<Object, Object> getMapping()
  {
    return mapping;
  }*/
}
