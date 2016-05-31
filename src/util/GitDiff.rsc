module util::GitDiff

import IO;
import util::ShellExec;
import String;

//loc INPUT = |project://textual-model-diff/input|;
loc INPUT = |file:///Users/rozen/proj/textual-model-diff/input/|;

//Added by rozen (why was this code missing?)
str gitPatienceDiff(str old, str new)
{
  str old_prefix = substring(old,0,findLast(old,"."));
  str new_prefix = substring(new,0,findLast(new,"."));
  str out = replaceAll(old_prefix+"_"+new_prefix,".","_")+".diff";
  
  //git diff --no-index --patience --ignore-space-change --ignore-blank-lines --ignore-space-at-eol -U0 <old> <new>
  PID id = createProcess("./mydiff.sh", [old, new, out], INPUT);
  str output = readEntireStream(id);
  print(output);
  killProcess(id);
  //read entire stream omitted linebreaks on my version.
  //workaround, first write it to a file and read that file.
 
  loc file = INPUT+out;
  println("Diff written to <file>. content:");
  str diff = readFile(file);
  println(diff);
  return diff;
}

