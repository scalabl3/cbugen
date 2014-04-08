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


#######################################################################
# Clear and Create Development and Production Design Documents
#######################################################################

def reset_design_docs
  puts
  puts "RESET DESIGN DOCS"
  puts

  prod_cbd = Couchbase.new(bucket: 'cbdocs', environment: :production)
	prod_cbu = Couchbase.new(bucket: 'cbu', environment: :production)
	dev_cbd = Couchbase.new(bucket: 'cbdocs', environment: :development)
	dev_cbu = Couchbase.new(bucket: 'cbu', environment: :development)
	
	
	print prod_cbd.environment.to_s + " - "
	p prod_cbd    
	
	print prod_cbu.environment.to_s + " - "
	p prod_cbu
	
	print dev_cbd.environment.to_s + " - "
	p dev_cbd
	
	print dev_cbu.environment.to_s + " - "
	p dev_cbu

  puts


	dddoc_cbd = Map.new(dev_cbd.design_docs)
	dddoc_cbu = Map.new(dev_cbu.design_docs)
  
	pddoc_cbd = Map.new(prod_cbd.design_docs)
	pddoc_cbu = Map.new(prod_cbu.design_docs)

  p "Deleting Design Docs..."
  puts

	dddoc_cbd.each_pair do |name, dd|
    dev_cbd.delete_design_doc(name)
  end

	dddoc_cbu.each_pair do |name, dd|
    dev_cbu.delete_design_doc(name)
  end

  pddoc_cbd.each_pair do |name, dd|
    prod_cbd.delete_design_doc(name)
  end

  pddoc_cbu.each_pair do |name, dd|
    prod_cbu.delete_design_doc(name)
  end

  p "Creating Design Docs..."

  new_ddocs_cbd = Map.new(YAML.load_file("./settings/cbu_cbd_design_docs.yml"))
	new_ddocs_cbu = Map.new(YAML.load_file("./settings/cbu_cbu_design_docs.yml"))

	# Couchbase Docs Bucket Views
  new_ddocs_cbd.ddocs.each do |dd|
		json_doc = Map.new({
      _id: "_design/dev_#{dd.ddname}",
      language: "javascript",
      views: {}
    })
    dd.views.each do |v|
      json_doc.views[v.vname.to_s] = {}
      json_doc.views[v.vname].map = v["map"]
      #json_doc.views[v.vname].reduce = v.reduce if v.reduce? and v.reduce and v.reduce.length > 1
    end
  	dev_cbd.save_design_doc(json_doc)


    json_doc = Map.new({
      _id: "_design/#{dd.ddname}",
      language: "javascript",
      views: {}
    })
    dd.views.each do |v|
      json_doc.views[v.vname.to_s] = {}
      json_doc.views[v.vname].map = v["map"]
      #json_doc.views[v.vname].reduce = v.reduce if v.reduce? and v.reduce and v.reduce.length > 1
    end
  	#dev_cbd.save_design_doc(json_doc)
    prod_cbd.save_design_doc(json_doc)
  end

	# Couchbase CBU Bucket Views
	new_ddocs_cbu.ddocs.each do |dd|
    json_doc = Map.new({
      _id: "_design/dev_#{dd.ddname}",
      language: "javascript",
      views: {}
    })
    dd.views.each do |v|
      json_doc.views[v.vname.to_s] = {}
      json_doc.views[v.vname].map = v["map"]
      #json_doc.views[v.vname].reduce = v.reduce if v.reduce? and v.reduce and v.reduce.length > 1
    end
		dev_cbu.save_design_doc(json_doc)
    json_doc = Map.new({
      _id: "_design/#{dd.ddname}",
      language: "javascript",
      views: {}
    })
    dd.views.each do |v|
      json_doc.views[v.vname.to_s] = {}
      json_doc.views[v.vname].map = v["map"]
      #json_doc.views[v.vname].reduce = v.reduce if v.reduce? and v.reduce and v.reduce.length > 1
    end
		prod_cbu.save_design_doc(json_doc)
  end

	puts
	
end

reset_design_docs   