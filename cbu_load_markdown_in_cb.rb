require 'rubygems'
require 'rails'
require 'json'
require 'multi_json'
require 'map'
require 'couchbase'
require 'awesome_print'
require 'yaml'
require 'elasticsearch'
require 'httparty'
require 'pp'
require 'chronic'
require 'base64'
require 'dotenv'

Dotenv.load ".env"
CB_SERVERS=ENV['cbu_couchbase_servers'].split(",")

CBD = Couchbase.new(node_list: CB_SERVERS, bucket: 'cbdocs')
CBU = Couchbase.new(node_list: CB_SERVERS, bucket: 'cbu')

Dir.chdir(".")
GROOT = Dir.pwd

content_root = "#{GROOT}/docs-transform"
Dir.chdir(content_root)
CROOT = Dir.pwd

CONTENT_LINK_PREFIX = ENV['cbu_content_link_prefix']


class ManageCluster
	include HTTParty
	
	attr_accessor :cb_u, :cb_p, :es_list, :cb_list
	
	def initialize(cb_u, cb_p, es_list, cb_list)
		@cb_u = cb_u
		@cb_p = cb_p
		@es_list = es_list
		@cb_list = cb_list
		
    @auth = {:username => cb_u, :password => cb_p}		
 		#.index#  index: 'myindex', type: 'mytype', id: 1, body: { title: 'Test' }
		#client.search index: 'myindex', body: { query: { match: { title: 'test' } } }
		
		@es = Elasticsearch::Client.new log: true
  end

	def xdcr_remote_clusters(options={})		
    options.merge!({:basic_auth => @auth})
    @clusters = self.class.get("http://#{@cb_list[0]}:8091/pools/default/remoteClusters", options)

		@clusters.each do |c|
			if c[:name] == "ES"
				@xdcr_es = Map.new(c)
			end
		end
  end

	def reset_es_index
		
		@es.indices.delete index: 'cbdocs' if @es.indices.exists index: 'cbdocs'
		@es.indices.delete index: 'cbdocs2' if @es.indices.exists index: 'cbdocs2'

		@es.indices.create index: 'cbdocs'
		puts @es.indices.exists index: 'cbdocs'		
	end
	
	def create_replication(options={})
		
		opts = {
			uuid:@xdcr_es.uuid,
			fromBucket: 'cbdocs',
			toCluster: 'ES',
			toBucket: 'cbdocs',
			replicationType: 'continuous'
		}
		options.merge!(opts)
		options.merge!({:basic_auth => @auth})
		self.class.post("http://#{@cb_list[0]}:8091/controller/createReplication", options)
	end
	
	def current_replications(options={})
		options.merge!({:basic_auth => @auth})
    self.class.get("http://#{@cb_list[0]}:8091/settings/replications/", options)
	end
	
	def remove_xdcr_replication
		# admin:password 
	end

end

#mc = ManageCluster.new(ENV['cbu_couchbase_server_user'], ENV['cbu_couchbase_server_pass'], ENV['cbu_elasticsearch_servers'], ENV['cbu_couchbase_servers'])
#ap mc.xdcr_remote_clusters
#ap mc.current_replications
#ap mc.reset_es_index
#exit



#######################################################################
# Utility Methods
#######################################################################

def parse_markdown_file(filepath)
  metadata = nil
  markdown = nil

  mdfile = (filepath + ".markdown" unless filepath.end_with? (".markdown"))

  md = File.read(mdfile)
  if match = md.match(/(<meta>)([\S\s]+)(<\/meta>)/)
    x, metadata, y = match.captures
    #puts metadata    
    metadata = YAML.load metadata
    markdown = md.gsub(/<meta>[\S\s]+<\/meta>/, "")
  else      
    markdown = md
  end
  
  return metadata, markdown
end

def read_and_encode_asset_file(filepath)
  return Base64.encode64( open(filepath).read ).gsub("\n", '')
end

def load_assets_and_store_binary_images(node)
	
	ayml = Map.new(YAML.load_file("#{node.source_path}/aaaa-assets.yml"))
	
	
	ayml.asset_items.each do |a|
		k = node.link + "/" + a.file
		v = Map.new({
			doctype: "asset",
			subtype: a.type,
			format: (a.file[(a.file.rindex(".") + 1)..-1]).gsub("jpg", "jpeg"),			
			link: "images/#{a.file}",
			full_link: "#{node.full_link}/#{a.file}",
			alt: a.img_alt,
  		caption: a.img_caption,
  		tooltip_text: a.img_tooltip_text,
			binary: read_and_encode_asset_file("#{node.source_path}/images/#{a.file}")
		})
		CBD.set(k,v)
		#puts
		#puts
		#puts k
		#ap v		
	end
		
end

def node_has_children(node)
  if node.children? and node.children.count? and node.children.count > 0 and node.children.items? and node.children.items
    true
  else
    false
  end
end

#######################################################################
# Setup Content Hash and Content Root Folder
#######################################################################

