require 'httparty'
require 'cgi'

Sites = Array.new

def strip_params(url)
	arr = url.split("?")
	return arr[0] if arr.length == 1
	arr.slice!(arr.length - 1)
	return arr.join("?")
end

def rounddown(num, nearest=10)
	return num % nearest == 0 ? num : num - (num % nearest)
end

class BaseSite
	@name = 'none'
	@regex = //

	def self.name
		return @name
	end

	def self.regex
		return @regex
	end

	def self.does_match(page)
		return @regex.match page
	end

	def self.get_file_name(page)
		return nil
	end

	def self.get_file_url(page)
		return nil
	end

	def self.get_thumb_url(page)
		return nil
	end
end

require_relative 'kongregate'
require_relative 'newgrounds'