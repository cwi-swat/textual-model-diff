module TheDiff

import String;
import List;
import util::Math;
import IO;
import lang::sl::IDE;
import lang::sl::Syntax;
import lang::sl::NameAnalyzer;

import Node;
import ParseTree;

  
void matchIt(loc v1, loc v2) {
  src1 = readFile(v1);
  src2 = readFile(v2);
  pt1 = sl_parse(v1);
  pt2 = sl_parse(v2);
  ast1 = sl_implode(pt1);
  ast2 = sl_implode(pt2);
  ts1 = typeMap(ast1);
  ts2 = typeMap(ast2);
  r1 = getNameGraph(setScope(ast1)); 
  r2 = getNameGraph(setScope(ast2));
  x = match(r1, r2, ts1, ts2, flatten(pt1), flatten(pt2));
  iprintln(x);
}
  
lrel[str, loc] flatten(Tree t) {
  l = [];
  
  top-down-break visit (t) {
    case x:appl(prod(lex(_), _, _), _): l += [<"<x>", x@\loc>];
    //case x:appl(prod(lit(_), _, _), _): l += [<"<x>", x@\loc>];
    case x:appl(prod(layouts(_), _, _), _): ;
  }
  return l;
}

  
tuple[set[loc] added, set[loc] deleted, map[loc, loc] id]
  match(NameGraph g1, NameGraph g2, map[loc, str] ts1, map[loc, str] ts2, 
    lrel[str,loc] src1, lrel[str, loc] src2) {
 
  bool eq(tuple[str, loc] x, tuple[str, loc] y) = x[0] == y[0];
 
 
//  src1 = sort(src1, bool(tuple[str, loc] x, tuple[str, loc] y) {
//     return x[0] < y[0];
//  });
//
//  src2 = sort(src2, bool(tuple[str, loc] x, tuple[str, loc] y) {
//     return x[0] < y[0];
//  });
 
  m = lcsMatrix(src1, src2, eq);
  df = getDiff(m, src1, src2, size(src1), size(src2), eq);
  
  println("The DIFF:");
  iprintln(df);
  
  int shift = 0;
  map[loc, loc] identify = ();
  adds = {};
  dels = {};
  
  for (e <- df) {
    switch (e) {
      case same(<x, l1>, <y, l2>): 
        if (ts1[l1]?, ts2[l2]?, ts1[l1] == ts2[l2]) {
          identify += ( l1: l2 | l1 in g1.defs, l2 in g2.defs );
        }
        else {
          dels += { l1 | l1 in g1.defs };
          adds += { l2 | l2 in g2.defs };
        }
      case add(<y, l2>, int p): {
        adds += { l2 | l2 in g2.defs };
      }     
      case remove(<x, l1>, int p): {
        dels += { l1 | l1 in g1.defs };
      }
    }
  
  } 
  return <adds, dels, identify>;
}
  
  
  
  
data Diff[&T]
  = same(&T t1, &T t2)
  | same(&T t)
  | add(&T t, int pos)
  | remove(&T t, int pos)
  ;
  

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


