// Generated by CoffeeScript 1.3.3
var click, finalize, output_canvas, output_index, player, saveOutput, saveURL;

player = function(src, j) {
  var c, img, render, replay, tpf, x;
  c = document.getElementById('playback');
  x = c.getContext('2d');
  img = new Image();
  img.src = src;
  tpf = 1000 / 5;
  render = function(frame, image) {
    return x.drawImage(image, frame.sX, frame.sY, frame.w, frame.h, frame.bX, frame.bY, frame.w, frame.h);
  };
  replay = function() {
    var frame, _fn, _i, _len;
    c.width = j[0].w;
    c.height = j[0].h;
    _fn = function(frame, img) {
      return setTimeout(function() {
        return render(frame, img);
      }, frame.f * tpf);
    };
    for (_i = 0, _len = j.length; _i < _len; _i++) {
      frame = j[_i];
      _fn(frame, img);
    }
    return setTimeout(function() {
      return replay();
    }, (j[j.length - 1].f + 1) * tpf);
  };
  return img.onload = replay;
};

click = function(node) {
  var event;
  event = document.createEvent("MouseEvents");
  event.initMouseEvent("click", true, false, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
  return node.dispatchEvent(event);
};

output_canvas = null;

output_index = null;

finalize = function(canvas, index, denseIndex) {
  document.getElementById('difference').style.display = 'none';
  document.getElementById('search').style.display = 'none';
  player(canvas.toDataURL('image/png'), index);
  output_canvas = canvas;
  output_index = index;
  document.getElementById('save').style.display = '';
  document.getElementById('save').onclick = saveOutput;
  return document.getElementById('code').innerText = denseIndex;
};

saveURL = function(name, url) {
  var link;
  link = document.createElement('a');
  link.download = name;
  link.href = url;
  link.target = "_blank";
  return click(link);
};

saveOutput = function() {
  return saveURL('output.png', output_canvas.toDataURL('image/png'));
};

window.onload = function() {
  return processFrames();
};
