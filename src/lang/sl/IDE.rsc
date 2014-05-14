module lang::sl::IDE

import lang::sl::Syntax;
import lang::sl::AST;
import lang::sl::NameAnalyzer;
import lang::sl::NameMapper;

import ParseTree;
import util::IDE;
import vis::Figure;
import IO;
import Message;

public str SL_NAME = "State Language"; //language name
public str SL_EXT  = "sl"; //file extension

public void sl_register()
{
  Contribution sl_style =
    categories
    (
      (
        "Name" : {foregroundColor(color("royalblue"))},
        "TypeName" : {foregroundColor(color("darkblue")),bold()},
        "Comment": {foregroundColor(color("dimgray"))},
        "Value": {foregroundColor(color("firebrick"))},
        "String": {foregroundColor(color("teal"))}
        //,"MetaKeyword": {foregroundColor(color("blueviolet")), bold()}
      )
    );

  set[Contribution] sl_contributions =
  {
    sl_style
  };

  registerLanguage(SL_NAME, SL_EXT, lang::sl::Syntax::sl_parse);
  registerContributions(SL_NAME, sl_contributions);
}

public lang::sl::AST::Machine sl_implode(Tree t) 
  = implode(#lang::sl::AST::Machine, t);

//--------------------------------------------------------------------------------
//for quick testing purposes
//--------------------------------------------------------------------------------
public void probeer()
{
  loc f1 = |project://textual-model-diff/test/test1.sl|;  
  loc f2 = |project://textual-model-diff/test/test2.sl|;

  Tree t1 = sl_parse(f1);
  Tree t2 = sl_parse(f2);
  
  Machine m1 = sl_implode(t1);
  Machine m2 = sl_implode(t2);
  
  Machine um1 = unordered(m1);
  Machine um2 = unordered(m2);
  
  Delta delta1 = init(um1);
  Delta delta2 = init(um2);
  
  PolanenModel pm1 = eval(NewPolanenModel,delta1);
  PolanenModel pm2 = eval(NewPolanenModel,delta2);
  
  rel[loc,loc] r = getMap(um1,um2); 

  iprintln(r);
  //iprintln(pm2);
  //iprintln(m);
  
  //Machine m2 = setScope(m);
 
  //Scope scope = scope(m2); 
  //iprintln(scope);  
  //iprintln(m2);
  
  //Machine m1b = unordered(m1);
  //Machine m2b = unordered(m2);
  
  //NameGraph ng = getNameGraph(m2);
  
  //treeDiff(m1b, m2b);
}