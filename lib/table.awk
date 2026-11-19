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
  least = 10
}

function cells_at(text, i,   b) {
  b = byte[substr(text, i, 1)]
  if (b >= 128 && b < 192) {
    return 0
  }
  return (b >= 227 && b <= 237) || b >= 240 || (b == 239 && substr(text, i + 1, 1) ~ /[\274\275]/) ? 2 : 1
}

function columns_of(text,   i, n, cells) {
  cells = 0
  n = length(text)
  for (i = 1; i <= n; i++) {
    cells += cells_at(text, i)
  }
  return cells
}

function fold(text, room,   out, i, n, step, cells, start, gap, cut) {
  out = ""
  start = 1
  cells = 0
  gap = 0
  n = length(text)
  for (i = 1; i <= n; i++) {
    step = cells_at(text, i)
    if (step == 0) {
      continue
    }
    if (cells + step > room) {
      cut = gap > start && substr(text, i, 1) != " " ? gap : i
      out = out substr(text, start, cut - start) "\n"
      start = substr(text, cut, 1) == " " ? cut + 1 : cut
      gap = 0
      cells = columns_of(substr(text, start, i - start))
      if (start > i) {
        continue
      }
    }
    if (substr(text, i, 1) == " ") {
      gap = i
    }
    cells += step
  }
  return out substr(text, start)
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
  room = width[columns]
  if (limit > 0 && total > limit && limit - (total - room) >= least) {
    room = limit - (total - room)
    total = limit
  }
  lead = pad(total - room)
  for (row = 1; row <= NR; row++) {
    count = split(rows[row], cell, "\t")
    line = ""
    for (column = 1; column < columns; column++) {
      value = column <= count ? cell[column] : ""
      shown = plain(value)
      colour = row == 1 ? acc : tint(value)
      line = line paint(shown, colour, row == 1) pad(width[column] - columns_of(shown)) "   "
    }
    value = columns <= count ? cell[columns] : ""
    colour = row == 1 ? acc : tint(value)
    pieces = split(fold(plain(value), room), part, "\n")
    print line paint(part[1], colour, row == 1) pad(room - columns_of(part[1]))
    for (piece = 2; piece <= pieces; piece++) {
      print lead paint(part[piece], colour, row == 1)
    }
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
