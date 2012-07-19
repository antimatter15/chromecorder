// Generated by CoffeeScript 1.3.3
var Packer, applyBlockImageTransform, blockSearch, blocks, boxPacking, compositeTiles, dataURLtoCanvas, denseIndex, frames, msort, parseDenseIndex, postProcessing, processFrames, sorts;

frames = chrome.extension.getBackgroundPage().frames;

dataURLtoCanvas = function(dataURL, callback) {
  var canvas, ctx, img;
  img = new Image();
  canvas = document.createElement('canvas');
  ctx = canvas.getContext('2d');
  img.src = dataURL;
  return img.onload = function() {
    canvas.width = img.width;
    canvas.height = img.height;
    ctx.drawImage(img, 0, 0);
    return callback(canvas, img, ctx);
  };
};

blocks = [];

compositeTiles = function(root, blocks) {
  var canvas, coords, ctx, fit, frame, h, image, index, isSubset, offsetX, offsetY, preview, subsets, w, _i, _j, _len, _len1, _ref, _ref1, _ref2;
  index = [];
  canvas = document.createElement('canvas');
  ctx = canvas.getContext('2d');
  canvas.width = root.w;
  canvas.height = root.h;
  ctx.fillStyle = '#007fff';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  for (_i = 0, _len = blocks.length; _i < _len; _i++) {
    _ref = blocks[_i], frame = _ref.frame, image = _ref.image, offsetX = _ref.offsetX, offsetY = _ref.offsetY, w = _ref.w, h = _ref.h, fit = _ref.fit, subsets = _ref.subsets, isSubset = _ref.isSubset;
    w = Math.min(w, image.width - offsetX);
    h = Math.min(h, image.height - offsetY);
    ctx.drawImage(image, offsetX, offsetY, w, h, fit.x, fit.y, w, h);
  }
  if (!isSubset) {
    index.push({
      f: frame,
      sX: fit.x,
      sY: fit.y,
      bX: offsetX,
      bY: offsetY,
      w: w,
      h: h
    });
  }
  if (subsets) {
    for (_j = 0, _len1 = subsets.length; _j < _len1; _j++) {
      _ref1 = subsets[_j], frame = _ref1.frame, w = _ref1.w, h = _ref1.h, coords = _ref1.coords, offsetX = _ref1.offsetX, offsetY = _ref1.offsetY;
      index.push({
        f: frame,
        sX: fit.x + coords[0],
        sY: fit.y + coords[1],
        bX: offsetX,
        bY: offsetY,
        w: w,
        h: h
      });
    }
  }
  preview = document.getElementById('preview');
  _ref2 = [canvas.width, canvas.height], preview.width = _ref2[0], preview.height = _ref2[1];
  preview = preview.getContext('2d');
  return preview.drawImage(canvas, 0, 0);
};

postProcessing = function() {
  return blockSearch(function(reduced) {
    var root, _ref;
    _ref = boxPacking(reduced), root = _ref[0], blocks = _ref[1];
    return applyBlockImageTransform(blocks, function(block, ctx, img) {
      return block.image = img;
    }, function() {
      return compositeTiles(root, blocks);
    });
  });
};

blockSearch = function(callback) {
  var transport, worker;
  blocks = blocks.sort(sorts.area);
  transport = [];
  worker = new Worker("searchworker.js");
  worker.onmessage = function(e) {
    if (typeof e.data === "number") {
      return document.getElementById('search').value = e.data;
    } else if (typeof e.data === "object" && e.data.pop) {
      return callback(e.data);
    } else {
      return console.log(e.data);
    }
  };
  applyBlockImageTransform(blocks, function(block, ctx, img) {
    var buf, data, h, offsetX, offsetY, w;
    offsetX = block.offsetX, offsetY = block.offsetY, w = block.w, h = block.h;
    data = ctx.getImageData(offsetX, offsetY, w, h);
    buf = (new Uint8ClampedArray(data.data)).buffer;
    transport.push(buf);
    return block.pixels = buf;
  }, function() {
    return worker.webkitPostMessage(blocks, transport);
  });
};

