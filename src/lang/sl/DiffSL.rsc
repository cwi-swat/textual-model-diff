module lang::sl::DiffSL

import lang::sl::AST;
import lang::sl::Syntax;
import lang::sl::IDE;
import lang::sl::NameAnalyzer;
import util::Mapping;
import util::Diff;
import util::NameGraph;
import util::GitDiff;

import String;
import Node;
import IO;
import ParseTree;

/*
list[Edit] treeDiffSL(loc v1, loc v2) {
  str src1 = readFile(v1);
  str src2 = readFile(v2);
  Tree pt1 = sl_parse(v1);
  Tree pt2 = sl_parse(v2);
  Machine ast1 = sl_implode(pt1);
  Machine ast2 = sl_implode(pt2);
  r1 = <{}, {}, {}>;
  r2 = <{}, {}, {}>;
  ts1 = slIdClassMap(ast1, r1);
  ts2 = slIdClassMap(ast2, r2);
  
  ia = <isKey, isRef, getId>;
  
  matching = <{}, {}, ()>;

  meta = astModelMap(#lang::sl::AST::Machine, "lang.sl.runtime");
  
  ops = diffNodes(ast1@location, ast2@location, [], ast1, ast2, r1, r2, matching, meta, ia);
  iprintln(ops);
  return ops;
}
*/

/*
tuple[list[Edit], map[loc,loc]] diffSL(Machine ast1, Machine ast2) {
  r1 = getNameGraph(setScope(ast1)); 
  r2 = getNameGraph(setScope(ast2));


  ts1 = slIdClassMap(ast1, r1);
  ts2 = slIdClassMap(ast2, r2);
  
  ia = <isKey, isRef, getId>;
  
  matching = identifyEntities(ast1, ast2, ts1, ts2, r1, r2, ia);
  iprintln(matching);

  meta = astModelMap(#lang::sl::AST::Machine, "lang.sl.runtime");
  
  ops = theDiff(ts1, ts2, r1, r2, matching, meta, ia);
  iprintln(ops);
  return <ops, matching.id>;
}*/

//ops = theDiff({}, ts1, <{}, {}, {}>, r1, <r1.defs, {}, ()>, meta, ia); 
  
tuple[list[Edit], list[Edit], map[loc,loc]] createSL(Tree tree){

  Machine ast = sl_implode(tree);
  r = getNameGraph(setScope(ast)); 
  ts = slIdClassMap(ast, r);
  ia = <isKey, isRef, getId>;
  meta = astModelMap(#lang::sl::AST::Machine, "lang.sl.runtime");
  mapping = <r.defs, {}, ()>;
  ops = theDiff({}, ts, <{}, {}, {}>, r, mapping, meta, ia);
  flatOps = flatten(ops,meta); 
  
  return <ops, flatOps, ()>;
}

/*
Delta testSL(loc v1, loc v2) {
  str src1 = readFile(v1);
  str src2 = readFile(v2);
  Tree pt1 = sl_parse(v1);
  Tree pt2 = sl_parse(v2);
  Machine ast1 = sl_implode(pt1);
  Machine ast2 = sl_implode(pt2);
  
  r1 = getNameGraph(setScope(ast1)); 
  r2 = getNameGraph(setScope(ast2));


  ts1 = slIdClassMap(ast1, r1);
  ts2 = slIdClassMap(ast2, r2);
  
  ia = <isKey, isRef, getId>;
  
  println("g1 = ");
  iprintln(r1);
  println("g2 = ");
  iprintln(r2);
  
  matching = identifyEntities(ast1, ast2, ts1, ts2, r1, r2, ia);
  iprintln(matching);

  meta = astModelMap(#lang::sl::AST::Machine, "lang.sl.runtime");
  println("META!!!!!");
  iprintln(meta);
  
  ops = theDiff(ts1, ts2, r1, r2, matching, meta, ia);

  return ops;
  
}
*/


tuple[list[Edit], list[Edit], map[loc,loc]] diffSL(loc old, loc new) {  

  meta = astModelMap(#lang::sl::AST::Machine, "lang.sl.runtime");
  println("META!!!!!");
  iprintln(meta);
  
//  str src1 = readFile(old);
//  str src2 = readFile(new);
  
  Tree pt1 = sl_parse(old);
  Tree pt2 = sl_parse(new);
  
  Machine ast1 = sl_implode(pt1);
  Machine ast2 = sl_implode(pt2);
  
  g1 = getNameGraph(setScope(ast1)); 
  g2 = getNameGraph(setScope(ast2));
  
  ts1 = slIdClassMap(ast1, g1);
  ts2 = slIdClassMap(ast2, g2);
  
  ia = <isKey, isRef, getId>;
  
  str textDiff = gitPatienceDiff(old.file, new.file);
  
  <delLines, addLines> = splitDiff(textDiff);
  
  println("Deleted: <delLines>");
  println("Added: <addLines>");
  tokens1 = projectEntities(ast1, ts1, g1, ia);
  tokens2 = projectEntities(ast2, ts2, g2, ia);
  
  i = 0;
  j = 0;
  IDMatching matching = <{}, {}, ()>;
  while (i < size(tokens1) || j < size(tokens2)) {
    if (i < size(tokens1), tokens1[i].location.begin.line in delLines) {
      matching.deleted += {tokens1[i].location};
      i += 1;
      continue;
    }
    if (j < size(tokens2), tokens2[j].location.begin.line in addLines) {
      matching.added += {tokens2[j].location};
      j += 1;
      continue;
    }
    assert tokens1[i].content == tokens2[j].content;
    if (tokens1[i].class == tokens2[j].class) {
      matching.id[tokens1[i].location] = tokens2[j].location;
    }
    else {
      matching.deleted = tokens1[i].location;
      matching.added = tokens2[j].location;
    }
    i += 1;
    j += 1;
  }
  assert i == size(tokens1);
  assert j == size(tokens2);


  ops = theDiff(ts1, ts2, g1, g2, matching, meta, ia);

  flatOps = flatten(ops, meta);

  return <ops, flatOps, matching.id>;
}




bool isRef(node k, NameGraph g) = Ref r := k && r@location in g.uses;
bool isKey(node k, NameGraph g) = Name n := k && n@location in g.defs;

loc getId(node k) {
  if (Ref r := k) return r@location;
  if (Name n := k) return n@location;
}

IDClassMap slIdClassMap(Machine m, NameGraph g) {
  return idClassMap(m, g, <isKey, isRef, getId>);
}

//Flatten delta's
public Delta flatten(Delta delta, ASTModelMap m)
  = fix(order([*flatten(op, m) | op <- delta]));
  
public Delta fix(Delta delta)
  = [fix(op) | op <- delta];  

public loc fix(loc l)
{
  loc n = l;
  if(l.file != "")
  {
    n.file = replaceAll(n.file, "prev.sl", "sl");
    println("fixing loc <l> = <n>");
  }
  return n;
}

public Edit fix(Edit edit)
{
  if(edit.object?){
    edit.object = fix(edit.object);
  }
  if(edit.ref?){
    edit.ref = fix(edit.ref);
  }
  return edit;
}
  
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