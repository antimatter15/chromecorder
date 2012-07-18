// Generated by CoffeeScript 1.3.3
var Packer, blocks, boxAreas, combinations, dataURLtoCanvas, f, fastAdjacentMerge, frames, getBounds, imageSearch, imageSearch2, lastFrame, postProcessing, processFrame, rowString;

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
    return callback(canvas, img, ctx, ctx.getImageData(0, 0, img.width, img.height));
  };
};

f = 0;

blocks = [];

lastFrame = null;

rowString = function(pixels, y) {
  var pix, row, x, _i, _ref;
  row = "";
  for (x = _i = 0, _ref = pixels.width; 0 <= _ref ? _i < _ref : _i > _ref; x = 0 <= _ref ? ++_i : --_i) {
    pix = (y * pixels.width + x) * 4;
    row += String.fromCharCode(pixels.data[pix]);
  }
  return row;
};

imageSearch = function(needle, haystack) {
  var bestReduce, bestRow, confirmTheory, firstRow, hpix, index, n, npix, nthCandidates, nthRow, pixc, reduce, row, rowCandidates, y, _i, _j, _k, _l, _len, _len1, _ref;
  if (needle.width > haystack.width) {
    return null;
  }
  if (needle.height > haystack.height) {
    return null;
  }
  hpix = function(x, y) {
    var pix;
    pix = (y * haystack.width + x) * 4;
    return [haystack.data[pix], haystack.data[pix + 1], haystack.data[pix + 2]];
  };
  npix = function(x, y) {
    var pix;
    pix = (y * needle.width + x) * 4;
    return [needle.data[pix], needle.data[pix + 1], needle.data[pix + 2]];
  };
  pixc = function(_arg, _arg1) {
    var B, G, R, b, g, r;
    r = _arg[0], g = _arg[1], b = _arg[2];
    R = _arg1[0], G = _arg1[1], B = _arg1[2];
    return r === R && g === G && b === B;
  };
  confirmTheory = function(hx, hy) {
    var x, y, _i, _j, _ref, _ref1;
    for (y = _i = 0, _ref = needle.height; 0 <= _ref ? _i < _ref : _i > _ref; y = 0 <= _ref ? ++_i : --_i) {
      for (x = _j = 0, _ref1 = needle.width; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; x = 0 <= _ref1 ? ++_j : --_j) {
        if (!pixc(hpix(hx + x, hy + y), npix(x, y))) {
          return;
        }
      }
    }
    return true;
  };
  firstRow = rowString(needle, 0);
  rowCandidates = [];
  for (y = _i = 0, _ref = haystack.height - needle.height; 0 <= _ref ? _i < _ref : _i > _ref; y = 0 <= _ref ? ++_i : --_i) {
    row = rowString(haystack, y);
    if (row.indexOf(firstRow !== -1)) {
      rowCandidates.push(y);
    }
  }
  if (rowCandidates.length === 0) {
    return null;
  }
  bestReduce = 0;
  bestRow = 0;
  for (n = _j = 1; _j < 15; n = ++_j) {
    nthRow = rowString(needle, n);
    nthCandidates = [];
    for (_k = 0, _len = rowCandidates.length; _k < _len; _k++) {
      y = rowCandidates[_k];
      row = rowString(haystack, y + n);
      if (row.indexOf(nthRow) !== -1) {
        nthCandidates.push(y);
      }
    }
    if (nthCandidates.length === 0) {
      return null;
    }
    reduce = rowCandidates.length - nthCandidates.length;
    if (reduce > bestReduce) {
      bestReduce = reduce;
      bestRow = n;
    }
    rowCandidates = nthCandidates;
    if (nthCandidates.length === 1) {
      break;
    }
  }
  for (_l = 0, _len1 = rowCandidates.length; _l < _len1; _l++) {
    y = rowCandidates[_l];
    index = -1;
    nthRow = rowString(needle, bestRow);
    row = rowString(haystack, y + bestRow);
    while ((index = row.indexOf(nthRow, index + 1)) !== -1) {
      if (confirmTheory(index, y)) {
        console.log("an actual match", index, y, needle.width, needle.height);
        return [index, y];
      }
    }
  }
};

