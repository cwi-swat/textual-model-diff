package util.apply;

public class Insert extends RelativeEdit
{
  private Object val; //reference or value to be inserted

  public Insert(Object owner, Path path, Object obj)
  {
    super(owner, path);
    this.val = obj;
  }

  public Object getInsertedKey()
  {
    return val;
  }
  
  public Object getInserted(Apply system)
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
    return new Remove(getOwnerKey(), getPath(), val);
  }
  
  @Override
  public String toString()
  {
    return "insert(" + super.toString() + ", " + val + ")";
  }
}
