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
		callback canvas, img, ctx, ctx.getImageData(0, 0, img.width, img.height)

f = 0
blocks = []

lastFrame = null

postProcessing = ->

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

	blocks = blocks.sort sorts.area

	blockDeduplication(blocks)
	#sort em first so that the bigger pieces get removed first
	#or is this backwards? should the smaller pieces be removed first

	console.log "Fitting boxes together"
	reduced = (block for block in blocks when !block.isSubset)

	# for color in ['#007fff', '#c0ffee', '#f1eece', '#efface', '#babb1e']
	# 	vanity = document.createElement('canvas');
	# 	[vanity.width, vanity.height] = [10, 10]
	# 	vx = vanity.getContext '2d'
	# 	vx.fillStyle = color
	# 	vx.fillRect(0, 0, vanity.width, vanity.height)
	# 	reduced.push {
	# 		image: vanity,
	# 		offsetX: 0,
	# 		offsetY: 0,
	# 		w: vanity.width,
	# 		h: vanity.height,
	# 		isSubset: true
	# 	}

	minHeight = Infinity
	bestSort = ''
	maxwidth = blocks[0].w
	maxheight = blocks[0].h
	for alg in ["width", "height", "area", "maxside"]
		boxes = ({w, h} for {w, h} in reduced).sort sorts[alg]
		if boxes[0].w != maxwidth or boxes[0].h != maxheight
			continue
		console.log boxes
		pack = new Packer(maxwidth, maxheight)
		pack.fit(boxes)
		console.log alg, pack.root.h
		if pack.root.h < minHeight
			minHeight = pack.root.h
			bestSort = alg
	
	blocks = blocks.sort sorts[bestSort]
	pack = new Packer(maxwidth, maxheight)
	pack.fit(blocks)

	canvas = document.createElement 'canvas'
	
	ctx = canvas.getContext '2d'
	canvas.width = pack.root.w
	canvas.height = pack.root.h
	ctx.fillStyle = '#007fff'
	ctx.fillRect 0, 0, canvas.width, canvas.height

	index = []
	for {frame, image, offsetX, offsetY, w, h, fit, subsets, isSubset} in blocks
		w = Math.min(w, image.width - offsetX)
		h = Math.min(h, image.height - offsetY)
		ctx.drawImage image, offsetX, offsetY, w, h, fit.x, fit.y, w, h
		unless isSubset
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
	
	preview.strokeStyle = 'green'
	for {frame, image, offsetX, offsetY, w, h, fit, subsets} in blocks
		preview.strokeRect fit.x, fit.y, w, h
		preview.fillText '(' + offsetX + ',' + offsetY + ')', fit.x, fit.y
	index = index.sort((a, b) -> a.f - b.f)
	# console.log index
	# console.log JSON.stringify(index)
	# console.log denseIndex(index, [canvas.width, canvas.height])
	finalize canvas, index, denseIndex(index, [canvas.width, canvas.height])
	



denseIndex = (index, [w, h]) ->
	#the range of all spatial values is 0..width/height of the first image
	#but if you have an insanely large number of frames...
	maxnum = Math.max(w, h, index[index.length - 1].f)
	digits = Math.ceil(Math.log(maxnum)/Math.log(36))
	newindex = []
	for {f, sX, sY, bX, bY, w, h} in index
		newindex = newindex.concat([f, sX, sY, bX, bY, w, h])
	a = for number in newindex
		n = number.toString 36
		while n.length < digits
			n = '0' + n
		n
	a.join('')


parseDenseIndex = (str) ->
	digits = /^0+/.match(str)[0].length / 5
	#on the root node, which is always first, the first 5 attrs are zero
	for i in [0...str.length] by 7 * digits
		item = str.slice(i, digits)
		[f, sX, sY, bX, bY, w, h] = for j in [0...item.length] by digits
			parseInt(item.slice(j, digits), 36)


processFrames = ->
	frame = 0
	blocks = []	
	c = document.getElementById 'preview'
	width = 0
	height = 0
	preview = c.getContext '2d'
	
	worker = new Worker("diffworker.js")
	worker.onmessage = (e) ->
		boxes = e.data
		
		preview.strokeStyle = "green"
		preview.lineWidth = 2
		for [x1, y1, x2, y2] in boxes
			preview.strokeRect x1 + .5, y1+ .5, x2 - x1 + .5, y2 - y1 + .5

		console.log "Exporting the blocks", boxes.length, boxes

		for [x1, y1, x2, y2] in boxes
			blocks.push {
				frame,
				w: Math.min(x2 - x1 + 1, width - x1),
				h: Math.min(y2 - y1 + 1, height - y1),
				offsetX: x1,
				offsetY: y1
			}

		frame++
		
		sendFrame()

			
	sendFrame = ->
		document.getElementById('difference').value = frame / frames.length
		if frame >= frames.length
			console.log "finished"
			return
		if frames[frame] is ""
			frame++
			return sendFrame()
		dataURLtoCanvas frames[frame], (canvas, image, ctx, pixels) ->
			c.width = width
			c.height = height
			preview.drawImage canvas, 0, 0
			{data, width, height} = pixels
			clamped = new Uint8ClampedArray(data)
			buf = clamped.buffer
			worker.webkitPostMessage({
				buf,
				width,
				height,
				frame
			}, [buf])

	sendFrame()



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