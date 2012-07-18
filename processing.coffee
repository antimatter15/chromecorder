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

rowString = (pixels, y) ->
	row = ""
	for x in [0...pixels.width]		
		pix = (y * pixels.width + x) * 4  
		row += String.fromCharCode(pixels.data[pix]) # + String.fromCharCode(pixels.data[pix + 1])  + String.fromCharCode(pixels.data[pix + 1])
	return row

imageSearch = (needle, haystack) ->
	return null if needle.width > haystack.width
	return null if needle.height > haystack.height
	#this is a hacky way which involves turning insto strings
	hpix = (x, y) ->
		pix = (y * haystack.width + x) * 4  
		[haystack.data[pix], haystack.data[pix + 1], haystack.data[pix + 2]]

	npix = (x, y) ->
		pix = (y * needle.width + x) * 4  
		[needle.data[pix], needle.data[pix + 1], needle.data[pix + 2]]

	pixc = ([r, g, b], [R, G, B]) ->
		r is R and g is G and b is B

	confirmTheory = (hx, hy) ->
		for y in [1...needle.height]
			for x in [0...needle.width]
				unless pixc hpix(hx + x, hy + y), npix(x, y)
					return
		return true



	firstRow = rowString(needle, 0)
	# console.log firstRow
	rowCandidates = []
	for y in [0...haystack.height - needle.height]
		row = rowString(haystack, y)
		if row.indexOf firstRow != -1
			rowCandidates.push y
	return null if rowCandidates.length == 0
	
	bestReduce = 0
	bestRow = 0
	for n in [1...haystack.height]
		nthRow = rowString(needle, n)
		nthCandidates = []
		for y in rowCandidates
			row = rowString(haystack, y + n)
			if row.indexOf(nthRow) != -1
				nthCandidates.push y
		return null if nthCandidates.length == 0
		reduce = rowCandidates.length - nthCandidates.length
		if reduce > bestReduce
			bestReduce = reduce
			bestRow = n
		rowCandidates = nthCandidates
		break if nthCandidates.length == 1
	if rowCandidates.length > 100
		console.log "reduce failure", rowCandidates.length
		return 
	for y in rowCandidates
		index = -1
		nthRow = rowString(needle, bestRow)
		row = rowString(haystack, y + bestRow)
		while (index = row.indexOf nthRow, index + 1) != -1
			if confirmTheory(index, y)
				console.log "an actual match", index, y, needle.width, needle.height
				return [index, y]
	



blockDeduplication = (blocks) ->
	for block in blocks
		candidates = (test for test in blocks when !test.isSubset and test.w >= block.w and test.h >= block.h and test != block)
		# console.log candidates
		console.log "Iterating through block parent candidates", candidates.length
		for candidate in candidates
			coords = imageSearch(block.pixels, candidate.pixels)
			if coords
				#does not deal with the possibility that this too has subsets itself
				block.isSubset = true
				block.coords = coords
				unless 'subsets' of candidate
					candidate.subsets = []
				candidate.subsets.push block
				break
				# remove block from candidate pool
			# console.log candidate


postProcessing = ->

	#okay, first is going through all the images and searching for 
	#the smaller pieces in the bigger ones but i'm not doing that 
	# yet because it's less cool than the next part
	# blocks = for [frame, image, offsetX, offsetY, width, height] in patches
		# { w: width, h: height, frame, image, offsetX, offsetY }

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

	# blockDeduplication(blocks)
	#sort em first so that the bigger pieces get removed first
	#or is this backwards? should the smaller pieces be removed first

	pack = new Packer
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

	blocks = pack.fit(reduced)

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
	document.getElementById('save').href = canvas.toDataURL('image/png')
	preview.strokeStyle = 'green'
	for {frame, image, offsetX, offsetY, w, h, fit, subsets} in blocks
		preview.strokeRect fit.x, fit.y, w, h
		preview.fillText '(' + offsetX + ',' + offsetY + ')', fit.x, fit.y
	index = index.sort((a, b) -> a.f - b.f)
	console.log index
	console.log JSON.stringify(index)
	console.log denseIndex(index, [canvas.width, canvas.height])
	player canvas.toDataURL('image/png'), index



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




player = (src, j) ->
	c = document.getElementById 'playback'
	x = c.getContext '2d'
	img = new Image();
	img.src = src;
	
	tpf = 1500

	render = (frame, image) ->
		x.drawImage(image, frame.sX, frame.sY, frame.w, frame.h, frame.bX, frame.bY, frame.w, frame.h)
		x.strokeStyle = 'purple'
		x.strokeRect(frame.bX, frame.bY, frame.w, frame.h)
	replay = ->
		c.width = j[0].w;
		c.height = j[0].h;
		for frame in j
			do (frame, img) ->
				setTimeout ->
					render(frame, img)
				, frame.f * tpf
		setTimeout ->
			replay()
		, (j[j.length - 1].f + 1) * tpf

	img.onload = replay

		


