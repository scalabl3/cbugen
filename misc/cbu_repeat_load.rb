loop do   
  cbu = "ruby cbu_load_cb.rb"
  10.times do puts end
  puts "RUNNING LOADUP -- #{Time.now.to_i}"
  puts "OUTPUT"   
  output = `#{cbu}`
  puts output
  sleep(10)
end