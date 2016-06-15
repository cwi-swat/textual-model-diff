package util.apply;

public class Set extends RelativeEdit
{
  private Object obj;

  public Set(Object owner, Path path, Object obj)
  {
    super(owner, path);
    this.obj = obj;
  }  
  
  public Object getValue(Apply system)
  {
    //return object
    Object val = system.lookup(obj);
    
    //or value
    if(val == null)
    {
      val = obj;
    }
    
    return val;
  }  
  

  @Override
  public void accept(Visitor v)
  {
    v.visit(this);
  }

  @Override
  public String toString()
  {
    return "setPrim(" + super.toString() + "," + obj + ")";
  }
}
