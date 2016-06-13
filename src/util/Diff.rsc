module util::Diff

import List;
import util::NameGraph;
import util::Mapping;
import util::LCS;
import util::Equals;

import Node;
import IO;
anno loc node@location;


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
  
data Name
 = name(str name);

data Edit
  = create(loc object, str class)
  | delete(loc object)
  | remove(loc object, Path path)
  | setPrim(loc object, Path path, value x)
  | setRef(loc object, Path path, loc ref)
  | insertRef(loc object, Path path, loc ref)
  //syntactic sugar -->
  | setTree(loc object, Path path, node tree)
  | insertTree(loc object, Path path, node tree)
  ;

//data EditOld 
// = \set(loc object, Path path, value x)
// | \insert(loc object, Path path, loc ref) 
// | remove(loc object, Path path)  
// | create(loc object, Path path, str class)
// | build(loc object, Path path, node tree)
// ;

str path2str(Path p) {
  str e2s(PathElement::field(x)) = ".<x>";
  str e2s(PathElement::index(x)) = "[<x>]";
  return intercalate("", [ e2s(e) | e <- p ]);
}

str delta2str(Delta d) {
   ids = ();
   i = 0;
   for (/loc l := d) {
      if (l notin ids) {
        ids[l] = i;
        i += 1;
      }
   } 
   
   node subst(node n) {
     return visit (delAnnotationsRec(n)) {
       case value x => "d<ids[obj]>"
         when loc obj := x
     }
   }

   s = "";
   for (e <- d) {
     switch (e) {
       case \setPrim(obj, path, x):
         s += "d<ids[obj]><path2str(path)> = <x>\n";
       case \setRef(obj, path, x):
         s += "d<ids[obj]><path2str(path)> = d<ids[x]>\n";
       case setTree(obj, path, node t):
         s += "d<ids[obj]><path2str(path)> = <subst(t)>\n";
       case \insertRef(obj, path, x):
         s += "d<ids[obj]><path2str(path)> = d<ids[x]>\n";
       case \insertPrim(obj, path, x):
         s += "d<ids[obj]><path2str(path)> = d<ids[x]>\n";
       case \insertTree(obj, path, x):
         s += "d<ids[obj]><path2str(path)> = <subst(x)>\n";
       case remove(obj, path):
         s += "remove d<ids[obj]><path2str(path)>\n";
       case create(obj, str class):
         s += "create <class> d<ids[obj]>\n";
       case delete(obj):
         s += "delete d<ids[obj]>\n";
       default:
         println("Missed: <e>");
     }
   }
   return s;
}

list[Edit] theDiff(IDClassMap r1, IDClassMap r2, NameGraph g1, NameGraph g2, 
                   IDMatching mapping, ASTModelMap meta, IDAccess ia) {

  ops = [];
  
  for (<loc l2, _, node n2> <- r2,  l2 notin mapping.id<1>)
    ops += addIt(l2, [], n2, meta, ia);
  
  for (<loc l2, _, node n2> <- r2,  l2 notin mapping.id<1>)
    ops += [setTree(l2, [], build(n2, g2, mapping, meta, ia))];

  for (<loc l1, _, node n1> <- r1, l1 in mapping.id) {
    l2 = mapping.id[l1];
    if (<_, node n2> <- r2[l2]) {
      ops += diffNodes(l1, l2, [], n1, n2, g1, g2, mapping, meta, ia);
    }
  }

  ops += [ remove(l1, []) | <loc l1, _, node n1> <- r1, l1 notin mapping.id ]; 

  return ops;
}


//list[Edit] addInline(loc myId, Path path, node n, NameGraph g, IDMatching mapping, ASTModelMap meta, IDAccess ia) {
//  //ops = addIt(myId, path, n, meta, ia); 
//  ops = initIt(myId, path, n, g, mapping, meta, ia);
//  return ops;
//}

list[Edit] addIt(loc myId, Path path, node n, ASTModelMap meta, IDAccess ia) 
  = [create(myId, classOf(n, meta))];

