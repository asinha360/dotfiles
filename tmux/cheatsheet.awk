# Lays cheatsheet.txt out for the popup it opens in: the header (up to the
# first blank line) as is, then whole sections side by side in as many 49-cell
# columns as fit, filled down then across with balanced heights.
# Run with LC_ALL=C: dropping UTF-8 continuation bytes leaves the display width
# (every glyph on the sheet is one cell). -v w=N overrides the popup width.
BEGIN {
  BOX = 49; GAP = 2
  if (!w) { "stty size </dev/tty 2>/dev/null" | getline size; split(size, a, " "); w = a[2] + 0 }
  if (!w) w = 80
}
!body { print; if ($0 == "") body = 1; next }
$0 == "" { if (h[n]) n++; next }
{ if (!n) n = 1; line[n, ++h[n]] = $0 }

function width(s) { gsub(/[\200-\277]/, "", s); return length(s) }

END {
  if (!h[n]) n--
  cols = int((w + GAP) / (BOX + GAP)); if (cols < 1) cols = 1
  for (i = 1; i <= n; i++) total += h[i] + 1
  # A section moves to the next column when its middle would pass the target height
  c = 1
  for (i = 1; i <= n; i++) {
    if (used[c] && used[c] + h[i] / 2 > total / cols && c < cols) c++
    if (used[c]) cell[c, ++used[c]] = ""
    for (j = 1; j <= h[i]; j++) cell[c, ++used[c]] = line[i, j]
    if (used[c] > rows) rows = used[c]
  }
  for (r = 1; r <= rows; r++) {
    out = ""
    for (k = 1; k <= c; k++) {
      s = cell[k, r]
      if (k < c) s = s sprintf("%" (BOX + GAP - width(s)) "s", "")
      out = out s
    }
    sub(/ +$/, "", out)
    print out
  }
}
