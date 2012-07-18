// Generated by CoffeeScript 1.3.3
var captureFrame, frameRate, frames, isRecording, timer;

frameRate = 5;

isRecording = false;

timer = null;

frames = [];

chrome.browserAction.onClicked.addListener(function(tab) {
  isRecording = !isRecording;
  if (isRecording === true) {
    chrome.browserAction.setIcon({
      path: 'img/rec.png'
    });
    chrome.browserAction.setTitle({
      title: 'Stop recording.'
    });
    timer = setInterval(captureFrame, 1000 / frameRate);
    return frames = [];
  } else {
    chrome.browserAction.setIcon({
      path: 'img/idle.png'
    });
    chrome.browserAction.setTitle({
      title: 'Start recording.'
    });
    clearInterval(timer);
    return chrome.tabs.create({
      url: "processing.html"
    });
  }
});

captureFrame = function() {
  return chrome.tabs.captureVisibleTab(null, {
    format: "png"
  }, function(dataURL) {
    frames.push(dataURL);
    return chrome.browserAction.setBadgeText({
      text: frames.length.toString()
    });
  });
};
