module util::Mapping

import Type;
import String;
import Node;


alias IDClassMap = rel[loc id, str class, node tree];

// Assume: only one id per list of arguments in a node.
IDClassMap idClassMap(&T<:node ast, bool(node) isId, loc(node) getId) 
  = { <getId(k), capitalize(getName(n)), n> | /node n := ast, 
       node k <- getChildren(n), isId(k) }; 


alias ASTModelMap = rel[str cons, str class, list[str] features];

// NB: this identifies constructors that have
// the same name, same arity, same argument labels, but
// different argument types. This is not a problem
// because differently typed arguments must have 
// different labels in Rascal
// Assume: fields must be labeled, as of now.
ASTModelMap astModelMap(type[&T<:node] adt) 
  = {  <x, capitalize(x), [ f | label(str f, _) <- flds ]> 
        | /cons(label(str x, _), flds, _) := adt };

        

map[str class, lrel[str, loc] defs] projectEntities(&T<:node t, IDClassMap cm, bool(node) isId, loc(node) getId) {
  m = ();
  
  lrel[str, loc] EMPTY = [];
  
  // Assumption:
  str getName(node id) = x when str x := getChildren(id)[0];
  
  visit (t) {
    case node n: 
      if (isId(n), x := getId(n), <x, class, _> <- cm) {
        m[class]?EMPTY += [<getName(n), getId(n)>];
      }
  }

  return m;
}       

