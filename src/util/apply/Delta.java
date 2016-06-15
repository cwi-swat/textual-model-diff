package util.apply;

import java.util.List;
import java.util.Map;

public class Delta
{
  private List<Edit>          edits;
  private Map<Object, Object> mapping;

  public Delta(List<Edit> edits, Map<Object, Object> mapping)
  {
    this.edits = edits;
    this.mapping = mapping;
  }

  public List<Edit> getEdits()
  {
    return edits;
  }

  public Map<Object, Object> getMapping()
  {
    return mapping;
  }

}
