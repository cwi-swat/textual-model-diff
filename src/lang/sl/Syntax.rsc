module lang::sl::Syntax

/*
  We use AST name paths to adapt a Polanen run-time model.
    
  The grammar defines a partial meta-model yielding Polanen types
  with features that have a defined multiplicity (through the Kleene star)
  and ordering (which is explicitly marked).
  Additionally, we derive the inverse of each feature automatically.
  
  An AST can be flattened into a Polanen model,
  and the AST can be reconstructed from this model,
  such that the run-time model can be serialized.
*/

start syntax Machine
  = mach: "machine" TID id State * /*unordered*/ states "end"
  | ;
  
syntax State
  = state: "state" TID id Trans* /*ordered*/ transitions 
  | group: TID id "{" State* /*unordered*/ states "}";
  
syntax Trans
  = trans: NAME event "=\>" Ref ref
  ;
 
syntax Ref 
  = simple: NID
  | qualified: NID "." Ref;

syntax String
  = @category="String"  "\"" STRING "\"";

syntax TID
  = @category="TypeName" ID;

syntax NID
  = @category="Name" ID;
    
syntax ID
  = name: NAME;

lexical NAME
  = ([a-zA-Z_$] [a-zA-Z0-9_$]* !>> [a-zA-Z0-9_$]) \ Keyword;
  
lexical STRING
  = ![\"]*;
  
layout LAYOUTLIST
  = LAYOUT* !>> [\t-\n \r \ ] !>> "//" !>> "/*";

lexical LAYOUT
  = Comment
  | [\t-\n \r \ ];
  
lexical Comment
  = @category="Comment" "/*" (![*] | [*] !>> [/])* "*/" 
  | @category="Comment" "//" ![\n]* [\n];

keyword Keyword
  = "machine" | "state";
  
public start[Machine] sl_parse(str src, loc file) = 
  parse(#start[Machine], src, file);
  
public start[Machine] sl_parse(loc file) = 
  parse(#start[Machine], file);

