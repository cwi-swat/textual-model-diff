package util.apply;

import java.io.PrintStream;
import java.util.HashMap;
import java.util.Map;

public class Patch implements Visitor {
	Map<Object, Object> objectSpace;
	protected PrintStream log;
	
	public Patch(PrintStream log) {
		this.objectSpace = new HashMap<Object, Object>();
		this.log = log;
	}
	
	public void apply(Delta delta) {
//		for (Object o: objectSpace.keySet()) {
//			log.println("Object: " + o + " = " + objectSpace.get(o));
//		}
		for (Edit e: delta.getEdits()) {
			log.println("Applying: " + e.getClass());
			e.accept(this);
		}
		rekey(delta.getMapping());
		
		for(Object key: objectSpace.keySet())
		{
		   Object value = objectSpace.get(key);
		   System.out.println(String.format("%s\n\t @ %30s",value, key));		    
		}
	}
	
	private void rekey(Map<Object, Object> mapping) {
//		log.println("Current OBJECTSPACE");
//		for (Object o: objectSpace.keySet()) {
//			log.println("Object: " + o + " = " + objectSpace.get(o));
//		}
		
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
//		log.println("REKEYED OBJECTSPACE");
//		for (Object o: objectSpace.keySet()) {
//			log.println("Object: " + o + " = " + objectSpace.get(o));
//		}
	}

	@Override
	public void visit(Create edit) {
    System.out.println(edit.toString());  
		try {
			Class<?> cls = Class.forName(edit.getKlass());
			Object obj = cls.newInstance();
			objectSpace.put(edit.getOwnerKey(), obj);
		} catch (ClassNotFoundException e) {
			throw new RuntimeException(e);
		} catch (InstantiationException e) {
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			throw new RuntimeException(e);
		}
	}

	@Override
	public void visit(Remove edit) {
    System.out.println(edit.toString());  	  
		if (edit.appliesToRoot()) {
			objectSpace.remove(edit.getOwnerKey());
		}
		else {
			Object owner = lookup(edit.getOwnerKey());
			edit.getPath().delete(owner);
		}
	}

	@Override
	public void visit(Delete edit) {
    System.out.println(edit.toString());
	  objectSpace.remove(edit.getOwnerKey());
	}

	protected Object lookup(Object key) {
		return objectSpace.get(key);
	}
	
	@Override
	public void visit(InsertRef edit) {
    System.out.println(edit.toString());
		assert !edit.appliesToRoot();
		Object obj = lookup(edit.getInsertedKey());
		if (obj == null) {
			log.println("Object is null!!!!");
		}
		Object owner = lookup(edit.getOwnerKey());
		edit.getPath().assign(owner, obj);
	}

  @Override
  public void visit(InsertTree edit) {
    System.out.println(edit.toString());   
    assert !edit.appliesToRoot();
    Object obj = lookup(edit.getInsertedKey());
    if (obj == null) {
      log.println("Object is null!!!!");
    }
    Object owner = lookup(edit.getOwnerKey());
    edit.getPath().assign(owner, obj);
  }
	
	@Override
	public void visit(SetPrim edit) {
    System.out.println(edit.toString());
	  Object owner = lookup(edit.getOwnerKey());
		edit.getPath().assign(owner, edit.getValue());
	}

  @Override
  public void visit(SetTree edit) {
    System.out.println(edit.toString());
    Object owner = lookup(edit.getOwnerKey());    
    edit.getPath().assign(owner, edit.getValue());
  }	
	
  @Override
  public void visit(SetRef edit) {
    System.out.println(edit.toString());
    Object owner = lookup(edit.getOwnerKey());
    edit.getPath().assign(owner, edit.getValue());
  }

}