applyBlockImageTransform = function(blocks, transform, callback) {
  var checkFrame, frame, lastContext, lastImage, nextFrame;
  frame = 0;
  lastImage = null;
  lastContext = null;
  checkFrame = function() {
    var block, _i, _len;
    for (_i = 0, _len = blocks.length; _i < _len; _i++) {
      block = blocks[_i];
      if (block.frame === frame) {
        transform(block, lastContext, lastImage);
      }
    }
    frame++;
    return nextFrame();
  };
  nextFrame = function() {
    if (frame >= frames.length) {
      callback();
      return;
    }
    if (frames[frame] !== "") {
      return dataURLtoCanvas(frames[frame], function(canvas, img, ctx) {
        lastContext = ctx;
        lastImage = img;
        return checkFrame();
      });
    } else {
      return checkFrame();
    }
  };
  return nextFrame();
};

boxPacking = function(reduced) {
  var alg, bestSort, boxes, h, maxheight, maxwidth, minHeight, pack, w, _i, _len, _ref;
  minHeight = Infinity;
  bestSort = '';
  maxwidth = reduced[0].w;
  maxheight = reduced[0].h;
  _ref = ["width", "height", "area", "maxside"];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    alg = _ref[_i];
    boxes = ((function() {
      var _j, _len1, _ref1, _results;
      _results = [];
      for (_j = 0, _len1 = reduced.length; _j < _len1; _j++) {
        _ref1 = reduced[_j], w = _ref1.w, h = _ref1.h;
        _results.push({
          w: w,
          h: h
        });
      }
      return _results;
    })()).sort(sorts[alg]);
    if (boxes[0].w !== maxwidth || boxes[0].h !== maxheight) {
      continue;
    }
    pack = new Packer(maxwidth, maxheight);
    pack.fit(boxes);
    console.log(alg, pack.root.h);
    if (pack.root.h < minHeight) {
      minHeight = pack.root.h;
      bestSort = alg;
    }
  }
  reduced = reduced.sort(sorts[bestSort]);
  pack = new Packer(maxwidth, maxheight);
  pack.fit(reduced);
  console.log(pack, reduced);
  return [pack.root, reduced];
};

denseIndex = function(index, _arg) {
  var a, bX, bY, digits, f, h, maxnum, n, newindex, number, sX, sY, w, _i, _len, _ref;
  w = _arg[0], h = _arg[1];
  maxnum = Math.max(w, h, index[index.length - 1].f);
  digits = Math.ceil(Math.log(maxnum) / Math.log(36));
  newindex = [];
  for (_i = 0, _len = index.length; _i < _len; _i++) {
    _ref = index[_i], f = _ref.f, sX = _ref.sX, sY = _ref.sY, bX = _ref.bX, bY = _ref.bY, w = _ref.w, h = _ref.h;
    newindex = newindex.concat([f, sX, sY, bX, bY, w, h]);
  }
  a = (function() {
    var _j, _len1, _results;
    _results = [];
    for (_j = 0, _len1 = newindex.length; _j < _len1; _j++) {
      number = newindex[_j];
      n = number.toString(36);
      while (n.length < digits) {
        n = '0' + n;
      }
      _results.push(n);
    }
    return _results;
  })();
  return a.join('');
};

parseDenseIndex = function(str) {
  var bX, bY, digits, f, h, i, item, j, sX, sY, w, _i, _ref, _ref1, _ref2, _results;
  digits = /^0+/.match(str)[0].length / 5;
  _results = [];
  for (i = _i = 0, _ref = str.length, _ref1 = 7 * digits; 0 <= _ref ? _i < _ref : _i > _ref; i = _i += _ref1) {
    item = str.slice(i, digits);
    _results.push((_ref2 = (function() {
      var _j, _ref2, _results1;
      _results1 = [];
      for (j = _j = 0, _ref2 = item.length; 0 <= _ref2 ? _j < _ref2 : _j > _ref2; j = _j += digits) {
        _results1.push(parseInt(item.slice(j, digits), 36));
      }
      return _results1;
    })(), f = _ref2[0], sX = _ref2[1], sY = _ref2[2], bX = _ref2[3], bY = _ref2[4], w = _ref2[5], h = _ref2[6], _ref2));
  }
  return _results;
};

