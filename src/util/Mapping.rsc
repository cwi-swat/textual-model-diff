module util::Mapping

import Type;
import String;
import Node;
import List;

import util::LCS;

alias IDClassMap = rel[loc id, str class, node tree];
alias ASTModelMap = rel[str cons, str class, list[str] features];

alias Token = tuple[str content, loc location];
alias Tokens = list[Token];

alias IDMatching = tuple[set[loc] added, set[loc] deleted, map[loc, loc] id];

alias IDAccess = tuple[bool(node) isId, loc(node) getId];

data Null = null();
 

bool isDef(node n, IDAccess ia) 
  = any(node k <- getChildren(n), ia.isId(k));
  
loc getDefId(node n, IDAccess ia) 
  = head([ ia.getId(k) | node k <- getChildren(n), ia.isId(k) ]);

bool isAtom(value x, IDAccess ia) 
  = (str _ := x || bool _ := x || num _ := x) || (node n := x && ia.isId(n)) || x == null();
  
bool isList(value x) 
  = (list[value] _ := x);
   
bool isContains(value x, IDAccess ia) = (node n := x && !ia.isId(n) && !isDef(n, ia) && !isAtom(x, ia));


// Assume: only one id per list of arguments in a node.
IDClassMap idClassMap(&T<:node ast, bool(node) isId, loc(node) getId) 
  = { <getId(k), capitalize(getName(n)), n> | /node n := ast, 
       node k <- getChildren(n), isId(k) }; 



// NB: this identifies constructors that have
// the same name, same arity, same argument labels, but
// different argument types. This is not a problem
// because differently typed arguments must have 
// different labels in Rascal
// Assume: fields must be labeled, as of now.
ASTModelMap astModelMap(type[&T<:node] theAdt) 
  //= {  <x, capitalize(x), [ f | label(str f, _) <- flds ]> 
//BUG:  //      | /cons(label(str x, _), flds, _) <- theAdt };
{
  r = {};
  visit (theAdt) {
    case cons(label(str x, _), flds, _):
      r += { <x, capitalize(x), [ f | label(str f, _) <- flds ]> };
  }
  return r;
}

// TODO!!! constructors cannot be shared among classes!!!


list[str] featuresOf(node n, int arity, ASTModelMap m) = fs 
  when cons := getName(n), <cons, _, fs> <- m, size(fs) == arity;

str featureOf(node n, int i, int arity, ASTModelMap m) = 
  featuresOf(n, arity, m)[i];

str classOf(node n, ASTModelMap m) = class
  when cons := getName(n), <cons, class, _> <- m; 

map[str class, Tokens defs] projectEntities(&T<:node t, IDClassMap cm, IDAccess ia) {
  m = ();
  
  Tokens EMPTY = [];
  
  // Assumption:
  str getName(node id) = x when str x := getChildren(id)[0];
  
  visit (t) {
    case node n: 
      if (ia.isId(n), x := ia.getId(n), <x, class, _> <- cm) {
        m[class]?EMPTY += [<getName(n), ia.getId(n)>];
      }
  }

  return m;
}       

IDMatching identifyEntities(node ast1, node ast2, IDClassMap ts1, IDClassMap ts2, IDAccess ia) {
  pr1 = projectEntities(ast1, ts1, ia);
  pr2 = projectEntities(ast2, ts2, ia);
  return ( <{}, {}, ()> | merge(it, match(pr1[k], pr2[k])) | k <- pr1, k in pr2 );
} 
  
  


IDMatching merge(IDMatching x, IDMatching y) 
  =  <x.added + y.added, x.deleted + y.deleted,  x.id + y.id>;

// Assume: src1 and src2 are token seqs of the single same type (e.g. State).
IDMatching match(Tokens src1, Tokens src2) {
 
  bool eq(Token x, Token y) = x.content == y.content;
 
  mx = lcsMatrix(src1, src2, eq);
  df = detectMoves(getDiff(mx, src1, src2, size(src1), size(src2), eq));

  return <{ l2 | add(<_, l2>, _) <-  df }, 
          { l1 | remove(<_, l1>, _) <- df }, 
          ( l1: l2 | same(<_, l1>, <_, l2>) <- df ) +
          ( l1: l2 | move(<_, l1>, <_, l2>, _, _) <- df )>;
}

list[Diff[Token]] detectMoves(list[Diff[Token]] edits) {
  // heuristic remove/add, add/remove pairs closest together.
  
  solve (edits) {
    for ([*xs1, add(<str x, l1>, to), *xs2, remove(<x, l2>, from), *xs3] := edits, [*_, remove(<x, _>, _), *_] !:= xs2) {
       edits = [*xs1, *xs2, move(<x, l2>, <x, l1>, from, to), *xs3];
    }
    for ([*xs1, remove(<str x, l1>, from), *xs2, add(<x, l2>, to), *xs3] := edits, [*_, add(<x, _>, _), *_] !:= xs2) {
       edits = [*xs1, move(<x, l1>, <x, l2>, from, to), *xs2, *xs3];
    }
  }
  
  return edits;  
}

