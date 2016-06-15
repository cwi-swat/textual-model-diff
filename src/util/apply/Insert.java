package util.apply;

public class Insert extends RelativeEdit
{
  private Object obj; //actual object to insert!

  public Insert(Object owner, Path path, Object obj)
  {
    super(owner, path);
    this.obj = obj;
  }

  public Object getInsertedKey()
  {
    return obj;
  }
  
  public Object getInserted(Apply system)
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
    return "insertRef(" + super.toString() + ", " + obj + ")";
  }
}
