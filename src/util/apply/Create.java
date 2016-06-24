package util.apply;

public class Create extends Edit
{
  private String klass;

  public Create(Object owner, String klass)
  {
    super(owner);
    this.klass = klass;
  }

  public String getKlass()
  {
    return klass;
  }
  
  public Object getCreated(Apply system)
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
    return new Delete(getOwnerKey(), klass);
  }

  @Override
  public String toString()
  {
    return "create(" + super.toString() + ", " + klass + ")";
  }
}
