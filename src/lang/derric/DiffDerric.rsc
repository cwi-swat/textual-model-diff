module lang::derric::DiffDerric

import util::Diff;
import util::Mapping;
import util::NameGraph;
import lang::derric::NameRel;
import lang::derric::BuildFileFormat;
import lang::derric::FileFormat;

import ValueIO;
import IO;
import String;
import List;


lrel[str,str,str, int, int] textStats() {
  msgs = readTextValueFile(#rel[str,str,str,str], |project://textual-model-diff/resources/derric.msgs|);
  diffs = readTextValueFile(#rel[str,str,str,str], |project://textual-model-diff/resources/derric.diffs|);
  srcs = readTextValueFile(#rel[str,str,str], |project://textual-model-diff/resources/derric.sources|);
  r = {};
  for (<path, from, to, diff> <- diffs) {
     <a, d> = countAddDel(diff);
     r += [<path, from, to, a, d>];
  }
  return r;
}



lrel[str path,str from,str to, int linesAdded, int linesRemoved, int create, int remove, int \set, int \insert, str msg] tmdiffStats() {
  diffs = readTextValueFile(#lrel[str,str,str,str,str, Delta], |project://textual-model-diff/resources/derric.tmdiffs|);
  iprintln(diffs);
  result = [];
  for (<path, from, to, msg, td, diff> <- diffs) {
     c = [ x | /node x := diff, x is create ];
     r = [ x | /node x := diff, x is remove ];
     s = [ x | /node x := diff, x is \set ];
     i = [ x | /node x := diff, x is \insert ];
     <a, d> = countAddDel(td);
     println("MSG = <msg>");
     println(delta2str(diff));
     result += [<path, from, to, a, d, size(c), size(r), size(s), size(i), msg>];
  }
  return result;
}


lrel[str,str,str,str,str,Delta] caseStudy() {
  msgs = readTextValueFile(#lrel[str,str,str,str], |project://textual-model-diff/resources/derric.msgs|);
  diffs = readTextValueFile(#lrel[str,str,str,str], |project://textual-model-diff/resources/derric.diffs|);
  srcs = readTextValueFile(#lrel[str,str,str], |project://textual-model-diff/resources/derric.sources|);
  
  meta = astModelMap(#lang::derric::FileFormat::FileFormat, "");
  
  tmDiffs = [];
  for (<path, from, to, textDiff> <- diffs, <path, from, v1> <- srcs, <path, to, v2> <- srcs) {
    println("Diffing <path> v1 = <from>, v2 = <to>");
    ast1 = load(v1, |project://textual-model-diff/resources/<path>.<from>|);
    ast2 = load(v2, |project://textual-model-diff/resources/<path>.<to>|);
    g1 = resolveNames(ast1); 
    g2 = resolveNames(ast2);
    ts1 = derricIdClassMap(ast1, g1);
    ts2 = derricIdClassMap(ast2, g2);
    
    
    
    
    ia = <isKey, isRef, getId>;
  
    matching = identifyEntities(ast1, ast2, ts1, ts2, g1, g2, ia);
    theMsg = "";
    if (<path, from, to, msg> <- msgs) {
      theMsg = msg;
    }

    ops = theDiff(ts1, ts2, g1, g2, matching, meta, ia);
    tmDiffs += [<path, from, to, theMsg, textDiff, ops>];
  }
  
  writeTextValueFile(|project://textual-model-diff/resources/derric.tmdiffs|, tmDiffs);


  
  return tmDiffs;
}

tuple[int, int] countAddDel(str diff) {
 a = 0;
 d = 0; 
 for (l <- split("\n", diff)) {
   if (startsWith(l, "+")) {
     a += 1;
   }
   if (startsWith(l, "-")) {
     d += 1;
   }
   
 }
 return <a, d>;
}

bool isRef(node k, NameGraph g) =
  ref(_) := k || ref(_, _) := k 
     || (Specification x := k && x is field) 
     || term(_) := k
     || (Id x := k && x@location in g.uses); 

bool isKey(node k, NameGraph g) = 
  Id x := k && x@location in g.defs;


// hack
anno loc node@location;
loc getId(node k) {
  if (Id x := k) return x@location;
  if (x:ref(_) := k) return x@location;
  if (x:ref(_, _) := k) return x@location;
  if (x:field(_) := k) return x@location;
  if (x:field(_, _) := k) return x@location;
  if (x:DSymbol::term(_) := k) return x@location;
}

IDClassMap derricIdClassMap(FileFormat f, NameGraph g) {
  return idClassMap(f, g, <isKey, isRef, getId>);
}
