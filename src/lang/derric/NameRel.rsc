module lang::derric::NameRel

import lang::derric::FileFormat;
import String;
import util::NameGraph;

NameGraph resolveNames(FileFormat frm) {
  structs = collectStructs(frm);
  inh = inheritance(frm, structs);
  structs = enrichByInheritance(structs, inh);
  e = resolveInheritance(frm, structs)
    + resolveSequence(frm, structs)
    + resolveFields(frm, structs);
  return <{frm.name@location} + structs<1> + structs<3>, e<0>, e>;
}

map[loc, str] typeMap(FileFormat frm) {
  ts = ();
  visit (frm) {
    case FileFormat f: ts[f.name@location] = "Format"; 
    case Term t: ts[t.name@location] = "Struct"; 
    case Field f: ts[f.name@location] = "Field"; 
  }
  return ts;
}

rel[str, loc, str, loc] collectStructs(FileFormat frm)
  = { <t.name.name, t.name@location, f.name.name, f.name@location> | 
       /Term t := frm, /Field f := t };

rel[str, loc, str, loc] enrichByInheritance(rel[str, loc, str, loc] structs, rel[loc,loc] inh) {
  // a struct x that inherits from struct y
  added = { <x, xId, f, fId> | <x, xId, _, _> <- structs, super <- (inh+)[xId],
            <_, super, f, fId> <- structs };
  return structs + added;
}

rel[loc, loc] inheritance(FileFormat f, rel[str, loc, str, loc] structs)
  = { <sub, sup> | /term(id(x), id(y), _) := f,
       <x, sub, _, _> <- structs, <y, sup, _, _> <- structs };
       


rel[loc,loc] resolveInheritance(FileFormat f, rel[str, loc, str, loc] structs) 
  = { <super@location, decl> | /term(x, super:id(str n), _) := f,
       <n, loc decl, _, _> <- structs };

rel[loc,loc] resolveSequence(FileFormat f, rel[str, loc, str, loc] structs)
  =  { <t@location, decl> | /t:term(x:id(n)) := f.sequence,
         <n, loc decl, _, _> <- structs  };
  
  
rel[loc,loc] resolveFields(FileFormat frm, rel[str, loc, str, loc] structs) {
   rel[loc,loc] resolveField(str struct, Field f) 
     = { <fl@location, decl> | /fl:field(x:id(n)) := f, 
            <struct, _, n , loc decl> <- structs }
     + { <fl@location, decl> | /fl:field(q:id(n1), x:id(n2)) := f, 
            <n1, _, n2, loc decl> <- structs }
     + { <fl@location, decl> | /fl:field(q:id(n1), x:id(n2)) := f, 
            <n1, loc decl, _, _> <- structs }
            
     // unfortunate duplication...
     + { <r@location, decl> | /r:ref(x:id(n)) := f, 
            <struct, _, n, loc decl> <- structs }
     + { <r@location, decl> | /r:ref(q:id(n1), x:id(n2)) := f, 
            <n1, _, n2, loc decl> <- structs }
     + { <r@location, decl> | /r:ref(q:id(n1), x:id(n2)) := f, 
            <n1, loc decl, _, _> <- structs };

   return ( {}| it + resolveField(t.name.name, f) | Term t <- frm.terms, Field f <- t.fields);
} 
  