imageSearch2 = function(needle, haystack) {
  var hpix, npix, nsearch, x, y, _i, _ref;
  if (needle.width > haystack.width) {
    return null;
  }
  if (needle.height > haystack.height) {
    return null;
  }
  hpix = function(x, y) {
    var pix;
    pix = (y * haystack.width + x) * 4;
    return [haystack.data[pix], haystack.data[pix + 1], haystack.data[pix + 2]];
  };
  npix = function(x, y) {
    var pix;
    pix = (y * needle.width + x) * 4;
    return [needle.data[pix], needle.data[pix + 1], needle.data[pix + 2]];
  };
  nsearch = function(x, y, _arg) {
    var b, g, h, i, r, _ref;
    r = _arg[0], g = _arg[1], b = _arg[2];
    while (x < needle.width) {
      _ref = npix(x, y), g = _ref[0], h = _ref[1], i = _ref[2];
      if (g === r && h === g && i === b) {
        return x;
      }
      x++;
    }
    return null;
  };
  for (y = _i = 0, _ref = haystack.height - needle.height; 0 <= _ref ? _i < _ref : _i > _ref; y = 0 <= _ref ? ++_i : --_i) {
    x = 0;
    x = nsearch(x, 0, hpix(0, y));
    if (x === null) {
      continue;
    }
    if (x > haystack.width - needle.width) {
      continue;
    }
    console.log(x);
    return null;
  }
};

