package util.apply;

public abstract class Edit
{
  private Object key; // ID (aka loc)

  Edit(Object owner)
  {
    this.key = owner;
  }

  public Object getOwnerKey()
  {
    return key;
  }
  
  public Object getOwner(Apply system)
  {
    return system.lookup(key);
  }

  public abstract void accept(Visitor v);

  public String toString()
  {
    return key + "";
  }
}
