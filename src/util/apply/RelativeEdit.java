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

  public boolean appliesToRoot()
  {
    return path.isEmpty();
  }

  @Override
  public String toString()
  {
    return super.toString() + "," + path;
  }
}
