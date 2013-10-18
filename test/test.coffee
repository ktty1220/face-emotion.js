###
ok(actual, message): actual == true
equal(actual, expected, message): actual == expected
notEqual(actual, expected, message): actual != expected
deepEqual(a, b, message)
notDeepEqual(a, b, message)
strictEqual(actual, expected, message): actual === expected
notStrictEqual(actual, expected, message): actual !== expected
###
suite = () ->
  QUnit.config.reorder = false
  faceEmo = null

  clear = () =>
    @face.removeChild @face.firstChild while @face.firstChild
    faceEmo = null

  hasEffectStyle = () ->
    tmp = document.createElement 'div'
    tmp.className = 'face-emotion-angry'
    tmp.style.display = 'none'
    document.body.appendChild tmp
    style = document.defaultView?.getComputedStyle?(tmp, '') ? { height: '10px' }
    result = parseInt(style.height, 10) > 0
    document.body.removeChild tmp
    result

  ###*
  * new
  ###
  module 'FaceEmotion: new',
    setup: () =>
    teardown: () => clear()
    
  test 'オプションなし', () =>
    equal hasEffectStyle(), false, 'エフェクト用CSSはDOMに追加されていない'
    throws (() => new FaceEmotion 'no-face'), '存在しないIDを指定してnew -> throw'
    equal hasEffectStyle(), false, 'エフェクト用CSSはDOMに追加されていない'
    faceEmo = new FaceEmotion 'face'
    equal hasEffectStyle(), true, 'エフェクト用CSSはDOMに追加されている'
    equal @face.getElementsByClassName('face-emotion-parts').length, 5, '#faceに顔パーツが作成される'
    equal faceEmo.parts.tear, null, '涙は作成されない'
    equal faceEmo.parts.angry, null, '怒マークは作成されない'

  test 'effect: tear指定', () =>
    faceEmo = new FaceEmotion 'face', effect: tear: true
    notEqual faceEmo.parts.tear, null, '涙が作成される'

  test 'effect: angry指定', () =>
    faceEmo = new FaceEmotion 'face', effect: angry: true
    notEqual faceEmo.parts.angry, null, '怒マークが作成される'

  test 'effect: tear & angry指定', () =>
    faceEmo = new FaceEmotion 'face', effect: { tear: true, angry: true }
    notEqual faceEmo.parts.tear, null, '涙が作成される'
    notEqual faceEmo.parts.angry, null, '怒マークが作成される'

  test 'サイズ指定', () =>
    size = 500
    faceEmo = new FaceEmotion 'face', size: size
    outline = @face.getElementsByClassName('face-emotion-outline')[0]
    equal outline.style.width, "#{size}px", 'size = width'
    equal outline.style.height, "#{size}px", 'size = height'

  ###*
  * state
  ###
  module 'FaceEmotion: state',
    setup: () =>
    teardown: () =>
    
  test 'new直後', () =>
    faceEmo = new FaceEmotion 'face'
    deepEqual faceEmo.state(), { eyebrow: 0, eye: 0, mouth: 0 }, '初期状態: ALL0'

  asyncTest 'set(name, value)後', () =>
    faceEmo.set 'mouth', -20, 
      complete: () =>
        start()
        deepEqual faceEmo.state(), { eyebrow: 0, eye: 0, mouth: -20 }, 'state()の値と同期されている'

  asyncTest 'set(parts)後', () =>
    faceEmo.set { eyebrow: -50, eye: -30, mouth: 30 },
      complete: () =>
        start()
        deepEqual faceEmo.state(), { eyebrow: -50, eye: -30, mouth: 30 }, 'state()の値と同期されている'

  test 'set(name, value, { animate: false })後', () =>
    faceEmo.set 'mouth', 100, animate: false
    deepEqual faceEmo.state(), { eyebrow: -50, eye: -30, mouth: 100 } , 'state()の値と同期されている'

  test 'set(parts,  { animate: false })後', () =>
    faceEmo.set { eyebrow: 70, eye: 100, mouth: 30 }, animate: false
    deepEqual faceEmo.state(), { eyebrow: 70, eye: 100, mouth: 30 }, 'state()の値と同期されている'

  test '100を超える値を指定', () =>
    faceEmo.set 'mouth', 1000, animate: false
    deepEqual faceEmo.state().mouth, 100, 'state()の値は100'

  asyncTest '-100を下回る値を指定', () =>
    faceEmo.set { eyebrow: -1000, eye: -101, mouth: -999 },
      complete: () =>
        start()
        deepEqual faceEmo.state(), { eyebrow: -100, eye: -100, mouth: -100 }, 'state()の値は-100'

  ###*
  * set
  ###
  module 'FaceEmotion: set',
    setup: () =>
      clear()
      faceEmo = new FaceEmotion 'face', effect: { tear: true, angry: true }
    teardown: () =>

  cssCheck = (parts, effect) =>
    expcss =
      parts: {}
      effect: {}

    expcss.parts[cc] = prop for cc, prop of faceEmo.parts[parts].obj.css
    expcss.effect[cc] = prop for cc, prop of faceEmo.parts[effect].obj.css if effect?

    base = [ 0, 50, 100 ]
    seed = []
    for b, i in base
      if i isnt 0
        n = b - 1
        seed.push n
        seed.push n * -1
      if b isnt 0
        seed.push b
        seed.push b * -1
      if i isnt base.length - 1
        n = b + 1
        seed.push n
        seed.push n * -1
    seed.sort (a, b) -> a - b

    ranges = []

    for s1, i1 in seed
      for s2, i2 in seed
        ranges.push [ s1, s2, 0 ] if i1 isnt i2

    key = parts.toLowerCase().replace /(right|left)$/, ''
    for range in ranges
      faceEmo.set key, r, animate: false for r in range
      deepEqual faceEmo.parts[parts].obj.css, expcss.parts, "#{parts}: #{range[0]}～#{range[1]}"
      deepEqual faceEmo.parts[effect].obj.css, expcss.effect, "#{effect}: #{range[0]}～#{range[1]}" if effect?

  test 'set後のCSS状態のズレ: eyeBrowLeft', () => cssCheck 'eyeBrowLeft'
  test 'set後のCSS状態のズレ: eyeBrowRight', () => cssCheck 'eyeBrowRight', 'angry'
  test 'set後のCSS状態のズレ: eyeLeft', () => cssCheck 'eyeLeft', 'tear'
  test 'set後のCSS状態のズレ: eyeRight', () => cssCheck 'eyeRight'
  test 'set後のCSS状態のズレ: mouth', () => cssCheck 'mouth'
      
  asyncTest 'set()が完了する前にset()', () =>
    faceEmo.set 'eye', -100, speed: 100
    setTimeout () =>
      param = { eyebrow: 100, eye: 100, mouth: 100 }
      faceEmo.set param,
        complete: () =>
          start()
          deepEqual faceEmo.state(), param, '後から実行したset()の値が有効'
    , 1000

switch true
  when @addEventListener? then @addEventListener 'load', suite, false
  when @attachEvent? then @attachEvent 'onload', suite
  else @onload = suite
