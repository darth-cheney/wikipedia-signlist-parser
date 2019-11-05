def row_has_headers(row)
  row.css('th').length > 0
end

def scrub_categories(raw_categories)
  result = Array.new
  raw_categories.each do |cat_name|
    result << scrub_category(cat_name)
  end
  result
end

def scrub_category(cat_name)
  cat_name.chomp("[edit][]")
end

def scrub_data_row(entry)
  scrubbed = {}
  entry.keys.each do |key|
    val = entry[key]
    if val.empty? or val == ' '
      val = nil
    end
    if !key.empty? and key != ' '
      scrubbed[key] = val
    end
  end
  scrubbed
end
