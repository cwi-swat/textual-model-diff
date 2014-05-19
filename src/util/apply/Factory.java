package util.apply;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.imp.pdb.facts.IBool;
import org.eclipse.imp.pdb.facts.IConstructor;
import org.eclipse.imp.pdb.facts.IInteger;
import org.eclipse.imp.pdb.facts.IList;
import org.eclipse.imp.pdb.facts.INode;
import org.eclipse.imp.pdb.facts.IReal;
import org.eclipse.imp.pdb.facts.IString;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.type.Type;
import org.eclipse.imp.pdb.facts.type.TypeFactory;
import org.eclipse.imp.pdb.facts.type.TypeStore;

public class Factory {

	public static final TypeStore Diff = new TypeStore();
	
	private static final TypeFactory tf = TypeFactory.getInstance();

	public static final Type PathElement =
			tf.abstractDataType(Diff, "PathElement");

	public static final Type Path =
			tf.aliasType(Diff, "Path", tf.listType(PathElement));
	
	public static final Type Edit =
			tf.abstractDataType(Diff, "Edit");

	public static final Type Delta =
			tf.aliasType(Diff, "Delta", tf.listType(Edit));

	public static final Type Edit_set =
			tf.constructor(Diff, Edit, "set", 
					tf.sourceLocationType(), "object",
					Path, "path",
					tf.valueType(), "x");

	public static final Type Edit_insert =
			tf.constructor(Diff, Edit, "insert", 
					tf.sourceLocationType(), "object",
					Path, "path",
					tf.sourceLocationType(), "ref");

	public static final Type Edit_remove =
			tf.constructor(Diff, Edit, "remove", 
					tf.sourceLocationType(), "object",
					Path, "path");

	public static final Type Edit_create =
			tf.constructor(Diff, Edit, "set", 
					tf.sourceLocationType(), "object",
					Path, "path",
					tf.stringType(), "class");

	public static List<Edit> convert(IValue value) {
		if (value.getType().isSubtypeOf(Delta)) {
			IList l = (IList)value;
			List<Edit> jl = new ArrayList<Edit>();
			for (IValue v: l) {
				jl.add(convertEdit((IConstructor)v));
			}
			return jl;
		}
		throw new IllegalArgumentException("not a delta");
	}

	private static Edit convertEdit(IConstructor v) {
		String n = v.getName();
		Object key = v.get("object");
		Path path = convertPath((IList)v.get("path"));
		if (n.equals("set")) {
			return new Set(key, path, convertValue(v.get("x")));
		}
		if (n.equals("insert")) {
			return new Insert(key, path, v.get("ref"));
		}
		if (n.equals("remove")) {
			return new Remove(key, path);
		}
		if (n.equals("create")) {
			return new Create(key, path, ((IString)v.get("class")).getValue());
		}
		throw new AssertionError("Invalid edit constructor: " + n);
	}

	private static Object convertValue(IValue x) {
		if (x.getType().isInteger()) {
			return Integer.parseInt(((IInteger)x).getStringRepresentation());
		}
		if (x.getType().isReal()) {
			return Double.parseDouble(((IReal)x).getStringRepresentation());
		}
		if (x.getType().isString()) {
			return ((IString)x).getValue();
		}
		if (x.getType().isBool()) {
			return ((IBool)x).getValue();
		}
		if (x.getType().isNode()) {
			// hack: to get names out of defs.
			return ((IString)((INode)x).get(0)).getValue();
		}
		throw new AssertionError("invalid value type " + x.getType());
	}

	private static Path convertPath(IList l) {
		PathElement[] elts = new PathElement[l.length()];
		for (int i = 0; i < l.length(); i++) {
			IConstructor e = (IConstructor) l.get(i);
			if (e.getName().equals("field")) {
				elts[i] = new Field(((IString)e.get("name")).getValue());
			}
			else if (e.getName().equals("index")) {
				elts[i] = new Index(Integer.parseInt(((IInteger)e.get("index")).getStringRepresentation()));
			}
			else {
				throw new AssertionError("invalid path element: " + e);
			}
		}
		return new Path(elts);
	}
}
