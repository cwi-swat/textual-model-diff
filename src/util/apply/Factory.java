package util.apply;

import java.util.ArrayList;
import java.util.List;

import lang.sl.runtime.PathElement;

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

	public static final Type Edit_setPrim =
			tf.constructor(Diff, Edit, "setPrim", 
					tf.sourceLocationType(), "object",
					Path, "path",
					tf.valueType(), "x");

	/*public static final Type Edit_setTree =
	      tf.constructor(Diff, Edit, "setTree", 
	          tf.sourceLocationType(), "object",
	          Path, "path",
	          tf.valueType(), "tree");
   */
	 /*
   public static final Type Edit_setRef =
       tf.constructor(Diff, Edit, "setref", 
           tf.sourceLocationType(), "object",
           Path, "path",
           tf.valueType(), "ref");
   */
	/*
   public static final Type Edit_insertRef =
       tf.constructor(Diff, Edit, "insertRef", 
           tf.sourceLocationType(), "object",
           Path, "path",
           tf.valueType(), "ref");
   */
	/*
	public static final Type Edit_insertTree =
			tf.constructor(Diff, Edit, "insertTree", 
					tf.sourceLocationType(), "object",
					Path, "path",
					tf.sourceLocationType(), "tree");
  */
	public static final Type Edit_remove =
			tf.constructor(Diff, Edit, "remove", 
					tf.sourceLocationType(), "object",
					Path, "path");

	public static final Type Edit_create =
			tf.constructor(Diff, Edit, "create", 
					tf.sourceLocationType(), "object",
					tf.stringType(), "class");

	public static final Type Edit_delete = 
	    tf.constructor(Diff, Edit, "delete",
	        tf.sourceLocationType(), "object");
	
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
		
    if (n.equals("create")) {
      return new Create(key, ((IString)v.get("class")).getValue());
    }
    else if(n.equals("delete")) {
      return new Delete(key);
    }
    else
    {
      Path path = convertPath((IList)v.get("path"));
      
		  if (n.equals("setTree")) {
		    return new SetTree(key, path, convertValue(v.get("tree")));
		  }
		  else if (n.equals("setRef")) {
        return new SetTree(key, path, convertValue(v.get("ref")));
      }
		  else if (n.equals("setPrim")) {
        return new SetTree(key, path, convertValue(v.get("x")));
      }
		  else if (n.equals("insertRef")) {
		    return new InsertRef(key, path, v.get("ref"));
		  }
      else if (n.equals("insertTree")) {
        return new InsertRef(key, path, v.get("tree"));
      }		  
      else if (n.equals("remove")) {
		    return new Remove(key, path);
  		}
    }
		throw new AssertionError("Invalid edit constructor: " + n);
	}
	
	/*
  private static Object convertValue(INode x)
  {
    Object object = null;
    java.util.Iterator<IValue> i = x.iterator();
    
    String name = x.getName();
    System.out.println("NAME: "+ name);
    
    if(name.equals("name")){
      return (Object) x.get(0).toString();
    }
    
    int count = 0;
    while(i.hasNext())
    {
       IValue child = i.next();
       System.out.println("child["+count+"]: "+ child.toString());
       count++;
    }
    
    return object;
  }*/
 
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
		if (x.getType().isNode()){
		  System.out.println("Oh dear we have a node: "+x.toString());
      //INode n = (INode) x;
		  return x;
      //Class<?> cls = Class.forName(S);
      //Object obj = cls.newInstance();		  
		}
		//if (x.getType().isNode() && ((IConstructor)x).arity() == 1) {
			// hack: to get names out of defs.
		//	return ((IString)((INode)x).get(0)).getValue();
		//}
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
