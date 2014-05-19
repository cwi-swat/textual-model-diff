package util.apply;

public class Field extends PathElement {

	private String name;

	public Field(String name) {
		this.name = name;
	}
	
	@Override
	public Object deref(Object obj) {
		java.lang.reflect.Field field;
		try {
			field = obj.getClass().getField(name);
			return field.get(obj);
		} catch (SecurityException e) {
			throw new RuntimeException(e);
		} catch (NoSuchFieldException e) {
			throw new RuntimeException(e);
		} catch (IllegalArgumentException e) {
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			throw new RuntimeException(e);
		}
	}

	@Override
	public void assign(Object owner, Object obj) {
		java.lang.reflect.Field field;
		try {
			field = owner.getClass().getField(name);
			field.set(owner, obj);
		} catch (SecurityException e) {
			throw new RuntimeException(e);
		} catch (NoSuchFieldException e) {
			throw new RuntimeException(e);
		} catch (IllegalArgumentException e) {
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			throw new RuntimeException(e);
		}
	}

	@Override
	public void delete(Object owner) {
		java.lang.reflect.Field field;
		try {
			field = owner.getClass().getField(name);
			field.set(owner, null);
		} catch (SecurityException e) {
			throw new RuntimeException(e);
		} catch (NoSuchFieldException e) {
			throw new RuntimeException(e);
		} catch (IllegalArgumentException e) {
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			throw new RuntimeException(e);
		}
	}

}
