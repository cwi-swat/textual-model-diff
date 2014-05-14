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
  return <e<1>, e<0>, e>;
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
  =  { <x@location, decl> | /term(x:id(n)) := f.sequence,
         <n, loc decl, _, _> <- structs  };
  
  
rel[loc,loc] resolveFields(FileFormat frm, rel[str, loc, str, loc] structs) {
   rel[loc,loc] resolveField(str struct, Field f) 
     = { <x@location, decl> | /field(x:id(n)) := f, 
            <struct, _, n , loc decl> <- structs }
     + { <x@location, decl> | /field(q:id(n1), x:id(n2)) := f, 
            <n1, _, n2, loc decl> <- structs }
     + { <q@location, decl> | /field(q:id(n1), x:id(n2)) := f, 
            <n1, loc decl, _, _> <- structs }
            
     // unfortunate duplication...
     + { <x@location, decl> | /ref(x:id(n)) := f, 
            <struct, _, n, loc decl> <- structs }
     + { <x@location, decl> | /ref(q:id(n1), x:id(n2)) := f, 
            <n1, _, n2, loc decl> <- structs }
     + { <q@location, decl> | /ref(q:id(n1), x:id(n2)) := f, 
            <n1, loc decl, _, _> <- structs };

   return ( {}| it + resolveField(t.name.name, f) | Term t <- frm.terms, Field f <- t.fields);
} 
  