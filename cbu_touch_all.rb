require 'map'
require 'couchbase'

Dotenv.load ".env"
CB_IP=ENV['cbu_couchbase_servers'].split(",")
CB_SERVERS=[]
CB_IP.each do |ip|
	CB_SERVERS << "http://#{ip}"
end

CBD = Couchbase.new(node_list: CB_SERVERS, bucket: 'cbdocs')
CBU = Couchbase.new(node_list: CB_SERVERS, bucket: 'cbu')

require "#{ENV['cbu_rails_root']}/app/models/docs_nav_tree.rb"
require "#{ENV['cbu_rails_root']}/app/models/render_nav_tree.rb"

DocsNavTree.generate
RenderNavTree.generate

l = DocsNavTree.links_only.last
d = CBD.get(l)


DocsNavTree.links_only.each do |l|
	doc = CBD.get(l)
	CBD.delete(l)
	CBD.set(l, doc)
end

CBD.set(l, d)