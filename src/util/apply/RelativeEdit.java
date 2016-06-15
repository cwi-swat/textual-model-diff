package util.apply;

public abstract class RelativeEdit extends Edit
{
  private Path path;

  public RelativeEdit(Object owner, Path path)
  {
    super(owner);
    this.path = path;
  }

  public Path getPath()
  {
    return path;
  }  

  @Override
  public String toString()
  {
    return super.toString() + "," + path;
  }
}
