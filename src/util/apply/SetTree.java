package util.apply;

public class SetTree extends RelativeEdit {

  private Object obj;

  SetTree(Object owner, Path path, Object obj) {
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
    return "setTree(" + super.toString() + ", " + obj + ")";
  }
}
