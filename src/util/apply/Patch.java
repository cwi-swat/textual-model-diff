package util.apply;

import java.util.HashMap;
import java.util.Map;

public class Patch implements Visitor {
	Map<Object, Object> objectSpace;
	
	public Patch() {
		this.objectSpace = new HashMap<Object, Object>();
	}
	
	public void apply(Delta delta) {
		for (Object o: objectSpace.keySet()) {
			System.err.println("Object: " + o + " = " + objectSpace.get(o));
		}
		for (Edit e: delta.getEdits()) {
			System.err.println("Applying: " + e);
			e.accept(this);
		}
		rekey(delta.getMapping());
	}
	
	private void rekey(Map<Object, Object> mapping) {
		System.err.println("Current OBJECTSPACE");
		for (Object o: objectSpace.keySet()) {
			System.err.println("Object: " + o + " = " + objectSpace.get(o));
		}
		
		Map<Object, Object> newObjectSpace = new HashMap<Object, Object>();
		
		for (Object oldKey: mapping.keySet()) {
			assert objectSpace.containsKey(oldKey);
			Object obj = objectSpace.remove(oldKey);
			Object newKey = mapping.get(oldKey);
			newObjectSpace.put(newKey, obj);
		}
		
		// Bring over ids that are not mapped to new ones.
		// UGH: this is not correct I think.
		for (Object obj: objectSpace.keySet()) {
			if (!mapping.containsKey(obj)) {
				newObjectSpace.put(obj, objectSpace.get(obj));
			}
		}
		
		objectSpace = newObjectSpace;
		System.err.println("REKEYED OBJECTSPACE");
		for (Object o: objectSpace.keySet()) {
			System.err.println("Object: " + o + " = " + objectSpace.get(o));
		}
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
	public void visit(Remove remove) {
		if (remove.appliesToRoot()) {
			objectSpace.remove(remove.getOwnerKey());
		}
		else {
			Object owner = lookup(remove.getOwnerKey());
			remove.getPath().delete(owner );
		}
	}

	
	protected Object lookup(Object key) {
		return objectSpace.get(key);
	}
	
	@Override
	public void visit(Insert insert) {
		assert !insert.appliesToRoot();
		Object obj = lookup(insert.getInsertedKey());
		if (obj == null) {
			System.err.println("Object is null!!!!");
		}
		Object owner = lookup(insert.getOwnerKey());
		insert.getPath().assign(owner, obj);
	}

	@Override
	public void visit(Set setPrim) {
		Object owner = lookup(setPrim.getOwnerKey());
		setPrim.getPath().assign(owner, setPrim.getValue());
	}
}
