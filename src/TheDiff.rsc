module TheDiff

import String;
import List;
import util::Math;
import IO;
import lang::sl::IDE;
import lang::sl::Syntax;
import lang::sl::AST;
import lang::sl::NameAnalyzer;
import lang::derric::NameRel;
import lang::derric::BuildFileFormat;
import util::NameGraph;

import Node;
import ParseTree;
import Set;

import lang::Delta::AST;
  
void matchItDerric(loc v1, loc v2) {
  src1 = readFile(v1);
  src2 = readFile(v2);
  pt1 = parseDerric(v1);
  pt2 = parseDerric(v2);
  ast1 = build(pt1);
  ast2 = build(pt2);
  ts1 = typeMap(ast1);
  ts2 = typeMap(ast2);
  r1 = resolveNames(ast1); 
  r2 = resolveNames(ast2);
  x = match(r1, r2, ts1, ts2, flatten(pt1), flatten(pt2));
  iprintln(x);
}

  
void matchIt(loc v1, loc v2) {
  str src1 = readFile(v1);
  str src2 = readFile(v2);
  Tree pt1 = sl_parse(v1);
  Tree pt2 = sl_parse(v2);
  Machine ast1 = sl_implode(pt1);
  Machine ast2 = sl_implode(pt2);
  ts1 = typeMap(ast1);
  ts2 = typeMap(ast2);
  r1 = getNameGraph(setScope(ast1)); 
  r2 = getNameGraph(setScope(ast2));
  x = match(r1, r2, ts1, ts2, flattenAST(ast1, "name", ts1, "State"), flattenAST(ast2, "name", ts2, "State"));
  y = match(r1, r2, ts1, ts2, flattenAST(ast1, "name", ts1, "Transition"), flattenAST(ast2, "name", ts2, "Transition"));
  z = match(r1, r2, ts1, ts2, flattenAST(ast1, "name", ts1, "Group"), flattenAST(ast2, "name", ts2, "Group"));
  z0 = match(r1, r2, ts1, ts2, flattenAST(ast1, "name", ts1, "Machine"), flattenAST(ast2, "name", ts2, "Machine"));
  iddiff = merge(merge(merge(x, y), z), z0);
  iprintln(iddiff);

  ns1 = findNodes(ast1, r1, ts1);
  ns2 = findNodes(ast2, r2, ts2);
  Delta delta = doIt(ns1, ns2, r1, r2, iddiff);

  iprintln(delta);
}


alias IDDiff = tuple[set[loc] added, set[loc] deleted, map[loc, loc] id];

IDDiff merge(IDDiff x, IDDiff y) {
  return <x.added + y.added, x.deleted + y.deleted,  x.id + y.id>;
} 

lrel[str, loc] flattenAST(&T t, str id, map[loc, str] ts, str typ) {
  l = [];
  visit (t) {
    case n:str x(str name): {
       if (x == id && n@location in ts, ts[n@location] == typ) {
         l += [<name, n@location>];
       }
    }
  }
  return l;
}
  
  
  
lrel[str, loc] flatten(Tree t) {
  l = [];
  
  top-down-break visit (t) {
    case x:appl(prod(lex(_), _, _), _): l += [<"<x>", x@\loc>];
    case x:appl(prod(label(_, lex(_)), _, _), _): l += [<"<x>", x@\loc>];
    case x:appl(prod(layouts(_), _, _), _): ;
  }
  return l;
}

tuple[set[loc] added, set[loc] deleted, map[loc, loc] id]
  match(NameGraph g1, NameGraph g2, map[loc, str] ts1, map[loc, str] ts2, 
    lrel[str,loc] src1, lrel[str, loc] src2) {
 
  bool eq(tuple[str, loc] x, tuple[str, loc] y) = x[0] == y[0];
 
  m = lcsMatrix(src1, src2, eq);
  df = getDiff(m, src1, src2, size(src1), size(src2), eq);
  
  //println("The DIFF:");
  //iprintln(df);

  df = detectMoves(df, ts1, ts2);
  iprintln(df);

  map[loc, loc] identify = ();
  set[loc] adds = {};
  set[loc] dels = {};
  
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
        
      case move(<_, l1>, <_, l2>, _, _): 
        if (ts1[l1]?, ts2[l2]?, ts1[l1] == ts2[l2]) {
          identify += ( l1: l2 | l1 in g1.defs, l2 in g2.defs );
        }
        else {
          dels += { l1 | l1 in g1.defs };
          adds += { l2 | l2 in g2.defs };
        }
        
      case add(<y, l2>, int p): {
        println("<l2> is added, in g2.defs? <l2 in g2.defs>");
        adds += { l2 | l2 in g2.defs };
      }     
      case remove(<x, l1>, int p): {
        dels += { l1 | l1 in g1.defs };
      }
    }
  
  } 
  return <adds, dels, identify>;
}
  
