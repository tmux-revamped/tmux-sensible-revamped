# frozen_string_literal: true

require "bashcov"
require "bashcov/lexer"
require "tmpdir"

require_relative "bashcov-lexer" unless ARGV.first == "--unpatched"

QUOTED_PROMPTS = <<~'SH'
  f() {
    if [ -n "$2" ]; then
      printf '%s [%s]: ' "$1" "$2" >&2
    else
      printf '%s: ' "$1" >&2
    fi
    printf '%s\n' "$1"
  }
SH

TWO_LINE_STRING = <<~'SH'
  text='one
  two'
SH

NESTED_AWK = <<~'SH'
  sizes="$(awk -v h="${HEIGHT}" 'BEGIN {
    printf "%d\n", h * 2
  }')"
SH

CLOSING_QUOTE_LINE = <<~'SH'
  median() {
    printf '%s\n' "$1" | awk '
      NF { print $1 }
    '
  }

  set_error() {
    printf '%s\n' "$1"
  }
SH

def lexed(text, hits)
  Dir.mktmpdir("bashcov-lexer") do |dir|
    path = File.join(dir, "sample.sh")
    File.write(path, text)
    coverage = Array.new(text.lines.size) { |index| hits[index + 1] }
    Bashcov::Lexer.new(path, coverage).complete_coverage
    coverage
  end
end

failures = []
check = lambda do |name, actual, expected|
  failures << format("%<name>s: expected %<expected>p, got %<actual>p", name:, expected:, actual:) unless actual == expected
end

# Arrange
untouched = {}

# Act
coverage = lexed(QUOTED_PROMPTS, untouched)

# Assert
check.call("a fi after quoted prompts is not code", coverage[5], nil)
check.call("an else after quoted prompts is not code", coverage[3], nil)

# Arrange
then_branch_only = { 2 => 1, 3 => 1, 7 => 1 }

# Act
coverage = lexed(QUOTED_PROMPTS, then_branch_only)

# Assert
check.call("an else branch that never ran stays uncovered", coverage[4], 0)

# Arrange
first_line_ran = { 1 => 1 }

# Act
coverage = lexed(TWO_LINE_STRING, first_line_ran)

# Assert
check.call("a string over two lines still shares its hit", coverage[1], 1)

# Arrange
substitution_ran = { 1 => 1 }

# Act
coverage = lexed(NESTED_AWK, substitution_ran)

# Assert
check.call("an awk program opened inside a command substitution shares its hit", coverage[1..2], [1, 1])

# Arrange
nothing_ran = {}

# Act
coverage = lexed(CLOSING_QUOTE_LINE, nothing_ran)

# Assert
check.call("a lone closing quote opens no new string", coverage[4..6], [nil, nil, nil])

if failures.empty?
  puts format("bashcov %<version>s lexer: 6 checks passed", version: Bashcov::VERSION)
  exit 0
end
warn format("bashcov %<version>s lexer:", version: Bashcov::VERSION)
failures.each { |failure| warn format("  %<failure>s", failure:) }
exit 1
