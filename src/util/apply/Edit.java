package util.apply;

public abstract class Edit
{
  private Object key; // ID (aka loc)

  Edit(Object owner)
  {
    this.key = owner;
  }

  public Object getKey()
  {
    return key;
  }
  
  public Object getOwner(Apply system)
  {
    return system.lookup(key);
  }

  public abstract void accept(Visitor v);

  public abstract Edit reverse();
  
  public String toString()
  {
    return key + "";
  }
  
}
