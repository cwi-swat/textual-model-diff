module util::Diff

import List;
import util::NameGraph;
import util::Mapping;
import util::LCS;
import util::Equals;

import Node;

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

list[Edit] theDiff(IDClassMap r1, IDClassMap r2, NameGraph g1, NameGraph g2, 
                   IDMatching mapping, ASTModelMap meta, IDAccess ia) {

  ops = [];
  
  for (<loc l2, _, node n2> <- r2,  l2 notin mapping.id<1>)
    ops += addIt(l2, [], n2, meta, ia);
  
  for (<loc l2, _, node n2> <- r2,  l2 notin mapping.id<1>)
    ops += initIt(l2, [], n2, g2, meta, ia);

  for (<loc l1, _, node n1> <- r1, l1 in mapping.id) {
    l2 = mapping.id[l1];
    if (<_, node n2> <- r2[l2]) {
      ops += diffNodes(l1, l2, [], n1, n2, g1, g2, mapping, meta, ia);
    }
  }

  ops += [ delete(l1) | <loc l1, _, node n1> <- r1, l1 notin mapping.id ]; 

  return ops;
}


list[Edit] addInline(loc myId, Path path, node n, NameGraph g, ASTModelMap meta, IDAccess ia) {
  ops = addIt(myId, path, n, meta, ia); 
  ops += initIt(myId, path, n, g, meta, ia);
  return ops;
}

list[Edit] addIt(loc myId, Path path, node n, ASTModelMap meta, IDAccess ia) 
  = [create(myId, path, classOf(n, meta))];


