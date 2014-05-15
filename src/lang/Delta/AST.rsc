module lang::Delta::AST

//Abstract Syntax of Polanen Operations
data Delta
  = delta(list[Operation] renames,    //rename elements
          list[Operation] additions,  //create new elements
          list[Operation] changes,    //changes to elements
          list[Operation] deletions); //delete elements

data Operation
  = op_rename    (loc id /*new*/ , loc id2 /*old*/ )
  | op_new       (loc id,          str name /*typeName*/)
  | op_del       (loc id,          str name /*typeName*/)
  | op_set       (loc id,          str name /*attributeName*/, str valNew, str valOld)
  | op_insert    (loc id /*from*/, str name /*featureName*/, loc id2 /*to*/)
  | op_remove    (loc id /*from*/, str name /*featureName*/, loc id2 /*to*/)
  | op_instertAt (loc id /*from*/, str name /*featureName*/, loc id2 /*to*/, int index)
  | op_removeAt  (loc id /*from*/, str name /*featureName*/, loc id2 /*to*/, int index);