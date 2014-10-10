require "coffee-script/register"
require "colors"

path 		= require "path"
fs 			= require "fs"
_ 			= require 'lodash'
When 		= require "when"
async 		= require "async"
moment 		= require "moment"
gm			= require 'gm'
imagemagick = require 'imagemagick'


#use first param as dir
image_dir = process.argv[2] ? './'
#use second param as output filename
output_filename = (process.argv[3] ? moment().format('YYYY-MM-DD-hh-mm-ss'))
#add .gif if it doesn't have it
output_filename += ".gif" if not /\.gif$/.test(output_filename)

#gif settings
settings =
	delay: 10
	width: 900
	height: 600

#to parse camera filename
filename_regex = /\d+-\d+-Rebel_(\d+)\.(\w{3})/





resize = (src, dest, cb=null) ->
	gm(src)
	.resize settings.width, settings.height
	.noProfile()
	.crop settings.width, settings.height, 0, 0
	.write dest, (err) ->
		cb err, dest



#feed me images
compileGif = (frames=[], reverse=false, cb=null) ->
	#lets it cycle back in reverse
	if reverse
		frames = frames.concat( frames[1..].reverse()[1..] )

	params = [
		"-loop", 0,
		"-size", "#{settings.width}x#{settings.height}"
		"-deconstruct",
		"-layers", "optimize",
		"-layers", "remove-zero"
		"-delay", settings.delay
	]
	#add frames
	_.each frames, (f, i) ->
		params.push f

	#append output filename
	params.push path.join(image_dir, output_filename)

	imagemagick.convert params, (err, stdout) ->
		console.log err, stdout
		cb err


findFrames = (dir) ->
	imgs = []
	#autoload route files
	fs.readdirSync(dir).forEach (file) ->
		file_path = path.join(dir, file)
		name = path.basename(file, path.extname(file))
		stats = fs.statSync file_path
		return if (/^index\./.test(file)) or (/^\./.test(file)) or !stats.isFile()
		imgs.push(file_path) if filename_regex.test(file)

	imgs


run = ->
	#get images in dir
	frames = findFrames image_dir
	#resize each image
	async.map frames, (frame, next) ->
		filename = path.basename frame
		#make a new name, forcing png encoding
		newname = filename.replace filename_regex, "frame$1.png"
		newpath = frame.replace filename, newname
		#resize
		resize frame, newpath, next
	#all done
	, (err, resized_frames) ->
		sorted_frames = resized_frames.sort()
		#compile the gif now
		compileGif sorted_frames, true, (err) ->
			console.error(err) if err?
			console.log "ALL DONE!".rainbow
			process.exit 0


#do it
run()