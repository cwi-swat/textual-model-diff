module util::Old

void diffTree(&T<:node t1, &T<:node t2, map[loc,str] ts1, map[loc, str] ts2,  
  NameGraph g1, NameGraph g2, IDDiff d) {

  for (x <- d.added) {
    println("v2_<x.offset> = new <ts2[x]>");
  }
  
  node findNode(node t2, loc l) {
     visit (t2) {
       case node n: if (n@location == l) return n; 
     }
  }
  
  bool isDef(node x, NameGraph g) =
     any(node k <- getChildren(x), k@location in g.defs);
  
  
  void updateFields(loc old, list[value] oldFields, list[value] newFields) {
     assert size(oldFields) == size(newFields);
     for (i <- [0..size(oldFields)]) {
        switch (<oldFields[i], newFields[i]>) {
          case <node a, node b> : {
             if (a@location in g1.uses, b@location in g2.uses,
                   d.id[g1.refs[a@location]] != g2.refs[b@location] ) {
               // both references, bot not to the same thing so update.
               if (g2.refs[b@location] in d.added) {
                 // ref to a new thing
                 println("v1_<old.offset>[<i>] = v2_<g2.refs[b@location].offset>");
               }
               else {
                 // updated ref to an old thing
                 ks = [ k | k <- d.id,  d.id[k] == g2.refs[b@location] ];
                 println("v1_<old.offset>[<i>] = v1_<ks[0].offset>");
               }
             }
          }
          case <value x, x>: ;
          case <value x, value y> : {
             println("v1_<old.offset>[<i>] = <y>");
          }
          
        }
     }
  }
  
  top-down visit (t1) {
    case node x: {
       if (x@location in d.id) {
         y = findNode(t2, d.id[x@location]);
         updateFields(x@location, getChildren(x), getChildren(y));
       } 
    }
  }
  
  void assignFields(loc new, list[value] newFields) {
    println("NEWFIELDS = <newFields>");
    for (i <- [0..size(newFields)]) {
      switch (newFields[i]) {
        case node b: {
           println("Node");
           if (b@location in g2.uses) {
               // it's a reference
               println("Found a reference: <b>");
               if (g2.refs[b@location] in d.added) {
                 // ref to a new thing
                 println("v2_<new.offset>[<i>] = v2_<g2.refs[b@location].offset>");
               }
               else {
                 // ref to an old thing
                 ks = [ k | k <- d.id,  d.id[k] == g2.refs[b@location] ];
                 println("v2_<new.offset>[<i>] = v1_<ks[0].offset>");
               }
             }
        }
      }
    }
  }
  
  top-down visit (t2) {
    case node x: {
       if (isDef(x, g2) /*x@location in d.added*/) {
          println("Assigning fields.");
          assignFields(x@location, getChildren(x));
       }
    }
  }
  
  for (x <- d.deleted) {
    println("delete v1_<x.offset>");
  }
  

}
