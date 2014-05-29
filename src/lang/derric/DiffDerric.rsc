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


void showDiff(str file, str v1, str v2) {
 diffs = readTextValueFile(#lrel[str,str,str,str,str, Delta], |project://textual-model-diff/resources/derric.tmdiffs|);
 if (<file, v1, v2, str a, str b, d> <- diffs) {
   println("A =");
   println(a);
   println("B =");
   println(b);
   println(splitDiff(b));
   println(delta2str(d));
 }
}

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

alias Stats
  = lrel[str path,str from,str to, int linesAdded, int linesRemoved, int create, int delete, int insT, int insR, int remove, int setP, int setR, int setT, str msg];
  

void stats2latex(Stats s) {
  prev = "";
  for (<str path,str from,str to, int linesAdded, int linesRemoved, int create, int delete, int insT, int insR, int remove, int setP, int setR, int setT, str msg> <- s) {
    p = "\\textbf{<path[findFirst(path, "/") + 1..]>}";
    if (path == prev) {
      p = "";
    }
    prev = path;
    from = "\\github{<from>}"; 
    to = "\\github{<to>}"; 
    println("<p> & <from> & <to> & <linesAdded> & <linesRemoved> & <create> & <delete> & <insT> & <insR> & <remove> & <setP> & <setR> & <setT> & <msg[findFirst(msg, ":") + 1..]>\\\\");
  }
}

Stats tmdiffStats() {
  diffs = readTextValueFile(#lrel[str,str,str,str,str, Delta], |project://textual-model-diff/resources/derric.tmdiffs|);
  iprintln(diffs);
  result = [];
  for (<path, from, to, msg, td, diff> <- diffs) {
     c = [ x | /Edit x := diff, x is create ];
     d = [ x | /Edit x := diff, x is delete ];
     insT = [ x | /Edit x := diff, x is insertTree ];
     insR = [ x | /Edit x := diff, x is insertRef ];
     r = [ x | /Edit x := diff, x is remove ];
     setP = [ x | /Edit x := diff, x is setPrim ];
     setR = [ x | /Edit x := diff, x is setRef ];
     setT = [ x | /Edit x := diff, x is setTree ];
     
     <ad, de> = countAddDel(td);
     println("MSG = <msg>");
     println(delta2str(diff));
     result += [<path, from, to, ad, de, size(c), size(d), size(insT), size(insR), size(r), size(setP), size(setR), size(setT), msg>];
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
      matching.id[tokens1[i].location] = tokens2[j].location;
      i += 1;
      j += 1;
    }
    assert i == size(tokens1);
    assert j == size(tokens2);
    
    
    
    
    //matching = identifyEntities(ast1, ast2, ts1, ts2, g1, g2, ia);
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
  ref1(_) := k || ref2(_, _) := k 
  || lengthOf1(_) := k || lengthOf2(_, _) := k 
  || offset1(_) := k || offset2(_, _) := k 
  || (Specification x := k && x is field7) 
  || (Specification x := k && x is field8) 
  || term0(_) := k
  || (Id x := k && x@location in g.uses); 

bool isKey(node k, NameGraph g) = 
  Id x := k && x@location in g.defs;


// hack
anno loc node@location;
loc getId(node k) {
  if (Id x := k) return x@location;
  if (x:ref1(_) := k) return x@location;
  if (x:ref2(_, _) := k) return x@location;
  if (x:lengthOf1(_) := k) return x@location;
  if (x:lengthOf2(_, _) := k) return x@location;
  if (x:offset1(_) := k) return x@location;
  if (x:offset2(_, _) := k) return x@location;
  if (x:field7(_) := k) return x@location;
  if (x:field8(_, _) := k) return x@location;
  if (x:DSymbol::term0(_) := k) return x@location;
  throw "Missed: <k>";
}

IDClassMap derricIdClassMap(FileFormat f, NameGraph g) {
  return idClassMap(f, g, <isKey, isRef, getId>);
}
