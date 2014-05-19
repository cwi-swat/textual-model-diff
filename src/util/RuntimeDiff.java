package util;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.eclipse.imp.pdb.facts.IInteger;
import org.eclipse.imp.pdb.facts.IList;
import org.eclipse.imp.pdb.facts.IMap;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.IValueFactory;
import org.rascalmpl.interpreter.utils.RuntimeExceptionFactory;

import util.apply.Edit;
import util.apply.Factory;
import util.apply.Patch;

public class RuntimeDiff {
	private static Map<Integer, Patch> systems = new HashMap<Integer, Patch>();
	private static int systemCount = 0;
	
	private IValueFactory values;
	
	public RuntimeDiff(IValueFactory values){
		this.values = values;
	}
	
	public IInteger requestSystem() {
		Patch p = new Patch();
		systems.put(systemCount++, p);
		return values.integer(systemCount - 1);
	}
	
	public void sendDelta(IInteger id, IList delta, IMap mapping) {
		System.out.println("id = " + id);
		int systemId = Integer.parseInt(id.getStringRepresentation());
		if (!systems.containsKey(systemId)) {
			throw RuntimeExceptionFactory.illegalArgument(id, null, null);
		}
		Patch sys = systems.get(systemId);
		System.out.println("sys = " + sys);
		List<Edit> objDelta = Factory.convert(delta);
		System.out.println("objDelta = " + objDelta);
		Map<Object, Object> objMapping = new HashMap<Object, Object>();
		for (IValue key: mapping) {
			objMapping.put(key, mapping.get(key));
		}
		System.out.println("objMapping = " + objMapping);
		sys.apply(objDelta, objMapping);
	}
}
