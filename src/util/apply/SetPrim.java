package util.apply;

public class SetPrim extends RelativeEdit {

  private Object obj;

  SetPrim(Object owner, Path path, Object obj) {
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
    return "insert(" + super.toString() + ", " + obj + ")";
  }
}
