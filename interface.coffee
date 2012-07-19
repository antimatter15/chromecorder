player = (src, j) ->
	c = document.getElementById 'playback'
	x = c.getContext '2d'
	img = new Image();
	img.src = src;
	
	tpf = 1000 / 5 

	render = (frame, image) ->
		x.drawImage(image, frame.sX, frame.sY, frame.w, frame.h, frame.bX, frame.bY, frame.w, frame.h)
		# x.strokeStyle = 'purple'
		# x.strokeRect(frame.bX, frame.bY, frame.w, frame.h)
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

click = (node) ->
	event = document.createEvent("MouseEvents")
	event.initMouseEvent("click", true, false, window, 0, 0, 0, 0, 0
	, false, false, false, false, 0, null)
	node.dispatchEvent(event)

output_canvas = null
output_index = null
finalize = (canvas, index, denseIndex) ->
	document.getElementById('difference').style.display = 'none'
	document.getElementById('search').style.display = 'none'
	player canvas.toDataURL('image/png'), index
	output_canvas = canvas
	output_index = index
	document.getElementById('save').style.display = ''
	document.getElementById('save').onclick = saveOutput
	document.getElementById('code').innerText = denseIndex


saveURL = (name, url) ->
	link = document.createElement('a')
	link.download = name
	link.href = url
	link.target = "_blank"
	click(link)
	
saveOutput = ->
	saveURL 'output.png', output_canvas.toDataURL('image/png')

window.onload = ->
	processFrames()