class Packer
	fit: (blocks) ->
		@root = { x: 0, y: 0, w: blocks[0].w, h: blocks[0].h }
		for block in blocks
			if node = @findNode(@root, block.w, block.h)
				block.fit = @splitNode(node, block.w, block.h)
			else
				block.fit = @growNode(block.w, block.h)
		return blocks

	findNode: (root, w, h) ->
		if root.used
			return @findNode(root.right, w, h) || @findNode(root.down, w, h)
		else if (w <= root.w) and h <= root.h
			return root
		else
			return null

	#dont need to grow rightwards because all blocks will be less wide
	#than the first one which will be huge
	growNode: (w, h) ->
		this.root = {
			used: true,
			x: 0,
			y: 0,
			w: this.root.w,
			h: this.root.h + h,
			down: { x: 0, y: this.root.h, w: this.root.w, h: h},
			right: this.root
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


processFrame = ->
	frame = f++
	if frame >= frames.length
		console.log "reached end of video"
		
		postProcessing()
		return
	dataURLtoCanvas frames[frame], (canvas, image, ctx, pixels) ->
		{data, width, height} = pixels

		ts = +new Date
		c = document.getElementById 'preview'
		c.width = width
		c.height = height
		preview = c.getContext '2d'
		preview.drawImage canvas, 0, 0
		if frame is 0
			#do nothing
			console.log "first frame, woot"
			# patches.push [frame, image, 0, 0, width, height]
			blocks.push {frame, image, ctx, w: width, h: height, offsetX: 0, offsetY: 0, pixels}
		else
			#do something

			boxes = differenceBoxes width, height, lastFrame, data
			#draw pretty shapes
			boxes = iteratedMerge boxes
			# preview.strokeRect minx, miny, maxx - minx, maxy - miny
			# console.log points

			#BOX MERGING
			#the first part is really more of an optimization thing
			#rather than, for creating a 1x1 pixel box for every of
			#the points and running the box merging, which would run
			#in essentially n^2 time, split them into contiguous lines
			#first so that there's much less to deal with
			boxes = ([x1, y1, x2, y2] for [x1, y1, x2, y2] in boxes when x2 - x1 > 0 and y2 - y1 > 0)

			preview.strokeStyle = "green"
			for [x1, y1, x2, y2] in boxes
				preview.strokeRect x1 + .5, y1+ .5, x2 - x1 + .5, y2 - y1 + .5

			console.log "Beginning preliminary adjacent box mergining", boxes.length

			
			# while (newboxes = fastAdjacentBoxes(boxes, 0.8)).length < boxes.length
				# console.log "another iteration"
				# boxes = newboxes


			console.log "Exporting the blocks", boxes.length, boxes
			# console.log newboxes
			for [x1, y1, x2, y2] in boxes
				preview.strokeRect x1, y1, x2 - x1, y2 - y1
			for [x1, y1, x2, y2] in boxes
				# patches.push [frame, image, x1, y1, x2 - x1, y2 - y1]
				blocks.push {
					frame,
					image,
					ctx,
					w: x2 - x1 + 1,
					h: y2 - y1 + 1,
					offsetX: x1,
					offsetY: y1,
					pixels: ctx.getImageData(x1, y1, x2 - x1, y2 - y1)
				}
					
		lastFrame = data
		# console.log data.length
		#if new Date - ts < 200
		setTimeout processFrame, 50


differenceBoxes = (width, height, lastFrame, currentFrame) ->
	boxes = []
	#this part is O(w * h)
	for y in [0..height]
		lastX = null
		startX = null
		for x in [0..width]
			pix = (y * width + x) * 4
			if lastFrame[pix] isnt currentFrame[pix] or 
			lastFrame[pix + 1] isnt currentFrame[pix + 1] or 
			lastFrame[pix + 2] isnt currentFrame[pix + 2]
				lastX = x
				if startX is null
					startX = x
			if x - lastX > 20 and startX isnt null
				boxes.push [startX, y, lastX, y + 1]
				startX = null
		if startX isnt null
			boxes.push [startX, y, lastX, y + 1]
	boxes


iteratedMerge = (boxes) ->
	newboxes = []
	for i in [0...2] #run it twice to make sure
		for axis in [1, 0, 3, 2] #orient the boxes along all four box axis to make sure you try ecverything
			while (newboxes = fastAdjacentMerge(boxes, axis)).length < boxes.length
				boxes = newboxes
	boxes


#get combinations that have two elements from a list
combinations = (list) ->
	newlist = []
	for a in [0...list.length]
		for b in [0...a]
			newlist.push [list[a], list[b]]
	newlist

boxAreas = (a, b) ->
	[bx1, by1, bx2, by2] = b
	[ax1, ay1, ax2, ay2] = a
	aarea = (ax2 - ax1) * (ay2 - ay1)
	barea = (bx2 - bx1) * (by2 - by1)
	maxWidth = Math.max(bx2 - bx1, ax2 - ax1)
	maxHeight = Math.max(ay2 - ay1, by2 - by1)
	sx1 = Math.min(ax1, bx1)
	sx2 = Math.max(ax2, bx2)
	sy1 = Math.min(ay1, by1)
	sy2 = Math.max(ay2, by2)
	sarea = (sy2 - sy1) * (sx2 - sx1)
	dWidth = (sx2 - sx1) - maxWidth
	dHeight = (sy2 - sy1) - maxHeight
	[sarea, barea + aarea, [sx1, sy1, sx2, sy2], [dWidth, dHeight]]


fastAdjacentMerge = (boxes, axis) ->
	boxes = boxes.sort((a, b) -> a[axis] - b[axis])
	newboxes = []
	skipNext = false
	if boxes.length > 0
		for i in [0...boxes.length-1]
			[sarea, tarea, newbox, [dW, dH]] = boxAreas boxes[i], boxes[i + 1]

			if (sarea - tarea < 256 or (sarea * 0.5 <= tarea and dW < 20 and dH < 20)) and !skipNext
			# if sarea * 0.8 <= tarea and !skipNext
				newboxes.push newbox
				skipNext = true
			else
				newboxes.push boxes[i] unless skipNext
				skipNext = false
		if !skipNext
			newboxes.push boxes[boxes.length - 1]
	newboxes
