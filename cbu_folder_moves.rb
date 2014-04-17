require 'rubygems'
require 'rails'
require 'json'
require 'map'
require 'couchbase'
require 'yaml'
require "awesome_print"

require 'dotenv'
Dotenv.load ".env"

puts "You may want to do a '$ git submodule update' to update docs before running this..."

current_folder = "."
Dir.chdir(current_folder)
CBU_ROOT = Dir.pwd

content_root = "#{CBU_ROOT}/docs-source/content"
Dir.chdir(content_root)
SROOT = Dir.pwd

content_target = "#{CBU_ROOT}/docs-transform"
if not File.directory?(content_target)
	FileUtils::mkdir_p content_target
end
Dir.chdir(content_target)
TROOT = Dir.pwd

MOVES = Map.new(YAML.load_file("#{CBU_ROOT}/settings/cbu_folder_moves.yml"))

FileUtils.cp_r "#{CBU_ROOT}/settings/home.markdown", "#{TROOT}/home.markdown", :verbose => true


MOVES.folder_moves.each do |f|
	d = "#{TROOT}/#{f.target}"
	
	
	if not File.directory?(d)
		FileUtils::mkdir_p d
	end
	if f.source?
		s = "#{SROOT}/#{f.source}/."
		t = "#{d}"
		t = "#{f.rename}" if f.rename?
		FileUtils.cp_r s, t, :verbose => true
		
		if f.older_versions?				
			o = "#{t}/older-versions"				
			FileUtils::mkdir_p(o) unless File.directory?(o)

			f.older_versions.each do |ov|
				s = "#{SROOT}/#{f.source}"
				s = s[0..s.length-4] + ov.to_s
				puts s
				FileUtils.cp_r s, o, :verbose => true
			end
		end
	end
	
	# subfolders
	if f.moves?
		f.moves.each do |m|
			s = "#{SROOT}/#{m.source}/."
			t = "#{d}/#{m.source}"
			t = "#{d}/#{m.rename}" if m.rename?
			FileUtils::mkdir_p(t) unless File.directory?(t)
			FileUtils.cp_r s, t, :verbose => true

			if m.older_versions?				
				o = "#{t}/older-versions"				
				FileUtils::mkdir_p(o) unless File.directory?(o)

				m.older_versions.each do |ov|
					s = "#{SROOT}/#{m.source}"
					s = s[0..s.length-4] + ov.to_s
					puts s
					FileUtils.cp_r s, o, :verbose => true
				end
			end
		end
	end
end