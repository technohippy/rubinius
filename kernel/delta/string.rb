class String
  BASE_64_A2B = {}
  (?A..?Z).each {|x| BASE_64_A2B[x] = x - ?A}
  (?a..?z).each {|x| BASE_64_A2B[x] = x - ?a + 26}
  (?0..?9).each {|x| BASE_64_A2B[x] = x - ?0 + 52}
  BASE_64_A2B[?+]  = ?>
  BASE_64_A2B[?\/] = ??
  BASE_64_A2B[?=]  = 0

  # TODO - Pass the starting line info into RubyParser
  # TODO: maybe move into lib/compiler and after_load
  def to_sexp(name="(eval)", line = 1, lit_rewriter=true)
    # TODO: for Ryan - fix the paths in compiler/ruby_parser and friends,
    # e.g. require 'sexp' should be require 'compiler/sexp'
    $: << "lib/compiler"
    require 'compiler/ruby_parser'
    require 'compiler/lit_rewriter'
    $:.pop

    sexp = RubyParser.new.process(self, name)
    sexp = Rubinius::LitRewriter.new.process(sexp) if lit_rewriter
    sexp
  end

end
