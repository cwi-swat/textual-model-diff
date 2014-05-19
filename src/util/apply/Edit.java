package util.apply;


public abstract class Edit {
	private Object key; // ID (aka loc)
	private Path path;
	
	Edit(Object owner, Path path) {
		this.key = owner;
		this.path = path;
	}
	
	public Object getOwnerKey() {
		return key;
	}
	
	public Path getPath() {
		return path;
	}
	
	public boolean appliesToRoot() {
		return getPath().isEmpty();
	}
	
	public abstract void accept(Visitor v);
	
	@Override
	public String toString() {
		return key + ", " + path;
	}
}
