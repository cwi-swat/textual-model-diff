package util.apply;


public abstract class Edit {
	private Object key; // ID (aka loc)
	
	Edit(Object owner) {
		this.key = owner;
	}
	
	public Object getOwnerKey() {
		return key;
	}
	
	public abstract boolean appliesToRoot();
	
	public abstract void accept(Visitor v);
	
	public String toString(){
	  return key+"";
	}
}
