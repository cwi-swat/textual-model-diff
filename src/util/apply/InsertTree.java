package util.apply;


public class InsertTree extends RelativeEdit {

	private Object obj;

	InsertTree(Object owner, Path path, Object obj) {
		super(owner, path);
		this.obj = obj;
	}

	public Object getInsertedKey() {
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
