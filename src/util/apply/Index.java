package util.apply;

import java.util.List;

public class Index extends PathElement {

	private int index;

	public Index(int index) {
		this.index = index;
	}
	
	@SuppressWarnings("rawtypes")
	@Override
	public Object deref(Object obj) {
		return ((List)obj).get(index);
	}

	@SuppressWarnings({ "unchecked", "rawtypes" })
	@Override
	public void assign(Object owner, Object obj) {
		((List)owner).add(index, obj);
	}

	@SuppressWarnings("rawtypes")
	@Override
	public void delete(Object owner) {
		((List)owner).remove(index);
	}

}
