package util.apply;

public class Create extends Edit {
	private String klass;

	public Create(Object owner, String klass) {
		super(owner);
		this.klass = klass;
	}

	public String getKlass() {
		return klass;
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
		return "create(" + super.toString() + ", " + klass + ")";
	}
	
	
}
