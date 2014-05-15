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
  /*Marking 'id' implies a Polanen type "Machine" is created.
    The Kleene star implies it has a "multi" feature
    to a Polanen element of type "State"
    which we named named "states" and defined as "unordered".
    As a convention we also generate "mach"
    as its inverse in the Polanen element of type "State"*/
  = mach: "machine" TID id State * /*unordered*/ states "end";
  
syntax State
  /*Marking 'id' implies a Polanen element of type "State" is created.
    The Kleene star implies it has a 'multi' feature,
    which we named "transitions" and defined as "ordered". */
  = state: "state" TID id Transition* /*ordered*/ transitions "end"
  /*Marking 'id' implies a Polanen element of type "State" is extended (...?...)
    The Kleene star implies it has a 'multi' feature
    which we named "states" and defined as "unordered".*/
  | group: TID id "{" State* /*unordered*/ states "}";
  
syntax Transition
  /*Marking 'id' implies a Polanen element of type "Transition" is created.
    The lack of a Kleene star after ref implies it might have a 'single' feature,
    but this is not the case because Ref has no 'id'.
    Therefore ref must be an attribute value (...?...)*/
  = trans: TID id "=\>" Ref ref
  | trans: TID id "=\>" Ref ref "when" Expr
  ;
 
syntax Ref /*No Polanen element is generated because it has no id, here we can use the AST value instead.*/
  = ref: NID
  | ref: NID "." Ref;

syntax String
  = @category="String"  "\"" STRING "\"";

syntax TID
  = @category="TypeName" ID;

syntax NID
  = @category="Name" ID;
    
syntax ID
  = name: NAME;

syntax Expr
  = lit: VALUE
  | var: Ref
  | left add: Expr "+" Expr
  > non-assoc gt: Expr "\>" Expr;



lexical VALUE
  = @category="Value" ([0-9]+([.][0-9]+?)?);  

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

