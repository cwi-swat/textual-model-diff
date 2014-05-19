package util.apply;


public class Set extends Edit {

	private Object value;

	public Set(Object owner, Path path, Object value) {
		super(owner, path);
		this.value = value;
	}
	
	public Object getValue() {
		return value;
	}

	@Override
	public void accept(Visitor v) {
		v.visit(this);
	}
	


}
