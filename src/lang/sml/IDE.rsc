module lang::sml::IDE

import lang::sml::Syntax;
import lang::sml::AST;
import lang::sml::DiffSL;
import util::Diff;

import ParseTree;
import util::IDE;
import vis::Figure;
import IO;
import ValueIO;
import Message;

import util::RuntimeDiff;


public str SL_NAME = "State Language"; //language name
public str SL_EXT  = "sml"; //file extension

private bool firstRun = true;

public void sml_register()
{
  system = requestSystem();
  runInterpreter(system, "lang.sml.runtime.Main");
  Contribution sml_style =
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

  set[Contribution] sml_contributions =
  {
    sml_style,
    annotator(Tree (Tree input) {
        return input;
    }),
    builder(set[Message] ((&T<:Tree) tree) {
      println("Saving!");
      loc curLoc = tree@\loc;
      loc prevLoc = |<curLoc.scheme>://<curLoc.authority>/<curLoc.path>|[extension="prev.sml"];
      
      //println("current location = <curLoc>");
      //println("previous location = <prevLoc>");
            
      if (exists(prevLoc) && firstRun == false) {
        println("We have previous version.");
        //prevAst = readTextValueFile(#lang::sml::AST::Machine, prevLoc);
        <delta, flatDelta, mapping> = diffSL(prevLoc, curLoc);
        str prettyDelta = delta2str(delta);
        //println("Mapping\n----------\n");
        mapping = fix(mapping);
        //iprintln(mapping);        
        flatDelta += [rekey(key,mapping[key]) | key <- mapping, key != mapping[key]];
        //println("----------\n");              
        println("Edit script\n----------\n<prettyDelta>----------");
        iprintln(delta);
        println("Sending delta");     
        iprintln(flatDelta);
        sendDelta(system, flatDelta);
      }
      else {
        firstRun = false;
        println("Initial run; creating.");
        <delta, flatDelta, mapping> = createSL(tree);        
        str prettyDelta = delta2str(delta);
        //println("Mapping\n----------\n");
        //iprintln(mapping);
        flatDelta += [rekey(key,mapping[key]) | key <- mapping, key != mapping[key]];
        //println("----------\n");
        println("Edit script\n----------\n<prettyDelta>----------");
        iprintln(delta);
        println("Sending delta");     
        iprintln(flatDelta);       
        sendDelta(system, flatDelta);
      }
      

      str contents = unparse(tree);
      writeFile(prevLoc, contents);
      println("End of save.");
      return {};
    })
  };

  registerLanguage(SL_NAME, SL_EXT, lang::sml::Syntax::sml_parse);
  registerContributions(SL_NAME, sml_contributions);
}

public lang::sml::AST::Machine sml_implode(Tree t) 
  = implode(#lang::sml::AST::Machine, t);
  
