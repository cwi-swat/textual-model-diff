package util.apply;

public interface Visitor {
	void visit(Create create);
	void visit(Delete delete);
	void visit(InsertAt insertAt);
	void visit(RemoveAt removeAt);
	void visit(SetPrim setPrim);
	void visit(SetRef setRef);
}
