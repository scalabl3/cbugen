require 'rubygems'
require 'rails'
require 'pp'
require 'awesome_print'
require 'base64'
require 'parallel'

require 'yaml'
require 'json'
require 'multi_json'
require 'map'

require 'httparty'
require 'chronic' 
require 'map'

require 'nokogiri'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

require 'elasticsearch'
require 'couchbase'


class CouchbaseUniversitySetup
	include SetupBuckets
	include SetupPaths
	
	@@cbd = nil
	@@cbu = nil
	
	attr_accessor :cb_node_list, :cb_admin_user, :cb_admin_pass, 
								:content_link_prefix, :cbu_rails_root, :cbugen_root
	
	
	def initialize(attr={})
		load_parameter_attributes(attr)		
		@@cbd = Couchbase.new(node_list: @cb_node_list, bucket: 'cbdocs')
		@@cbu = Couchbase.new(node_list: @cb_node_list, bucket: 'cbu')
		setup_paths
	end
	
	# generic attribute loader
  def load_parameter_attributes(attributes = {})
    if !attributes.nil?
      attributes.each do |name, value|
        setter = "#{name}="
        next unless respond_to?(setter)
        send(setter, value)
      end
    end
  end
	
	def to_s
		puts "CouchbaseUniversitySetup"
	  ap self
		puts "@@root_cbugen = #{@@root_cbugen}"
		puts "@@content_orig = #{@@content_orig}"
		puts "@@content_cbu = #{@@content_cbu}"
		puts "@@gen_output = #{@@gen_output}"
		puts "@@settings = #{@@settings}"
	end
end