processFrames = function() {
  var c, frame, height, preview, sendFrame, width, worker;
  frame = 0;
  blocks = [];
  c = document.getElementById('preview');
  width = 0;
  height = 0;
  preview = c.getContext('2d');
  worker = new Worker("diffworker.js");
  worker.onmessage = function(e) {
    var boxes, x1, x2, y1, y2, _i, _j, _len, _len1, _ref, _ref1;
    boxes = e.data;
    preview.strokeStyle = "green";
    preview.lineWidth = 2;
    for (_i = 0, _len = boxes.length; _i < _len; _i++) {
      _ref = boxes[_i], x1 = _ref[0], y1 = _ref[1], x2 = _ref[2], y2 = _ref[3];
      preview.strokeRect(x1 + .5, y1 + .5, x2 - x1 + .5, y2 - y1 + .5);
    }
    console.log("Exporting the blocks", boxes.length, boxes);
    for (_j = 0, _len1 = boxes.length; _j < _len1; _j++) {
      _ref1 = boxes[_j], x1 = _ref1[0], y1 = _ref1[1], x2 = _ref1[2], y2 = _ref1[3];
      blocks.push({
        frame: frame,
        w: Math.min(x2 - x1 + 1, width - x1),
        h: Math.min(y2 - y1 + 1, height - y1),
        offsetX: x1,
        offsetY: y1
      });
    }
    frame++;
    return sendFrame();
  };
  sendFrame = function() {
    document.getElementById('difference').value = frame / frames.length;
    if (frame >= frames.length) {
      console.log("finished");
      postProcessing();
      return;
    }
    if (frames[frame] === "") {
      frame++;
      return sendFrame();
    }
    return dataURLtoCanvas(frames[frame], function(canvas, image, ctx) {
      var buf, clamped, data;
      width = image.width, height = image.height;
      c.width = width;
      c.height = height;
      preview.drawImage(canvas, 0, 0);
      data = ctx.getImageData(0, 0, width, height).data;
      clamped = new Uint8ClampedArray(data);
      buf = clamped.buffer;
      return worker.webkitPostMessage({
        buf: buf,
        width: width,
        height: height,
        frame: frame
      }, [buf]);
    });
  };
  sendFrame();
};

Packer = (function() {

  function Packer(w, h) {
    this.root = {
      x: 0,
      y: 0,
      w: w,
      h: h
    };
  }

  Packer.prototype.fit = function(blocks) {
    var block, node, _i, _len;
    for (_i = 0, _len = blocks.length; _i < _len; _i++) {
      block = blocks[_i];
      if (node = this.findNode(this.root, block.w, block.h)) {
        block.fit = this.splitNode(node, block.w, block.h);
      } else {
        block.fit = this.growNode(block.w, block.h);
      }
    }
    return blocks;
  };

  Packer.prototype.findNode = function(root, w, h) {
    if (root.used) {
      return this.findNode(root.right, w, h) || this.findNode(root.down, w, h);
    } else if ((w <= root.w) && (h <= root.h)) {
      return root;
    } else {
      return null;
    }
  };

  Packer.prototype.growNode = function(w, h) {
    var node;
    this.root = {
      used: true,
      x: 0,
      y: 0,
      w: this.root.w,
      h: this.root.h + h,
      down: {
        x: 0,
        y: this.root.h,
        w: this.root.w,
        h: h
      },
      right: this.root
    };
    if (node = this.findNode(this.root, w, h)) {
      return this.splitNode(node, w, h);
    } else {
      return null;
    }
  };

  Packer.prototype.splitNode = function(node, w, h) {
    node.used = true;
    node.down = {
      x: node.x,
      y: node.y + h,
      w: node.w,
      h: node.h - h
    };
    node.right = {
      x: node.x + w,
      y: node.y,
      w: node.w - w,
      h: h
    };
    return node;
  };

  return Packer;

})();

msort = function(a, b, criteria) {
  var criterion, diff, _i, _len;
  for (_i = 0, _len = criteria.length; _i < _len; _i++) {
    criterion = criteria[_i];
    diff = sorts[criterion](a, b);
    if (diff !== 0) {
      return diff;
    }
  }
  return 0;
};

sorts = {
  random: function(a, b) {
    return Math.random() - 0.5;
  },
  w: function(a, b) {
    return b.w - a.w;
  },
  h: function(a, b) {
    return b.h - a.h;
  },
  a: function(a, b) {
    return b.area - a.area;
  },
  max: function(a, b) {
    return Math.max(b.w, b.h) - Math.max(a.w, a.h);
  },
  min: function(a, b) {
    return Math.min(b.w, b.h) - Math.min(a.w, a.h);
  },
  height: function(a, b) {
    return msort(a, b, ['h', 'w']);
  },
  width: function(a, b) {
    return msort(a, b, ['w', 'h']);
  },
  area: function(a, b) {
    return msort(a, b, ['a', 'h', 'w']);
  },
  maxside: function(a, b) {
    return msort(a, b, ['max', 'min', 'h', 'w']);
  }
};
