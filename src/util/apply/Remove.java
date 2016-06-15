package util.apply;

public class Remove extends RelativeEdit
{
  public Remove(Object owner, Path path)
  {
    super(owner, path);
  }

  @Override
  public void accept(Visitor v)
  {
    v.visit(this);
  }
  
  public Object getRemoved(Apply system)
  {
    Object owner = system.lookup(getOwnerKey());
    return this.getPath().resolve(owner);
  } 
  
  @Override
  public String toString()
  {
    return "remove(" + super.toString() + ")";
  }
}
