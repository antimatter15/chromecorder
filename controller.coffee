#note, not processing.js as in the implementation of processing in js

frames = chrome.extension.getBackgroundPage().frames

dataURLtoCanvas = (dataURL, callback) ->
	img = new Image()
	canvas = document.createElement 'canvas'
	# canvas = document.getElementById 'preview'
	ctx = canvas.getContext '2d'
	img.src = dataURL
	img.onload = ->
		canvas.width = img.width
		canvas.height = img.height
		ctx.drawImage img, 0, 0
		callback canvas, img, ctx


blocks = []


compositeTiles = (root, blocks) ->
	index = []
	canvas = document.createElement 'canvas'

	ctx = canvas.getContext '2d'
	canvas.width = root.w
	canvas.height = root.h
	ctx.fillStyle = '#007fff'
	ctx.fillRect 0, 0, canvas.width, canvas.height

	for {frame, offsetX, offsetY, w, h, fit, subsets, isSubset} in blocks
		data = imageDataCache["frame-#{frame}-#{offsetX}-#{offsetY}-#{w}-#{h}"]
		delete imageDataCache["frame-#{frame}-#{offsetX}-#{offsetY}-#{w}-#{h}"]
		# w = Math.min(w, data.width - offsetX)
		# h = Math.min(h, data.height - offsetY)
		# ctx.drawImage image, offsetX, offsetY, w, h, fit.x, fit.y, w, h
		ctx.putImageData data, fit.x, fit.y
		unless isSubset
			#this is actually a hack so that we can put fun stuff in the extra space
			index.push {
				f: frame,
				sX: fit.x, #sourceX
				sY: fit.y, #sourceY
				bX: offsetX, #blitX
				bY: offsetY, #blitY
				w,
				h
			}
		if subsets
			for {frame, w, h, coords, offsetX, offsetY} in subsets
				index.push {
					f: frame,
					sX: fit.x + coords[0], #sourceX
					sY: fit.y + coords[1], #sourceY
					bX: offsetX, #blitX
					bY: offsetY, #blitY
					w,
					h
				}
	preview = document.getElementById 'preview'
	[preview.width, preview.height] = [canvas.width, canvas.height]
	preview = preview.getContext '2d'
	preview.drawImage canvas, 0, 0
	index = index.sort((a, b) -> a.f - b.f)
	finalize canvas, index, denseIndex(index, [canvas.width, canvas.height])


postProcessing = ->
	blockSearch (reduced) ->
		console.time("box packing")
		[root, blocks] = boxPacking(reduced)
		console.timeEnd("box packing")
		console.time("compositing")
		compositeTiles(root, blocks)
		console.timeEnd("compositing")
		# applyBlockImageTransform blocks, (block, ctx, img) ->
		# 	block.image = img
		# , ->
		# 	compositeTiles(root, blocks)


imageDataCache = {}

blockSearch = (callback) ->
	blocks = blocks.sort sorts.area
	#sort em first so that the bigger pieces get removed first
	#or is this backwards? should the smaller pieces be removed first
	transport = []

	worker = new Worker("searchworker.js")
	worker.onmessage = (e) ->
		if typeof e.data == "number"
			document.getElementById('search').value = e.data
		else if typeof e.data == "object" and e.data.pop
			callback e.data
		else
			console.log e.data
	console.time("getting image data")
	
	for b in blocks
		transport.push b.pixels

	worker.webkitPostMessage blocks, transport

	# applyBlockImageTransform blocks, (block, ctx, img) ->
	# 	{offsetX, offsetY, w, h, frame} = block
	# 	data = ctx.getImageData(offsetX, offsetY, w, h)
	# 	# console.log(typeof data.data)

	# 	buf = (new Uint8ClampedArray(data.data)).buffer
	# 	transport.push buf
	# 	block.pixels = buf
	# 	imageDataCache["frame-#{frame}-#{offsetX}-#{offsetY}-#{w}-#{h}"] = data
	# , ->
	# 	console.timeEnd("getting image data")
	# 	# console.log "posting a message", transport, blocks
	# 	worker.webkitPostMessage blocks, transport
	# # blockDeduplication(blocks)
	return

