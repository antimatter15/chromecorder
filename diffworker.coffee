#stuff which is vaguely computationally expensive

lastFrame = null

addEventListener 'message', (e) ->
	{buf, width, height, frame} = e.data
	data = new Uint8ClampedArray(buf)
	if frame is 0
		postMessage [[0, 0, width, height]]
	else
		boxes = differenceBoxes width, height, lastFrame, data
		boxes = iteratedMerge boxes
		#filter to make sure they're all valid
		boxes = ([x1, y1, x2, y2] for [x1, y1, x2, y2] in boxes when x2 - x1 > 0 and y2 - y1 > 0)
		postMessage boxes

	lastFrame = data

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



iteratedMerge = (boxes) ->
	newboxes = []
	for i in [0...2] #run it twice to make sure
		for axis in [1, 0, 3, 2] #orient the boxes along all four box axis to make sure you try ecverything
			while (newboxes = fastAdjacentMerge(boxes, axis)).length < boxes.length
				boxes = newboxes
	boxes



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

