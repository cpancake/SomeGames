class NewgroundsSite < BaseSite
	@name = "Newgrounds"
	@regex = /^http:\/\/www\.newgrounds\.com\/portal\/view\/(\d{1,})$/
	data = nil

	def self.get_file_name(page)
		data = HTTParty.get(page).body if not data
		m = /<title>(.+?)<\/title>/.match(data)
		return nil if not m or not m[1]
		return m[1]
	end

	def self.get_file_url(page)
		data = HTTParty.get(page).body if not data
		m1 = /\{\"url\":\"(.+?\.swf)\",/.match(data)
		return m1[1].gsub("\\/","/") if m1 and m1[1]
		return nil
	end

	def self.get_thumb_url(page)
		num = @regex.match(page)[1].to_i
		return "http://picon.ngfiles.com/" + rounddown(num, 1000).to_s + "/flash_" + num.to_s + ".jpeg"
	end
end

Sites.push NewgroundsSite