applyBlockImageTransform = (blocks, transform, callback) ->
	#this is partly inefficient, because it's like O(n^2)
	#but the values of n are low enough (hundreds or less)
	#that it makes virtually no impact, but remains some
	#place for optimization
	frame = 0
	lastImage = null
	lastContext = null
	checkFrame = ->
		for block in blocks
			if block.frame is frame
				transform block, lastContext, lastImage
		frame++
		nextFrame()

	nextFrame = ->
		if frame >= frames.length
			callback()
			return
		if frames[frame] != ""
			dataURLtoCanvas frames[frame], (canvas, img, ctx) ->
				lastContext = ctx
				lastImage = img
				checkFrame()

		else
			checkFrame()

	nextFrame()

	

boxPacking = (reduced) ->
	minHeight = Infinity
	bestSort = ''
	maxwidth = reduced[0].w
	maxheight = reduced[0].h
	for alg in ["width", "height", "area", "maxside"]
		boxes = ({w, h} for {w, h} in reduced).sort sorts[alg]
		if boxes[0].w != maxwidth or boxes[0].h != maxheight
			continue
		# console.log boxes
		pack = new Packer(maxwidth, maxheight)
		pack.fit(boxes)
		console.log alg, pack.root.h
		if pack.root.h < minHeight
			minHeight = pack.root.h
			bestSort = alg
	
	reduced = reduced.sort sorts[bestSort]
	pack = new Packer(maxwidth, maxheight)
	pack.fit(reduced)
	console.log pack, reduced
	[pack.root, reduced]

	



denseIndex = (index, [w, h]) ->
	frameMap = {}
	for frame in index
		frameMap[frame.f] ||= []
		frameMap[frame.f].push frame
	frames = ((parseInt(f) for f of frameMap).sort((a, b) -> b - a))
	lastframe = frames[0]
	pad = (num, len) ->
		num = num.toString(36)
		while num.length < len
			num = '0' + num
		return num
	main = for i in [0..lastframe]
		if frameMap[i]
			changes = for fr in frameMap[i]
				{sX, sY, bX, bY, w, h} = fr
				pad(bX, 2) + pad(bY, 2) + pad(w, 2) + pad(h, 2) + pad(sX, 2) + pad(sY, 3)
			changes.join('-')
		else
			''
	return main.slice(1).join(':')

	

	#the range of all spatial values is 0..width/height of the first image
	#but if you have an insanely large number of frames...
	# maxnum = Math.max(w, h, index[index.length - 1].f)
	# digits = Math.ceil(Math.log(maxnum)/Math.log(36))
	# newindex = []
	# for {f, sX, sY, bX, bY, w, h} in index
	# 	newindex = newindex.concat([f, sX, sY, bX, bY, w, h])
	# a = for number in newindex
	# 	n = number.toString 36
	# 	while n.length < digits
	# 		n = '0' + n
	# 	n
	# a.join('')


# parseDenseIndex = (str) ->
# 	digits = /^0+/.match(str)[0].length / 5
# 	#on the root node, which is always first, the first 5 attrs are zero
# 	for i in [0...str.length] by 7 * digits
# 		item = str.slice(i, digits)
# 		[f, sX, sY, bX, bY, w, h] = for j in [0...item.length] by digits
# 			parseInt(item.slice(j, digits), 36)


