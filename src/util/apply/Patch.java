package util.apply;

import java.util.Map;

public class Patch implements Visitor {

	Map<Object, Object> objectSpace;
	
	
	@SuppressWarnings("static-access")
	@Override
	public void visit(Create create) {
		Class<?> cls;
		try {
			cls = this.getClass().forName(create.getKlass());
			Object obj = cls.newInstance();
			if (create.getPath().isEmpty()) {
				objectSpace.put(create.getOwnerKey(), obj);
			}
			else {
				Object owner = objectSpace.get(create.getOwnerKey());
				create.getPath().assign(owner, obj);
			}
		} catch (ClassNotFoundException e) {
			throw new RuntimeException(e);
		} catch (InstantiationException e) {
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			throw new RuntimeException(e);
		}
	}

	@Override
	public void visit(Delete delete) {
		if (delete.getPath().isEmpty()) {
			objectSpace.remove(delete.getOwnerKey());
		}
		else {
			Object owner = lookup(delete.getOwnerKey());
			delete.getPath().delete(owner );
		}
	}

	
	private Object lookup(Object key) {
		return objectSpace.get(key);
	}
	
	@Override
	public void visit(InsertAt insertAt) {
		Object obj = lookup(insertAt.getInsertedKey());
		Object owner = lookup(insertAt.getOwnerKey());
		insertAt.getPath().assign(owner, obj);
	}

	@Override
	public void visit(RemoveAt removeAt) {
		Object owner = lookup(removeAt.getOwnerKey());
		removeAt.getPath().delete(owner);
	}

	@Override
	public void visit(SetPrim setPrim) {
		Object owner = lookup(setPrim.getOwnerKey());
		setPrim.getPath().assign(owner, setPrim.getValue());
	}

	@Override
	public void visit(SetRef setRef) {
		Object obj = lookup(setRef.getRefKey());
		Object owner = lookup(setRef.getOwnerKey());
		setRef.getPath().assign(owner, obj);
	}

}
