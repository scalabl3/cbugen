
class TreeGenerator
	
  attr_accessor :folder_root,
								:folder_content,
								:folder_output,
								:filepath_substitutions,
								:substitutions,
								:content_prefix, 
								:force_overwrite_navigation_yml, 
								:force_overwrite_assets_yml


	def initialize(root_folder, options = {})
		setup_defaults
		
		current_folder = "."
		Dir.chdir(current_folder)
		CBU_ROOT = Dir.pwd

		:substitutions = Map.new(YAML.load_file("#{CBU_ROOT}/settings/cbu_substitutions.yml"))

		content_root = "../docs-ng/source_content"
		Dir.chdir(content_root)
		CROOT = Dir.pwd

	end
	
	def setup_defaults
		:force_overwrite_navigation_yml = false
		:force_overwrite_assets_yml = false
		:content_prefix = "d"
	end
	
	####################################################################################################
	# Execute All Traversals
	####################################################################################################

	def process_content
		nav_tree = Map.new
		nav_tree.nav = {}
		nav_tree.nav.source_path = CROOT
		nav_tree.nav.nav_level = 0
		nav_tree.nav.nav_type = "root"
		nav_tree.nav.navigation_yml = (File.exists? (CROOT + "/navigation.yml"))
		nav_tree.nav.index_erb = (File.exists? (CROOT + "/index.erb"))							 
			
		items = traverse_folders(1, nil, "", "", CROOT)

		nav_tree.nav.children = {}
		nav_tree.nav.children.count = items.size
		nav_tree.nav.children.items = items

		File.open("#{CBU_ROOT}/output/cbu_nav_tree.yml", 'w') { |file| file.write(nav_tree.to_yaml) }
		File.open("#{CBU_ROOT}/output/cbu_tree.json", 'w') { |file| file.write(nav_tree.to_json) }

		generate_navigation_yml(nav_tree.nav, force_overwrite_navigation_yml)
		generate_assets_yml(nav_tree.nav, force_overwrite_assets_yml)
		align_navigation_yaml_with_index_erb(nav_tree.nav) if force_overwrite_navigation_yml

		items = traverse_nav_markdown(nav_tree.nav)
		nav_tree.nav.children.count = items.size
		nav_tree.nav.children.items = items
		puts "ERROR: Something is WRONG, items.size = 0!" if items.size == 0

		items = traverse_sort_and_add_nav_order_to_nodes(nav_tree.nav)
		nav_tree.nav.children.items = items

		# compute all nodes ancestry, descendants and siblings
		nav_tree.nav = traverse_ancestry_descendants_siblings(nav_tree.nav)

		#ap nav_tree

		####################################################################################################
		# Output nav_tree yaml file for cbu_loadup.rb to Load content into Couchbase
		####################################################################################################

		File.open("#{CBU_ROOT}/output/cbu_nav_tree.yml", 'w') { |file| file.write(nav_tree.to_yaml) }
		File.open("#{CBU_ROOT}/output/cbu_nav_tree.json", 'w') { |file| file.write(nav_tree.to_json) }
  
	end
	
	
	
	####################################################################################################
	# Traverse Folder Structure of Source Content and Create Tree 
	####################################################################################################

	def traverse_folders(nav_level, parent, parent_link, parent_full_link, node_folder_path) 

		node_list = []
	
		#puts "traverse_folders(#{nav_level.to_s}, #{parent}, #{node_folder_path})"
	
		subfolders = nil
		begin
			subfolders = Dir.entries(node_folder_path).select {|entry| File.directory? File.join(node_folder_path, entry) and !(entry == '.' || entry == '..' || entry == 'assets' || entry == 'images') }
		rescue Errno::ENOENT
			puts "ERROR: No File or Directory [#{node_folder}]"
			puts puts
			exit
		end	 
		
		subfolders.each do |folder|
			node = Map.new

			sub_path = node_folder_path + "/" + folder
		
			link = (parent_link.length == 0 ? "" : parent_link + "/" ) + folder
			full_link =	 (parent_full_link.length == 0 ? "/" : parent_full_link + "/" ) + folder
				
			node = Map.new({
				doctype: "nav",
				subtype: "nav_" + nav_level.to_s,
				nav_type: (File.exist?("#{sub_path}/../#{folder}.markdown") ? "folder+markdown" : "folder"),
				nav_level: nav_level,
				nav_order: 9000,
				nav_title: process_navigation_name(folder),			 
				source: folder,
				link: link,
				full_link: full_link,
				parent: parent,
				parent_nav_title: process_navigation_name(parent_link),
				parent_link: parent_link,
				parent_full_link: parent_full_link,
				parent_path: node_folder_path,
				source_path: sub_path,
				ancestors: [],
				ancestors_links: [],
				siblings: [],
				siblings_links: [],
				descendants: [],
				descendants_links: [],
				navigation_yml: (File.exists? (sub_path + "/aaaa-navigation.yml")),
				index_erb: (File.exists? (sub_path + "/index.erb"))
			})
				
			items = traverse_folders(nav_level + 1, folder, link, full_link, sub_path)
		
			if items.size > 0
				 node.children = {}
				 node.children.count = items.size
				 node.children.items = items
			end
		
			node_list << node
		end
	
		node_list
	 
	end 




	####################################################################################################
	# Traverse Folder Structure of Source Content and Generate navigation.yml files
	####################################################################################################

	def generate_navigation_yml(node, force = true)

		# traverse subfolders, go deep
		if node_has_children(node)
			 node.children.items.each_with_index do |child|
				 generate_navigation_yml(child, force)
			 end
		end	 
		
		if force or !File.exists?("#{node.source_path}/aaaa-navigation.yml")
		
			naml = Map.new({ 
				common_metadata: {
					tags: [ "couchbase" ]
				},
				nav_items: [] 
			})

			subfolders = nil
			if node.source_path?		
				subfolders = Dir.entries(node.source_path).select {|entry| File.directory? File.join(node.source_path, entry) and !(entry == '.' || entry == '..' || entry == 'assets' || entry == 'images') }
			else
				 ap node
				 puts "ERROR: Missing \"source_path\" in node"
				 exit
			end			 
		
			markdowns = Dir.glob("#{node.source_path}/*.markdown")
		
			# add each markdown to the collection
			markdowns.each do |md|
			
				source = md.gsub(/#{node.source_path}\//, "").gsub(/.markdown/, "")
			
				item = Map.new({
					source: source,
					type: "markdown",
					nav_title: process_navigation_name(source),
					content_footers: nil
				})
				naml.nav_items << item unless md.start_with? "aaab-"
			end
		
			# add each folder to the collection
			subfolders.each do |sf|
				item = Map.new({
					source: sf,
					type: "folder",
					nav_title: process_navigation_name(sf),
					content_footers: nil
				})
				naml.nav_items << item 
			end		 
		
			naml_yaml = naml.to_yaml.gsub(/^(- )/, "\n- ")
		
			# write out navigation.yml file...
			File.open("#{node.source_path}/aaaa-navigation.yml", 'w') { |file| file.write(naml_yaml) }
		
			#ap naml
		end
	end



	####################################################################################################
	# Traverse Folder Structure of Source Content and Generate assets.yml files
	####################################################################################################

	def generate_assets_yml(node, force = true)

		# traverse subfolders, go deep
		if node_has_children(node)
			 node.children.items.each_with_index do |child|
				 generate_assets_yml(child, force)
			 end
		end 
	
		if force or !File.exists?("#{node.source_path}/aaaa-assets.yml")
		
			aaml = Map.new({ asset_items: [] })

			image_subfolder = nil
			if node.source_path?		
				image_subfolder = Dir.entries(node.source_path).select {|entry| File.directory? File.join(node.source_path, entry) and (entry == 'images') }
			else
				 ap node
				 exit
			end
		 
			if image_subfolder
			
				images = []
				images.concat Dir.glob("#{node.source_path}/images/*.png")
				images.concat Dir.glob("#{node.source_path}/images/*.jpg")
				images.concat Dir.glob("#{node.source_path}/images/*.jpeg")
				images.concat Dir.glob("#{node.source_path}/images/*.gif")
					
				images.each do |image_path|
			
					source = node.full_link + image_path.gsub(/#{node.source_path}/, "")
					file = source[source.rindex("/") + 1..-1]
					title = file[0..file.rindex(".") - 1].gsub(/_/, " ")
				
					item = Map.new({
						type: "image",
						#source: source,
						#link: "/images" + source,
						file: file,
						img_alt: process_navigation_name(title),
						img_caption: nil,
						img_tooltip_text: nil 
					})
					aaml.asset_items << item
				end
			
				if images.size > 0
							
					aaml_yaml = aaml.to_yaml.gsub(/^(- )/, "\n- ")
		
					# write out navigation.yml file...
					File.open("#{node.source_path}/aaaa-assets.yml", 'w') { |file| file.write(aaml_yaml) }
				
					#ap aaml 
				end
		
			end
		end
	end




	####################################################################################################
	# Traverse and make navigation.yml match index.erb order (if exists)
	####################################################################################################

	def align_navigation_yaml_with_index_erb(node)
				
			# traverse subfolders, go deep
			if node_has_children(node)
				 node.children.items.each_with_index do |child|
					 align_navigation_yaml_with_index_erb(child)
				 end
			end
		
			has_index_erb = File.exist?("#{node.source_path}/index.erb")
			has_navig_yml = File.exist?("#{node.source_path}/aaaa-navigation.yml")
		
			# load aaaa-navigation.yml
			naml = Map.new(YAML.load_file("#{node.source_path}/aaaa-navigation.yml"))
		
			erb_markdowns = []
		
			# load index.erb
			if has_index_erb
			 
				f = File.readlines("#{node.source_path}/index.erb")	 
				f.delete_if { |line| !line.start_with?("<%= include_item") }	
			 
				erb_markdowns = []
			 
				f.each_with_index do |item, i|
					source_path = nil		 
					if match = item.match(/([\'])([\w\-\/.]+)([\'])/)
					 x, source, y = match.captures
					else
					 #puts "NO MATCH - [#{item}]"
					end

					hierarchy = source.split("/")

					snav = Map.new({						
					 source: hierarchy.last,
					 parents: (hierarchy.pop;hierarchy),
					 nav_order: i
					})	

					erb_markdowns << snav
				end
		
				# iterate and re-order navigation.yml
				sort_nav_items = naml.dup.nav_items
		
				sort_nav_items.each_with_index do |n, i| 
					n.nav_order = i + 1000
				end
		
				erb_markdowns.each_with_index do |erb, i|
					sort_nav_items.each do |n| 
						n.nav_order = i if erb.source == n.source
					end
				end
		
				sort_nav_items.sort! { |x, y| x.nav_order <=> y.nav_order }
		
				sort_nav_items.each_with_index do |n, i| 
					n.nav_order = i + 1
				end 
			
				# copy re-ordered nav_items back
				naml.nav_items = sort_nav_items
		
				# write the changes to disk
				naml_yaml = naml.to_yaml.gsub(/^(- )/, "\n- ")
		
				# write out navigation.yml file...
				File.open("#{node.source_path}/aaaa-navigation.yml", 'w') { |file| file.write(naml_yaml) }
		end
	end		



	def modify_existing_navigation_yml(node)
				
		# traverse subfolders, go deep
		if node_has_children(node)
			 node.children.items.each_with_index do |child|
				 modify_existing_navigation_yml(child)
			 end
		end
	
		has_navig_yml = File.exist?("#{node.source_path}/aaaa-navigation.yml")
	
		# load aaaa-navigation.yml
		naml = Map.new(YAML.load_file("#{node.source_path}/aaaa-navigation.yml"))
	
		naml_yaml = naml.to_yaml.gsub(/^(- )/, "\n- ")
	
			# write out navigation.yml file...
		File.open("#{node.source_path}/aaaa-navigation.yml", 'w') { |file| file.write(naml_yaml) }
	
	end		


	####################################################################################################
	# Traverse Folder Structure of Source Content and Add Markdown Files to Child Nodes
	####################################################################################################

	def traverse_nav_markdown(node)
	
		# traverse subfolders, go deep
		if node_has_children(node)
			 node.children.items.each_with_index do |child|

				 items = traverse_nav_markdown(child)
				 child.children = Map.new unless child.children?
				 child.children.count = 0 unless child.children.count?
				 child.children.items = [] unless child.children.items?
		 
				 child.children.count = items.size
				 child.children.items = items				

			 end
		end
	
		node_list = nil
		if node.children? and node.children.items?
			node_list = node.children.items
		end
	
		markdowns = Dir.glob("#{node.source_path}/*.markdown")
	
		# if we are at the root node (content source), don't process markdowns here (home.markdown handled separately, special)
		markdowns = [] if node.nav_level == 0
	

		if markdowns.size > 0 and node.nav_level > 0

			#puts
			#puts "#{node.source} - #{node.children?}"
			node.children = Map.new unless node.children?
			node.children.count = 0 unless node.children.count?
			node.children.items = [] unless node.children.items?
			#puts "#{node.source} - #{node.children?} - #{node.children.count?}"
		
			node_list = node.children.items
			
			markdowns.each do |md|						
				source = md.gsub(/#{node.source_path}\//, "").gsub(/.markdown/, "")
			
				is_cbdoc_special_file = source.start_with? "aaab-"
			
				unless is_cbdoc_special_file				
				
					if node.link?
						link = node.link + "/" + source 
					else		 
						node.link = "undefined"
						puts node.nav_type
						exit
					end
				
					source_path = node.source_path + "/" + source			 

					is_markdown_and_folder = (File.exist?("#{source_path}") && File.directory?("#{source_path}"))
			
					unless is_markdown_and_folder		 
					
						full_link = (node.link.start_with?("/#{CONTENT_LINK_PREFIX}/") ?	link : "/#{CONTENT_LINK_PREFIX}/" + link )
						parent_path = node.source_path
						parent_full_link = (node.link.start_with?("/#{CONTENT_LINK_PREFIX}/") ?	 node.link : "/#{CONTENT_LINK_PREFIX}/" + node.link )
				
						item = Map.new({
							doctype: "nav",
							subtype: "nav_" + (node.nav_level + 1).to_s,
							nav_type: "markdown",
							nav_level: node.nav_level + 1,				
							nav_order: 9000,
							nav_title: process_navigation_name(source),
							source: source,
							link: link,
							full_link: full_link,
							parent: node.source,
							parent_nav_title: node.nav_title,
							parent_link: node.link,
							parent_full_link: parent_full_link,
							parent_path: parent_path,
							source_path: source_path,
							ancestors: [],
							ancestors_links: [],
							siblings: [],
							siblings_links: [],
							descendants: [],
							descendants_links: []				 
						})
					
						node_list << item                 
					end		 
				end
			end		 
		end
	
		#ap node_list
	
		node_list
	end
                
	
	####################################################################################################
	# Traverse Folder Structure of Source Content and Sort Child Nodes by navigation.yml ordering
	####################################################################################################

	def traverse_sort_and_add_nav_order_to_nodes(node)
	
		# traverse subfolders, go deep
		if node_has_children(node)
		
			 node.children.items.each_with_index do |child|
				 if child.nav_type == "folder" || child.nav_type == "folder+markdown"
					 items = traverse_sort_and_add_nav_order_to_nodes(child)
					 child.children.items = items if items and items.size > 0
				 end
			 end
		 
		end	 
	
		has_navig_yml = File.exist?("#{node.source_path}/aaaa-navigation.yml")
	
		if has_navig_yml and node.children and node.children.items?
	
		else
			return nil		
		end 
	
		sorted_nav_items = nil
	
		if node.children? and node.children.items?
			sorted_nav_items = node.children.items
		end
	
		if File.exists?("#{node.source_path}/aaaa-navigation.yml")
			# load aaaa-navigation.yml
			naml = Map.new(YAML.load_file("#{node.source_path}/aaaa-navigation.yml"))		
	
			# iterate and re-order navigation.yml
			sorted_nav_items = node.children.items

			sorted_nav_items.each_with_index do |sni, i| 
				sni.nav_order = i + 1000
			end

			naml.nav_items.each_with_index do |naml_item, i|
				sorted_nav_items.each do |sni| 
					sni.nav_order = i if sni.source == naml_item.source
				end
			end

			sorted_nav_items.sort! { |x, y| x.nav_order <=> y.nav_order }

			sorted_nav_items.each_with_index do |sni, i| 
				sni.nav_order = i + 1
			end																																	 
		end
	
		sorted_nav_items
	end

	####################################################################################################
	# Compute a given node's ancestry and immediate descendants
	####################################################################################################

	def compute_ancestry(node)

		# compute ancestry and ancestry links
		if node.nav_level > 0
		
			ancestors = node.link.split("/")
			ancestors.pop
			ancestors_links = []
	
	
			alink = node.link.dup
			while alink.index("/")
				ancestors_links << alink.dup
				alink = alink[0..(alink.rindex("/") - 1)]
			end			 
			ancestors_links << alink.dup
	
			ancestors_links.reverse!.pop
	
		end
	
		node.ancestors = ancestors.uniq if ancestors
		node.ancestors_links = ancestors_links.uniq if ancestors
	
		return node
	end

	def compute_descendants(node)
	
		# compute descendants and descendant links
		descendants = []
		descendants_links = []
	
		if node_has_children(node)
		
			node.children.items.each do |child|
				descendants << child.source.dup
				descendants_links << child.link.dup			 
			end
		
		end
	
		node.descendants = descendants.uniq
		node.descendants_links = descendants_links.uniq
	
		return node
	end

	def compute_siblings_for_children(node)

		if node_has_children(node)
		
			siblings = []
			siblings_links = []
		
			node.children.items.each do |child|
				siblings << child.source
				siblings_links << child.link
			end
		
			node.children.items.each do |child|
				child.siblings = siblings.uniq
				child.siblings_links = siblings_links.uniq
			end		 
		
		end
	
		return node
	end

	####################################################################################################
	# Traverse Folder Structure and add ancestry and descendant info
	####################################################################################################

	def traverse_ancestry_descendants_siblings(node)
	
		node = compute_ancestry(node)
		node = compute_descendants(node)
		node = compute_siblings_for_children(node)
	
		# traverse descendants
		if node_has_children(node)
		
			 node.children.items.each do |child|			
					 child = traverse_ancestry_descendants_siblings(child)				 
			 end
		 
		end	 
	
		return node
	end

	
	#######################################################################
	# Utility functions
	#######################################################################

	
	def process_navigation_name(folder_root)
		#folder_root.gsub(/-/, ' ').split.map(&:capitalize).join(' ').gsub(/Net/, '.Net').gsub(/Php/, 'PHP').gsub(/Sdk/, 'SDK')
	
		p = folder_root.dup.gsub(/-/, ' ').split.map(&:capitalize).join(' ')
	
		p_words = p.split(" ")
	
		# first pass substitutions
		:substitutions.firstpass.each do |s|
			sw = s.originals.split(" ")
			sw.each do |w|
				p_words.each { |pw| pw.gsub! /#{w}/, s.target }
			end
		end

		# join words for multi-word substitutions
		p = p_words.join(' ')
	
		# second pass substitutions
		:substitutions.secondpass.each do |s|
			p.gsub! /#{s.original}/, s.target
		end

		# split words again for individual word substitutions
		#p_words = p.split(" ")	 

		# lowercase
		:substitutions.lowercase.split(" ").each do |w|
			p.gsub! /\b#{w}\b/, w.downcase unless p.start_with?(w) 
		end
	
		#p = p_words.join(' ')
	
		p
	end
	
	def node_has_children(node)
		if node.children? and node.children.count? and node.children.count > 0 and node.children.items? and node.children.items
			true
		else
			false
		end
	end 
	
end