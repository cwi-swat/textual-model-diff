module util::Diff

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
import util::Mapping;
import util::LCS;

import Node;
import ParseTree;
import Set;

/*

Assume garbage collection
We don't have unordered collections
We don't support inversion
*/


alias Delta = list[Edit];

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


data Null = null();

alias IdAccess = tuple[bool(node) isId, loc(node) getId]; 

bool isDef(node n, IdAccess ia) 
  = any(node k <- getChildren(n), ia.isId(k));
  
loc getDefId(node n, IdAccess ia) 
  = head([ ia.getId(k) | node k <- getChildren(n), ia.isId(k) ]);

bool isAtom(value x, IdAccess ia) 
  = (str _ := x || bool _ := x || num _ := x) || (node n := x && ia.isId(n)) || x == null();
  
bool isList(value x) 
  = (list[value] _ := x);
   
bool isContains(value x, IdAccess ia) = (node n := x && !ia.isId(n) && !isDef(n, ia) && !isAtom(x, ia));


list[Edit] addInline(loc myId, Path path, node n, ASTModelMap meta, IdAccess ia) {
  ops =  addIt(myId, path, n, meta, ia); 
  ops += initIt(myId, path, n, meta, ia);
  return ops;
}

list[Edit] addIt(loc myId, Path path, node n, ASTModelMap meta, IdAccess ia) 
  = [create(myId, path, classOf(n, meta))];


list[Edit] initIt(loc myId, Path path, node n, ASTModelMap meta, IdAccess ia) {
  ops = [];
  ks = getChildren(n);
  i = 0;
  for (value k <- ks) {
    f = field(featureOf(n, i, size(ks), meta));
    println("<f> = <k>");

    // NB: check that kn is the id of the current n
    // otherwise we add references to self.    
    if (node kn := k, ia.isId(kn), !isDef(n, ia)) {
      // set ref
      ops += [setRef(myId, path + [field(f)], ia.getId(kn))];
    }
    
    if (node kn := k, isDef(kn, ia)) {
      // set ref
      ops += [setRef(myId, path + [field(f)], getDefId(kn, ia))];
    }
    
    if (isAtom(k, ia)) {
      // set prim
      ops += [setPrim(myId, path + [f], k)];
    }
    
    if (node kn := k, isContains(kn, ia)) {
      // creates 
      ops += addInline(myId, path + [f], kn, meta, ia);
    }
    
    if (isList(k)) {
      if (list[value] xs := k) {
        j = 0;
        for (x <- xs) {
          if (isAtom(x, ia)) {
            throw "Atoms cannot be in lists";
          }
          else if (node xn := x, isContains(x, ia)) {
            ops += addInline(myId, path + [f, index(j)], xn, meta, ia);
          }
          else if (node xn := x, isDef(xn, ia)) {
            ops += [insertAt(myId, path + [f, index(j)], getDefId(xn, ia))];
          }
          else if (node xn := x, ia.isId(xn)) {
            ops += [insertAt(myId, path + [f, index(j)], ia.getId(xn))];
          }
          j += 1;
        }
      }
    }
    i += 1;
  }
  return ops;
}

