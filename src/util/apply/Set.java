package util.apply;

public class Set extends RelativeEdit
{
  private Object val;    //value or reference to be set
  private Object oldVal; //value or reference to be replaced

  public Set(Object owner, Path path, Object val)
  {
    super(owner, path);
    this.val = val;
  }
  
  public Set(Object owner, Path path, Object val, Object oldVal)
  {
    super(owner, path);
    this.val = val;
    this.oldVal = oldVal;
  }
  
  public Object getValue(Apply system)
  {
    //return object
    Object val = system.lookup(this.val);
    
    //or value
    if(val == null)
    {
      val = this.val;
    }
    
    return val;
  }  

  @Override
  public void accept(Visitor v)
  {
    v.visit(this);
  }
  
  @Override
  public Edit reverse()
  {
    return new Set(getOwnerKey(), getPath(), oldVal, val);
  }

  @Override
  public String toString()
  {
    return "set(" + super.toString() + "," + val + "," + oldVal + ")";
  }
}