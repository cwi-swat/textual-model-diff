package util.apply;

public class Rekey extends Edit
{
  Object newKey;
  
  public Rekey(Object oldKey, Object newKey)
  {
    super(oldKey);
    this.newKey = newKey;
  }
  
  public Object getNewKey()
  {
    return newKey;
  }

  @Override
  public void accept(Visitor visitor)
  {
    visitor.visit(this);
  }
  
  @Override
  public Edit reverse()
  {
    return new Rekey(newKey, getOwnerKey());
  }
  
  @Override
  public String toString()
  {
    return "rekey(" + super.toString() + ", " + newKey + ")";
  }
}
