module util::Mapping

import Type;
import String;
import Node;
import List;
import IO;

import util::NameGraph;
import util::LCS;

alias IDClassMap = rel[loc id, str class, node tree];
alias ASTModelMap = rel[str cons, str class, list[str] features];

alias Token = tuple[str content, str class, loc location];
alias Tokens = list[Token];

alias IDMatching = tuple[set[loc] added, set[loc] deleted, map[loc, loc] id];

alias IDAccess = tuple[bool(node, NameGraph) isKeyId, bool(node, NameGraph) isRefId, loc(node) getId];

data Null = null();
 
alias Classes = rel[str cons, str class, list[str] fields];

Classes classify(type[&T<:node] theAdt) = 
  {  <cons, class, [ f | label(str f, _) <-  flds ]>  
     | /adt(str class, /cons(label(str x, _), flds, _)) := theAdt };

bool isDef(node n, NameGraph g, IDAccess ia) 
  = any(node k <- getChildren(n), ia.isKeyId(k, g));
  
loc getDefId(node n, NameGraph g, IDAccess ia) 
  = head([ ia.getId(k) | node k <- getChildren(n), ia.isKeyId(k, g) ]);

bool isAtom(value x, NameGraph g, IDAccess ia) 
  = (str _ := x || bool _ := x || num _ := x) || (node n := x && ia.isKeyId(n, g)) || x == null();
  
bool isList(value x) 
  = (list[value] _ := x);
   
bool isContains(value x, NameGraph g, IDAccess ia) 
  = (node n := x && !ia.isRefId(n, g) && !isDef(n, g, ia) && !isAtom(x, g, ia));


// Assume: only one id per list of arguments in a node.
IDClassMap idClassMap(&T<:node ast, NameGraph g, IDAccess ia) 
  = { <ia.getId(k), capitalize(getName(n)), n> | /node n := ast, 
       node k <- getChildren(n), ia.isKeyId(k, g) }; 



// NB: this identifies constructors that have
// the same name, same arity, same argument labels, but
// different argument types. This is not a problem
// because differently typed arguments must have 
// different labels in Rascal
// Assume: fields must be labeled, as of now.
ASTModelMap astModelMap(type[&T<:node] theAdt, str pkg) 
  //= {  <x, capitalize(x), [ f | label(str f, _) <- flds ]> 
//BUG:  //      | /cons(label(str x, _), flds, _) <- theAdt };
{
  r = {};
  visit (theAdt) {
    case cons(label(str x, _), flds, _): {
      q = (pkg == "") ? "" : (pkg + ".");
      r += { <x, q + capitalize(x), [ f | label(str f, _) <- flds ]> };
    }
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

Tokens projectEntities(&T<:node t, IDClassMap cm, NameGraph g, IDAccess ia) {
  m = [];
  
  
  // Assumption:
  str getName(node id) = x when str x := getChildren(id)[0];
  
  top-down visit (t) {
    case node n: { 
      if (ia.isKeyId(n, g), x := ia.getId(n), <x, class, _> <- cm) {
        m += [<getName(n), class, ia.getId(n)>];
      }
    }
  }

  return m;
}       

IDMatching identifyEntities(node ast1, node ast2, IDClassMap ts1, IDClassMap ts2, NameGraph g1, NameGraph g2,  IDAccess ia) {
  pr1 = projectEntities(ast1, ts1, g1, ia);
  pr2 = projectEntities(ast2, ts2, g2, ia);
  return match(pr1, pr2);
  //return ( <{}, {}, ()> | merge(it, match(pr1[k], pr2[k])) | k <- pr1, k in pr2 );
} 
  
  


IDMatching merge(IDMatching x, IDMatching y) 
  =  <x.added + y.added, x.deleted + y.deleted,  x.id + y.id>;

// Assume: src1 and src2 are token seqs of the single same type (e.g. State).
IDMatching match(Tokens src1, Tokens src2) {
 
  bool eq(Token x, Token y) = x.content == y.content && x.class == y.class;
 
  mx = lcsMatrix(src1, src2, eq);
  df = getDiff(mx, src1, src2, size(src1), size(src2), eq);
  //df = detectMoves(df);

  return <{ l2 | add(<_, _, l2>, _) <-  df }, 
          { l1 | remove(<_, _, l1>, _) <- df }, 
          ( l1: l2 | same(<_, _, l1>, <_, _, l2>) <- df ) +
          ( l1: l2 | move(<_, _, l1>, <_, _, l2>, _, _) <- df )>;
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