list[Edit] initIt(loc myId, Path path, node n, NameGraph g, ASTModelMap meta, IDAccess ia) {
  ops = [];
  ks = getChildren(n);
  i = 0;
  for (value k <- ks) {
    f = field(featureOf(n, i, size(ks), meta));
    //println("<f> = <k>");

    // NB: check that kn is the id of the current n
    // otherwise we add references to self.    
    if (node kn := k, ia.isRefId(kn, g), !isDef(n, g, ia)) {
      // set ref
      if (d2 <- g.refs[ia.getId(kn)]) {
        ops += [setRef(myId, path + [f], d2)];
      }
      else {
        assert false;
      }
    }
    
    if (node kn := k, isDef(kn, g, ia)) {
      // set ref
      ops += [setRef(myId, path + [f], getDefId(kn, g, ia))];
    }
    
    if (isAtom(k, g, ia)) {
      // set prim
      ops += [setPrim(myId, path + [f], k)];
    }
    
    if (node kn := k, isContains(kn, g, ia)) {
      // creates 
      ops += addInline(myId, path + [f], kn, meta, ia);
    }
    
    if (isList(k)) {
      if (list[value] xs := k) {
        j = 0;
        for (x <- xs) {
          if (isAtom(x, g, ia)) {
            throw "Atoms cannot be in lists";
          }
          else if (node xn := x, isContains(x, g, ia)) {
            ops += addInline(myId, path + [f, index(j)], xn, g, meta, ia);
          }
          else if (node xn := x, isDef(xn, g, ia)) {
            ops += [insertAt(myId, path + [f, index(j)], getDefId(xn, g, ia))];
          }
          else if (node xn := x, ia.isRefId(xn, g)) {
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
       NameGraph g1, NameGraph g2, IDMatching mapping, ASTModelMap meta, IDAccess ia) {
       
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
      
    csr = outerJoin(csr1, csr2, null());
      
    for (<str f1, value k1, str f2, value k2> <- csr)  {
    
      if (node k1n := k1, node k2n := k2, ia.isRefId(k1n, g1), ia.isRefId(k2n, g2)) {
        if (d1 <- g1.refs[ia.getId(k1n)], d2 <- g2.refs[ia.getId(k2n)],
            d1 in mapping.id ==> mapping.id[d1] != d2) {
          changes += [setRef(id1, path + [field(f1)], d2)];
        } 
      } 
      
      else if (isAtom(k1, g1, ia), isAtom(k2, g2, ia)) {
        if (k1 != k2) {
          changes += [setPrim(id2, path + [field(f1)], k2)];
        }
      }
      
      else if (node k1n := k1, node k2n := k2, ia.isRefId(k1n, g1), isContains(k2n, g2, ia)) {
        changes += addInline(id1, path + [field(f1)], k2n, meta, ia);
      } 
      
      else if (node k1n := k1, node k2n := k2, isContains(k1n, g1, ia), ia.isRefId(k2n, g2)) {
        if (d2 <- g2.refs[ia.getId(k2n)]) {
          changes += [setRef(id1, path + [field(f1)], d2)];
        }
        else {
          assert false;
        }
      } 
      
      else if (node k1n := k1, node k2n := k2, isDef(k1n, g1, ia), isDef(k2n, g2, ia)) {
        if (mapping.id[getDefId(k1n, g1, ia)] != getDefId(k2n, g2, ia)) {
          changes += [setRef(id1, path + [field(f1)], getDefId(k2n, g2, ia))];
        }
      }
      
      
      // TODO: check that isId does not mean self-id
      else if (node k1n := k1, node k2n := k2, isDef(k1n, g1, ia), ia.isRefId(k2n, g2)) {
        if (d2 <- g2.refs[ia.getId(k2n)]) {
          if (mapping.id[getDefId(k1n, g1, ia)] != d2) {
            changes += [setRef(id1, path + [field(f1)], d2)];
          }
        }
        else {
          assert false;
        }
      }
      
      // TODO: check that isId does not mean self-id
      // Or not needed? because will be the same then?
      else if (node k1n := k1, node k2n := k2, ia.isRefId(k1n, g1), isDef(k2n, g2, ia)) {
        if (mapping.id[g1.refs[ia.getId(k1n)]] != getDefId(k2n, g2, ia)) {
          changes += [setRef(id1, path + [field(f1)], getDefId(k2n, g2, ia))];
        }
      }
      
      else if (list[value] k1l := k1, list[value] k2l := k2) {
         edits = diffLists(k1l, k2l, g1, g2, mapping, ia);
         for (e <- edits) {
           switch (e) {
             case remove(value a, int pos): {
               p = path + [field(f1), index(pos)];
               if (node an := a) {
                 changes += [removeAt(id1, p)];
               }
               else {
                 assert false: "unsupported list element";
               }
             }
             case add(value a, int pos): {
               p = path + [field(f1), index(pos)];
               if (node an := a, isDef(an, g2, ia)) {
                 changes += [insertAt(id1, p, getDefId(an, g2, ia))];
               }
               else if (node an := a, ia.isRefId(an, g2)) {
                 changes += [insertAt(id1, p, ia.getId(an))];
               }
               else if (node an := a, isContains(an, g2, ia)) {
                 changes += addInline(id1, p, an, g2, meta, ia);
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
        throw "Error: unsupported node args: <k1> and <k2>";
      }
   }  
   return changes;
}


list[Diff[value]] diffLists(list[value] xs, list[value] ys, 
    NameGraph g1, NameGraph g2, IDMatching mapping, IDAccess ia) {

  bool eq(value x, value y) = modelEquals(x, y, g1, g2, mapping, ia);
 
  mx = lcsMatrix(xs, ys, eq);
  return getDiff(mx, xs, ys, size(xs), size(ys), eq);
}

rel[&T, &U, &T, &U] outerJoin(rel[&T, &U] r1, rel[&T, &U] r2, &U null) {
  r = { <f1, k1, f1, k2> | <&T f1, &U k1> <- r1, <f1, value k2> <- r2 };
  r += { <f1, k1, f1, null> | <&T f1, &U k1> <- r1, f1 notin r2<0> };
  r += { <f2, null, f2, k2> | <&T f2, &U k2> <- r2, f2 notin r1<0> };
  return r;
} 
    
   
