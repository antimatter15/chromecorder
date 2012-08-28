addEventListener 'message', (e) ->
	blocks = e.data
	return postMessage blocks
	p = 0
	for block in blocks
		postMessage (++p / blocks.length)/2
		data = new Uint8ClampedArray(block.pixels)
		# postMessage "caching block"
		block.pixels = {
			data,
			string: rowCache(data, row, block.w) for row in [0...block.h],
			width: block.w,
			height: block.h
		}
		

	p = 0
	for block in blocks
		postMessage 0.5 + (++p / blocks.length)/2
		candidates = (test for test in blocks when !test.isSubset and test.w >= block.w and test.h >= block.h and test != block)
		for candidate in candidates
			coords = imageSearch(block.pixels, candidate.pixels)
			if coords
				#does not deal with the possibility that this too has subsets itself
				block.isSubset = true
				delete block.pixels
				block.coords = coords
				unless 'subsets' of candidate
					candidate.subsets = []
				candidate.subsets.push block

				if 'subsets' of block
					[xoff, yoff] = coords
					for subset in block.subsets
						[xsub, ysub] = subset.coords
						subset.coords = [xoff + xsub, yoff + ysub]
						candidate.subsets.push subset
				break
	postMessage "o captain my captain"
	reduced = for {isSubset, frame, w, h, offsetX, offsetY, subsets} in blocks when !isSubset
		{w, h, frame, offsetX, offsetY, subsets}

	postMessage reduced

rowCache = (pixels, y, width) ->
	row = ""
	for x in [0...width]
		pix = (y * width + x) * 4  
		row += String.fromCharCode(pixels[pix]) # + String.fromCharCode(pixels.data[pix + 1])  + String.fromCharCode(pixels.data[pix + 1])
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



	firstRow = needle.string[0]
	# console.log firstRow
	rowCandidates = []
	for y in [0...haystack.height - needle.height]
		row = haystack.string[y]
		if row.indexOf firstRow != -1
			rowCandidates.push y
	return null if rowCandidates.length == 0
	
	# postMessage needle.height+ "rowcan" + rowCandidates.length
	bestReduce = 0
	bestRow = 0
	for n in [1...haystack.height]
		nthRow = needle.string[n]
		nthCandidates = []
		for y in rowCandidates
			row = haystack.string[y + n]
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
		nthRow = needle.string[bestRow]
		row = haystack.string[y + bestRow]
		# postMessage "investigating candidate"
		while (index = row.indexOf nthRow, index + 1) != -1
			# postMessage "almost a match"
			if confirmTheory(index, y)
				# console.log "an actual match", index, y, needle.width, needle.height
				return [index, y]
	


