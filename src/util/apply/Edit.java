package util.apply;


public abstract class Edit implements Visitable {

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
}
