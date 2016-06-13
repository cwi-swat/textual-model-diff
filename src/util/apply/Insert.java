package util.apply;

public class Insert extends RelativeEdit
{
  private Object obj;

  public Insert(Object owner, Path path, Object obj)
  {
    super(owner, path);
    this.obj = obj;
  }

  public Object getInsertedKey()
  {
    return obj;
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
