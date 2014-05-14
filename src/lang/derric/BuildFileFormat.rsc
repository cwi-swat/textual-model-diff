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

module lang::derric::BuildFileFormat

import lang::derric::FileFormat;
import lang::derric::Syntax;
import ParseTree;


Tree parseDerric(loc l) 
  = parse(#start[FileFormat], l);

lang::derric::FileFormat::FileFormat load(str src, loc l) 
  = build(parse(#start[FileFormat], src, l).top);

lang::derric::FileFormat::FileFormat load(loc l) 
  = build(parse(#start[FileFormat], l).top);

lang::derric::FileFormat::FileFormat build(Tree pt)
  = implode(#lang::derric::FileFormat::FileFormat, pt);
