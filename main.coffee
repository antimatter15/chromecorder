#another day, another thing in coffeescript

frameRate = 5
isRecording = false
timer = null
frames = []
realFrames = 0
lastFrame = ""

chrome.browserAction.onClicked.addListener (tab) ->
	isRecording = !isRecording
	if isRecording is true
		chrome.browserAction.setIcon({path: 'img/rec.png'})
		chrome.browserAction.setTitle({title: 'Stop recording.'})
		captureFrame()
		timer = setInterval captureFrame, 1000 / frameRate
		frames = []
		realFrames = 0
	else
		chrome.browserAction.setIcon({path: 'img/idle.png'})
		chrome.browserAction.setTitle({title: 'Start recording.'})
		chrome.browserAction.setBadgeText { text: '' }
		clearInterval timer
		chrome.tabs.create {url: "processing.html"}

captureFrame = ->
	chrome.tabs.captureVisibleTab null, {format: "png"}, (dataURL) ->
		if lastFrame == dataURL
			frames.push ""
		else
			frames.push dataURL
			lastFrame = dataURL
			realFrames++
		chrome.browserAction.setBadgeText { text: realFrames.toString() }