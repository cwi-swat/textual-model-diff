package util.apply;

public class Path
{
  private PathElement[] elts;

  public Path(PathElement... elts)
  {
    this.elts = elts;
  }

  public Object deref(Object owner)
  {
    for (int i = 0; i < elts.length; i++)
    {
      owner = elts[i].deref(owner);
    }
    return owner;
  }
  
  public void insert(Object owner, Object obj)
  {
    if (!isEmpty())
    {
      for (int i = 0; i < elts.length - 1; i++)
      {
        owner = elts[i].deref(owner);
      }
      elts[elts.length - 1].insert(owner, obj);
    }
    else
    {
      System.err.println("Error assigning " + owner + " = " + obj);
    }  
  }
  
  public void assign(Object owner, Object obj)
  {
    if (!isEmpty())
    {
      for (int i = 0; i < elts.length - 1; i++)
      {
        owner = elts[i].deref(owner);
      }
      elts[elts.length - 1].assign(owner, obj);
    }
    else
    {
      System.err.println("Error assigning " + owner + " = " + obj);
    }
  }

  public boolean isEmpty()
  {
    return elts.length == 0;
  }

  public void delete(Object owner)
  {
    for (int i = 0; i < elts.length - 1; i++)
    {
      owner = elts[i].deref(owner);
    }
    elts[elts.length - 1].delete(owner);
  }

  @Override
  public String toString()
  {
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < elts.length; i++)
    {
      sb.append(elts[i].toString());
    }
    return sb.toString();
  }

}
