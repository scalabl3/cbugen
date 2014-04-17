require 'couchbase'
require 'map'
require 'httparty'
require 'nokogiri'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require 'parallel'
require 'awesome_print'

require 'dotenv'
Dotenv.load ".env"
CB_SERVERS=ENV['cbu_couchbase_servers'].split(",")

CBD = Couchbase.new(node_list: CB_SERVERS, bucket: 'cbdocs')
CBU = Couchbase.new(node_list: CB_SERVERS, bucket: 'cbu')

START = Time.now.to_i

MIN_TTL = 60 * 60
CACHE_DISTRIBUTION = (1...24)
CONTENT_LINK_PREFIX = ENV['cbu_content_link_prefix']

require "#{ENV['cbu_rails_root']}/config/initializers/redcarpet_rouge_patches.rb"
require "#{ENV['cbu_rails_root']}/app/models/markdown_render.rb"
require "#{ENV['cbu_rails_root']}/app/models/docs_nav_tree.rb"
require "#{ENV['cbu_rails_root']}/app/models/render_nav_tree.rb"

DocsNavTree.generate
RenderNavTree.generate

class Jambalaya

	ROOT_BREADCRUMB = []
	CBD = Couchbase.new(node_list: CB_SERVERS, bucket: 'cbdocs')
	CBU = Couchbase.new(node_list: CB_SERVERS, bucket: 'cbu')

	
	def initialize		
		create_root_breadcrumb
	end
	
	def run_parallel
		begining = Time.now.to_i
		timers = []
		
		start = Time.now.to_i
		Parallel.each(DocsNavTree.links_only, :in_processes => 4) do |node|
			render_markdown(node)			
		end
		timers << "RENDER TIME - #{Time.now.to_i - start} seconds"
		
		
		
		start = Time.now.to_i
		Parallel.each(DocsNavTree.links_only, :in_processes => 4) do |node|
			render_nav(node)
		end
		timers <<  "NAV RENDER TIME - #{Time.now.to_i - start} seconds"
		
		
		start = Time.now.to_i
		Parallel.each(DocsNavTree.by_level["nav_1"], :in_processes => 4) do |node|
			render_breadcrumb(node)
		end
		timers <<  "BREADRCRUMB Lvl 1 (#{DocsNavTree.by_level["nav_1"].size}) - #{Time.now.to_i - start} seconds"
		
		
		
		start = Time.now.to_i
		Parallel.each(DocsNavTree.by_level["nav_2"], :in_processes => 4) do |node|
			render_breadcrumb(node)
		end
		timers <<  "BREADRCRUMB Lvl 2 (#{DocsNavTree.by_level["nav_2"].size}) - #{Time.now.to_i - start} seconds"
		
		
		
		start = Time.now.to_i
		Parallel.each(DocsNavTree.by_level["nav_3"], :in_processes => 4) do |node|
			render_breadcrumb(node)
		end
		timers <<  "BREADRCRUMB Lvl 3 (#{DocsNavTree.by_level["nav_3"].size}) - #{Time.now.to_i - start} seconds"
		
		
		
		start = Time.now.to_i
		Parallel.each(DocsNavTree.by_level["nav_4"], :in_processes => 4) do |node|
			render_breadcrumb(node)
		end
		timers <<  "BREADRCRUMB Lvl 4 (#{DocsNavTree.by_level["nav_4"].size}) - #{Time.now.to_i - start} seconds"
		
		
		
		if DocsNavTree.by_level["nav_5"]
			
			start = Time.now.to_i
			Parallel.each(DocsNavTree.by_level["nav_5"], :in_processes => 4) do |node|
				render_breadcrumb(node)
			end
			timers <<  "BREADRCRUMB Lvl 5 (#{DocsNavTree.by_level["nav_5"].size}) - #{Time.now.to_i - start} seconds"
			
		end
		
		
		
		if DocsNavTree.by_level["nav_6"]
			
			start = Time.now.to_i
			Parallel.each(DocsNavTree.by_level["nav_6"], :in_processes => 4) do |node|
				render_breadcrumb(node)
			end
			timers <<  "BREADRCRUMB Lvl 6 (#{DocsNavTree.by_level["nav_6"].size}) - #{Time.now.to_i - start} seconds"
		
		end
		
		if DocsNavTree.by_level["nav_7"]
			
			start = Time.now.to_i
			Parallel.each(DocsNavTree.by_level["nav_7"], :in_processes => 4) do |node|
				render_breadcrumb(node)
			end
			timers <<  "BREADRCRUMB Lvl 7 (#{DocsNavTree.by_level["nav_7"].size}) - #{Time.now.to_i - start} seconds"
		
		end      

		# Parallel.each(DocsNavTree.by_level["nav_3"], :in_processes => 8) do |node|
		# 			render_breadcrumb(node)
		# 		end
		# 		Parallel.each(DocsNavTree.by_level["nav_4"], :in_processes => 8) do |node|
		# 			render_breadcrumb(node)
		# 		end
		# 		Parallel.each(DocsNavTree.by_level["nav_5"], :in_processes => 8) do |node|
		# 			render_breadcrumb(node)
		# 		end

		timers.each { |t| puts t }
		puts "TOTAL TIME = #{Time.now.to_i - begining} seconds"
	end
	
	def render_markdown(link)
				
		cas_retry = false

		begin
			doc, flags, cas = CBD.get(link, extended: true)
			doc = Map.new(doc)
			mod = false

			if doc.markdown? and doc.markdown 				
				unless doc.markdown_render? and doc.markdown_render					
					doc.markdown_render = MarkdownRender::render(doc.markdown)
					mod = true
				end
			else
				puts "NO MARKDOWN #{link}"				
			end	
		
			if mod
				puts "MDRENDER::#{link}"
				begin
					CBD.replace(link, doc, cas: cas)
					cas_retry = false
				rescue Couchbase::Error::KeyExists 
					cas_retry = true
					puts "RETRY::MDRENDER::#{link}"
				end
			else
				cas_retry = false
			end
		end while cas_retry 
	end
	
	def render_nav(link)
		ttl = 60 * 60 * 24
    cached_nav = RenderNavTree.generate_html(link)
		CBU.set("navcache::#{link}", cached_nav, :ttl => ttl) 
		puts "navcache::#{link}"
	end
	
	def render_breadcrumb(n)

		cas_retry = false

		begin
			doc, flags, cas = CBD.get(n.link, extended: true)
			doc = Map.new(doc)
			mod = false
			unless doc.breadcrumb? and doc.breadcrumb 
				doc.delete(:breadcrumb)
				breadcrumb = create_breadcrumb(n)
				#puts "#######################################################################\n#{n.link}\n"
				#ap breadcrumb
				#puts "#######################################################################"
				doc.breadcrumb = breadcrumb
				mod = true
			else
				brd = -1
			end
		
			if mod
				puts "bread::#{n.link}"
				begin
					CBD.replace(n.link, doc, cas: cas)
					cas_rety = false
				rescue Couchbase::Error::KeyExists 
					cas_retry = true
					puts "RETRY::bread::#{n.link}"
				rescue Couchbase::Error::TooBig
					ap doc
				end
			else
				cas_retry = false
			end
		
		end while cas_retry
		
	end
	
	def create_breadcrumb(node)

		breadcrumb = Marshal.load(Marshal.dump(ROOT_BREADCRUMB))
		
		t1 = Time.now.to_i
		node.ancestors_links.each_with_index do |al, i|
		
			puts "ancestors::bread::#{al}"
			parent = CBU.get("bread::#{al}")
		
			if parent.nil?
				t2 = Time.now.to_i
				ancestor_node = DocsNavTree.by_link[al]
				puts "2: #{Time.now.to_i - t2}"

				parent = Map.new({
					name: ancestor_node.nav_title,
					link: ancestor_node.full_link,
					dropdown: false,
					dropdown_items: nil,
					final: false
				})
	 
				if ancestor_node.nav_type == "folder"
					parent.dropdown = true
					parent.dropdown_items = []
		 
					t2 = Time.now.to_i
					ancestor_node.descendants_links.each do |dl|
						d = DocsNavTree.by_link[dl]
			 
						item = Map.new({
							name: d.nav_title,
							link: d.full_link
						})
			 
						parent.dropdown_items << item
					end				 
					puts "3: #{Time.now.to_i - t2}"
				end
				puts "BREADCRUMB::SET ancestors::bread::#{al}}"
				CBU.set("bread::#{al}", parent)
			end
			
			breadcrumb << parent
		end
		breadcrumb << Map.new({
			name: node.nav_title, 
			link: nil, 
			final: true, 
			dropdown: false, 
			dropdown_items: false 
		})
		puts "1: #{Time.now.to_i - t1}"
		
		breadcrumb
	end

	#######################################################################
	# Create Root Breadcrumb
	#######################################################################
	def create_root_breadcrumb

		root = Map.new({
			name: "Docs",
			link: "/#{CONTENT_LINK_PREFIX}/",
			dropdown: true,
			dropdown_items: [],
			final: false
		})
		
		DocsNavTree.by_level["nav_1"].each do |n|
			item = Map.new({
				name: n.nav_title,
				link: n.full_link
			})
			root.dropdown_items << item
		end

		ROOT_BREADCRUMB << root
		puts "Create Root Breadcrumb"
		ap ROOT_BREADCRUMB
	end

end


x = Jambalaya.new
x.run_parallel

exit
