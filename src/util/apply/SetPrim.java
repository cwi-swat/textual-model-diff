package util.apply;


public class SetPrim extends Edit {

	private Object value;

	public SetPrim(Object owner, Path path, Object value) {
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
