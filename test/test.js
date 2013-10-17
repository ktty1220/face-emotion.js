// Generated by CoffeeScript 1.6.3
/*
ok(actual, message): actual == true
equal(actual, expected, message): actual == expected
notEqual(actual, expected, message): actual != expected
deepEqual(a, b, message)
notDeepEqual(a, b, message)
strictEqual(actual, expected, message): actual === expected
notStrictEqual(actual, expected, message): actual !== expected
*/


(function() {
  var suite;

  suite = function() {
    var clear, cssCheck, hasEffectStyle,
      _this = this;
    QUnit.config.reorder = false;
    clear = function() {
      while (_this.face.firstChild) {
        _this.face.removeChild(_this.face.firstChild);
      }
      return _this.obj = null;
    };
    hasEffectStyle = function() {
      var result, style, tmp, _ref, _ref1;
      tmp = document.createElement('div');
      tmp.className = 'face-emotion-angry';
      tmp.style.display = 'none';
      document.body.appendChild(tmp);
      style = (_ref = (_ref1 = document.defaultView) != null ? typeof _ref1.getComputedStyle === "function" ? _ref1.getComputedStyle(tmp, '') : void 0 : void 0) != null ? _ref : {
        height: '10px'
      };
      result = parseInt(style.height, 10) > 0;
      document.body.removeChild(tmp);
      return result;
    };
    /**
    * new
    */

    module('FaceEmotion: new', {
      setup: function() {},
      teardown: function() {
        return clear();
      }
    });
    test('オプションなし', function() {
      equal(hasEffectStyle(), false, 'エフェクト用CSSはDOMに追加されていない');
      throws((function() {
        return new FaceEmotion('no-face');
      }), '存在しないIDを指定してnew -> throw');
      equal(hasEffectStyle(), false, 'エフェクト用CSSはDOMに追加されていない');
      _this.obj = new FaceEmotion('face');
      equal(hasEffectStyle(), true, 'エフェクト用CSSはDOMに追加されている');
      equal(_this.face.getElementsByClassName('face-emotion-parts').length, 5, '#faceに顔パーツが作成される');
      equal(_this.obj.parts.tear, null, '涙は作成されない');
      return equal(_this.obj.parts.angry, null, '怒マークは作成されない');
    });
    test('effect: tear指定', function() {
      _this.obj = new FaceEmotion('face', {
        effect: {
          tear: true
        }
      });
      return notEqual(_this.obj.parts.tear, null, '涙が作成される');
    });
    test('effect: angry指定', function() {
      _this.obj = new FaceEmotion('face', {
        effect: {
          angry: true
        }
      });
      return notEqual(_this.obj.parts.angry, null, '怒マークが作成される');
    });
    test('effect: tear & angry指定', function() {
      _this.obj = new FaceEmotion('face', {
        effect: {
          tear: true,
          angry: true
        }
      });
      notEqual(_this.obj.parts.tear, null, '涙が作成される');
      return notEqual(_this.obj.parts.angry, null, '怒マークが作成される');
    });
    test('サイズ指定', function() {
      var outline, size;
      size = 500;
      _this.obj = new FaceEmotion('face', {
        size: size
      });
      outline = _this.face.getElementsByClassName('face-emotion-outline')[0];
      equal(outline.style.width, "" + size + "px", 'size = width');
      return equal(outline.style.height, "" + size + "px", 'size = height');
    });
    /**
    * state
    */

    module('FaceEmotion: state', {
      setup: function() {},
      teardown: function() {}
    });
    test('new直後', function() {
      _this.obj = new FaceEmotion('face');
      return deepEqual(_this.obj.state(), {
        eyebrow: 0,
        eye: 0,
        mouth: 0
      }, '初期状態: ALL0');
    });
    asyncTest('set(name, value)後', function() {
      return _this.obj.set('mouth', -20, {
        complete: function() {
          start();
          return deepEqual(_this.obj.state(), {
            eyebrow: 0,
            eye: 0,
            mouth: -20
          }, 'state()の値と同期されている');
        }
      });
    });
    asyncTest('set(parts)後', function() {
      return _this.obj.set({
        eyebrow: -50,
        eye: -30,
        mouth: 30
      }, {
        complete: function() {
          start();
          return deepEqual(_this.obj.state(), {
            eyebrow: -50,
            eye: -30,
            mouth: 30
          }, 'state()の値と同期されている');
        }
      });
    });
    test('set(name, value, { animate: false })後', function() {
      _this.obj.set('mouth', 100, {
        animate: false
      });
      return deepEqual(_this.obj.state(), {
        eyebrow: -50,
        eye: -30,
        mouth: 100
      }, 'state()の値と同期されている');
    });
    test('set(parts,  { animate: false })後', function() {
      _this.obj.set({
        eyebrow: 70,
        eye: 100,
        mouth: 30
      }, {
        animate: false
      });
      return deepEqual(_this.obj.state(), {
        eyebrow: 70,
        eye: 100,
        mouth: 30
      }, 'state()の値と同期されている');
    });
    test('100を超える値を指定', function() {
      _this.obj.set('mouth', 1000, {
        animate: false
      });
      return deepEqual(_this.obj.state().mouth, 100, 'state()の値は100');
    });
    asyncTest('-100を下回る値を指定', function() {
      return _this.obj.set({
        eyebrow: -1000,
        eye: -101,
        mouth: -999
      }, {
        complete: function() {
          start();
          return deepEqual(_this.obj.state(), {
            eyebrow: -100,
            eye: -100,
            mouth: -100
          }, 'state()の値は-100');
        }
      });
    });
    /**
    * set
    */

    module('FaceEmotion: set', {
      setup: function() {
        clear();
        return _this.obj = new FaceEmotion('face', {
          effect: {
            tear: true,
            angry: true
          }
        });
      },
      teardown: function() {}
    });
    cssCheck = function(parts, effect) {
      var b, base, cc, expcss, i, i1, i2, key, n, prop, r, range, ranges, s1, s2, seed, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _ref, _ref1, _results;
      expcss = {
        parts: {},
        effect: {}
      };
      _ref = _this.obj.parts[parts].obj.css;
      for (cc in _ref) {
        prop = _ref[cc];
        expcss.parts[cc] = prop;
      }
      if (effect != null) {
        _ref1 = _this.obj.parts[effect].obj.css;
        for (cc in _ref1) {
          prop = _ref1[cc];
          expcss.effect[cc] = prop;
        }
      }
      base = [0, 50, 100];
      seed = [];
      for (i = _i = 0, _len = base.length; _i < _len; i = ++_i) {
        b = base[i];
        if (i !== 0) {
          n = b - 1;
          seed.push(n);
          seed.push(n * -1);
        }
        if (b !== 0) {
          seed.push(b);
          seed.push(b * -1);
        }
        if (i !== base.length - 1) {
          n = b + 1;
          seed.push(n);
          seed.push(n * -1);
        }
      }
      seed.sort(function(a, b) {
        return a - b;
      });
      ranges = [];
      for (i1 = _j = 0, _len1 = seed.length; _j < _len1; i1 = ++_j) {
        s1 = seed[i1];
        for (i2 = _k = 0, _len2 = seed.length; _k < _len2; i2 = ++_k) {
          s2 = seed[i2];
          if (i1 !== i2) {
            ranges.push([s1, s2, 0]);
          }
        }
      }
      key = parts.toLowerCase().replace(/(right|left)$/, '');
      _results = [];
      for (_l = 0, _len3 = ranges.length; _l < _len3; _l++) {
        range = ranges[_l];
        for (_m = 0, _len4 = range.length; _m < _len4; _m++) {
          r = range[_m];
          _this.obj.set(key, r, {
            animate: false
          });
        }
        deepEqual(_this.obj.parts[parts].obj.css, expcss.parts, "" + parts + ": " + range[0] + "～" + range[1]);
        if (effect != null) {
          _results.push(deepEqual(_this.obj.parts[effect].obj.css, expcss.effect, "" + effect + ": " + range[0] + "～" + range[1]));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };
    test('set後のCSS状態のズレ: eyeBrowLeft', function() {
      return cssCheck('eyeBrowLeft');
    });
    test('set後のCSS状態のズレ: eyeBrowRight', function() {
      return cssCheck('eyeBrowRight', 'angry');
    });
    test('set後のCSS状態のズレ: eyeLeft', function() {
      return cssCheck('eyeLeft', 'tear');
    });
    test('set後のCSS状態のズレ: eyeRight', function() {
      return cssCheck('eyeRight');
    });
    test('set後のCSS状態のズレ: mouth', function() {
      return cssCheck('mouth');
    });
    return asyncTest('set()が完了する前にset()', function() {
      _this.obj.set('eye', -100, {
        speed: 100
      });
      return setTimeout(function() {
        var param;
        param = {
          eyebrow: 100,
          eye: 100,
          mouth: 100
        };
        return _this.obj.set(param, {
          complete: function() {
            start();
            return deepEqual(_this.obj.state(), param, '後から実行したset()の値が有効');
          }
        });
      }, 1000);
    });
  };

  switch (true) {
    case this.addEventListener != null:
      this.addEventListener('load', suite, false);
      break;
    case this.attachEvent != null:
      this.attachEvent('onload', suite);
      break;
    default:
      this.onload = suite;
  }

}).call(this);
