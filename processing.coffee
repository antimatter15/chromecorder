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
		for y in [0...needle.height]
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
	for n in [1...15]
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

	for y in rowCandidates
		index = -1
		nthRow = rowString(needle, bestRow)
		row = rowString(haystack, y + bestRow)
		while (index = row.indexOf nthRow, index + 1) != -1
			if confirmTheory(index, y)
				console.log "an actual match", index, y, needle.width, needle.height
				return [index, y]
	

		# index = -1
		# while (index = row.indexOf firstRow, index + 1) != -1
		# 	rowCandidates.push []
		# 	if confirmTheory(index, y)
		# 		console.log "an actual match", index, y, needle.width, needle.height
		# 		return [index, y]
		# 	# console.log "amazing, a possible match", index, y, needle.width, needle.height




imageSearch2 = (needle, haystack) ->
	return null if needle.width > haystack.width
	return null if needle.height > haystack.height

	hpix = (x, y) ->
		pix = (y * haystack.width + x) * 4  
		[haystack.data[pix], haystack.data[pix + 1], haystack.data[pix + 2]]

	npix = (x, y) ->
		pix = (y * needle.width + x) * 4  
		[needle.data[pix], needle.data[pix + 1], needle.data[pix + 2]]

	nsearch = (x, y, [r, g, b]) ->
		while x < needle.width
			[g, h, i] = npix(x, y)
			if g is r and h is g and i is b
				return x
			x++
		return null

	for y in [0...haystack.height - needle.height]
		x = 0
		x = nsearch(x, 0, hpix(0, y))
		if x is null
			continue
		if x > haystack.width - needle.width
			continue
		console.log x
		return null
	# for x in [0...haystack.width]]

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

	#sort em first so that the bigger pieces get removed first
	#or is this backwards? should the smaller pieces be removed first

	for block in blocks
		candidates = (test for test in blocks when !test.isSubset and test.w >= block.w and test.h >= block.h and test != block)
		# console.log candidates
		console.log "Iterating through block parent candidates"
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

	pack = new Packer
	console.log "Fitting boxes together"
	blocks = pack.fit(block for block in blocks when !block.isSubset)

	canvas = document.createElement 'canvas'
	
	ctx = canvas.getContext '2d'
	canvas.width = pack.root.w
	canvas.height = pack.root.h

	index = []
	for {frame, image, offsetX, offsetY, w, h, fit, subsets} in blocks
		ctx.drawImage image, offsetX, offsetY, w, h, fit.x, fit.y, w, h
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

	for {frame, image, offsetX, offsetY, w, h, fit, subsets} in blocks
		preview.strokeRect fit.x, fit.y, w, h
	console.log index.sort((a, b) -> a.f - b.f)
	console.log JSON.stringify(index.sort((a, b) -> a.f - b.f))



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
		
		postProcessing() if blocks.length < 132
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
			console.log "finding changed pixels"
			points = []
			#this part is O(w * h)
			for y in [0..height]
				for x in [0..width]
					pix = (y * width + x) * 4
					if lastFrame[pix] isnt data[pix] or 
					lastFrame[pix + 1] isnt data[pix + 1] or 
					lastFrame[pix + 2] isnt data[pix + 2]
						points.push [x, y]
			minx = Infinity
			miny = Infinity
			maxx = 0
			maxy = 0
			#this is O(n) where n is pixels changed
			for [x, y] in points
				minx = Math.min(minx, x)
				miny = Math.min(miny, y)
				maxx = Math.max(maxx, x)
				maxy = Math.max(maxy, y)
			#draw pretty shapes
			# for [x, y] in points	
				# preview.fillRect x, y, 1, 1
			# preview.strokeRect minx, miny, maxx - minx, maxy - miny
			# console.log points

			#BOX MERGING
			#the first part is really more of an optimization thing
			#rather than, for creating a 1x1 pixel box for every of
			#the points and running the box merging, which would run
			#in essentially n^2 time, split them into contiguous lines
			#first so that there's much less to deal with
			console.log "Merging contiguous lines", points.length
			boxes = []
			lastX = null #not sure what to set this to as initially
			beginX = null
			lastY = null
			#this is O(n) where n is pixels changed
			for [x, y] in points
				if lastX >= x - 6 and lastY is y #if the last pixel was less than a few pixels away
					beginX = lastX if beginX is null
					#continue expanding box
				else
					#add whatever "box" (so far just a row) has been made
					if lastX - beginX > 0
						boxes.push [beginX, lastY, lastX, lastY + 1]
					beginX = null
					lastY = y
				lastX = x
			#now show pretty pictures about these boxes
			# console.log boxes
			preview.fillStyle = "green"
			for [x1, y1, x2, y2] in boxes
				preview.fillRect x1, y1, x2 - x1, y2 - y1
			console.log "Beginning preliminary adjacent box mergining", boxes.length
			
			while (newboxes = fastAdjacentBoxes(boxes, 0.8)).length < boxes.length
				# console.log "another iteration"
				boxes = newboxes

			return if boxes.length > 1600

			console.log "Beginning slower combination box merge", boxes.length
			#box merging is O(y^2 * log y) I think
			while (newboxes = fastMergeBoxes(boxes, 0.9)).length < boxes.length
				console.log "another iteration"
				boxes = newboxes
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
					w: x2 - x1,
					h: y2 - y1,
					offsetX: x1,
					offsetY: y1,
					pixels: ctx.getImageData(x1, y1, x2 - x1, y2 - y1)
				}
					
		lastFrame = data
		# console.log data.length
		#if new Date - ts < 200
		setTimeout processFrame, 500

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
	sx1 = Math.min(ax1, bx1)
	sx2 = Math.max(ax2, bx2)
	sy1 = Math.min(ay1, by1)
	sy2 = Math.max(ay2, by2)
	sarea = (sy2 - sy1) * (sx2 - sx1)
	[sarea, barea + aarea, [sx1, sy1, sx2, sy2]]