postProcessing = function() {
  var block, candidate, candidates, canvas, coords, ctx, fit, frame, h, image, index, msort, offsetX, offsetY, pack, preview, sorts, subsets, test, w, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _ref, _ref1, _ref2, _ref3;
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
  blocks = blocks.sort(sorts.area);
  for (_i = 0, _len = blocks.length; _i < _len; _i++) {
    block = blocks[_i];
    candidates = (function() {
      var _j, _len1, _results;
      _results = [];
      for (_j = 0, _len1 = blocks.length; _j < _len1; _j++) {
        test = blocks[_j];
        if (!test.isSubset && test.w >= block.w && test.h >= block.h && test !== block) {
          _results.push(test);
        }
      }
      return _results;
    })();
    console.log("Iterating through block parent candidates");
    for (_j = 0, _len1 = candidates.length; _j < _len1; _j++) {
      candidate = candidates[_j];
      coords = imageSearch(block.pixels, candidate.pixels);
      if (coords) {
        block.isSubset = true;
        block.coords = coords;
        if (!('subsets' in candidate)) {
          candidate.subsets = [];
        }
        candidate.subsets.push(block);
        break;
      }
    }
  }
  pack = new Packer;
  console.log("Fitting boxes together");
  blocks = pack.fit((function() {
    var _k, _len2, _results;
    _results = [];
    for (_k = 0, _len2 = blocks.length; _k < _len2; _k++) {
      block = blocks[_k];
      if (!block.isSubset) {
        _results.push(block);
      }
    }
    return _results;
  })());
  canvas = document.createElement('canvas');
  ctx = canvas.getContext('2d');
  canvas.width = pack.root.w;
  canvas.height = pack.root.h;
  index = [];
  for (_k = 0, _len2 = blocks.length; _k < _len2; _k++) {
    _ref = blocks[_k], frame = _ref.frame, image = _ref.image, offsetX = _ref.offsetX, offsetY = _ref.offsetY, w = _ref.w, h = _ref.h, fit = _ref.fit, subsets = _ref.subsets;
    ctx.drawImage(image, offsetX, offsetY, w, h, fit.x, fit.y, w, h);
    index.push({
      f: frame,
      sX: fit.x,
      sY: fit.y,
      bX: offsetX,
      bY: offsetY,
      w: w,
      h: h
    });
    if (subsets) {
      for (_l = 0, _len3 = subsets.length; _l < _len3; _l++) {
        _ref1 = subsets[_l], frame = _ref1.frame, w = _ref1.w, h = _ref1.h, coords = _ref1.coords, offsetX = _ref1.offsetX, offsetY = _ref1.offsetY;
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
  }
  preview = document.getElementById('preview');
  _ref2 = [canvas.width, canvas.height], preview.width = _ref2[0], preview.height = _ref2[1];
  preview = preview.getContext('2d');
  preview.drawImage(canvas, 0, 0);
  document.getElementById('save').href = canvas.toDataURL('image/png');
  for (_m = 0, _len4 = blocks.length; _m < _len4; _m++) {
    _ref3 = blocks[_m], frame = _ref3.frame, image = _ref3.image, offsetX = _ref3.offsetX, offsetY = _ref3.offsetY, w = _ref3.w, h = _ref3.h, fit = _ref3.fit, subsets = _ref3.subsets;
    preview.strokeRect(fit.x, fit.y, w, h);
  }
  console.log(index.sort(function(a, b) {
    return a.f - b.f;
  }));
  return console.log(JSON.stringify(index.sort(function(a, b) {
    return a.f - b.f;
  })));
};

Packer = (function() {

  function Packer() {}

  Packer.prototype.fit = function(blocks) {
    var block, node, _i, _len;
    this.root = {
      x: 0,
      y: 0,
      w: blocks[0].w,
      h: blocks[0].h
    };
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
    } else if ((w <= root.w) && h <= root.h) {
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

getBounds = function(points) {
  var maxx, maxy, minx, miny, x, y, _i, _len, _ref;
  minx = Infinity;
  miny = Infinity;
  maxx = 0;
  maxy = 0;
  for (_i = 0, _len = points.length; _i < _len; _i++) {
    _ref = points[_i], x = _ref[0], y = _ref[1];
    minx = Math.min(minx, x);
    miny = Math.min(miny, y);
    maxx = Math.max(maxx, x);
    maxy = Math.max(maxy, y);
  }
  return [minx, miny, maxx, maxy];
};

processFrame = function() {
  var frame;
  frame = f++;
  if (frame >= frames.length) {
    console.log("reached end of video");
    if (blocks.length < 132) {
      postProcessing();
    }
    return;
  }
  return dataURLtoCanvas(frames[frame], function(canvas, image, ctx, pixels) {
    var axis, boxes, c, data, height, i, lastX, newboxes, pix, preview, startX, ts, width, x, x1, x2, y, y1, y2, _i, _j, _k, _l, _len, _len1, _len2, _m, _n, _o, _ref, _ref1, _ref2;
    data = pixels.data, width = pixels.width, height = pixels.height;
    ts = +(new Date);
    c = document.getElementById('preview');
    c.width = width;
    c.height = height;
    preview = c.getContext('2d');
    preview.drawImage(canvas, 0, 0);
    if (frame === 0) {
      console.log("first frame, woot");
      blocks.push({
        frame: frame,
        image: image,
        ctx: ctx,
        w: width,
        h: height,
        offsetX: 0,
        offsetY: 0,
        pixels: pixels
      });
    } else {
      boxes = [];
      for (y = _i = 0; 0 <= height ? _i <= height : _i >= height; y = 0 <= height ? ++_i : --_i) {
        lastX = null;
        startX = null;
        for (x = _j = 0; 0 <= width ? _j <= width : _j >= width; x = 0 <= width ? ++_j : --_j) {
          pix = (y * width + x) * 4;
          if (lastFrame[pix] !== data[pix] || lastFrame[pix + 1] !== data[pix + 1] || lastFrame[pix + 2] !== data[pix + 2]) {
            lastX = x;
            if (startX === null) {
              startX = x;
            }
          }
          if (x - lastX > 20 && startX !== null) {
            boxes.push([startX, y, lastX, y + 1]);
            startX = null;
          }
        }
      }
      newboxes = [];
      for (i = _k = 0; _k < 2; i = ++_k) {
        for (axis = _l = 0; _l < 4; axis = ++_l) {
          while ((newboxes = fastAdjacentMerge(boxes, axis)).length < boxes.length) {
            boxes = newboxes;
          }
        }
      }
      preview.strokeStyle = "green";
      for (_m = 0, _len = boxes.length; _m < _len; _m++) {
        _ref = boxes[_m], x1 = _ref[0], y1 = _ref[1], x2 = _ref[2], y2 = _ref[3];
        preview.strokeRect(x1 + .5, y1 + .5, x2 - x1 + .5, y2 - y1 + .5);
      }
      console.log("Beginning preliminary adjacent box mergining", boxes.length);
      console.log("Exporting the blocks", boxes.length, boxes);
      for (_n = 0, _len1 = boxes.length; _n < _len1; _n++) {
        _ref1 = boxes[_n], x1 = _ref1[0], y1 = _ref1[1], x2 = _ref1[2], y2 = _ref1[3];
        preview.strokeRect(x1, y1, x2 - x1, y2 - y1);
      }
      for (_o = 0, _len2 = boxes.length; _o < _len2; _o++) {
        _ref2 = boxes[_o], x1 = _ref2[0], y1 = _ref2[1], x2 = _ref2[2], y2 = _ref2[3];
        blocks.push({
          frame: frame,
          image: image,
          ctx: ctx,
          w: x2 - x1,
          h: y2 - y1,
          offsetX: x1,
          offsetY: y1,
          pixels: ctx.getImageData(x1, y1, x2 - x1, y2 - y1)
        });
      }
    }
    lastFrame = data;
    return setTimeout(processFrame, 500);
  });
};

combinations = function(list) {
  var a, b, newlist, _i, _j, _ref;
  newlist = [];
  for (a = _i = 0, _ref = list.length; 0 <= _ref ? _i < _ref : _i > _ref; a = 0 <= _ref ? ++_i : --_i) {
    for (b = _j = 0; 0 <= a ? _j < a : _j > a; b = 0 <= a ? ++_j : --_j) {
      newlist.push([list[a], list[b]]);
    }
  }
  return newlist;
};

boxAreas = function(a, b) {
  var aarea, ax1, ax2, ay1, ay2, barea, bx1, bx2, by1, by2, dHeight, dWidth, maxHeight, maxWidth, sarea, sx1, sx2, sy1, sy2;
  bx1 = b[0], by1 = b[1], bx2 = b[2], by2 = b[3];
  ax1 = a[0], ay1 = a[1], ax2 = a[2], ay2 = a[3];
  aarea = (ax2 - ax1) * (ay2 - ay1);
  barea = (bx2 - bx1) * (by2 - by1);
  maxWidth = Math.max(bx2 - bx1, ax2 - ax1);
  maxHeight = Math.max(ay2 - ay1, by2 - by1);
  sx1 = Math.min(ax1, bx1);
  sx2 = Math.max(ax2, bx2);
  sy1 = Math.min(ay1, by1);
  sy2 = Math.max(ay2, by2);
  sarea = (sy2 - sy1) * (sx2 - sx1);
  dWidth = (sx2 - sx1) - maxWidth;
  dHeight = (sy2 - sy1) - maxHeight;
  return [sarea, barea + aarea, [sx1, sy1, sx2, sy2], [dWidth, dHeight]];
};

fastAdjacentMerge = function(boxes, axis) {
  var dH, dW, i, newbox, newboxes, sarea, skipNext, tarea, _i, _ref, _ref1, _ref2;
  boxes = boxes.sort(function(a, b) {
    return a[axis] - b[axis];
  });
  newboxes = [];
  skipNext = false;
  if (boxes.length > 0) {
    for (i = _i = 0, _ref = boxes.length - 1; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      _ref1 = boxAreas(boxes[i], boxes[i + 1]), sarea = _ref1[0], tarea = _ref1[1], newbox = _ref1[2], (_ref2 = _ref1[3], dW = _ref2[0], dH = _ref2[1]);
      if ((sarea - tarea < 100 || (sarea * 0.5 <= tarea && dW < 15 && dH < 15)) && !skipNext) {
        newboxes.push(newbox);
        skipNext = true;
      } else {
        if (!skipNext) {
          newboxes.push(boxes[i]);
        }
        skipNext = false;
      }
    }
    if (!skipNext) {
      newboxes.push(boxes[boxes.length - 1]);
    }
  }
  return newboxes;
};
