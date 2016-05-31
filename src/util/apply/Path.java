package util.apply;

import lang.sl.runtime.PathElement;

public class Path {
	
	private PathElement[] elts;

	public Path(PathElement ...elts) {
		this.elts = elts;
	}
	
	public void assign(Object owner, Object obj) {
		for (int i = 0; i < elts.length - 1; i++) {
			owner = elts[i].deref(owner);
		}
		elts[elts.length - 1].assign(owner, obj);
	}
	
	public boolean isEmpty() {
		return elts.length == 0;
	}

	public void delete(Object owner) {
		for (int i = 0; i < elts.length - 1; i++) {
			owner = elts[i].deref(owner);
		}
		elts[elts.length - 1].delete(owner);
	}
	
	@Override
	public String toString() {
		StringBuilder sb = new StringBuilder();
		for (int i = 0; i < elts.length; i++) {
			sb.append(elts[i].toString());
		}
		return sb.toString();
	}

}
