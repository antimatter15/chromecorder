#SpriteCast

Okay, what is this? This is an interesting approach to video compression which might be particularly relevant to screencasting. It consists of two streams of data, first a JSON array (henceforth to be referred to as the Index) containing pixel coordinates (or it could be in some denser format based on encoded strings, possibly with a special efficient coding scheme), and then an image file (probably PNG or some other lossless file because they tend to compress screenshots well). There may be multiple PNG/Index pairs in an entire screencast to replicate the idea of keyframes in traditional videos (. Javascript combines these two streams into a functional video of sorts.

## Why

Because I went to sublimetext.com and it's got this really quite awesome screencast at the beginning. It loads quickly and seems fairly efficient (17kbps, 11 seconds long and 190KB for one of them). There needs to be something which makes screencasts like that.

## How

Okay, so I guess there are a few algorithms and trade-offs which need to be decided first.

Well, one part is pretty obvious, that is it needs some system to get frames, and once it has gotten those frames it needs to find out regions that have changed in successive frames (basically XOR'ing the pixels should be enough).

Then it needs to identify which regions have changed and draw bounding boxes around them. This part is what confuses me, because it treads into algorithms territory. 