require 'awesome_print'
require 'dotenv'
Dotenv.load            

require './classes/setup_buckets.rb'
require './classes/setup_paths.rb'

require './classes/couchbase_university_setup.rb'


cbus = CouchbaseUniversitySetup.new({
	    	cb_node_list: ENV['cbu_couchbase_servers'].split(","),
				cb_admin_user: ENV['cbu_couchbase_server_user'],
				cb_admin_pass: ENV['cbu_couchbase_server_pass'],
				content_link_prefix: ENV['cbu_content_link_prefix'],
				cb_rails_root: ENV['cbu_rails_root'],
				cbugen_root: Dir.pwd
			})


cbus.to_s