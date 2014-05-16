module util::Mapping

import Type;
import String;
import Node;
import List;
import util::Math;
import IO;

alias IDClassMap = rel[loc id, str class, node tree];
alias ASTModelMap = rel[str cons, str class, list[str] features];

alias Token = tuple[str content, loc location];
alias Tokens = list[Token];

alias IDMatching = tuple[set[loc] added, set[loc] deleted, map[loc, loc] id];

data Diff[&T]
  = same(&T t1, &T t2)
  | same(&T t)
  | add(&T t, int pos)
  | remove(&T t, int pos)
  | move(&T t1, &T t2, int from, int to)
  ;



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


map[str class, Tokens defs] projectEntities(&T<:node t, IDClassMap cm, bool(node) isId, loc(node) getId) {
  m = ();
  
  Tokens EMPTY = [];
  
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



IDMatching merge(IDMatching x, IDMatching y) {
  return <x.added + y.added, x.deleted + y.deleted,  x.id + y.id>;
} 

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

list[Diff[&T]] getDiff(map[int,map[int,int]] c, list[&T] x, list[&T] y, int i, int j,
   bool(&T, &T) equals) {
  if (i > 0, j > 0,  equals(x[i-1], y[j-1])) {
    //println("============= Returning same(<i-1>, <j-1>)");
    //println(x[i-1]);
    //println(y[j-1]);
    return getDiff(c, x, y, i - 1, j - 1, equals) + [same(x[i-1], y[j-1])];
  }
  if (j > 0, (i == 0 || c[i][j-1] >= c[i-1][j])) {
    //println("+++++++++++++ Returning add(<j-1>)");
    //println(y[j-1]);
    return getDiff(c, x, y, i, j-1, equals) + [add(y[j-1], j-1)];
  }
  if (i > 0, (j == 0 || c[i][j-1] < c[i-1][j])) {
    //println("------------- Returning remove(<i-1>)");
    //println(x[i-1]);
    return getDiff(c, x, y, i-1, j, equals) + [remove(x[i-1], i-1)];
  }
  return [];
}

map[int,map[int,int]] lcsMatrix(list[&T] x, list[&T] y, bool (&T,&T) equals) {
  map[int,map[int,int]] c = ();
  
  m = size(x);
  n = size(y);
  
  for (int i <- [0..m + 1]) {
    c[i] = ();
    c[i][0] = 0;
  }
  
  for (int j <- [0..n + 1]) {
    c[0][j] = 0;
  }
  
  for (int i <- [1..m + 1], int j <- [1.. n + 1]) {
    if (equals(x[i - 1], y[j - 1])) {
      c[i][j] = c[i-1][j-1] + 1;
    }
    else {
      c[i][j] = max(c[i][j-1], c[i-1][j]);
    }
  }
  
  return c;  
}
