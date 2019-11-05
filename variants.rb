def add_unicode_extras(entry)
  unicode_extras = {
    'codes' => Array.new,
    'chars' => Array.new
  }

  glyph_cell_text = entry['Glyph/Unicode Code Point']
  if glyph_cell_text.nil?
    entry[:unicode] = unicode_extras
    return entry
  end
  regex = /U\+(?<unicode>\d[\dA-Fa-f]+)\s+(?<char>[^0-9A-Za-z])/
  glyph_cell_text.scan(regex) do |match_pair|
    unicode_extras['codes'] << parse_unicode_int(match_pair.first)
    unicode_extras['chars'] << match_pair[1]
  end
  entry[:unicode] = unicode_extras
  entry
end

def parse_unicode_int(a_string)
  a_string.to_i(16)
end

def by_unicode_char(entries)
  result = {}
  entries.each do |entry|
    if entry.key?(:unicode)
      entry[:unicode]['chars'].each do |char|
        if !result.key?(char)
          result[char] = Array.new
        end
        result[char] << entry
      end
    end
  end
  return result
end

def by_unicode_int(entries)
  result = {}
  entries.each do |entry|
    if entry.key?(:unicode)
      entry[:unicode]['codes'].each do |code|
        if !result.key?(code)
          result[code] = Array.new
        end
        result[code] << entry
      end
    end
  end
  return result
end