anno loc node@location;


   
rel[loc id, str typ, node tree] findNodes(&T<:node ast, NameGraph g, map[loc, str] ts) {
  r = {};
  
  bool isId(loc l) = l in g.defs + g.uses;
  loc getId(node n) = head([ k@location | node k <- getChildren(n), isId(k@location)]);
  bool hasId(node n) = any(node k <- getChildren(n), isId(k@location));
  bool isDef(node n) = hasId(n) && getId(n) in g.defs;
  bool isUse(node n) = n@location in g.uses;

  node addIt(loc id, str typ, node t) {
     r += {<id, typ, t>};
     return t;
  }

  top-down visit (ast) {
    case node n: if (isDef(n))  addIt(getId(n), ts[getId(n)], n);
  }

  return r;
}


map[str, map[int, str]] METAMODEL = (
  "group": (0: "name", 1: "states"),
  "State": (0: "name", 1: "transitions"),
  "Transition": (0: "event", 1: "target")
);


/*void*/ Delta doIt(rel[loc id, str typ, node tree] r1, rel[loc id, str typ, node tree] r2,
    NameGraph g1, NameGraph g2, IDDiff mapping) {
 
  list[Operation] additions = [];
  list[Operation] changes = [];
  list[Operation] deletions = [];  
 
  bool isId1(loc l) = l in g1.defs + g1.uses;
  bool isId2(loc l) = l in g2.defs + g2.uses;
  
  loc getDefId1(node n) = head([ k@location | node k <- getChildren(n), isId1(k@location)]);
  loc getDefId2(node n) = head([ k@location | node k <- getChildren(n), isId2(k@location)]);
  
  bool hasId1(node n) = any(node k <- getChildren(n), isId1(k@location));
  bool hasId2(node n) = any(node k <- getChildren(n), isId2(k@location));
  
  bool isDef1(node n) = hasId1(n) && getId1(n) in g.defs1;
  bool isDef2(node n) = hasId2(n) && getId2(n) in g.defs2;
  
  bool isUse1(node n) = n@location in g1.uses;
  bool isUse2(node n) = n@location in g2.uses;
 
  loc getUseId(node n) = n@location;
 
  bool isAtom(value x) = (str _ := x || bool _ := x || num _ := x)
    || (node n := x && (isId1(n@location) || isId2(n@location)));
  bool isList(value x) = (list[value] _ := x); 
  
  bool isContains1(value x) = (node n := x && !isUse1(n) && !isDef1(n) && !isAtom(x));
  bool isContains2(value x) = (node n := x && !isUse2(n) && !isDef2(n) && !isAtom(x));
 
  void deleteIt(node n) = deleteIt(n@location, n);
  void deleteIt(loc myId, node n) {
    
    for (node k <- getChildren(n)) {
      if (isContains1(k)) {
         deleteIt(k);
      }
    }
    println("delete <getName(n)> with id <myId>");
    deletions += [op_del(myId, getName(n))];
  }
  
  loc addIt(node n) = addIt(n@location, n);
  
  loc addIt(loc newId, node n) {
     println("ADD <newId> = new <getName(n)>");
     additions += [op_new(newId, getName(n))];
     i = 0;
     for (node k <- getChildren(n)) {
       if (isUse2(k)) {
         if (target <- g2.refs[getUseId(k)], original <- mapping.id, mapping.id[original] == target) {
           println("set to original reference [<i>] of <newId> = <original>");           
           changes += [op_insert(newId, "<i>", original) ];
         }
         else {
           //FIXME:
           //println("set new reference [<i>] of <newId> = <target>");
           //changes += [op_insert(newId, "<i>", target) ];
           ;
         }
       }
       else if (isDef2(k)) {
         println("set ref field [<i>] of <newId> = <getDefId2(k)>");
         changes += [op_insert(newId, "<i>", getDefId2(k))];
       }
       else if (isAtom(k)) {
         println("set prim field [<i>] of <newId>  = <k>");
         changes += [op_set(newId, "<i>", k, 0)];
       }
       else if (isContains2(k)) {
         if (node n := k) {
           kidId = addIt(n);
           println("set contains field [<i>] of <newId>  = <kidId>");
           changes += [op_insert(newId, "contains", kidId)];
         }
         else {
           throw "Error";
         }
       }
       i += 1;
     }
     return newId;
  }
  
 void diffNodes(loc id1, loc id2, node n1, node n2) {
      // TODO: remove getDefId on n1/n2, is now id1, id2
      cs1 = getChildren(n1);
      cs2 = getChildren(n2);
      assert size(cs1) == size(cs2);
      // TODO: fields in n1 and n2 may differ
      // need to pair them based on name
      // NB: it's not necessary that name of n1 == name of n2.
      // (2 constructors for one object type).
      
      
      int i = 0;
      for (<value k1, value k2> <- zip(cs1, cs2)) {
         if (node k1n := k1, node k2n := k2, isUse1(k1n), isUse2(k2n)) {
           loc trg1 = getOneFrom(g1.refs[getUseId(k1n)]);
           loc trg2 = getOneFrom(g2.refs[getUseId(k2n)]);
           if (trg1 in mapping.id && mapping.id[trg1] == trg2) {
              ; // nothing
           }
           else {
             println("set field [<i>] in <getDefId2(n2)> to <trg2>");
             changes += [op_insert(getDefId2(n2), "<i>", trg2)]; 
           }
         } 
         //else if (isUse(k1), isDef(k2)) {
         //;
         //} 
         //else if (isDef(k1), isUse(k2)) {
         //;
         //} 
         else if (isAtom(k1), isAtom(k2)) {
           if (k1 == k2) {
             ; // nothing
           }
           else {
             println("set primitive field [<i>] in <n2> to <k2>");
             changes += [op_set(id2, "<i>", k2, k1)];
           }
         }
         else if (node k1n := k1, node k2n := k2, isUse1(k1n), isContains1(k2n)) {
           // always different
           newId = addIt(k2n);
           println("set to contains field [<i>] in <getDefId2(n2)> to <newId>");
           changes += [op_insert(getDefId2(n2), "contains", newId)];
         } 
         else if (node k1n := k1, node k2n := k2, isContains1(k1n), isUse2(k2n)) {
           deleteIt(k1n);
           println("set to reference field [<i>] in <getDefId2(n2)> to <getUseId(k2n)>");
           changes += [op_insert(getDefId2(n2), "reference", getUseId(k2n))];
         } 
         //else if (isDef(k1), isContains(k2)) {
         //;
         //} 
         //else if (isContains(k1), isDef(k2)) {
         //;
         //}
         
         else if (isList(k1), isList(k2)) {
            bool eqWithRefs(node a, node b) {
               if (getName(a) != getName(b)) {
                  return false;
               }
               if (size(getChildren(a)) != size(getChildren(b))) {
                 return false;
               }
               
               for (<k1, k2> <- zip(getChildren(a), getChildren(b))) {
                 if (isUse1(k1), isUse2(k2)) {
                   trg1 = g1.refs[getUseId1(k1)];
                   trg2 = g2.refs[getUseId2(k2)];
                   if (mapping.id[trg1] == trg2) {
                      return true;
                   }
                   return false;
                 }
               }
            }
         } 
         else if (node k1n := k1, node k2n := k2, isContains1(k1n), isContains2(k2n)) {
              if (getName(k1n) == getName(k2n), size(getChildren(k1n)) == size(getChildren(k2n))) {
                 diffNodes(k1n@location, k2n@location, k1n, k2n);
              }
              else {
                deleteIt(k1n);
                newId = addIt(k2n);
                println("set contains field [<i>] to <newId>");
              }
         } 
         else {
           println("k1 = <k1>");
           println("k2 = <k2>");
           throw "Error";
         }
         i += 1;
     }
   }
 
  for (<loc l2, _, node n2> <- r2,  l2 notin mapping.id<1>) {
    addIt(l2, n2);  
  }
  
  for (<loc l1, _, node n1> <- r1, l1 in mapping.id) {
    other = mapping.id[l1];
    if (<_, node n2> <- r2[other]) {
      diffNodes(l1, other, n1, n2);
    }
  }
  
  for (<loc l1, _, node n1> <- r1, l1 notin mapping.id) {
    deleteIt(l1, n1);
  }
  
  
  return delta(additions,changes,deletions);
}
  
  
data Diff[&T]
  = same(&T t1, &T t2)
  | same(&T t)
  | add(&T t, int pos)
  | remove(&T t, int pos)
  | move(&T t1, &T t2, int from, int to)
  ;
  
list[Diff[tuple[str,loc]]] detectMoves(list[Diff[tuple[str,loc]]] edits, map[loc, str] ts1, map[loc, str] ts2) {
  // heuristic remove/add, add/remove pairs closest together.
  
  solve (edits) {
    for ([*xs1, add(<str x, l1>, to), *xs2, remove(<x, l2>, from), *xs3] := edits, [*_, remove(<x, _>, _), *_] !:= xs2,
           l1 in ts1, l2 in ts2, ts1[l1] == ts2[l2]) {
       edits = [*xs1, *xs2, move(<x, l2>, <x, l1>, from, to), *xs3];
    }
    for ([*xs1, remove(<str x, l1>, from), *xs2, add(<x, l2>, to), *xs3] := edits, [*_, add(<x, _>, _), *_] !:= xs2,
           l1 in ts1, l2 in ts2, ts1[l1] == ts2[l2]) {
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