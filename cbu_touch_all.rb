require 'map'
require 'couchbase'

Dotenv.load ".env"
CB_SERVERS=ENV['cbu_couchbase_servers'].split(",")

CBD = Couchbase.new(node_list: CB_SERVERS, bucket: 'cbdocs')
CBU = Couchbase.new(node_list: CB_SERVERS, bucket: 'cbu')

require '../university.couchbase.com/app/models/docs_nav_tree.rb'
require '../university.couchbase.com/app/models/render_nav_tree.rb'

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