list[Edit] diffNodes(loc id1, loc id2, Path path, node n1, node n2,
       NameGraph g1, NameGraph g2, IDMatching mapping, ASTModelMap meta, IdAccess ia) {
       
    assert classOf(n1, meta) == classOf(n2, meta);

    changes = [];
    
     
    cs1 = getChildren(n1);
    cs2 = getChildren(n2);
      
    /*
     * We can simplify here by assuming
     * - n1.name == n2.name => classOf(n1) == classOf(n2)
     * - n1.name == n2.name => arity(n1) == arity(n2)
     */
      
    fs1 = featuresOf(n1, size(cs1), meta);
    fs2 = featuresOf(n2, size(cs2), meta);
    csr1 = { <fs1[j], cs1[j]> | j <- [0..size(fs1)] };
    csr2 = { <fs2[j], cs2[j]> | j <- [0..size(fs2)] };
      
    csr = { <<f1, k1>, <f1, k2>> | <str f1, value k1> <- csr1, <f1, value k2> <- csr2 };
    csr += { <<f1, k1>, <f1, null()>> | <str f1, value k1> <- csr1, f1 notin csr2<0> };
    csr += { <<f2, null()>, <f2, k2>> | <str f2, value k2> <- csr2, f2 notin csr1<0> };
      
    for (<<str f1, value k1>, <str f2, value k2>> <- csr)  {
      if (node k1n := k1, node k2n := k2, ia.isId(k1n), ia.isId(k2n)) {
        if (d1 <- g1.refs[ia.getId(k1n)], d2 <- g2.refs[ia.getId(k2n)],
            d1 in mapping.id ==> mapping.id[d1] != d2) {
          changes += [setRef(id1, path + [field(f1)], d2)];
        } 
      } 
      
      else if (isAtom(k1,ia), isAtom(k2, ia)) {
        if (k1 != k2) {
          changes += [setPrim(id2, path + [field(f1)], k2)];
        }
      }
      
      else if (node k1n := k1, node k2n := k2, ia.isId(k1n), isContains(k2n, ia)) {
        changes += addInline(id1, path + [field(f1)], k2n, meta, ia);
      } 
      
      else if (node k1n := k1, node k2n := k2, isContains(k1n, ia), ia.isId(k2n)) {
        changes += [setRef(id1, path + [field(f1)], ia.getId(k2n))];
      } 
      
      else if (node k1n := k1, node k2n := k2, isDef(k1n, ia), isDef(k2n, ia)) {
        if (mapping.id[getDefId(k1n, ia)] != getDefId(k2n, ia)) {
          changes += [setRef(id1, path + [field(f1)], getDefId(k2n, ia))];
        }
      }
      
      
      // TODO: check that isId does not mean self-id
      else if (node k1n := k1, node k2n := k2, isDef(k1n, ia), ia.isId(k2n)) {
        if (mapping.id[getDefId(k1n, ia)] != g2.refs[ia.getId(k2n)]) {
          changes += [setRef(id1, path + [field(f1)], ia.getId(k2n))];
        }
      }
      
      // TODO: check that isId does not mean self-id
      // Or not needed? because will be the same then?
      else if (node k1n := k1, node k2n := k2, ia.isId(k1n), isDef(k2n, ia)) {
        if (mapping.id[g1.refs[ia.getId(k1n)]] != getDefId(k2n, ia)) {
          changes += [setRef(id1, path + [field(f1)], getDefId(k2n, ia))];
        }
      }
      
      else if (list[value] k1l := k1, list[value] k2l := k2) {
         edits = listDiff(k1l, k2l, g1, g2, mapping, ia);
         for (e <- edits) {
           switch (e) {
             case remove(value a, int pos): {
               if (node an := a, isDef(an, ia)) {
                 changes += [removeAt(id1, path + [field(f1), index(pos)])];
               }
               else if (node an := a, ia.isId(an)) {
                 changes += [removeAt(id1, path + [field(f1), index(pos)])];
               }
               else if (node an := a, isContains(an, ia)) {
                 changes += [removeAt(id1, path + [field(f1), index(pos)])];
               }
               else {
                 assert false: "unsupported list element";
               }
             }
             case add(value a, int pos): {
               if (node an := a, isDef(an, ia)) {
                 changes += [insertAt(id1, path + [field(f1), index(pos)], getDefId(an, ia))];
               }
               else if (node an := a, ia.isId(an)) {
                 changes += [insertAt(id1, path + [field(f1), index(pos)], ia.getId(an))];
               }
               else if (node an := a, isContains(an, ia)) {
                 changes += addInline(id1, path + [field(f1), index(pos)], an, meta, ia);
               }
               else {
                 assert false: "unsupported list element";
               }
             }
           }
         }
      } 
      
      else if (node k1n := k1, node k2n := k2, isContains(k1n, ia), isContains(k2n, ia)) {
        if (classOf(k1n, meta) == classOf(k2n, meta)) {
          changes += diffNodes(id1, id2, path + [field(f1)], k1n, k2n, g1, g2, mapping, meta, ia);
        }
        else {
          // What if k1n contains defs???
          // should we do remove here? delete? or neither (i.e. let add override)?
          //changes += deleteIt(id1, path + [field(f1)], k1n, meta, ia);
          changes += addInline(id1, path + [field(f1)], k2n, meta, ia);
        }
      } 
      else {
        println("k1 = <k1>");
        println("k2 = <k2>");
        throw "Error";
      }
   }  
   return changes;
}


