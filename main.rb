require 'json'
require 'set'
require 'nokogiri'
require 'open-uri'
require_relative './parsers'
require_relative './util'

WIKI_URL = 'https://en.wikipedia.org/wiki/List_of_cuneiform_signs'
doc = Nokogiri::HTML(open(WIKI_URL))

table_hash = {}
row_hash = {}
headers = doc.css('h2')
valid_headers = headers.select {|h| h.css('+ table > tbody').length > 0}
puts valid_headers.length
valid_headers.each do |h|
  scrubbed_cat = scrub_category(h.css('span').text)
  table_hash[scrubbed_cat] = h.css('+ table > tbody')
end

table_hash.each do |key, table|
  row_hash[key] = table.css('tr').select {|r| !row_has_headers(r)}
end

headers_by_category = {}
categories = Array.new

results = Array.new
table_hash.each do |category, tbody|
  table_parser = TableParser.new(tbody, category)
  headers_by_category[category] = table_parser.headers
  categories << category
  new_results = table_parser.parse_rows.collect {|row|
    scrub_data_row(row)
  }
  results = results.concat(new_results)
end

final = {
  "categories" => categories,
  "headers" => headers_by_category,
  "signs" => results
}

wf = File.open('./signs.json', 'w')
_json = JSON.pretty_generate(final)
wf.puts _json
wf.close()
