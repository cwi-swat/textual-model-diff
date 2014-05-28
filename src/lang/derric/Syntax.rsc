@license{
   Copyright 2011-2012 Netherlands Forensic Institute and
                       Centrum Wiskunde & Informatica

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
}

module lang::derric::Syntax

start syntax FileFormat 
  = @Foldable format: "format" Id name 
      "extension" Id+ extensions 
      Qualifier* defaults
      "sequence" DSymbol* sequence 
      "structures" Term* terms;

syntax DSymbol 
  = anyOf: "(" DSymbol+ ")"
  | seq: "[" DSymbol* "]"
  | right not: "!" DSymbol
  > iter: DSymbol "*"
  | optional: DSymbol "?"
  | term: Id
  ;

syntax Qualifier 
  = unit: "unit" Id name
  | sign: "sign" Bool present
  | endian: "endian" Id name
  | strings: "strings" Id encoding
  | \type: "type" Id type
  | size: "size" Expression count
  ;

syntax Term
   = @Foldable term1: Id name "{" Field* fields "}"
   | @Foldable term2: Id name "=" Id super "{" Field* fields "}"
   ;
   
syntax Field 
  = field5: Id name ":" FieldModifier* modifiers ";"
  | field6: Id name ";"
  | field4: Id name ":" "{" Field* fields "}"
  ;

syntax FieldModifier
  = modifier: Modifier
  // follow-rest. needed for things like size length-x, 
  // which can be size(length) -x, size(lenght - x)
  | qualifier: Qualifier !>> [\-] 
  | content: ContentSpecifier
  | expressions: {Expression ","}+  
  ;

syntax ContentSpecifier 
  = specifier: ContentSpecifierId name "(" { ContentModifier "," }* ")"
  ;

syntax ContentModifier 
  = contentModifier: Id "=" { Specification "+" }+
  ;

syntax Specification 
  = string: String // normalize to const(int/str)
  | number: Number
  | field7: Id name
  | field8: Id struct "." Id name
  ;

syntax Modifier 
  //= required:  /* required */ 
  = expected: "expected"
  // TODO: normalize to terminator 
  | terminatedBefore: "terminatedBefore" 
  | terminatedBy: "terminatedBy";


lexical Bool
  = "true"
  | "false"
  ;

//syntax Qualifiers = @Foldable Qualifier*;
//syntax Structures = @Foldable "structures" Structure*;
//syntax Sequence = @Foldable "sequence" DSymbol*;



syntax ContentSpecifierId = @category="Todo" Id;
syntax ExpressionId = @category="Identifier" Id id;
lexical Number = @category="Constant" hex: ([0][xX][a-f A-F 0-9]+) !>> [a-f A-F 0-9]
              |  @category="Constant" bin: ([0][bB][0-1]+) !>> [0-1]
              |  @category="Constant" oct: ([0][oO][0-7]+) !>> [0-7]
              |  @category="Constant" dec: [0-9]+ !>> [0-9xXbBoO];
lexical String = @category="Constant" "\"" ![\"]*  "\"";
lexical Comment = @category="Comment" "/*" CommentChar* "*/";
lexical CommentChar = ![*] | [*] !>> [/];




syntax Expression = number: Number
                  | string: String
                  | ref1: ExpressionId
                  | ref2: ExpressionId "." ExpressionId
                  | bracket "(" Expression ")"
                  | offset1: "offset" "(" ExpressionId ")"
                  | offset2: "offset" "(" ExpressionId "." ExpressionId ")"
                  | lengthOf1: "lengthOf" "(" ExpressionId ")"
                  | lengthOf2: "lengthOf" "(" ExpressionId "." ExpressionId ")"
                  | negate: "-" Expression
                  | not: "!" Expression 
                  > left pow: Expression "^" Expression
                  > left ( times: Expression "*" Expression
                         | divide: Expression "/" Expression)
                  > left ( add: Expression "+" Expression
                         | minus: Expression "-" Expression)
                  > non-assoc range: Expression ".." Expression
                  > left or: Expression "|" Expression;

layout LAYOUTLIST = LAYOUT* !>> [\t-\n \r \ ];
lexical LAYOUT = whitespace: [\t-\n \r \ ] | Comment;

keyword DerricKeywords =
   "format"
 | "extension"
 | "sequence"
 | "structures"
 | "unit" | "sign" | "endian" | "strings" | "type"
 | "true" | "false" // | "integer" | "float" | "string"
 | "size"
 | "expected" | "terminatedBefore" | "terminatedBy"
 | "lengthOf" | "offset";

lexical Id = id: ([a-z A-Z _] !<< [a-z A-Z _][a-z A-Z 0-9 _]* !>> [a-z A-Z 0-9 _]) \ DerricKeywords;
