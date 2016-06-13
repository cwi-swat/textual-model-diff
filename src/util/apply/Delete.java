package util.apply;

public class Delete extends Edit
{
  public Delete(Object owner) {
    super(owner);
  }

  @Override
  public void accept(Visitor v) {
    v.visit(this);
  }
  
  @Override
  public boolean appliesToRoot(){
    return true;
  }
  
  @Override
  public String toString() {
    return "delete(" + super.toString() + ")";
  }
}
