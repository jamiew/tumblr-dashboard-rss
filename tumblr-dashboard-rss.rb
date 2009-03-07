#!/usr/bin/env ruby
#
# tumblr dashboard => RSS generator
# fingers crossed they'll add their own soon <3
# 
# code: http://github.com/jamiew/tumblr-dashboard-rss
#
# @author	Jamie Wilkinson 
# @email 	jamie@internetfamo.us
# @website 	http://jamiedubs.com
#

require 'rubygems'
gem 'mechanize', '>=0.9.0' # new version w/ nokogiri pls!
require 'mechanize'
require 'rss/maker'

## config
email = "you@example.com"
password = "secret"
pages = 3



## mixins
class String
  def strip_html(allowed = ['a','img','p','br','i','b','u','ul','li'])
    str = self.strip || ''
    str.gsub(/<(\/|\s)*[^(#{allowed.join('|') << '|\/'})][^>]*>/,'')
  end
end

## start

# freak out if you haven't set this up yet
raise "You need to set your email & password! Edit this file" if email == 'you@example.com' and password == 'secret'

# login to tumblr
# TODO: load & save cookies
agent = WWW::Mechanize.new
agent.user_agent = "#{email} :: Tumblr Dashboard RSS <http://github.com/jamiew/tumblr-dashboard-rss>"

page = agent.get("http://www.tumblr.com/login")
form = page.form_with(:action => '/login')
form.email = email
form.password = password
agent.submit(form)

## go back to dashboard
posts = []
(1..pages).each { |i|
  i = '' if i == 1 # what we'll grab in the URL (/dashboard/2)
  STDERR.puts "getting page #{i}..."
  page = agent.get("http://www.tumblr.com/dashboard/#{i}")
  start = (i == '' ? 1 : 0)  # 1st post on 1st page isn't a real post

  # hmm. Nokogiri doesn't seem to be having a good time with li.post (just returns the first)
  # fortunately we have li.not_mine; FIXME TODO
  posts += (page/'#posts li.not_mine')
  sleep 2
}

## generate RSS
content = RSS::Maker.make("2.0") { |m|
  m.channel.title = "tumblr dashboard for #{email}"
  m.channel.link = "http://www.tumblr.com/dashboard"
  m.channel.description = "Latest from yr Tumblr Dashboard"
  # m.items.do_sort = true # sort items by date
  
  author = "WHO DAT NINJA" #temp
  posts.each { |post|

    # basic post info
    kind = post['class'].gsub('post','').gsub('is_mine','').split(' ').first
    title = (post/'.post_title a').first.content.strip_html([]) rescue kind
    author = (post/'.post_info a').first.content unless (post/'.post_info a').first.nil? # carry over previous author
    link = (post/'a').last.attributes['href']
    
    # delete things we don't want and extract the remaining stuff as 'content'
    (post/'.post_title').remove
    (post/'.post_info').remove
    (post/'.post_controls').remove
    (post/'table').remove
    (post/'.so_ie_doesnt_treat_this_as_inline').remove
    content = post.to_s.strip
    
    # STDERR.puts "#{kind} post by #{author}, #{title} => #{link}"
    # STDERR.puts "#{content.inspect}"
    # STDERR.puts "---"

    item = m.items.new_item    
    item.title = title
    item.link = link # just use whatever link is first
    item.description = content # ghetto, should strip some stuff
    # i.date = Time.now # they don't give us a time
  }
}

## write to disk
# destination = "tumblr-dashboard-rss.xml"
# File.open(destination,"w") { |f|
#   f.write(content)
# }

## output now
puts "Content-Type: application/rss+xml\n"
puts content

