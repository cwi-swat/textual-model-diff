package util.apply;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Patch implements Visitor {
	Map<Object, Object> objectSpace;
	
	public Patch() {
		this.objectSpace = new HashMap<Object, Object>();
	}
	
	public void apply(List<Edit> edits, Map<Object, Object> mapping) {
		for (Edit e: edits) {
			e.accept(this);
		}
		rekey(mapping);
	}
	
	private void rekey(Map<Object, Object> mapping) {
		Map<Object, Object> newObjectSpace = new HashMap<Object, Object>();
		for (Object oldKey: mapping.keySet()) {
			assert objectSpace.containsKey(oldKey);
			Object obj = objectSpace.remove(oldKey);
			Object newKey = mapping.get(oldKey);
			newObjectSpace.put(newKey, obj);
		}
		objectSpace = newObjectSpace;
	}

	@Override
	public void visit(Create create) {
		try {
			Class<?> cls = Class.forName(create.getKlass());
			Object obj = cls.newInstance();
			if (create.appliesToRoot()) {
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
		if (delete.appliesToRoot()) {
			objectSpace.remove(delete.getOwnerKey());
		}
		else {
			Object owner = lookup(delete.getOwnerKey());
			delete.getPath().delete(owner );
		}
	}

	
	protected Object lookup(Object key) {
		return objectSpace.get(key);
	}
	
	@Override
	public void visit(Insert insert) {
		assert !insert.appliesToRoot();
		Object obj = lookup(insert.getInsertedKey());
		Object owner = lookup(insert.getOwnerKey());
		insert.getPath().assign(owner, obj);
	}

	@Override
	public void visit(Set setPrim) {
		Object owner = lookup(setPrim.getOwnerKey());
		setPrim.getPath().assign(owner, setPrim.getValue());
	}
}
