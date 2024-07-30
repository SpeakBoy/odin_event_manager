require "csv"
require "google/apis/civicinfo_v2"
require "erb"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(phone_number)
  truncated_phone_number = phone_number.to_s.tr("^0-9", "")
  if truncated_phone_number.length == 11 && truncated_phone_number[0] == "1"
    truncated_phone_number = truncated_phone_number[1..]
  end
  unless truncated_phone_number.length == 10
    truncated_phone_number = "bad"
  end
  truncated_phone_number
end

def clean_date_and_time(date_and_time)
  seperate_date_and_time = date_and_time.split(" ")
  date_seperated = seperate_date_and_time[0].split("/")
  month = date_seperated[0].to_i
  day = date_seperated[1].to_i
  year = ("20" + date_seperated[2]).to_i
  time_seperated = seperate_date_and_time[1].split(":")
  hour = time_seperated[0].to_i
  minute = time_seperated[1].to_i
  Time.new(year, month, day, hour, minute, 0)
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read("secret.key").strip

  begin
    civic_info.representative_info_by_address(address: zip, levels: "country", roles: ["legislatorUpperBody", "legislatorLowerBody"]).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  date_and_time = clean_date_and_time(row[:regdate])

  weekday_registered = date_and_time.wday

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)
  puts weekday_registered
end

