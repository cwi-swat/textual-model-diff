module lang::sl::DiffSL

import lang::sl::AST;
import lang::sl::Syntax;
import lang::sl::IDE;
import lang::sl::NameAnalyzer;
import util::Mapping;
import util::NameGraph;
import TheDiff;
import lang::Delta::AST;

import IO;
import ParseTree;

void testSL(loc v1, loc v2) {
  str src1 = readFile(v1);
  str src2 = readFile(v2);
  Tree pt1 = sl_parse(v1);
  Tree pt2 = sl_parse(v2);
  Machine ast1 = sl_implode(pt1);
  Machine ast2 = sl_implode(pt2);
  ts1 = slIdClassMap(ast1);
  ts2 = slIdClassMap(ast2);
  r1 = getNameGraph(setScope(ast1)); 
  r2 = getNameGraph(setScope(ast2));
  pr1 = projectEntities(ast1, ts1, isId, getId);
  pr2 = projectEntities(ast2, ts2, isId, getId);
  
  iddiff = ( <{}, {}, ()> | merge(it, match(r1, r2, ts1, ts2, pr1[k], pr2[k])) | k <- pr1, k in pr2 ); 
  iprintln(iddiff);

  ns1 = findNodes(ast1, r1, ts1);
  ns2 = findNodes(ast2, r2, ts2);
  Delta delta = doIt(ns1, ns2, r1, r2, iddiff);

  iprintln(delta);
}

bool isId(node k) = name(_) := k;
loc getId(node k) = n@location when Name n := k;


IDClassMap slIdClassMap(Machine m) {
  return idClassMap(m, isId, getId);
}


