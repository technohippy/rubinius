#!/usr/bin/env ruby
#
# A tiny spec-style runner for working on a parser.

def to_sexp_pt_r(source)
  source.to_sexp_pt '(string)', 1, false, false
end

def to_sexp_pt_u(source)
  source.to_sexp_pt '(string)', 1, false, true
end

def to_sexp_rp(source)
  RubyParser.new.process source, '(string)'
end

def to_sexp_x(cmd, str, source)
  name = "__parser_spec_source__.rb"
  File.open(name, "w") do |f|
    f.puts str % source
  end
  eval `cat #{name} | #{cmd}`
ensure
  File.delete name rescue nil
end

# Runs the example after fetching the sexp from +sexp+
# method. Compares the sexp to +standard+ from +hash+.
def run(node, hash, standard, sexp, cmd, str)
  src = hash['Ruby']
  expected = hash[standard].to_a

  if cmd
    actual = send sexp, cmd, str, src
  else
    actual = send sexp, src
  end
  actual = actual.to_a unless actual.instance_of? Array

  if actual != expected
    return false, "#{node}\n\n#{src}\n\nexpected\n  #{actual.inspect}\n" \
                  "to equal\n  #{expected.inspect}\n\n"
  else
    return true, nil
  end
end

def usage
  puts "usage: run [options] (FILE|DIRECTORY|GLOB)+"
  puts ""
  puts "-r      Compare to raw ParseTree"
  puts "-p      Compare to ParseTree (default)"
  puts "-R      Get sexp from RubyParser"
  puts "-P      Get sexp from MRI parser + ParseTree builtin to rbx (default)"
  puts "-X CMD  Get sexp from invoking CMD (see -s)"
  puts "-s STR  Substitute into STR at %s"
  puts "-h      Show this message"
  puts ""
  exit 1
end

# command line processing
standard = nil
sexp = nil
command = nil
str = nil

files = []
while x = ARGV.shift
  if File.file? x
    files << x
  elsif File.directory? x
    files.concat Dir["#{x}/**/*_spec.rb"]
  elsif x == "-r"
    standard = 'RawParseTree'
    sexp = :to_sexp_pt_r unless sexp
  elsif x == "-p"
    standard = 'ParseTree'
    sexp = :to_sexp_pt_u unless sexp
  elsif x == "-R"
    sexp = :to_sexp_rp
  elsif x == "-P"
    if standard == 'RawParseTree'
      sexp = :to_sexp_pt_r
    else
      sexp = :to_sexp_pt_u
    end
  elsif x == "-X"
    command = ARGV.shift
    sexp = :to_sexp_x
  elsif x == "-s"
    str = ARGV.shift
  elsif x == "-h"
    usage
  end
end

# defaults
standard = 'ParseTree' unless standard
sexp = :to_sexp_pt_u unless sexp
str = %Q{%s} unless str

if files.empty?
  puts "No files given"
  usage
end

report = []
total = failures = errors = 0

start = Time.now
files.each do |name|
  total += 1
  load name
  begin
    node = File.basename(name, "_spec.rb").split("/").last
    status, output = run(node, test_case, standard, sexp, command, str)
    if status
      print "."
    else
      print "F"
      failures += 1
      report << output
    end
  rescue Object => e
    print "E"
    errors += 1
    report << "#{name}\n#{e.inspect}\n#{e.backtrace.join("\n")}"
  end
end
finish = Time.now

unless report.empty?
  puts "\n"
  report.each_with_index do |e, i|
    puts "\n#{i+1})\n"
    puts e
  end
end

puts "\nFinished in #{finish-start} seconds"
puts "\n#{total} examples, #{failures} failures, #{errors} errors"
