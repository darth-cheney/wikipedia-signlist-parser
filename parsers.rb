class TableParser
  def initialize(tbody, category)
    @category = category
    @rows = tbody.css('tr')
    first_row = @rows[0]
    @rows.shift
    raw_headers = first_row.css('th').collect {|th| th.text}
    @headers = raw_headers
    @tracker = {}
    @headers.each do |header_name|
      @tracker[header_name] = 1
    end
    @prev_row = nil
    @processed_rows = Array.new
  end

  def parse_rows
    st = "Parsing #{@category}  with #{@rows.length} non-header rows..."
    puts st
    @rows.each_with_index {|row, idx|
      row_parser = RowParser.new(row, self, idx)
      @processed_rows << row_parser.parse
      decrement_tracker
    }
    return @processed_rows
  end

  def decrement_tracker
    @tracker.keys.each do |key|
      current_val = @tracker[key]
      if current_val > 1
        @tracker[key] = current_val - 1
      end
    end
  end

  def tracker
    @tracker
  end

  def headers
    @headers
  end

  def category
    @category
  end

  def prev_row
    @prev_row
  end

  def prev_row=(row_parser)
    @prev_row = row_parser
  end
end


class RowParser
  def initialize(row, table_parser, index)
    @row = row
    @index = index
    @table = table_parser
    @cells = row.css('td')
    @orig_cell_length = @cells.length
    @header_index = 0
    @cell_index = 0
    @result = {"category" => @table.category}
  end

  def result
    @result
  end

  def rowspan_for(td)
    rowspan = td['rowspan']
    if rowspan
      return rowspan.to_i + 1
    end
    return nil
  end

  def colspan_for(td)
    colspan = td['colspan']
    if colspan
      return colspan.to_i
    end
    return 1
  end

  def update_tracker(header_name, span_num)
    @table.tracker[header_name] = span_num
  end

  def parse
    if @table.headers.length == @cells.length
      return parse_aligned_row
    else
      return parse_complex_row
    end
  end

  def parse_aligned_row
    @cells.each_with_index {|td, idx|
      header_name = @table.headers[idx]
      rowspan = rowspan_for(td)
      if rowspan
        update_tracker(header_name, rowspan)
      end
      @result[header_name] = td.text
    }
    @table.prev_row = self
    return @result
  end

  def index_string
    "#{@table.category} [#{@index}]"
  end

  def validate_row
    valid_headers = @table.tracker.values.reduce(0) {|sum, num|
      if num == 1
        sum + 1
      else
        sum
      end
    }
    cell_values = get_cell_values
    valid = valid_headers == cell_values.length
    if !valid
      puts @table.tracker
      puts @row
      err_msg = "Invalid complex row #{valid_headers} x #{cell_values.length} #{index_string}"
      raise err_msg unless valid_headers == cell_values.length
    end
  end

  def get_cell_values
    result = Array.new
    @cells.each do |td|
      colspan = colspan_for(td)
      text_val = td.text
      colspan.times do |idx|
        result << text_val
      end
    end
    result
  end

  def get_abs_cells
    result = Array.new
    @cells.each do |td|
      colspan = colspan_for(td)
      colspan.times do |idx|
        result << td
      end
    end
    result
  end

  def should_use_cached(header_name)
    val = @table.tracker[header_name]
    return val > 1
  end

  def parse_complex_row
    validate_row
    cell_vals = get_abs_cells
    if @orig_cell_length == 0
      return @result
    end
    @table.headers.each_with_index {|header_name, header_idx|
      if should_use_cached(header_name)
        @result[header_name] = @table.prev_row.result[header_name]
      else
        cur_cell = cell_vals.shift()
        if !cur_cell
          raise "Out of cells at header #{header_name}-#{header_idx}"
        end
        rowspan = rowspan_for(cur_cell)
        if rowspan
          update_tracker(header_name, rowspan)
        end
        @result[header_name] = cur_cell.text
      end
    }
    if !cell_vals.empty?
      raise "Cell vals not empty at #{@table.category} [#{@index}]!"
    end
    return @result
  end
end
