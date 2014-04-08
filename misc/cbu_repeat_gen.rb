loop do   
  cbu = "ruby cbu_generate_nav.rb"
  10.times do puts end
  puts "RUNNING GEN -- #{Time.now.to_i}"
  puts "OUTPUT"   
  output = `#{cbu}`
  puts output
  sleep(3)
end