list[Edit] theDiff(IDClassMap r1, 
                        IDClassMap r2, 
                        NameGraph g1, 
                        NameGraph g2, 
                        IDMatching mapping, 
                        ASTModelMap meta,
                        IdAccess ia) {
  ops = [];
  for (<loc l2, _, node n2> <- r2,  l2 notin mapping.id<1>) {
    ops += addIt(l2, [], n2, meta, ia);
  }
  
  for (<loc l2, _, node n2> <- r2,  l2 notin mapping.id<1>) {
    ops += initIt(l2, [], n2, meta, ia);
  }

  for (<loc l1, _, node n1> <- r1, l1 in mapping.id) {
    l2 = mapping.id[l1];
    if (<_, node n2> <- r2[l2]) {
      ops += diffNodes(l1, l2, [], n1, n2, g1, g2, mapping, meta, ia);
    }
  }
  
  for (<loc l1, _, node n1> <- r1, l1 notin mapping.id) {
    ops += [delete(l1)];
  }

  return ops;
}


list[Diff[value]] listDiff(list[value] xs, list[value] ys, 
    NameGraph g1, NameGraph g2, IDMatching mapping, IdAccess ia) {

  bool eq(value x, value y) = modelEquals(x, y, g1, g2, mapping, ia);
 
  mx = lcsMatrix(xs, ys, eq);
  return getDiff(mx, xs, ys, size(xs), size(ys), eq);
}

bool modelEquals(value x, value y, NameGraph g1, NameGraph g2, IDMatching mapping, IdAccess ia) {
  if (node xn := x, node yn := y, isDef(xn, ia), isDef(yn, ia), getDefId(xn, ia) in mapping.id) {
    return mapping.id[getDefId(xn, ia)] == getDefId(yn, ia);
  }
  else if (node xn := x, node yn := y, ia.isId(xn), ia.isId(yn)) {
    if (d1 <- g1.refs[ia.getId(xn)], d2 <- g2.refs[ia.getId(yn)]) {
      return mapping.id[d1] == d2;
    }
    assert false: "BUG: Could not find use in ref graph.";
  }
  else if (node xn := x, node yn := y, ia.isId(xn), isDef(yn, ia)) {
    if (d1 <- g1.refs[ia.getId(xn)]) {
      return mapping.id[d1] == getDefId(yn, ia);
    }
    assert false: "BUG: Could not find use in ref graph.";
  }
  else if (node xn := x, node yn := y, isDef(xn, ia), ia.isId(yn)) {
    if (d2 <- g2.refs[ia.getId(yn)]) {
      return mapping[getDefId(xn, ia)] == d2;
    }
    assert false: "BUG: Could not find uses in ref graph.";
  }
  else if (node xn := x, node yn := y, isContains(xn, ia), ia.isContains(yn)) {
    xks = getChildren(xn);
    yks = getChildren(yn);
    if (getName(xn) != getName(yn)) {
      return false;
    }
    if (size(xks) != size(yks)) {
      return false;
    }
    for (<a, b> <- zip(xks, yks)) {
      if (!modelEquals(a, b, g1, g2, mapping, ia)) {
        return false;
      }
    }
    return true;
  }
  else if (list[value] xl := x, list[value] yl := y) {
    return listDiff(x, y) == [];
  }
  else if (isAtom(x, ia), isAtom(y, ia)) {
    return x == y;
  }
  return false;
}

   
