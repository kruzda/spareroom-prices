#!/usr/bin/env ruby

# Spareroom.co.uk search parser, data collector
# process:
# 1. load http://www.spareroom.co.uk/flatshare/search.pl with your search parameters
# 2. get new_search_history cookie that contains data similar to 216844970,216845030 - the latter being search_id
# 3. use this cookie to execute the actual query on http://www.spareroom.co.uk/flatshare/
# 4. get html response of a single page offsetted by offset
# 5. parse html
# 6. increase offset until 'number_of_results - offset' is larger than 10
# 7. goto 4.


require "net/http"
require "nokogiri"

uri = URI('http://www.spareroom.co.uk')

def process_price(pricetext)
    # md = matchdata, get lower price, upper price (if any) and period
    md = /\£(?<lower>\d+)(-(?<upper>\d+))?(?<period>(pw|pcm))/.match(pricetext)
    # do average if the price is a range
    price = md[:upper] ? ( md[:lower].to_i + md[:upper].to_i ) / 2 : md[:lower].to_i
    # calculate pcm if price is pw
    price = price * 52 / 12 if md[:period] == "pw"
    return price
end


search_params = {
                    :action         =>   'search',
                    :available_search   =>   'N',
                    :year_avail     =>   '',
                    :mon_avail      =>   '',
                    :day_avail      =>   '',
                    :days_of_wk_available   =>   '',
                    :editing        =>   '',
                    :ensuite        =>   '',
                    :flatshare_type =>   'offered',
                    :genderfilter   =>   'none',
                    :keyword        =>   '',
                    :location_type  =>   'area',
                    :max_age_req    =>   '',
                    :max_beds       =>   '',
                    :max_rent       =>   '',
                    :max_term       =>   '0',
                    :miles_from_max =>   '0',
                    :min_age_req    =>   '',
                    :min_beds       =>   '',
                    :min_rent       =>   '',
                    :min_term       =>   '0',
                    # :bills_inc      =>   'Yes',
                    :mode           =>   '',
                    :nmsq_mode      =>   '',
                    :no_of_rooms    =>   '',
                    :per            =>   '',
                    :posted_by      =>   '',
                    :photoadsonly   =>   '',
                    :room_types     =>   '',
                    :rooms_for      =>   '',
                    :search         =>   '',
                    :searchtype     =>   'advanced',
                    :share_type     =>   '',
                    :show_results   =>   '',
                    :showme_1beds   =>   'Y',
                    :showme_buddyup_properties  =>   'Y',
                    :showme_rooms   =>   'Y',
                    :smoking        =>   '',
                    :templateoveride    =>   '',
                }
                    
Net::HTTP.start(uri.host, uri.port) do |http|
    uri_search1 = URI('http://www.spareroom.co.uk/flatshare/search.pl')
    uri_search1.query = URI.encode_www_form(search_params)

    request_search1 = Net::HTTP::Get.new uri_search1
    response_search1 = http.request request_search1

    new_search_history_cookie = response_search1['set-cookie'].split('; ')[0]
    search_id = new_search_history_cookie.split('=')[1]

    uri_search2 = URI('http://www.spareroom.co.uk/flatshare/')
    offset = 0
    there_are_more_pages = true
    sum_results = 0
    
    while there_are_more_pages do
        uri_search2.query = URI.encode_www_form({:search_id => search_id, :offset => offset})
        request_search2 = Net::HTTP::Get.new uri_search2
        request_search2["Cookie"] = new_search_history_cookie
        response_search2 = http.request request_search2

        page = Nokogiri::HTML(response_search2.body.gsub! /(\t|\n)/, '')
        page.css('a.listing_price').each do |price|
            puts process_price price.text
        end
        number_of_results = page.css('p.navcurrent strong')[1].text.to_i
        there_are_more_pages = 10 < number_of_results - offset
        offset += 10 if there_are_more_pages
    end
    puts "That's #{number_of_results} results for #{search_params}"
end



# parts of the login mechanism - not actually needed for searching
# apparently you don't have to log in to search, but leaving this here for future use

# email = ""
# password = ""
# loginfrom_url = "/flatshare/search.pl?searchtype=advanced"

#    uri_login = URI('http://www.spareroom.co.uk/flatshare/logon.pl')
#    request = Net::HTTP::Post.new uri_login
#    request.set_form_data('email' => email, 'password' => password, 'loginfrom_url' => loginfrom_url, 'remember_me' => "Y")
#    response_login = http.request request

#    cookies_array = Array.new
#    response_login.get_fields('set-cookie').each do | cookie |
#        cookies_array.push(cookie.split('; ')[0])
#    end
#    login_cookies = cookies_array.join('; ')

#    request_search1["Cookie"] = login_cookies


