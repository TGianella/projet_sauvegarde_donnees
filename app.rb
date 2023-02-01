require 'bundler'
Bundler.require

$:.unshift File.expand_path('./../lib', __FILE__)
require 'app/scraper'

scraper = Scraper.new('https://www.annuaire-des-mairies.com/val-d-oise.html')
scraper.perform

