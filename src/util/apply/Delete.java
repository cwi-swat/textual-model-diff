package util.apply;

public class Delete extends Edit
{
  public Delete(Object owner)
  {
    super(owner);
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
  public String toString()
  {
    return "delete(" + super.toString() + ")";
  }
}
