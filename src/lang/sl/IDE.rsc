module lang::sl::IDE

import lang::sl::Syntax;
import lang::sl::AST;
import lang::sl::NameAnalyzer;
import lang::sl::DiffSL;
import util::Diff;

import ParseTree;
import util::IDE;
import vis::Figure;
import IO;
import ValueIO;
import Message;

import util::RuntimeDiff;

public str SL_NAME = "State Language"; //language name
public str SL_EXT  = "sl"; //file extension

private bool firstRun = true;

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
      println("Saving!");
      loc curLoc = tree @\loc;
      loc prevLoc = |<curLoc.scheme>://<curLoc.authority>/<curLoc.path>|[extension="prev.sl"];
      
      //println("current location = <curLoc>");
      //println("previous location = <prevLoc>");
            
      if (exists(prevLoc) && firstRun == false) {
        println("We have previous version.");
        //prevAst = readTextValueFile(#lang::sl::AST::Machine, prevLoc);
        <delta, flatDelta, mapping> = diffSL(prevLoc, curLoc);
        str prettyDelta = delta2str(delta);
        println("Edit script\n----------\n<prettyDelta>----------");
        iprintln(delta);
        println("Sending delta");     
        iprintln(flatDelta);
        sendDelta(system, flatDelta, mapping);
      }
      else {
        firstRun = false;
        println("Initial run; creating.");
        <delta, flatDelta, mapping> = createSL(tree);        
        str prettyDelta = delta2str(delta);
        println("Edit script\n----------\n<prettyDelta>----------");
        iprintln(delta);
        println("Sending delta");     
        iprintln(flatDelta);       
        sendDelta(system, flatDelta, mapping);
      }
      

      str contents = unparse(tree);
      writeFile(prevLoc, contents);
      println("End of save.");
      return {};
    })
  };

  registerLanguage(SL_NAME, SL_EXT, lang::sl::Syntax::sl_parse);
  registerContributions(SL_NAME, sl_contributions);
}

public lang::sl::AST::Machine sl_implode(Tree t) 
  = implode(#lang::sl::AST::Machine, t);
  
