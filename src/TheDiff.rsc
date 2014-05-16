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
import util::Mapping;

import Node;
import ParseTree;
import Set;

import lang::Delta::AST;

data Null = null();

alias IdAccess = tuple[bool(node) isId, loc(node) getId]; 

bool isDef(node n, IdAccess ia) 
  = any(node k <- getChildren(n), ia.isId(k));
  
loc getDefId(node n, IdAccess ia) 
  = head([ getId(k) | node k <- getChildren(n), isId(k, ia) ]);

bool isAtom(value x, IdAccess ia) 
  = (str _ := x || bool _ := x || num _ := x) || (node n := x && ia.isId(n)) || x == null();
  
bool isList(value x) 
  = (list[value] _ := x);
   
bool isContains(value x, IdAccess ia) = (node n := x && !ia.isId(n) && !isDef(n, ia) && !isAtom(x, ia));


list[Operation] deleteIt(loc myId, Path path, node n, ASTModelMap meta, IdAccess ia) {
  ops = [];
  ks = getChildren(n);
  i = 0;
  for (value k <- ks) {
    if (node kn := k, isContains(kn, ia)) {
      // first delete kids
      ops += deleteIt(myId, path + [featureOf(n, i, size(ks), meta)], kn, meta, ia);
    }
    i += 1;
  }
  ops += [op_del(myId, path, classOf(n, meta))];
  return ops;
}

list[Operation] addIt(loc myId, Path path, node n, ASTModelMap meta, IdAccess ia) {
  ops = [];
  ks = getChildren(n);
  i = 0;
  // first add container
  ops += [op_new(myId, path, classOf(n, meta))];
  for (value k <- ks) {
    if (node kn := k, isContains(kn, ia)) {
      // first add kids
      println("kn = <kn>");
      println("ks = <ks>");
      iprintln(meta);
      ops += addIt(myId, path + [featureOf(n, i, size(ks), meta)], kn, meta, ia);
    }
    i += 1;
  }
  return ops;
}