processFrames = ->
	frame = 0
	blocks = []	
	c = document.getElementById 'preview'
	width = 0
	height = 0
	preview = c.getContext '2d'
	future_context = null
	
	worker = new Worker("diffworker.js")
	worker.onmessage = (e) ->
		boxes = e.data
		
		c.width = future_context.canvas.width
		c.height = future_context.canvas.height
		preview.drawImage future_context.canvas, 0, 0

		preview.fillStyle = "rgba(0, 255, 0, 0.2)"
		preview.lineWidth = 2
		for [x1, y1, x2, y2] in boxes
			preview.fillRect x1 - 1, y1 - 1, x2 - x1 + 2, y2 - y1 + 2

		console.log "Exporting the blocks", boxes.length, boxes

		for [x1, y1, x2, y2] in boxes
			block = {
				frame,
				w: Math.min(x2 - x1 + 1, width - x1),
				h: Math.min(y2 - y1 + 1, height - y1),
				offsetX: x1,
				offsetY: y1
			}

			{offsetX, offsetY, w, h, frame} = block
			data = future_context.getImageData(offsetX, offsetY, w, h)
			buf = (new Uint8ClampedArray(data.data)).buffer
			# transport.push buf
			block.pixels = buf
			imageDataCache["frame-#{frame}-#{offsetX}-#{offsetY}-#{w}-#{h}"] = data

			blocks.push block

		frame++
		
		sendFrame()

			
	sendFrame = ->
		document.getElementById('difference').value = frame / frames.length
		if frame >= frames.length
			console.log "finished"
			postProcessing()
			return
		if frames[frame] is ""
			frame++
			return sendFrame()
		dataURLtoCanvas frames[frame], (canvas, image, ctx) ->
			{width, height} = image
			future_context = ctx
			data = ctx.getImageData(0, 0, width, height).data
			clamped = new Uint8ClampedArray(data)
			buf = clamped.buffer
			worker.webkitPostMessage({
				buf,
				width,
				height,
				frame
			}, [buf])
			

	sendFrame()
	return



class Packer
	constructor: (w, h) ->
		@root = { x: 0, y: 0, w: w, h: h }

	fit: (blocks) ->
		
		for block in blocks
			if node = @findNode(@root, block.w, block.h)
				block.fit = @splitNode(node, block.w, block.h)
			else
				block.fit = @growNode(block.w, block.h)
		return blocks

	findNode: (root, w, h) ->
		if root.used
			return @findNode(root.right, w, h) || @findNode(root.down, w, h)
		else if (w <= root.w) and (h <= root.h)
			return root
		else
			return null

	#dont need to grow rightwards because all blocks will be less wide
	#than the first one which will be huge
	growNode: (w, h) ->
		@root = {
			used: true,
			x: 0,
			y: 0,
			w: @root.w,
			h: @root.h + h,
			down: { x: 0, y: @root.h, w: @root.w, h: h},
			right: @root
		}
		if node = @findNode(@root, w, h)
			return @splitNode(node, w, h)
		else
			return null

	splitNode: (node, w, h) ->
		node.used = true
		node.down = {x: node.x, y: node.y + h, w: node.w, h: node.h - h}
		node.right = {x: node.x + w, y: node.y, w: node.w - w, h: h}
		return node

#okay, first is going through all the images and searching for 
#the smaller pieces in the bigger ones but i'm not doing that 
# yet because it's less cool than the next part
msort = (a, b, criteria) ->
	for criterion in criteria
		diff = sorts[criterion](a,b)
		return diff if diff != 0
	return 0

sorts = {
    random  : (a,b) -> return Math.random() - 0.5,
    w       : (a,b) -> return b.w - a.w,
    h       : (a,b) -> return b.h - a.h,
    a       : (a,b) -> return b.area - a.area,
    max     : (a,b) -> return Math.max(b.w, b.h) - Math.max(a.w, a.h),
    min     : (a,b) -> return Math.min(b.w, b.h) - Math.min(a.w, a.h),

    height  : (a,b) -> return msort(a, b, ['h', 'w']),
    width   : (a,b) -> return msort(a, b, ['w', 'h']),
    area    : (a,b) -> return msort(a, b, ['a', 'h', 'w']),
    maxside : (a,b) -> return msort(a, b, ['max', 'min', 'h', 'w'])
}