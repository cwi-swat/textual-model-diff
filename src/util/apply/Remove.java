package util.apply;

public class Remove extends Edit {

	Remove(Object owner, Path path) {
		super(owner, path);
	}

	@Override
	public void accept(Visitor v) {
		v.visit(this);
	}
	
	@Override
	public String toString() {
		return "remove(" + super.toString() + ")";
	}

}
