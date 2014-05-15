module lang::Polanen::Syntax

//Concrete Syntax of Delta Operations
//Note, currently not fully up-to-date

syntax Transformation
  = delta: "[" {Operation ","}* "]"
  ;

syntax Operation
  = op_rename: "rename" "(" UID "," UID ")"
  | op_new: "new" "(" UID "," TID ")"
  | op_del: "del" "(" UID "," TID ")"
  | op_set: "set" "(" UID "," NID "," VALUE "," UID ")"
  | op_insert: "insert" "(" UID "," NID "," UID ")"
  | op_remove: "remove" "(" UID "," NID "," UID ")"
  | op_insertAt: "insertAt" "(" UID "," NID "," UID "," VALUE ")"
  | op_removeAt: "removeAt" "(" UID "," NID "," UID "," VALUE ")"
  ;

syntax String
  = @category="String"  "\"" STRING "\"";
    
syntax NID
  = @category="Name" ID;
  
syntax TID
  = @category="TypeName" ID; 
  
syntax UID
  = @category="UniversalID" VALUE;
    
syntax ID
  = id: NAME;

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
  = "new" | "del" | "set" | "insert" | "remove" | "insertAt" | "removeAt";
