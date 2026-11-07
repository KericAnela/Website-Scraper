require 'open-uri'
require 'nokogiri'
require 'json'
require 'csv'

puts "=== Advanced Interactive Ruby Scraper ==="

print "Enter the URL to scrape: "
url = gets.chomp

print "Enter the main container CSS selector (e.g., .quote, .product_pod): "
container_selector = gets.chomp

fields = {}
puts "\nNow, let's define what data points to extract from each container."
loop do
  print "Enter field name (e.g., title, price) or type 'done' to finish: "
  field_name = gets.chomp.strip.downcase
  break if field_name == 'done' || field_name.empty?

  print "Enter CSS selector for '#{field_name}' (relative to container, e.g., h3 a, .price): "
  field_selector = gets.chomp.strip
  
  fields[field_name] = field_selector
end

if fields.empty?
  puts "No fields defined. Exiting."
  exit
end

print "Choose export format [json / csv]: "
format = gets.chomp.downcase

print "Enter output filename (leave blank for 'scraped_data'): "
filename = gets.chomp
filename = "scraped_data" if filename.empty?

begin
  puts "\nFetching and parsing #{url}..."
  html = URI.open(url)
  doc = Nokogiri::HTML(html)

  scraped_data = []

  doc.css(container_selector).each do |container|
    item = {}
    fields.each do |name, selector|
      element = container.at_css(selector)
      
      item[name] = element ? element.text.strip : nil
    end
    scraped_data << item
  end

  if scraped_data.empty?
    puts "Warning: No containers found matching '#{container_selector}'."
    exit
  end

  if format == 'json'
    file_path = "#{filename}.json"
    File.write(file_path, JSON.pretty_generate(scraped_data))
    puts "Successfully saved #{scraped_data.length} records to #{file_path}"
  else
    file_path = "#{filename}.csv"
    CSV.open(file_path, "w") do |csv|
      csv << fields.keys
      scraped_data.each do |row|
        csv << row.values
      end
    end
    puts "Successfully saved #{scraped_data.length} records to #{file_path}"
  end

rescue StandardError => e
  puts "An error occurred: #{e.message}"
end