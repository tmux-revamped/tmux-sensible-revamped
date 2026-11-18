function hexval(digit) {
  return index("0123456789abcdef", tolower(digit)) - 1
}

function rgb(colour) {
  if (colour == "") {
    return ""
  }
  return (hexval(substr(colour, 2, 1)) * 16 + hexval(substr(colour, 3, 1))) ";" \
    (hexval(substr(colour, 4, 1)) * 16 + hexval(substr(colour, 5, 1))) ";" \
    (hexval(substr(colour, 6, 1)) * 16 + hexval(substr(colour, 7, 1)))
}

function paint(text, colour, bold) {
  if (colour == "" && !bold) {
    return text
  }
  return "\033[" (bold ? "1" : "0") (colour == "" ? "" : ";38;2;" rgb(colour)) "m" text "\033[0m"
}

function plain(text) {
  sub(/^@(ok|warn|bad|acc|mut):/, "", text)
  return text
}

function tint(text) {
  if (text ~ /^@ok:/) { return ok }
  if (text ~ /^@warn:/) { return warn }
  if (text ~ /^@bad:/) { return bad }
  if (text ~ /^@acc:/) { return acc }
  if (text ~ /^@mut:/) { return mut }
  return txt
}

BEGIN {
  for (code = 128; code < 256; code++) {
    byte[sprintf("%c", code)] = code
  }
}

function columns_of(text,   i, n, b, cells) {
  cells = 0
  n = length(text)
  for (i = 1; i <= n; i++) {
    b = byte[substr(text, i, 1)]
    if (b >= 128 && b < 192) {
      continue
    }
    cells += (b >= 227 && b <= 237) || b >= 240 || (b == 239 && substr(text, i + 1, 1) ~ /[\274\275]/) ? 2 : 1
  }
  return cells
}

function pad(count,   out) {
  out = ""
  while (count-- > 0) {
    out = out " "
  }
  return out
}

{
  rows[NR] = $0
  for (column = 1; column <= NF; column++) {
    if (columns_of(plain($column)) > width[column]) {
      width[column] = columns_of(plain($column))
    }
  }
  if (NF > columns) {
    columns = NF
  }
}

END {
  total = 0
  for (column = 1; column <= columns; column++) {
    total += width[column] + (column > 1 ? 3 : 0)
  }
  for (row = 1; row <= NR; row++) {
    count = split(rows[row], cell, "\t")
    line = ""
    for (column = 1; column <= columns; column++) {
      value = column <= count ? cell[column] : ""
      shown = plain(value)
      colour = row == 1 ? acc : tint(value)
      line = line (column > 1 ? "   " : "") paint(shown, colour, row == 1) pad(width[column] - columns_of(shown))
    }
    print line
    if (row == 1) {
      print paint(rule(total), mut, 0)
    }
  }
}

function rule(count,   out) {
  out = ""
  while (count-- > 0) {
    out = out dash
  }
  return out
}
