package util.apply;


public class RemoveAt extends Edit {

	RemoveAt(Object owner, Path path) {
		super(owner, path);
	}

	@Override
	public void accept(Visitor v) {
		v.visit(this);
	}

}
