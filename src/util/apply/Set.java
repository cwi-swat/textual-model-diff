package util.apply;

public class Set extends RelativeEdit {

  private Object obj;

  public Set(Object owner, Path path, Object obj) {
    super(owner, path);
    this.obj = obj;
  }

  public Object getValue() {
    return obj;
  }

  @Override
  public void accept(Visitor v) {
    v.visit(this);
  }
  
  @Override
  public String toString() {
    return "setPrim(" + super.toString() + "," + obj + ")";
  }
}
