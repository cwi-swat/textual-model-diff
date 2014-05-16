module lang::Delta::AST

//Abstract Syntax of Polanen Operations
data Delta
  = delta(list[Operation] additions,  //create new elements
 list[Operation] changes,    //changes to elements
 list[Operation] deletions); //delete elements

alias Path = list[str];

data Operation
  = op_new       (loc obj, Path path, str \type)
  | op_del       (loc obj, Path path, str \type)
  | op_set       (loc owner, Path path, value valNew, value valOld)
  | op_insert    (loc owner, Path path, loc id2)
  | op_remove    (loc owner, Path path, loc id2)
  | op_insertAt  (loc owner, Path path, loc id2, int index)
  | op_removeAt  (loc owner, Path path, loc id2, int index);