fastAdjacentBoxes = (boxes, ratio) ->
	return [] if boxes.length is 0	
	# console.log "input", boxes.length
	lastY = 0
	rowBuffer = []
	rowDoubleBuffer = []
	removed = {}
	newboxes = []
	# skipNext = false

	# for i in [0...boxes.length-1]
	# 	[sarea, tarea, newbox] = boxAreas boxes[i], boxes[i + 1]
	# 	if !skipNext
	# 		if sarea - tarea < 512 or sarea * ratio <= tarea
	# 			skipNext = true
	# 			newboxes.push newbox
	# 		else
	# 			newboxes.push boxes[i]
	# 			# newboxes.push boxes[i + 1]
	# 	skipNext = false
	# box = newboxes
	# newboxes = []

	for box in boxes
		# if lastY is box[1]
		if rowBuffer.length < 25
			rowBuffer.push box
			for test in rowDoubleBuffer
				continue if test.join(',') of removed
				[sarea, tarea, newbox] = boxAreas test, box
				priorWidth = Math.max(Math.abs(box[0] - box[2]), Math.abs(test[0] - test[2]))
				dwidth = (Math.abs(newbox[0] - newbox[2]) - priorWidth)
				if (sarea - tarea < 1024) and dwidth < 20
					# console.log sarea - tarea, newbox
					newboxes.push newbox
					removed[box.join(',')] = true
					removed[test.join(',')] = true
					break
		else
			# different line
			rowDoubleBuffer = rowBuffer
			rowBuffer = []
			
		lastY = box[1]
	old = (box for box in boxes when !(box.join(',') of removed))
	# console.log newboxes.length, old.length
	
	newboxes.concat(old)


#actually this isn't really fast, it's just that it can
#merge more than one box per iteration
fastMergeBoxes = (boxes, ratio) ->
	removed = []
	newboxes = []
	for a in [0...boxes.length]
		for b in [0...a]
			continue if a in removed or b in removed
			[sarea, tarea, box] = boxAreas boxes[a], boxes[b]
			priorWidth = Math.max(Math.abs(boxes[b][0] - boxes[b][2]), Math.abs(boxes[a][0] - boxes[a][2]))
			dwidth = (Math.abs(box[0] - box[2]) - priorWidth)
			if  sarea - 1024 <= tarea and dwidth < 20
				removed.push a
				removed.push b
				newboxes.push box
	for i in [0...boxes.length]
		#I don't think coffeescript implements "in" terribly efficiently
		#todo, replace this with a hashmap or something 
		unless i in removed
			newboxes.push boxes[i]
	newboxes

#maybe we can skip this step
slowMergeBoxes = (boxes) ->
	scores = for [a, b] in combinations(boxes)
		[32, a, b]
	sorted = scores.sort ([a], [b]) -> a - b
