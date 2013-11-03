class KongregateSite < BaseSite
	@name = "Kongregate"
	@regex = /^https?:\/\/(www\.)?kongregate\.com\/games\/(.+?)$/
	data = nil

	def self.get_file_name(page)
		data = CGI::unescape(HTTParty.get(page).body) if not data
		m = /<h1.+?itemprop=\"name\">(.+?)<\/h1>/.match(data)
		return nil if not m or not m[1]
		return m[1]
	end

	def self.get_file_url(page)
		data = CGI::unescape(HTTParty.get(page).body) if not data
		m1 = /\"game_swf\":\"(https?:\/\/chat\.kongregate\.com\/game(z|_files).+?)\?kongregate_game_version=\d{1,}\"/.match(data)
		m2 = /var.+?swf_location.+?=.+?\"(.+?)\?kongregate_game_version=\d{1,}";/.match(data)
		return m1[1] if m1 and m1[1]
		return m2[1] if m2 and m2[1]
		return nil
	end

	def self.get_thumb_url(page)
		data = HTTParty.get(page + '/show_hover').body
		m1 = /<img.+?class=\"game_icon screenshot_img\".+?src=\"(https?:\/\/cdn\d.kongcdn.com\/game_icons.+?)\"/.match(data)
		m2 = /<div class=\"screenshot\"><img.+?class=\"screenshot_img\".+?src=\"(https?:\/\/cdn\d.kongcdn.com\/assets\/screenshots\/.+?)\"/.match(data)
		return strip_params(m1[1]) if m1 and m1[1]
		return strip_params(m2[1]) if m2 and m2[1]
		return nil
	end
end

Sites.push KongregateSite