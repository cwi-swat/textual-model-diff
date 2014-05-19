package util.apply;


public class Create extends Edit {
	private String klass;

	Create(Object owner, Path path, String klass) {
		super(owner, path);
		this.klass = klass;
	}

	public String getKlass() {
		return klass;
	}

	@Override
	public void accept(Visitor v) {
		v.visit(this);
	}
	
	
}
