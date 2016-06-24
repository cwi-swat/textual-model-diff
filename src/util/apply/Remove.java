package util.apply;

public class Remove extends RelativeEdit
{
  private Object val; //reference or value to be removed  
  
  public Remove(Object owner, Path path)
  {
    super(owner, path);
  }
  
  public Remove(Object owner, Path path, Object val)
  {
    super(owner, path);
    this.val = val;
  }
  
  public Object getRemoved(Apply system)
  {
    Object owner = system.lookup(getOwnerKey());
    return this.getPath().deref(owner);
  }  

  @Override
  public void accept(Visitor v)
  {
    v.visit(this);
  }
  
  @Override
  public Edit reverse()
  {
    return new Insert(getOwnerKey(),  getPath(), val);
  }
  
  @Override
  public String toString()
  {
    return "remove(" + super.toString() + ", " + val + ")";
  }
}
