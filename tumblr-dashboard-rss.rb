#!/usr/bin/env ruby
#
# tumblr dashboard => RSS generator
#
# @author	Jamie Wilkinson 
# @email 	jamie@internetfamo.us
# @website 	http://jamiedubs.com
require 'rubygems'
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
# TODO save & load cookies
agent = WWW::Mechanize.new
agent.get("http://www.tumblr.com/login")
form = agent.page.forms[0]
form.email = email
form.password = password
agent.submit(form)

## go back to dashboard
posts = []
(1..pages).each { |i|
  i = '' if i == 1
  print "getting page #{i}..."
  agent.get("http://www.tumblr.com/dashboard/#{i}")
  start = (i == '' ? 1 : 0)  # 1st post on 1st page isn't a real post
  posts += agent.page.search('#posts li.post')[start..-1]
  sleep 2
}

## generate RSS
content = RSS::Maker.make("2.0") { |m|
  m.channel.title = "tumblr dashboard for #{email}"
  m.channel.link = "http://www.tumblr.com/dashboard"
  m.channel.description = "Latest from yr tumblr feed"
  # m.items.do_sort = true # sort items by date
  
  posts.each { |post|
    i = m.items.new_item
    title = post.search('.username').innerHTML.strip_html([]).gsub(/:$/,'')
    puts "post by #{title}"
    i.title = title
    i.link = post.search('a')[0].attributes['href'] # just use whatever link is first
    i.description = post.search('.post_container') # ghetto, should strip some stuff
    # i.date = Time.now # they don't give us a time, bastards
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

