require 'sequel'

DB = Sequel.sqlite 'games.db'

if not DB[:items] then
	DB.create_table :items do
		primary_key :id
		String :name
		String :slug, :unique => true, :null => false
		String :flash_file
		String :thumb_file
		Integer :width
		Integer :height
		Boolean :flash
	end
end