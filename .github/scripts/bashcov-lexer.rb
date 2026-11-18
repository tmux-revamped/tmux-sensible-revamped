# frozen_string_literal: true

require "bashcov"
require "bashcov/lexer"

unbalanced_lead = /\G[^\n]+(?:[ \t=]|\\\n[ \t]*)+/.source
paired_leads = {
  "'" => /\G(?:[^\n']|'[^'\n]*')+(?:[ \t=]|\\\n[ \t]*)+/.source,
  '"' => /\G(?:[^\n"\\]|\\[^\n]|"(?:[^"\\\n]|\\[^\n])*")+(?:[ \t=]|\\\n[ \t]*)+/.source,
}
string_patterns = 4

shipped = Bashcov::Lexer::MULTILINE_PATTERNS
patterns = shipped.map do |regexp, forward|
  source = regexp.source
  rest = source.delete_prefix(unbalanced_lead)
  lead = paired_leads[rest[0]] if source.start_with?(unbalanced_lead)
  next [regexp, forward] unless lead

  [Regexp.new(lead + rest, regexp.options), forward]
end

rewritten = patterns.zip(shipped).count { |(new, _), (old, _)| !new.equal?(old) }
unless rewritten == string_patterns
  abort format("coverage: bashcov %<version>s has %<found>d multiline string patterns where %<expected>d " \
               "were expected, so .github/scripts/bashcov-lexer.rb no longer fits its lexer.",
               version: Bashcov::VERSION, found: rewritten, expected: string_patterns)
end

Bashcov::Lexer.send(:remove_const, :MULTILINE_PATTERNS)
Bashcov::Lexer.const_set(:MULTILINE_PATTERNS, patterns.freeze)

string_regexps = patterns.zip(shipped).reject { |(new, _), (old, _)| new.equal?(old) }.map(&:first).map(&:first)

after_closing_quote = Module.new do
  define_method(:mark_multiline) do |content, offset, lineno, regexp, forward: true|
    start = offset
    start = @closed_at if @closed_at.to_i > offset && !content[offset...@closed_at].include?("\n")
    match = content.match(regexp, start)
    last = super(content, start, lineno, regexp, forward: forward)
    @closed_at = match.end(0) if last && match && string_regexps.any? { |string| string.equal?(regexp) }
    last
  end
  private :mark_multiline
end
Bashcov::Lexer.prepend(after_closing_quote)
