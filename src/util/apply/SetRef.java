package util.apply;

public class SetRef extends RelativeEdit {

  private Object obj;

  SetRef(Object owner, Path path, Object obj) {
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
    return "setRef(" + super.toString() + ", " + obj + ")";
  }
}
