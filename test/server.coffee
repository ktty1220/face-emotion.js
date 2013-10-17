#!/usr/bin/env coffee

fs = require 'fs'
http = require 'http'
path = require 'path'
url = require 'url'

require 'blanket'
open = require 'open'
coffee = require 'coffee-script'
watch = require 'node-watch'

require "../js/#{js}" for js in fs.readdirSync '../js' when /^(?!.*\.min).+\.js$/.test js

port = Number(process.argv[2] ? 3000)
mime =
  html: 'text/html'
  js: 'aplication/javascript'
  css: 'text/css'
http.createServer (req, res) ->
  ui = url.parse req.url, true
  file = ui.pathname
  file = '/test/test.html' if file is '/test/'
  file = "..#{file}"
  unless fs.existsSync file
    res.writeHead 404
    res.end 'NotFound'
    return
  res.writeHead 200, 'Content-Type': mime[path.extname(file).substr 1]
  res.end fs.readFileSync file, 'utf-8'
.listen port

cfs = ("../js/#{cf}" for cf in fs.readdirSync '../js' when /\.coffee$/.test cf)
cfs.push 'test.coffee'
watch cfs, (filename) ->
  js = filename.replace /\.coffee$/, '.js'
  try
    input = fs.readFileSync filename, 'utf-8'
    output = coffee.compile input, header: true
    fs.writeFileSync js, output, 'utf-8'
    console.log "#{new Date()} compiled #{filename}"
  catch e
    coffee.helpers
    color = process.stdout.isTTY and not process.env.NODE_DISABLE_COLORS
    message = coffee.helpers.prettyErrorMessage e, filename, input, color
    console.log "\n#{message}"

console.log '### QUnit Server ###'
#open "http://localhost:#{port}/test/"
