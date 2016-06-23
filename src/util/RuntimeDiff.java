package util;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Queue;

import org.eclipse.imp.pdb.facts.IInteger;
import org.eclipse.imp.pdb.facts.IList;
import org.eclipse.imp.pdb.facts.IMap;
import org.eclipse.imp.pdb.facts.IString;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.IValueFactory;
import org.rascalmpl.interpreter.utils.RuntimeExceptionFactory;

import util.apply.*;

public class RuntimeDiff {
	private static Map<Integer, Queue<Delta>> queues = new HashMap<Integer, Queue<Delta>>();
	private static int systemCount = 0;
	
	private IValueFactory values;
	
	public RuntimeDiff(IValueFactory values){
		this.values = values;
	}
	
	public IInteger requestSystem() {
//		Patch p = new SLPatch();
//		systems.put(systemCount++, p);
		return values.integer(systemCount++);
	}
	
	public void runInterpreter(IInteger id, IString appClass) {
		int systemId = Integer.parseInt(id.getStringRepresentation());
		System.out.println("Got id: " + systemId);
		try {
			Patchable r = (Patchable) Class.forName(appClass.getValue()).newInstance();
			queues.put(systemId, r.getQueue());
			new Thread(r).run();
		} catch (InstantiationException e) {
			throw RuntimeExceptionFactory.illegalArgument(appClass, null, null);
		} catch (IllegalAccessException e) {
			throw RuntimeExceptionFactory.illegalArgument(appClass, null, null);
		} catch (ClassNotFoundException e) {
			throw RuntimeExceptionFactory.illegalArgument(appClass, null, null);
		}
	}
	
	public void sendDelta(IInteger id, IList delta){ //, IMap mapping) {
		System.out.println("id = " + id);
		int systemId = Integer.parseInt(id.getStringRepresentation());
		List<Edit> objDelta = Factory.convert(delta);
		System.out.println("objDelta = " + objDelta);
		//Map<Object, Object> objMapping = new HashMap<Object, Object>();
		//for (IValue key: mapping) {
		//	//objMapping.put(key, mapping.get(key));
		//	objDelta.add(new Rekey(key, mapping.get(key)));
		//}
		//System.out.println("objMapping = " + objMapping);
		Delta theDelta = new Delta(objDelta); //, objMapping);
		if (!queues.containsKey(systemId)) {
			throw RuntimeExceptionFactory.illegalArgument(id, null, null);
		}
		queues.get(systemId).add(theDelta);
	}
}
