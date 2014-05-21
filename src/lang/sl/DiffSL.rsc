module lang::sl::DiffSL

import lang::sl::AST;
import lang::sl::Syntax;
import lang::sl::IDE;
import lang::sl::NameAnalyzer;
import util::Mapping;
import util::Diff;
import util::NameGraph;

import IO;
import ParseTree;

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
}

//ops = theDiff({}, ts1, <{}, {}, {}>, r1, <r1.defs, {}, ()>, meta, ia); 
  

tuple[list[Edit], map[loc,loc]] createSL(Machine ast) {
  r = getNameGraph(setScope(ast)); 
  ts = slIdClassMap(ast, r);
  ia = <isKey, isRef, getId>;
  meta = astModelMap(#lang::sl::AST::Machine, "lang.sl.runtime");
  ops = theDiff({}, ts, <{}, {}, {}>, r, <r.defs, {}, ()>, meta, ia);
  return <ops, ()>;
}

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
  
  matching = identifyEntities(ast1, ast2, ts1, ts2, r1, r2, ia);
  iprintln(matching);

  meta = astModelMap(#lang::sl::AST::Machine, "lang.sl.runtime");
  
  ops = theDiff(ts1, ts2, r1, r2, matching, meta, ia);

  return ops;
  
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