list[Operation] diffNodes(loc id1, loc id2, Path path, node n1, node n2,
       NameGraph g1, NameGraph g2, ASTModelMap meta, IdAccess ia) {
       
    assert classOf(n1, meta) == classOf(n2, meta);

    changes = [];
    
     
    cs1 = getChildren(n1);
    cs2 = getChildren(n2);
      
      
    fs1 = featuresOf(n1, size(cs1), meta);
    fs2 = featuresOf(n2, size(cs2), meta);
    csr1 = { <fs1[j], cs1[j]> | j <- [0..size(fs1)] };
    csr2 = { <fs2[j], cs2[j]> | j <- [0..size(fs2)] };
      
    csr = { <<f1, k1>, <f1, k2>> | <str f1, value k1> <- csr1, <f1, value k2> <- csr2 };
    csr += { <<f1, k1>, <f1, null()>> | <str f1, value k1> <- csr1, f1 notin csr2<0> };
    csr += { <<f2, null()>, <f2, k2>> | <str f2, value k2> <- csr2, f2 notin csr1<0> };
      
      // Loop over shared features in both sides.
    for (<<str f1, value k1>, <str f2, value k2>> <- csr)  {
      if (node k1n := k1, node k2n := k2, ia.isId(k1n), ia.isId(k2n)) {
        if (d1 <- g1.refs[ia.getId(k1n)], d2 <- g2.refs[ia.getId(k2n)],
            d1 in mapping.id ==> mapping.id[d1] != d2) {
          changes += [op_insert(id1, path + [f1], d2)];
        } 
      } 
      
      else if (isAtom(k1,ia), isAtom(k2, ia)) {
        if (k1 != k2) {
          changes += [op_set(id2, path + [f1], k2, k1)];
        }
      }
      
      else if (node k1n := k1, node k2n := k2, ia.isId(k1n), isContains(k2n, ia)) {
        changes += [op_remove(id1, path + [f1], ia.getId(k1n))];
        changes += addIt(id1, path + [f1], k2n, meta, ia);
      } 
      
      else if (node k1n := k1, node k2n := k2, isContains(k1n, ia), ia.isId(k2n)) {
        changes += deleteIt(id1, path + [f1], k1n, meta, ia);
        changes += [op_insert(id1, path + [f1], ia.getId(k2n))];
      } 
      
      else if (node k1n := k1, node k2n := k2, isDef(k1n, ia), isDef(k2n, ia)) {
        if (mapping.id[getDefId(k1n, ia)] != getDefId(k2n, ia)) {
          changes += [op_remove(id1, path + [f1], getDefId(k1n, ia))];
          changes += [op_insert(id1, path + [f1], getDefId(k2n, ia))];
        }
      }
      
      
      else if (node k1n := k1, node k2n := k2, isDef(k1n, ia), ia.isId(k2n)) {
        if (mapping.id[getDefId(k1n, ia)] != g2.refs[ia.getId(k2n)]) {
          changes += [op_remove(id1, path + [f1], getDefId(k1n, ia))];
          changes += [op_insert(id1, path + [f1], ia.getId(k2n))];
        }
      }
      
      else if (node k1n := k1, node k2n := k2, ia.isId(k1n), isDef(k2n, ia)) {
        if (mapping.id[g1.refs[ia.getId(k1n)]] != getDefId(k2n, ia)) {
          changes += [op_remove(id1, path + [f1], ia.getId(k1n))];
          changes += [op_insert(id1, path + [f1], getDefId(k2n, ia))];
        }
      }
      
      else if (isList(k1), isList(k2)) {
         ;// TODO
      } 
      
      else if (node k1n := k1, node k2n := k2, isContains(k1n, ia), isContains(k2n, ia)) {
        if (classOf(k1n, meta) == classOf(k2n, meta)) {
          changes += diffNodes(id1, id2, path + [f1], k1n, k2n, g1, g2, meta, ia);
        }
        else {
          changes += deleteIt(id1, path + [f1], k1n, meta, ia);
          changes += addIt(id1, path + [f1], k2n, meta, ia);
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


list[Operation] theDiff(IDClassMap r1, 
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
  
  for (<loc l1, _, node n1> <- r1, l1 in mapping.id) {
    l2 = mapping.id[l1];
    if (<_, node n2> <- r2[l2]) {
      ops += diffNodes(l1, l2, [], n1, n2, g1, g2,meta, ia);
    }
  }
  
  for (<loc l1, _, node n1> <- r1, l1 notin mapping.id) {
    ops += deleteIt(l1, [], n1, meta, ia);
  }

  return ops;
}

   
/*void*/ Delta doIt(IDClassMap r1, IDClassMap r2, NameGraph g1, NameGraph g2, IDMatching mapping, ASTModelMap meta) {
 
  list[Operation] additions = [];
  list[Operation] changes = [];
  list[Operation] deletions = [];  
  
  int count = 0;
 
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
    deletions += [op_del(myId, classOf(n, meta))];
  }
  
  loc new(node n) {
     l = n@location;
     l.fragment = "<count>";
     count += 1;
     return l;
  }
  
  loc addIt(node n) = addIt(new(n), n);
  
  loc addIt(loc newId, node n) {
     println("ADD <newId> = new <classOf(n, meta)>");
     additions += [op_new(newId, classOf(n, meta))];
     int i = 0;
     for (value k <- getChildren(n)) {
       if (node kn := k, isUse2(kn)) {
         if (target <- g2.refs[getUseId(kn)], original <- mapping.id, mapping.id[original] == target) {
           println("set to original reference [<i>] of <newId> = <original>");           
           changes += [op_insert(newId, featureOf(n, i, meta), original) ];
         }
         else {
           //FIXME:
           //println("set new reference [<i>] of <newId> = <target>");
           //changes += [op_insert(newId, "<i>", target) ];
           ;
         }
       }
       else if (node kn := k, isDef2(kn)) {
         println("set ref field [<i>] of <newId> = <getDefId2(kn)>");
         changes += [op_insert(newId, featureOf(n, i, meta), getDefId2(kn))];
       }
       else if (isAtom(k)) {
         println("set prim field [<i>] of <newId>  = <k>");
         changes += [op_set(newId, featureOf(n, i, meta), k, 0)];
       }
       else if (isContains2(k)) {
         if (node kn := k) {
           kidId = addIt(kn);
           println("set contains field [<i>] of <newId>  = <kidId>");
           iprintln(meta);
           println(n);
           println(kn);
           changes += [op_insert(newId, featureOf(n, i, meta), kidId)];
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
      
      assert classOf(n1, meta) == classOf(n2, meta);
      
      cs1 = getChildren(n1);
      cs2 = getChildren(n2);
      
      
      fs1 = featuresOf(n1, meta);
      fs2 = featuresOf(n2, meta);
      csr1 = { <fs1[j], cs1[j]> | j <- [0..size(fs1)] };
      csr2 = { <fs2[j], cs2[j]> | j <- [0..size(fs2)] };
      
      
      // features in n1, not in n2
      for (<str f1, value k1> <- csr1, f1 notin csr2<0>) {
        ;
      }
      

      // features in n2, not in n1
      for (<str f2, value k2> <- csr2, f2 notin csr1<0>) {
      ;
      }
      
      // Loop over shared features in both sides.
      for (<str f1, value k1> <- csr1, <f1, value k2> <- csr2)  {
         if (node k1n := k1, node k2n := k2, isUse1(k1n), isUse2(k2n)) {
           loc trg1 = getOneFrom(g1.refs[getUseId(k1n)]);
           loc trg2 = getOneFrom(g2.refs[getUseId(k2n)]);
           if (trg1 in mapping.id && mapping.id[trg1] == trg2) {
              ; // nothing
           }
           else {
             changes += [op_insert(getDefId2(n2), f1, trg2)]; 
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
             changes += [op_set(id2, f1, k2, k1)];
           }
         }
         else if (node k1n := k1, node k2n := k2, isUse1(k1n), isContains1(k2n)) {
           // always different
           newId = addIt(k2n);
           println("set to contains field [<i>] in <getDefId2(n2)> to <newId>");
           changes += [op_insert(getDefId2(n2), [f1], newId)];
         } 
         else if (node k1n := k1, node k2n := k2, isContains1(k1n), isUse2(k2n)) {
           deleteIt(k1n);
           println("set to reference field [<i>] in <getDefId2(n2)> to <getUseId(k2n)>");
           changes += [op_insert(getDefId2(n2), [f1], getUseId(k2n))];
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
              if (classOf(k1n, meta) == classOf(k2n, meta), size(getChildren(k1n)) == size(getChildren(k2n))) {
                 diffContainsNodes(id1, id2, [f1], k1n, k2n);
              }
              else {
                deleteIt(k1n);
                newId = addIt(k2n);
                // TODO!!!
              }
         } 
         else {
           println("k1 = <k1>");
           println("k2 = <k2>");
           throw "Error";
         }
     }
   }
 
  for (<loc l2, _, node n2> <- r2,  l2 notin mapping.id<1>) {
    println("Adds----------");
    println("L2 = <l2>");
    println(mapping.id<1>);
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
  
  
