require 'rubygems'
require 'rails'
require 'couchbase' 
require 'map'
require 'json'

#######################################################################
# Create Couchbase Connection
#######################################################################

CBD = Couchbase.new(bucket: 'cbdocs')
CBU = Couchbase.new(bucket: 'cbu')


json = File.read('./cbu_videos_general.json')
videos = Map.new(JSON.parse(json))

videos.samples.each_pair do |k,v|
	CBU.set(k, v)
end

json = File.read('./cbu_videos_training.json')
videos = Map.new(JSON.parse(json))

videos.samples.each_pair do |k,v|
	CBU.set(k, v)
end


json = File.read('./cbu_sample_questions.json')
questions = Map.new(JSON.parse(json))

CBU.set("q::count", questions.count)

questions.samples.each_with_index do |q, i|
	t = (Time.now - (5 + i).days)
	q.created_at = t.to_i
	q.updated_at = (Time.now - 1.day - i.hour).to_i
	CBU.set("q::#{q.id}", q)
end 

prod_cbu = Couchbase.new(bucket: 'cbu', environment: :production)
pddoc_cbu = Map.new(prod_cbu.design_docs)

puts "Data Loaded, Query all Views..."
pddoc_cbu["content"].views.each do |v|
	view = pddoc_cbu["content"].send(v)
	view.each do |r|
		#puts r.id
	end
end

pddoc_cbu["content"].views.each do |v|
	view = pddoc_cbu["content"].send(v)
	view.each do |r|
		#puts r.id
	end
end