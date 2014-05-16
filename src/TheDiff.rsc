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

  
anno loc node@location;


   
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
  
  void diffContainsNodes(loc id1, loc id2, Path path, node n1, node n2) {
    cs1 = getChildren(n1);
    cs2 = getChildren(n2);
    i = 0;
    for (<value k1, value k2> <- zip(cs1, cs2)) {
      if (node k1n := k1, node k2n := k2, isUse1(k1n), isUse2(k2n)) {
           loc trg1 = getOneFrom(g1.refs[getUseId(k1n)]);
           loc trg2 = getOneFrom(g2.refs[getUseId(k2n)]);
           if (trg1 in mapping.id && mapping.id[trg1] == trg2) {
              ; // nothing
           }
           else {
             changes += [op_insert(id1, path + [featureOf(n1, i, meta)], trg2)]; 
           }
         } 
         else if (isAtom(k1), isAtom(k2)) {
           if (k1 == k2) {
             ; // nothing
           }
           else {
             changes += [op_set(id2, path + [featureOf(n1, i, meta)], k2, k1)];
           }
         }
         else if (node k1n := k1, node k2n := k2, isUse1(k1n), isContains1(k2n)) {
           // always different
           newId = addIt(k2n);
           // TODO: make creation inline here, just like deletes.
           // Is ok because no aliasing.
           changes += [op_insert(id2, path + [featureOf(n1, i, meta)], newId)];
         } 
         else if (node k1n := k1, node k2n := k2, isContains1(k1n), isUse2(k2n)) {
           // TODO: add delete to changes here 
           // so that we can use paths.
           deleteIt(k1n);
           //changes += [op_remove(id2, path + [i], getUseId(k2n))];
           changes += [op_insert(id2, path + [featureOf(n1, i, meta)], getUseId(k2n))];
         } 
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
              // NOTE: for now we require size of children to be the same
              // should match arguments based on names. 
              if (classOf(k1n, meta) == classOf(k2n, meta), size(getChildren(k1n)) == size(getChildren(k2n))) {
                 diffContainsNodes(id1, id2, path + [featureOf(n1, i, meta)], k1n, k2n);
              }
              else {
                deleteIt(k1n);
                newId = addIt(k2n);
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
             changes += [op_insert(getDefId2(n2), featureOf(n1, i, meta), trg2)]; 
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
             changes += [op_set(id2, featureOf(n1, i, meta), k2, k1)];
           }
         }
         else if (node k1n := k1, node k2n := k2, isUse1(k1n), isContains1(k2n)) {
           // always different
           newId = addIt(k2n);
           println("set to contains field [<i>] in <getDefId2(n2)> to <newId>");
           changes += [op_insert(getDefId2(n2), featureOf(n1, i, meta), newId)];
         } 
         else if (node k1n := k1, node k2n := k2, isContains1(k1n), isUse2(k2n)) {
           deleteIt(k1n);
           println("set to reference field [<i>] in <getDefId2(n2)> to <getUseId(k2n)>");
           changes += [op_insert(getDefId2(n2), featureOf(n1, i, meta), getUseId(k2n))];
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
                 diffContainsNodes(id1, id2, [featureOf(n1, i, meta)], k1n, k2n);
              }
              else {
                deleteIt(k1n);
                newId = addIt(k2n);
                println("set contains field [<i>] to <newId>");
                // TODO!!!
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
  
  
