module lang::Delta::AST

//Abstract Syntax of Polanen Operations
data Delta
  = delta(list[Operation] additions,  //create new elements
 list[Operation] changes,    //changes to elements
 list[Operation] deletions); //delete elements

data Operation
  = op_new       (loc obj, str \type)
  | op_del       (loc obj, str \type)
  | op_set       (loc owner, str name, value valNew, value valOld)
  | op_insert    (loc owner, str name, loc id2)
  | op_remove    (loc owner, str name, loc id2)
  | op_insertAt  (loc owner, str name, loc id2, int index)
  | op_removeAt  (loc owner, str name, loc id2, int index);