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
  
  // TODO: the case that either pr1 or pr2 doesn't have any "Xs"
  // --> make domains of pr1 and pr2 uniform.
  iddiff = ( <{}, {}, ()> | merge(it, match(pr1[k], pr2[k])) | k <- pr1, k in pr2 ); 
  iprintln(iddiff);

  meta = astModelMap(#lang::sl::AST::Machine);
  Delta delta = doIt(ts1, ts2, r1, r2, iddiff, meta);

  iprintln(delta);
}

bool isId(node k) = name(_) := k;
loc getId(node k) = n@location when Name n := k;


IDClassMap slIdClassMap(Machine m) {
  return idClassMap(m, isId, getId);
}