node build(node n, NameGraph g, IDMatching mapping, ASTModelMap meta, IDAccess ia) {
  ks = getChildren(n);
  newKs = [];
  for (k <- ks) {
    if (node kn := k, ia.isRefId(kn, g) /*, !isDef(n, g, ia) */) {
      // set ref
      if (d2 <- g.refs[ia.getId(kn)]) {
        if (org <- mapping.id, mapping.id[org] == d2) {
          newKs += [org];
        }
        else {
          newKs += [d2];
        }
      }
      else {
        assert false;
      }
    }
    
    if (node kn := k, isDef(kn, g, ia)) {
      // set ref
      d2 = getDefId(kn, g, ia);
      if (org <- mapping.id, mapping.id[org] == d2) {
        newKs += [org];
      }
      else {
        newKs += [d2];
      }
    }
    
    if (isAtom(k, g, ia)) {
      // set prim
      newKs += [k];
    }
    
    if (node kn := k, isContains(kn, g, ia)) {
      newKs += build(kn, g, mapping, meta, ia);
    }
    
    if (isList(k)) {
      list[value] newList = [];
      if (list[value] xs := k) {
        for (x <- xs) {
          if (isAtom(x, g, ia)) {
            throw "Atoms cannot be in lists";
          }
          else if (node xn := x, isContains(x, g, ia)) {
            newList += [build(xn, g, mapping, meta, ia)];
          }
          else if (node xn := x, isDef(xn, g, ia)) {
            d2 = getDefId(xn, g, ia);
            if (org <- mapping.id, mapping.id[org] == d2) {
              newList += [org];
            }
            else {
              newList += [d2];
            }
          }
          else if (node xn := x, ia.isRefId(xn, g)) {
            u2 = ia.getId(xn);
            if (d2 <- g.refs[u2]) {
              if (org <- mapping.id, mapping.id[org] == d2) {
                newList += [org];
              }
              else {
                newList += [d2];
              }
            }
          }
          else if (tuple[value,value] xt := x) {
            newList += [build("tuple"(xt[0], xt[1]), g, mapping, meta, ia)];
          }
          else {
            throw "Unsupported: <x>";
          }
        }
      }
      newKs += [newList];
    }
  }

  
  loc l = n@location;  
  return makeNode(getName(n), newKs)[@location = l];
}

//list[Edit] initIt(loc myId, Path path, node n, NameGraph g, IDMatching mapping, ASTModelMap meta, IDAccess ia) {
//  //return [set{ri(myId, path, build(n, g, mapping, meta, ia))];
//  ops = [];
//  ks = getChildren(n);
//  i = 0;
//  for (value k <- ks) {
//    f = field(featureOf(n, i, size(ks), meta));
//    //println("<f> = <k>");
//
//    // NB: check that kn is the id of the current n
//    // otherwise we add references to self.    
//    if (node kn := k, ia.isRefId(kn, g) /*, !isDef(n, g, ia) */) {
//      // set ref
//      if (d2 <- g.refs[ia.getId(kn)]) {
//        if (org <- mapping.id, mapping.id[org] == d2) {
//          ops += [\insertRef(myId, path + [f], org)];
//        }
//        else {
//          ops += [\insertRef(myId, path + [f], d2)];
//        }
//      }
//      else {
//        assert false;
//      }
//    }
//    
//    if (node kn := k, isDef(kn, g, ia)) {
//      // set ref
//      d2 = getDefId(kn, g, ia);
//      if (org <- mapping.id, mapping.id[org] == d2) {
//        ops += [\insertRef(myId, path + [f], org)];
//      }
//      else {
//        ops += [\insertRef(myId, path + [f], d2)];
//      }
//    }
//    
//    if (isAtom(k, g, ia)) {
//      // set prim
//      ops += [\setPrim(myId, path + [f], k)];
//    }
//    
//    if (node kn := k, isContains(kn, g, ia)) {
//      // creates 
//      ops += addInline(myId, path + [f], kn, g, mapping, meta, ia);
//    }
//    
//    if (isList(k)) {
//      if (list[value] xs := k) {
//        j = 0;
//        for (x <- xs) {
//          if (isAtom(x, g, ia)) {
//            throw "Atoms cannot be in lists";
//          }
//          else if (node xn := x, isContains(x, g, ia)) {
//            ops += addInline(myId, path + [f, index(j)], xn, g, mapping, meta, ia);
//          }
//          else if (node xn := x, isDef(xn, g, ia)) {
//            d2 = getDefId(xn, g, ia);
//            if (org <- mapping.id, mapping.id[org] == d2) {
//              ops += [\insertRef(myId, path + [f, index(j)], org)];
//            }
//            else {
//              ops += [\insertRef(myId, path + [f, index(j)], d2)];
//            }
//          }
//          else if (node xn := x, ia.isRefId(xn, g)) {
//            u2 = ia.getId(xn);
//            if (d2 <- g.refs[u2]) {
//              if (org <- mapping.id, mapping.id[org] == d2) {
//                ops += [\insertRef(myId, path + [f, index(j)], org)];
//              }
//              else {
//                ops += [\insertRef(myId, path + [f, index(j)], org)];
//              }
//            }
//            
//          }
//          j += 1;
//        }
//      }
//    }
//    i += 1;
//  }
//  return ops;
//}

