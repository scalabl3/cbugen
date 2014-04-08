require 'rubygems'
require 'couchbase'
require 'elasticsearch'
require 'json'
require 'yaml'
require 'httparty'

class CbuSystemSetup
	
	attr_accessor :node_list, :user, :password, :bucket_cbu_docs, :bucket_cbu_content, :bucket_cbu_users
	
	def initialize(options = {})
	
	
		:user ||= "Administrator"
		:password ||= "asdfsadf"
		:bucket_cbu_docs ||= "cbu_docs"
		:bucket_cbu_content ||= "cbu_content"
		:bucket_cbu_users ||= "cbu"
		
	end
	
	def setup_buckets
		
	end
	
	def delete_buckets
  	begin
	    cb_cluster = Couchbase::Cluster.new({ username: "Administrator", password: "asdfasdf"})
	    cb_cluster.delete_bucket("cbdocs")
	  rescue Couchbase::Error::HTTP

	  end  
	end
	
	def create_views
		
	end
	
end
