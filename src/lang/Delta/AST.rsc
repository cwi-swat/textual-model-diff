module lang::Delta::AST

//Abstract Syntax of Polanen Operations
data Delta
  = delta(list[Operation] additions,  //create new elements
 list[Operation] changes,    //changes to elements
 list[Operation] deletions); //delete elements

//alias Path = list[str];

// Deviation from Polanen, we don't cater for inversion of changes.

data Operation
  = op_new       (loc obj, Path path, str \type)
  | op_del       (loc obj, Path path, str \type)
  | op_set       (loc owner, Path path, value valNew, value valOld)
  | op_insert    (loc owner, Path path, loc id2)
  | op_remove    (loc owner, Path path, loc id2)
  | op_insertAt  (loc owner, Path path, loc id2, int index)
  | op_removeAt  (loc owner, Path path, int index);
  
/*

Assume garbage collection
We don't have unordered collections

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


