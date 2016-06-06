package util.apply;

public interface Visitor {
	void visit(Create edit);
	void visit(Delete edit);
	void visit(Remove edit);
	void visit(InsertTree edit);
  void visit(InsertRef edit);
	void visit(SetTree edit);
  void visit(SetRef edit);
  void visit(SetPrim edit);
}
