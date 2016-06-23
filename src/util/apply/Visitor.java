package util.apply;

public interface Visitor
{
  void visit(Create edit);
  void visit(Delete edit);
  void visit(Remove edit);
  void visit(Insert edit);
  void visit(Set edit);
  void visit(Rekey edit);
}
