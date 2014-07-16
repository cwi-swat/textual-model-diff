module lang::sl::IDE

import lang::sl::Syntax;
import lang::sl::AST;
import lang::sl::NameAnalyzer;
import lang::sl::DiffSL;

import ParseTree;
import util::IDE;
import vis::Figure;
import IO;
import ValueIO;
import Message;

import util::RuntimeDiff;

public str SL_NAME = "State Language"; //language name
public str SL_EXT  = "sl"; //file extension

public void sl_register()
{
  system = requestSystem();
  runInterpreter(system, "lang.sl.runtime.Main");
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
    sl_style,
    annotator(Tree (Tree input) {
        return input;
    }),
    builder(set[Message] ((&T<:Tree) tree) {
      ast = sl_implode(tree);
      println("Saving!");
      prevLoc = tree@\loc[extension="prev"];
      if (exists(prevLoc)) {
        println("We have previous version.");
        prevAst = readTextValueFile(#lang::sl::AST::Machine, prevLoc);
        <delta, mapping> = diffSL(prevAst, ast);
        for (d <- delta) {
          println(d);
        }
        iprintln(mapping);
        println("Sending delta");
        sendDelta(system, delta, mapping);
      }
      else {
        println("Initial run; creating.");
        <delta, mapping> = createSL(ast);
        for (d <- delta) {
          println(d);
        }
        sendDelta(system, delta, mapping);
      }
      writeTextValueFile(prevLoc, ast);
      println("End of save.");
      return {};
    })
  };

  registerLanguage(SL_NAME, SL_EXT, lang::sl::Syntax::sl_parse);
  registerContributions(SL_NAME, sl_contributions);
}

public lang::sl::AST::Machine sl_implode(Tree t) 
  = implode(#lang::sl::AST::Machine, t);
