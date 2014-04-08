require 'rubygems'
require 'couchbase'
require 'map'
require 'parallel'
require 'awesome_print'

BEGINNING = Time.now.to_i

CBD = Couchbase.new(bucket: "cbdocs", :quiet => true)
CBU = Couchbase.new(bucket: "cbu", :quiet => true)

require '../../university.couchbase.com/app/models/docs_nav_tree.rb'
require '../../university.couchbase.com/app/models/render_nav_tree.rb'

DocsNavTree.generate
#RenderNavTree.generate

class Couscous

	CBD = Couchbase.new(bucket: "cbdocs", :quiet => true)
	
	def initialize		

	end
	
	def run_parallel

		timers = []
		
		start = Time.now.to_i
		Parallel.each(DocsNavTree.links_only, :in_processes => 4) do |link|
			update_parent_nav_title(link)
		end
		timers << "UPDATE TIME - #{Time.now.to_i - start} seconds"		
		
		timers.each { |t| puts t }
	end

	def update_parent_nav_title(k)
		d, f, cas = CBD.get(k, extended: true)
		d = Map.new(d)
		if d and d.parent? and d.parent and d.parent_link? and d.parent_link
			 d.parent_nav_title = (Map.new(CBD.get(d.parent_link))).nav_title
			 CBD.replace(k,d, cas: cas)
		end		
	end
end


x = Couscous.new
x.run_parallel

puts "TOTAL TIME = #{Time.now.to_f - BEGINNING} seconds"
exit

