#another day, another thing in coffeescript

frameRate = 5
isRecording = false
timer = null
frames = []

chrome.browserAction.onClicked.addListener (tab) ->
	isRecording = !isRecording
	if isRecording is true
		chrome.browserAction.setIcon({path: 'img/rec.png'})
		chrome.browserAction.setTitle({title: 'Stop recording.'})
		timer = setInterval captureFrame, 1000 / frameRate
		frames = []
	else
		chrome.browserAction.setIcon({path: 'img/idle.png'})
		chrome.browserAction.setTitle({title: 'Start recording.'})
		clearInterval timer
		chrome.tabs.create {url: "processing.html"}

captureFrame = ->
	chrome.tabs.captureVisibleTab null, {format: "png"}, (dataURL) ->
		frames.push dataURL
		chrome.browserAction.setBadgeText { text: frames.length.toString() }