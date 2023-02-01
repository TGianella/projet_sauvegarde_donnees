class Scraper
  
  def initialize(page_url)
    @page_url = page_url
  end

  def get_townhall_email(townhall_url)
    email = Nokogiri::HTML(URI.open(townhall_url, {ssl_verify_mode: 0})).xpath('/html/body/div/main/section[2]/div/table/tbody/tr[4]/td[2]').text
    email.empty? ? puts("Didn't find the email !") : puts("Scraped #{email}")
    email
  end
  
  def get_townhall_urls
    cities = Nokogiri::HTML(URI.open(@page_url, {ssl_verify_mode: 0})).xpath("//tr[3]/td//td[2]//td[@width='627']//a")
    #return cities
    prefix = "https://www.annuaire-des-mairies.com"
    res = []
    cities.each do |city|
      res << [[city.text, prefix + city['href'][1..]]].to_h
      puts "Adding #{[city.text, prefix + city['href'][1..]]} to list (control : #{res[-1..]})."
    end
    res
  end

  def get_townhall_emails_from_URL_hash(url_array)
    res = []
    url_array.each do |hash|
      hash.each do |city, url|
        email = get_townhall_email(url)
        unless email.empty? 
          res << {city =>email}
          puts "Replacing #{city}'s url with its email (control : #{res[-1..]})."
        else
          puts "Email is not provided for #{city} : deleting item"
        end
      end
    end
    res 
  end

  def save_as_json(result)
    File.open("db/emails.json", "w") do |f|
      f.write(result.to_json)
    end
    puts "Saved results to db/emails.json"
  end

  def save_as_spreadsheet(result)
    session = GoogleDrive::Session.from_config("config/config.json")
    spreadsheet = session.create_spreadsheet(title = "emails")
    ws = spreadsheet.worksheets[0]
    ws[1, 1] = "Ville"
    ws[1, 2] = "Email"
    result.each_with_index do |pair, line|
      ws[line + 2, 1] = pair.keys[0]
      ws[line + 2, 2] = pair.values[0]
    end
    ws.save
    puts "Saved results to google drive"
  end

  def save_as_csv(result)
    CSV.open("db/emails.csv", "w") do |csv|
      result.each do |pair|
        csv << [pair.keys.first, pair.values.first]
      end
    end
    puts "Saved results to db/emails.csv"
  end

  def format_choice
    puts "Sous quel format les résultats doivent-ils être enregistrés ?\n1 - JSON\n2 - Google spreadsheet\n3 - CSV"
    user_choice = gets.chomp.to_i
    case user_choice
    when 1
      save_as_json(get_townhall_emails_from_URL_hash(get_townhall_urls))
    when 2
      save_as_spreadsheet(get_townhall_emails_from_URL_hash(get_townhall_urls))
    when 3
      save_as_csv(get_townhall_emails_from_URL_hash(get_townhall_urls))
    else
      puts "Erreur"
    end
  end
      
  def perform
    format_choice
  end
end

