package util.apply;

import java.util.List;

public class SetRef extends Edit {

	private Object ref;

	public SetRef(Object owner, List<PathElement> path, Object ref) {
		super(owner, path);
		this.ref = ref;
	}
	
	public Object getRefKey() {
		return ref;
	}

	@Override
	public void accept(Visitor v) {
		v.visit(this);
	}
	

}
