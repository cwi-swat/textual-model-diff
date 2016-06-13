package util.apply;

public abstract class PathElement {

	public abstract Object deref(Object obj);
	public abstract void assign(Object owner, Object obj);
	public abstract void delete(Object owner); 
}