def traverse_nav_tree_store_in_cb(node)
    
  # traverse subfolders, go deep
  if node_has_children(node)
     node.children.items.each do |child|
       traverse_nav_tree_store_in_cb(child)
     end
  end
  
  return if node.nav_level == 0
  
  mod = node.dup

  link = node.link
  full_link = node.full_link
  
  mod.parent_link = parent_link = node.link[0..(link.rindex("/") - 1)] if node.nav_level > 1
  
  if CONTENT_LINK_PREFIX && CONTENT_LINK_PREFIX.length > 0
    #link = mod.link = CONTENT_LINK_PREFIX + node.link
    full_link = mod.full_link = "/" + CONTENT_LINK_PREFIX + node.full_link unless node.full_link.start_with?("/#{CONTENT_LINK_PREFIX}")
  end

  
  mod.delete :source_path
  mod.delete :parent_path
  mod.delete :children


  #puts "storing [#{mod.nav_level}][#{mod.nav_order}][#{mod.nav_type}] - #{mod.nav_title}"
  case mod.nav_type  
  
  when "folder"
    CBD.set(link, mod)		
		load_assets_and_store_binary_images(node) if File.exists?("#{node.source_path}/aaaa-assets.yml")

  when "markdown"
    metadata, markdown = parse_markdown_file(node.source_path)
		
		filepath_markdown = node.source_path.dup		
		filepath_markdown += ".markdown"	unless filepath_markdown.end_with? (".markdown")		
		mod.updated_at = Chronic.parse(File.mtime(filepath_markdown).to_s).utc.to_i
		
    mod.metadata = metadata if metadata
    mod.markdown = markdown
    
    CBD.set(link, mod)
  when "folder+markdown"
    metadata, markdown = parse_markdown_file(node.source_path)
		
		filepath_markdown = node.source_path.dup		
		filepath_markdown += ".markdown"	unless filepath_markdown.end_with? (".markdown")		
		mod.updated_at = Chronic.parse(File.mtime(filepath_markdown).to_s).utc.to_i
		
    mod.metadata = metadata if metadata
    mod.markdown = markdown
    CBD.set(link, mod)
		
		load_assets_and_store_binary_images(node) if File.exists?("#{node.source_path}/aaaa-assets.yml")
  end
  
end

def clean_up_hierarchy(node)
  # traverse subfolders, go deep
  if node_has_children(node)
     node.children.items.each do |child|
         items = clean_up_hierarchy(child)
     end
  end
  
  cleaned_nav_items = nil
  
  if node_has_children(node)
    cleaned_nav_items = node.children.items

    cleaned_nav_items.each do |n| 
      n.delete :source_path
      n.delete :parent_path
    end  
  end
  
  if node.full_link? && CONTENT_LINK_PREFIX && CONTENT_LINK_PREFIX.length > 0
    node.full_link = "/" + CONTENT_LINK_PREFIX + node.full_link unless node.full_link.start_with?("/#{CONTENT_LINK_PREFIX}")
  end
  
  cleaned_nav_items
end


def create_ordered_flattened_hierarchy(node)
  
  list = []
  node_orphan = node.dup
  node_orphan.delete(:children)  
  list << node_orphan
  
  if node_has_children(node)
    node.children.items.each do |child|
      child_list = create_ordered_flattened_hierarchy(child)
      child_list.each do |n|
        list << n
      end      
    end
  end
  
  return list
end


#######################################################################
# Load into Couchbase
#######################################################################


nav_tree = Map.new(YAML.load_file("#{GROOT}/output/cbu_nav_tree.yml"))


traverse_nav_tree_store_in_cb(nav_tree.nav)

hierarchy = { root: clean_up_hierarchy(nav_tree.nav) }

flat_arr = create_ordered_flattened_hierarchy(nav_tree.nav)
flat_arr.shift

flat_hierarchy = { list: flat_arr }

flat_hierarchy[:list].each do |n|
  puts "[#{n.nav_level}][#{n.nav_order}] - [#{n.link}]"
end

File.open("#{GROOT}/output/cbu_nav_tree_flat.yml", 'w') { |file| file.write(flat_hierarchy.to_yaml) }

CBU.set("docs-nav-tree", hierarchy)
CBU.set("docs-nav-tree-flat", flat_hierarchy)

home = Map.new({
  doctype: "nav",
  subtype: "nav_0",
  nav_type: "markdown",
  nav_level: 0,        
  nav_order: 0,
  nav_title: "Docs Home",
  source: "/home",
  link: "home",
  full_link: "/" + CONTENT_LINK_PREFIX + "/home",
  parent: nil,
	parent_nav_title: nil,
  parent_link: nil,
  parent_full_link: nil,
  ancestors: [],
  ancestors_links: [],
  siblings: [],
  siblings_links: [],
  descendants: [],
  descendants_links: [],
  markdown: (parse_markdown_file("#{CROOT}/home"))[1]
})

CBD.set("home", home)

puts "Done... pause then query view to update indexes"
sleep(2)

print "Query 1..."
pddoc = CBD.design_docs["docs"]
pddoc.nav(stale: false).each do |r|  
end
puts "done"

sleep(2)
print "Query 2..."
pddoc = CBD.design_docs["docs"]
pddoc.nav(stale: false).each do |r|  
end
puts "done"



puts 

exit


