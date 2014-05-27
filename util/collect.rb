
require 'pp'


def collect(path, out)
  log = `git log --oneline #{path}`
  commits = log.split(/\n/).reverse
  rev = nil
  msg = nil

  diffs = {}
  sources = {}
  msgs = {}
  
  0.upto(commits.length) do |i|
    cur = commits[i]
    ind = sprintf("%02d", i)

    next if !cur
    if cur =~ /^([a-z0-9]*) (.*)$/ then
      msg = $2

      
      
      if !rev.nil? then
        new = $1
        #puts "MSG -------------> #{msg}"
        diff = `git diff -U0 #{rev} #{new} #{path}`
        file = "#{out}/#{ind}_#{rev}-#{new}_#{File.basename(path)}.diff"
        diffs[[rev,new]] = diff;
        msgs[[rev,new]] = msg;
        rev = new
      else
        rev = $1
      end
      
      contents = `git show #{rev}:#{path}`
      file = "#{out}/#{File.basename(path)}.#{rev}"
      sources[rev] = contents
      #puts file
      
      File.open(file, "w") do |f|
         f.write(contents)
      end
    else
      raise "Error: no match: #{cur}"
    end
  end
  pp msgs
  return diffs, sources, msgs
 end

if __FILE__ == $0 then
  require 'pp'
  srcs = ["gif/gif.derric", "png/png.derric", "jpeg/jpeg.derric"]
  tbl = {}
  lst = []
  srclst = []
  difflst = []
  srcs.each do |src|
    diffs, sources, msgs = collect(src, ".")
    msgs.each_key do |f, t|
      lst << [src.inspect, f.inspect, t.inspect, msgs[[f,t]].inspect]
    end
    diffs.each_key do |f, t|
      difflst << [src.inspect, f.inspect, t.inspect, diffs[[f,t]].inspect]
    end
    sources.each_key do |rev|
      srclst << [src.inspect, rev.inspect, sources[rev].inspect]
    end
  end
  lst.map! { |x| "<#{x[0]}, #{x[1]}, #{x[2]}, #{x[3]}>" }
  puts "{#{lst.join(",\n")}}"
  puts
  
  srclst.map! { |x| "<#{x[0]}, #{x[1]}, #{x[2]}>" }
  puts "{#{srclst.join(",\n")}}"
  puts


  difflst.map! { |x| "<#{x[0]}, #{x[1]}, #{x[2]}, #{x[3]}>" }
  puts "{#{difflst.join(",\n")}}"

  File.open('derric.msgs', 'w') do |f|
    f.write("[#{lst.join(",\n")}]")
  end

  File.open('derric.sources', 'w') do |f|
    f.write("[#{srclst.join(",\n")}]")
  end

  File.open('derric.diffs', 'w') do |f|
    f.write("[#{difflst.join(",\n")}]")
  end
  
end
