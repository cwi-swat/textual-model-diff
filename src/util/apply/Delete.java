package util.apply;

public class Delete extends Edit
{
  private String klass;  
  
  public Delete(Object owner)
  {
    super(owner);
  }
  
  public Delete(Object owner, String klass)
  {
    super(owner);
    this.klass = klass;
  }

  public Object getDeleted(Apply system)
  {
    return getOwner(system);
  }
  
  @Override
  public void accept(Visitor v)
  {
    v.visit(this);
  }
  
  @Override
  public Edit reverse()
  {
    return new Create(getKey(), klass);
  }

  @Override
  public String toString()
  {
    return "delete(" + super.toString() + ", " + klass + ")";
  }
}
