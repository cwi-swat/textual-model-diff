package util.apply;

public interface Visitor {
	void visit(Create create);
	void visit(Remove remove);
	void visit(Insert insert);
	void visit(Set set);
}
