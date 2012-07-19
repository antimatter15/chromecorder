

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
	


