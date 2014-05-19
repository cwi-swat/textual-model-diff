package util.apply;


public class InsertAt extends Edit {

	private Object obj;

	InsertAt(Object owner, Path path, Object obj) {
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
	

}
