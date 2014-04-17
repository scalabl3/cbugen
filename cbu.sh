git submodule update
rm -f output/*.json
rm -f output/*.yml
rm -rf docs-transform
ruby cbu_folder_moves.rb
ruby cbu_buckets_and_views.rb
ruby cbu_generate_nav.rb
ruby cbu_load_markdown_in_cb.rb
ruby cbu_render_and_cache.rb
