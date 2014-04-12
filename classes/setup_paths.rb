module SetupPaths
	def setup_paths		
		Dir.chdir(@cbugen_root)
		@@root_cbugen = Dir.pwd
		@@content_orig = "#{@@root_cbugen}/docs-source"
		@@content_cbu = "#{@@root_cbugen}/docs-transform"
		@@gen_output = "#{@@root_cbugen}/output"
		@@settings = "#{@@root_cbugen}/settings"
	end
end