list[Edit] diffNodes(loc id1, loc id2, Path path, node n1, node n2,
       NameGraph g1, NameGraph g2, IDMatching mapping, ASTModelMap meta, IDAccess ia) {
       
    assert classOf(n1, meta) == classOf(n2, meta);

    list[Edit] changes = [];
    
     
    cs1 = getChildren(n1);
    cs2 = getChildren(n2);
      
    /*
     * We can simplify here by assuming
     * - n1.name == n2.name => classOf(n1) == classOf(n2)
     * - n1.name == n2.name => arity(n1) == arity(n2)
     */
      
    fs1 = featuresOf(n1, size(cs1), meta);
    fs2 = featuresOf(n2, size(cs2), meta);
    csr1 = [ <fs1[j], cs1[j]> | j <- [0..size(fs1)] ];
    csr2 = [ <fs2[j], cs2[j]> | j <- [0..size(fs2)] ];
      
    csr = outerJoin(csr1, csr2, null());
      
    for (<str f1, value k1, str f2, value k2> <- csr)  {
      assert f1 == f2;
      //println("f1 <f1> = <k1>");
      //println("f2 <f2> = <k2>");
      //
    
      if (node k1n := k1, node k2n := k2, ia.isRefId(k1n, g1), ia.isRefId(k2n, g2)) {
        if (d1 <- g1.refs[ia.getId(k1n)], d2 <- g2.refs[ia.getId(k2n)],
            d1 in mapping.id ==> mapping.id[d1] != d2) {
          if (org <- mapping.id, mapping.id[org] == d2) {
            // always update to old id if possible
            changes += [setRef(id1, path + [field(f1)], org)];
          }
          else {
            changes += [setRef(id1, path + [field(f1)], d2)];
          }
        } 
      } 
      
      else if (isAtom(k1, g1, ia), isAtom(k2, g2, ia)) {
        if (k1 != k2) {
          changes += [\setPrim(id2, path + [field(f1)], k2)];
        }
      }
      
      else if (node k1n := k1, node k2n := k2, ia.isRefId(k1n, g1), isContains(k2n, g2, ia)) {
        //changes += addInline(id1, path + [field(f1)], k2n, mapping, meta, ia);
        changes += [setTree(id1, path + [field(f1)], build(k2n, g2, mapping, meta, ia))];
      } 
      
      else if (node k1n := k1, node k2n := k2, isContains(k1n, g1, ia), ia.isRefId(k2n, g2)) {
        if (d2 <- g2.refs[ia.getId(k2n)]) {
          if (org <- mapping.id, mapping.id[org] == d2) {
            changes += [setRef(id1, path + [field(f1)], org)];
          }
          else {
            changes += [setRef(id1, path + [field(f1)], d2)];
          }
        }
        else {
          assert false;
        }
      } 
      
      else if (node k1n := k1, node k2n := k2, isDef(k1n, g1, ia), isDef(k2n, g2, ia)) {
        if (mapping.id[getDefId(k1n, g1, ia)] != getDefId(k2n, g2, ia)) {
          d2 = getDefId(k2n, g2, ia);
          if (org <- mapping.id, mapping.id[org] == d2) {
            changes += [setRef(id1, path + [field(f1)], org)];
          }
          else {
            changes += [setRef(id1, path + [field(f1)], d2)];
          }
        }
      }
      
      
      // TODO: check that isId does not mean self-id
      else if (node k1n := k1, node k2n := k2, isDef(k1n, g1, ia), ia.isRefId(k2n, g2)) {
        if (d2 <- g2.refs[ia.getId(k2n)]) {
          if (mapping.id[getDefId(k1n, g1, ia)] != d2) {
            if (org <- mapping.id, mapping[org] == d2) {
              changes += [setRef(id1, path + [field(f1)], org)];
            }
            else {
              changes += [setRef(id1, path + [field(f1)], d2)];
            }
          }
        }
        else {
          assert false;
        }
      }
      
      // TODO: check that isId does not mean self-id
      // Or not needed? because will be the same then?
      else if (node k1n := k1, node k2n := k2, ia.isRefId(k1n, g1), isDef(k2n, g2, ia)) {
        d2 = getDefId(k2n, g2, ia);
        if (mapping.id[g1.refs[ia.getId(k1n)]] != d2) {
          if (org <- mapping.id, mapping.id[org] == d2) { 
            changes += [setRef(id1, path + [field(f1)], org)];
          }
          else {
            changes += [setRef(id1, path + [field(f1)], d2)];
          }
        }
      }
      
      else if (list[value] k1l := k1, list[value] k2l := k2) {
         edits = diffLists(k1l, k2l, g1, g2, mapping, ia);
         offset = 0;
         for (e <- edits) {
           switch (e) {
             case remove(value a, int pos): {
               p = path + [field(f1), index(pos + offset)];
               offset -= 1;
               if (node an := a) {
                 changes += [remove(id1, p)];
               }
               else {
                 assert false: "unsupported list element";
               }
             }
             case add(value a, int pos): {
               p = path + [field(f1), index(pos)];
               offset += 1;
               if (node an := a, isDef(an, g2, ia)) {
                 d2 = getDefId(an, g2, ia);
                 if (org <- mapping.id, mapping.id[org] == d2) {
                   changes += [insertRef(id1, p, org)];
                 }
                 else {
                   changes += [insertRef(id1, p, d2)];
                 }
               }
               else if (node an := a, ia.isRefId(an, g2)) {
                 u2 = ia.getId(an);
                 if (d2 <- g2.refs[u2]) {
                   if (org <- mapping.id, mapping.id[org] == d2) {
                     changes += [insertRef(id1, p, org)];
                   }
                   else {
                     changes += [insertRef(id1, p, d2)];
                   }
                 }
               }
               else if (node an := a, isContains(an, g2, ia)) {
                 //changes += addInline(id1, p, an, g2, mapping, meta, ia);
                 changes += insertTree(id1, p, build(an, g2, mapping, meta, ia));
               }
               else {
                 assert false: "unsupported list element";
               }
             }
           }
         }
      } 
      
      else if (node k1n := k1, node k2n := k2, isContains(k1n, g1, ia), isContains(k2n, g2, ia)) {
        if (classOf(k1n, meta) == classOf(k2n, meta)) {
          changes += diffNodes(id1, id2, path + [field(f1)], k1n, k2n, g1, g2, mapping, meta, ia);
        }
        else {
          // What if k1n contains defs???
          // should we do remove here? delete? or neither (i.e. let add override)?
          //changes += deleteIt(id1, path + [field(f1)], k1n, meta, ia);
          //changes += addInline(id1, path + [field(f1)], k2n, mapping, meta, ia);
          changes += setTree(id1, path + [field(f1)], build(k2n, g2, mapping, meta, ia));
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

lrel[&T, &U, &T, &U] outerJoin(lrel[&T, &U] r1, lrel[&T, &U] r2, &U null) {
  r = [ <f1, k1, f1, k2> | <&T f1, &U k1> <- r1, <f1, value k2> <- r2 ];
  r += [ <f1, k1, f1, null> | <&T f1, &U k1> <- r1, f1 notin r2<0> ];
  r += [ <f2, null, f2, k2> | <&T f2, &U k2> <- r2, f2 notin r1<0> ];
  return r;
}


private bool notCreateOrDelete(Edit op)
  =  insertRef(_,_,_) := op
  || insertTree(_,_,_) := op
  || setRef(_,_,_) := op 
  || setTree(_,_,_) := op
  || setPrim(_,_,_) := op
  || remove(_,_) := op;

public Delta order(Delta d)
  = [op | op <- d, create(_,_) := op ]
  + [op | op <- d, notCreateOrDelete(op)] //remove order by path length
  + [op | op <- d, delete(_) := op ];

public bool less(Edit e1, Edit e2)
{
  if(size(e1.path) < size(e2.path))
  {
    return true;
  }
  else if(size(e1.path) == size(e2.path) && size(e1.path) > 0)
  {
    if(index(i1) := e1.path[size(e1.path)-1] &&
       index(i2) := e2.path[size(e2.path)-1])
      {
        return (i1 < i2);
      }
  }
  return false;
}

public Delta orderByPathLength(Delta d)
  = sort(d, less);


public list[Edit] flatten(insertTree(object, path, tree), ASTModelMap m)
  = flatten(object, path, tree, m);
  
public list[Edit] flatten(setTree(object, path, tree), ASTModelMap m)
  = flatten(object, path, tree, m);

public list[Edit] flatten(create(object, klass), ASTModelMap m)
  = []; //hack, creates are recreated by flatten!
  
public list[Edit] flatten(Edit edit, ASTModelMap m)
  = [edit];

public list[Edit] flatten(loc object, Path path, name(x), ASTModelMap m)
 = [setPrim(object, path, x)];

public list[Edit] flatten(loc object, Path path, int x, ASTModelMap m)
 = [setPrim(object, path, x)];

public list[Edit] flatten(loc object, Path path, str x, ASTModelMap m)
 = [setPrim(object, path, x)];

public list[Edit] flatten(loc object, Path path, loc ref, ASTModelMap m)
 = [insertRef(object, path, ref)];

public list[Edit] flatten(loc object, Path path, list[value] l, ASTModelMap m)
{ 
  list[Edit] ops = [];
  int pos = 0;
  for(child <- l)
  {
    println("position[<pos>]"); 
    ops += [*flatten(object, path + [index(pos)], child, m)];
    pos += 1;
  }
  return ops;
}

//flatten an object
public list[Edit] flatten(loc object, Path path, node tree, ASTModelMap m)
{
  str klass = classOf(tree, m);
  println("Object <klass>");
  iprintln(tree);
  list[Edit] ops = [];
    
  if(path == []){
    ops += [create(object, klass)];
  } else {  
    ops +=
    [
      create(tree@location, klass),
      insertRef(object, path, tree@location)
    ];
  }
  
  int arity = size(getChildren(tree));  
  int pos = 0;
  for(child <- getChildren(tree))
  {
    str feature = featureOf(tree, pos, arity, m);
    println("Feature[<pos>]: <feature>");
  
    ops += [*flatten(object, path + [field(feature)], child, m)];
    pos += 1;
  }
  
  //[*flatten(object, path + [field(getName(tree))], child) | child <- getChildren(tree)];
  return ops;
}
  