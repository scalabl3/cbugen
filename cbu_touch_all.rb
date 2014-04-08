require 'map'
require 'couchbase'

CBD = Couchbase.new(bucket: "cbdocs", :quiet => true)
CBU = Couchbase.new(bucket: "cbu", :quiet => true)

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