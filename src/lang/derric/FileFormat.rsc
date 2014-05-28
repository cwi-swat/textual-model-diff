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

module lang::derric::FileFormat

import List;

data FileFormat 
  = format(Id name, list[str] extensions, 
       list[Qualifier] defaults, 
       list[DSymbol] sequence, 
       list[Term] terms);

data DSymbol 
  = term0(Id name)
  | optional(DSymbol symbol)
  | iter(DSymbol symbol)
  | not(DSymbol symbol)
  | anyOf(list[DSymbol] symbols)
  | seq(list[DSymbol] sequence)
  ;

data Qualifier 
  = unit(Id name)
  | sign(bool present)
  | endian(Id name)
  | strings(Id encoding)
  | \type(Id \type)
  | size(Expression count)
  ;

data Term 
  = term1(Id name, list[Field] fields)
  | term2(Id name, Id source, list[Field] fields)
  ;

data Field 
  =  field1(Id name, list[Modifier] modifiers, list[Qualifier] qualifiers, list[Expression] specifications)
   | field2(Id name, list[Modifier] modifiers, list[Qualifier] qualifiers, Expression specification)
   | field3(Id name, list[Modifier] modifiers, list[Qualifier] qualifiers, ContentSpecifier specifier)
   | field4(Id name, list[Field] fields)
   // Normalize these to the above
   | field5(Id name, list[FieldModifier] fmodifiers)
   | field6(Id name)
   ;
   
data FieldModifier
  = modifier(Modifier modifier)
  | qualifier(Qualifier qualifier)
  | content(ContentSpecifier specifier)
  | expressions(list[Expression] expressions)
  ;

data ContentSpecifier 
= specifier(Id name, list[ContentModifier] arguments);

data ContentModifier
  = contentModifier(str name, list[Specification] specs);

data Specification = const(str s)
	| const(int i)
    | field7(Id name)
    | field8(Id struct, Id name)
    | string(str s)
    | number(str n)
    ;

data Modifier 
    = required()
	| expected()
	| terminator(bool includeTerminator)
	| terminatedBefore()
	| terminatedBy()
	;

data Expression 
    = ref1(Id name)
    | ref2(Id struct, Id name)
	| not(Expression exp)
	| pow(Expression base, Expression exp)
	| minus(Expression lhs, Expression rhs)
	| times(Expression lhs, Expression rhs)
	| add(Expression lhs, Expression rhs)
	| divide(Expression lhs, Expression rhs)
	| \value1(int i)
	| \value2(str s)
	| lengthOf1(Id name)
	| lengthOf2(Id struct, Id name)
	| offset1(Id name)
	| offset2(Id struct, Id name)
	| or(Expression lhs, Expression rhs)
	| range(Expression from, Expression to)
	| negate(Expression exp)
	| noValue()
	| string(str s)
	| number(str n)
	;
	
data Id
  = id(str name);
	
anno loc FileFormat@location;
anno loc DSymbol@location;
anno loc Qualifier@location;
anno loc Term@location;
anno loc Field@location;
anno loc ContentSpecifier@location;
anno loc Specification@location;
anno loc Modifier@location;
anno loc Expression@location;
anno loc Id@location;
	