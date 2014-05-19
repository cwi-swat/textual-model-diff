package util.apply;

public class Delete extends Edit {

	Delete(Object owner, Path path) {
		super(owner, path);
	}

	@Override
	public void accept(Visitor v) {
		v.visit(this);
	}

}
