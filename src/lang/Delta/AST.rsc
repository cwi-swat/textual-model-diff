module lang::Delta::AST

/*

Assume garbage collection
We don't have unordered collections
We don't support inversion
*/


alias Path = list[PathElement];

data PathElement
  = field(str name)
  | index(int index)
  ;

data Edit 
 = setPrim(loc object, Path path, value x)
 | setRef(loc object, Path path, loc ref) // single
 | insertAt(loc object, Path path, loc ref) // 
 | removeAt(loc object, Path path)  // list
 | create(loc object, Path path, str class) // if path = [], it's "Polanen new" else it's inline "value" creation, if path has indices can be list
 | delete(loc object)
 ;


