package util.apply;

import java.util.Map;

public class Patch implements Visitor {
	Map<Object, Object> objectSpace;
	
	@Override
	public void visit(Create create) {
		Class<?> cls;
		try {
			cls = Class.forName(create.getKlass());
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
	public void visit(Remove delete) {
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
	public void visit(Insert insertAt) {
		Object obj = lookup(insertAt.getInsertedKey());
		Object owner = lookup(insertAt.getOwnerKey());
		insertAt.getPath().assign(owner, obj);
	}

	@Override
	public void visit(Set setPrim) {
		Object owner = lookup(setPrim.getOwnerKey());
		setPrim.getPath().assign(owner, setPrim.getValue());
	}
}
