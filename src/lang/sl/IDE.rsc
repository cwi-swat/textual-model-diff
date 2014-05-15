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

import TheDiff;

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
  loc f1 = |project://textual-model-diff/input/test1.sl|;  
  loc f2 = |project://textual-model-diff/input/test1-v2.sl|;

  matchIt(f1, f2);
}