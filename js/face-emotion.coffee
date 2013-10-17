###!
* face-emotion.js v0.1.0
*
* https://github.com/ktty1220/face-emotion.js
*
* Copyright (c) 2013 ktty1220 ktty1220@gmail.com
* Licensed under the MIT license
###

'use strict'

commonPrefix = 'face-emotion-'
effectStyleAdded = false

util =
  ###*
  * ベンダープレフィックスを付加したプロパティの配列を返す
  *
  * @param prop CSSプロパティ名
  * @return ベンダープレフィックスを付加したプロパティの配列
  ###
  venderPrefix: (prop) ->
    result = [ prop ]
    initCapPrefix = "#{prop.substr(0, 1).toUpperCase()}#{prop.substr 1}"
    for vp in [ 'ms', 'Webkit', 'Moz', 'O' ]
      result.push "#{vp}#{initCapPrefix}"
    result

  ###*
  * 4辺の値が同じborder-radiusプロパティを作成
  *
  * @param prop 丸角の値
  * @return 4辺のプロパティと値の連想配列
  ###
  borderRadius: (value) ->
    borderTopLeftRadius: value
    borderTopRightRadius: value
    borderBottomRightRadius: value
    borderBottomLeftRadius: value

  ###*
  * border-widthをまとめて指定
  *
  * @param prop 各borderの値(CSSでの定義と同仕様)
  * @return 4辺のプロパティと値の連想配列
  ###
  borderWidth: (top, right, bottom, left) ->
    borderTopWidth: top
    borderRightWidth: right ? top
    borderBottomWidth: bottom ? top
    borderLeftWidth: left ? right ? top

  ###*
  * 小数を含む演算は途中から誤差が発生してくるので自力で計算(小数第2位までの計算限定)
  *
  * @param value1 値1
  * @param value2 値2
  * @return 値1 + 値2
  ###
  sum: (value1, value2) ->
    ### 100倍して整数にしてから加算 ###
    n = Math.round((value1 * 100) + (value2 * 100))
    ### 加算後の値の正負を保存 ###
    sign = if n < 0 then '-' else ''
    ### 文字列の段階で小数点を後ろから3文字目に挿入して数値化 ###
    parseFloat("#{sign}00#{Math.abs n}".replace /(..)$/, '.$1')

  ###*
  * 文字列を含むCSSプロパティから数字部分だけ取得
  *
  * @param prop CSSプロパティの値
  * @return 数字部分(数値型)
  ###
  styleNumValue: (prop) -> parseFloat(("#{prop}".match(/(-?[\d\.]+)/) ? [])[1] ? '0')

  ###*
  * キャメルケースの文字列を展開
  *
  * @param str キャメルケースの文字列
  * @return 展開後の文字列
  ###
  caseConv: (str) -> str.replace /[A-Z]/g, (m) -> "-#{m.toLowerCase()}"

  ###*
  * 短縮したCSSセレクタ名を展開
  *
  * @param str 短縮状態のCSSセレクタ名
  * @return 展開後のCSSセレクタ名
  ###
  expandSelector: (prefix, str = '') ->
    ### ':b' -> ':before', ':a' -> ':after' & カンマ区切りで分割 ###
    tmp = str.replace(/:a/g, ':after').replace(/:b/g, ':before').split ','
    ### 分割した各セレクタにプレフィックスを付加 ###
    sarray = []
    for t in tmp
      t = "-#{t}" if t.length > 0 and t.substr(0, 1) isnt ':'
      sarray.push ".#{commonPrefix}#{prefix}#{t}"
    ### またつなげる ###
    sarray.join ",\n"

  ###*
  * エフェクト系のスタイルをDOMに追加
  *
  * @param effects エフェクトスタイル設定
  ###
  addEffectStyle: (effects) ->
    ### すでに追加済なら何もしない ###
    return if effectStyleAdded
    rule = ''

    ### 短縮表記のオブジェクトをスタイルシートに書き込む文字列として展開 ###
    for type, info of effects
      for sel, sty of info
        rule += "#{util.expandSelector(type, sel)} {\n"
        for cc, prop of sty
          prop += 'px' if typeof(prop) is 'number'
          rule += "  #{util.caseConv(cc)}: #{prop};\n"
        rule += "}\n"

    ### DOMにstyleタグを追加して書き込み ###
    head = document.getElementsByTagName('head')[0]
    style = document.createElement 'style'
    rules = document.createTextNode rule
    style.type = 'text/css'

    if style.styleSheet
      style.styleSheet.cssText = rules.nodeValue
    else
      style.appendChild rules
    head.appendChild style
    effectStyleAdded = true

###*
* 各パーツのベースとなるクラス
*
* @class FaceParts
###
class FaceParts
  ### 全パーツ共通CSSプロパティ ###
  commonCss:
    position: 'absolute'
    background: 'transparent'
    borderStyle: 'solid'
    borderColor: '#000'
    height: 0
    zIndex: '10'

  ###*
  * コンストラクタ
  *
  * @param opt オプション(FaceEmotion()呼び出し時に渡されたものがそのまま入る)
  * @param pos パーツの左右の識別子('left' or 'right')
  ###
  constructor: (@opt, @pos) ->
    ### 継承先の初期処理 ###
    @init()

    ### エレメントを作成してCSS適用 ###
    @el = document.createElement 'div'
    if @pos is 'effect'
      @el.className = "#{commonPrefix}effect #{commonPrefix}#{@name}"
    else
      @el.className = "#{commonPrefix}parts #{commonPrefix}#{@name}"
      @setStyle @commonCss
      @setStyle @css

    ### 目などの対になるパーツの傾き方向 ###
    @deg = if @pos is 'left' then -1 else if @pos is 'right' then 1 else 0

    ### 初期状態位置 ###
    @cur = 100

    ### アニメーションのタイマー ###
    @timer = null

  ###*
  * パーツの状態変化を1ステップ進める
  *
  * @param animate true: アニメーションさせる(即時反映), false: 内部CSSプロパティだけ更新
  ###
  progress: (animate = true) =>
    state = @calc() ? {}
    @applyCss state
    @setStyle state if animate
    @cur += @step

  ###*
  * アニメーションを中断する
  ###
  abort: () =>
    if @timer?
      clearInterval @timer
      @timer = null

  ###*
  * パーツの状態を変化させる
  *
  * @param value 変更させる状態位置
  * @param options オプション
  * @param callback 変化完了後に呼び出されるコールバック関数
  ###
  set: (value = 0, options = {}, callback) =>
    @effect.set value, options if @effect?

    @goto = value

    ### 100や-100を超えてたら補正 ###
    @goto = if @goto > 100 then 100 else if @goto < -100 then -100 else @goto

    ### -100～100だと管理が面倒なので0～200にする ###
    @goto += 100

    ### 現在の状態からプラス方向に進むかマイナス方向に進むかの識別値 ###
    @step = if @goto > @cur then 1 else if @goto < @cur then -1 else 0

    ### マイナス方向に進む場合は各状態値の判定ボーダーを1つずらす(そうしないと計算が狂ってくる) ###
    @adjust = if @step is -1 then 1 else 0

    count = 0
    range = Math.abs(@goto - @cur)
    if options.animate
      ### アニメーションの場合はタイマー起動 ###
      @timer = setInterval () =>
        @progress true
        if ++count >= range
          @abort()
          callback?()
      , options.speed
    else
      ### 内部CSSプロパティ変更のみ ###
      @progress false for i in [0...range]
      @setStyle @css
      callback?()

  ###*
  * 内部CSSプロパティ更新
  *
  * @param style CSSプロパティの連想配列
  ###
  applyCss: (styles = {}) => @css[cc] = prop for cc, prop of styles

  ###*
  * エレメントのCSSを更新
  *
  * @param style CSSプロパティの連想配列
  ###
  setStyle: (styles = {}) =>
    for cc, prop of styles
      ### 数字なら'px'を付加 ###
      prop += 'px' if typeof(prop) is 'number'
      @el.style[cc] = prop

###*
* 眉毛パーツ
*
* @class EyeBrow
###
class EyeBrow extends FaceParts
  ###*
  * 初期処理(親クラスのコンストラクタから呼ばれる)
  ###
  init: () ->
    ### 左右の指定がなければエラー ###
    throw new Error "invalid Eye position: #{@pos}" unless /^(right|left)$/.test @pos

    ### エレメントのクラス名に入れるパーツ名 ###
    @name = "eyebrow-#{@pos}"

    ### パーツ独自のCSS ###
    @css =
      top: @opt.size / 200 * 45
      width: @opt.size / 10 * 2
      height: 0
      borderTopWidth: @opt.size / 200 * 5
      borderBottomWidth: @opt.size / 200 * 5
    @css[@pos] = @opt.size / 10 * 2
    @css[tf] = 'rotate(0deg)' for tf in util.venderPrefix 'transform'

  ###*
  * 状態位置に対するCSSプロパティの算出
  *
  * @return 算出したCSSプロパティ
  ###
  calc: () =>
    tr = util.sum util.styleNumValue(@css.transform), (-0.3 * @step * @deg)
    tmp = {}
    tmp[tf] = "rotate(#{tr}deg)" for tf in util.venderPrefix 'transform'
    tmp

###*
* 目パーツ
*
* @class EyeBrow
###
class Eye extends FaceParts
  ###*
  * 初期処理(親クラスのコンストラクタから呼ばれる)
  ###
  init: () ->
    ### 左右の指定がなければエラー ###
    throw new Error "invalid Eye position: #{@pos}" unless /^(right|left)$/.test @pos

    ### エレメントのクラス名に入れるパーツ名 ###
    @name = "eye-#{@pos}"

    ### パーツ独自のCSS ###
    @css =
      top: @opt.size / 20 * 7
      width: @opt.size / 20 * 3
      height: 1
      backgroundColor: '#000'
      borderTopColor: '#000'
      borderBottomColor: '#000'
    @css[@pos] = @opt.size / 20 * 5
    @css[tf] = 'rotate(0deg)' for tf in util.venderPrefix 'transform'
    @css[cc] = prop for cc, prop of util.borderRadius '50%'
    @css[cc] = prop for cc, prop of util.borderWidth @opt.size / 200 * 15, 0 

  ###*
  * 状態位置に対するCSSプロパティの算出
  *
  * @return 算出したCSSプロパティ
  ###
  calc: () =>
    tmp = {}
    switch true
      when @cur < 50 + @adjust
        ### < 50 (実質 -50～-100) ###
        tmp.top = util.sum @css.top, (0.1 * @step)
        tmp.height = util.sum @css.height, (-0.3 * @step)
        tmp[@pos] = util.sum @css[@pos], (-0.05 * @step)
        tr = util.sum util.styleNumValue(@css.transform), (-0.4 * @step * @deg)
        tmp[tf] = "rotate(#{tr}deg)" for tf in util.venderPrefix 'transform'
      when @cur < 100 + @adjust
        ### < 100 (実質 0～-50) ###
        if @cur is 50 + @adjust
          if @step is 1
            tmp.borderTopColor = tmp.backgroundColor = '#000'
            tmp.borderTopLeftRadius = tmp.borderTopRightRadius = '30%'
            br = 30.4
          else
            tmp.borderTopColor = tmp.backgroundColor = 'transparent'
            tmp.borderTopLeftRadius = tmp.borderTopRightRadius = '0%'
            br = 0
        else
          br = util.sum util.styleNumValue(@css.borderTopLeftRadius), (0.4 * @step)
        tmp.borderTopLeftRadius = tmp.borderTopRightRadius = "#{br}%"
        tmp.borderTopWidth = util.sum @css.borderTopWidth, (0.3 * @step)
        tmp.borderBottomWidth = util.sum @css.borderBottomWidth, (0.05 * @step)
      when @cur < 150 + @adjust
        ### < 150 (実質 50～0) ###
        tmp.borderTopWidth = util.sum @css.borderTopWidth, (-0.05 * @step)
        tmp.borderBottomWidth = util.sum @css.borderBottomWidth, (-0.3 * @step)
        br = util.sum util.styleNumValue(@css.borderBottomLeftRadius), (-0.25 * @step)
        tmp.borderBottomLeftRadius = tmp.borderBottomRightRadius = "#{br}%"
      else
        ### < 200 (実質 100～50) ###
        if @cur is 150 + @adjust
          if @step is 1
            tmp.borderBottomColor = tmp.backgroundColor = 'transparent'
            tmp.borderBottomLeftRadius = tmp.borderBottomRightRadius = tmp.height = 0
          else
            tmp.borderBottomColor = tmp.backgroundColor = '#000'
            tmp.borderBottomLeftRadius = tmp.borderBottomRightRadius = '37.5%'
        tmp.height = util.sum @css.height, (0.5 * @step)
    tmp

###*
* 口パーツ
*
* @class Mouth
###
class Mouth extends FaceParts
  ### エレメントのクラス名に入れるパーツ名 ###
  name: 'mouth'

  ###*
  * 初期処理(親クラスのコンストラクタから呼ばれる)
  ###
  init: () ->
    ### パーツ独自のCSS ###
    @css =
      top: @opt.size / 10 * 7
      left: @opt.size / 10 * 3
      width: @opt.size / 10 * 4
      height: 0
    @css[cc] = prop for cc, prop of util.borderRadius '0%'
    @css[cc] = prop for cc, prop of util.borderWidth @opt.size / 20, 0, 0 

  ###*
  * 状態位置に対するCSSプロパティの算出
  *
  * @return 算出したCSSプロパティ
  ###
  calc: () =>
    switch true
      when @cur < 50 + @adjust
        ### < 50 (実質 -50～-100) ###
        tmp =
          top: util.sum @css.top, (0.3 * @step)
          borderTopWidth: util.sum @css.borderTopWidth, (-0.8 * @step)
      when @cur < 100 + @adjust
        ### < 100 (実質 0～-50) ###
        tmp =
          top: util.sum @css.top, (0.1 * @step)
          left: util.sum @css.left, (0.2 * @step)
          width: util.sum @css.width, (-0.4 * @step)
          height: util.sum @css.height, (-1.5 * @step)
        br = util.sum util.styleNumValue(@css.borderTopLeftRadius), (-1 * @step)
        tmp.borderTopLeftRadius = tmp.borderTopRightRadius = "#{br}%"
      when @cur < 150 + @adjust
        ### < 150 (実質 50～0) ###
        tmp =
          top: util.sum @css.top, (-2 * @step)
          left: util.sum @css.left, (-0.4 * @step)
          width: util.sum @css.width, (0.8 * @step)
          height: util.sum @css.height, (2.4 * @step)
        br = util.sum util.styleNumValue(@css.borderBottomLeftRadius), (1 * @step)
        tmp.borderBottomLeftRadius = tmp.borderBottomRightRadius = "#{br}%"
        if @cur is 100 + @adjust
          if @goto > 100 + @adjust
            tmp.borderTopWidth = 0
            tmp.borderBottomWidth = @opt.size / 20
          else
            tmp.borderTopWidth = @opt.size / 20
            tmp.borderBottomWidth = 0
      else
        ### < 200 (実質 100～50) ###
        tmp =
          top: util.sum @css.top, (-0.5 * @step)
          borderBottomWidth: util.sum @css.borderBottomWidth, (1 * @step)
    tmp

###*
* 涙パーツ
*
* @class Tear
###
class Tear extends FaceParts
  ### エレメントのクラス名に入れるパーツ名 ###
  name: 'tear'

  ###*
  * 初期処理(親クラスのコンストラクタから呼ばれる)
  ###
  init: () ->
    @css =
      top: util.sum @opt.size / 200 * 86, 0
      opacity: '0'
    @drop = util.sum @opt.size / 200 * -0.36, 0

  ###*
  * 状態位置に対するCSSプロパティの算出
  *
  * @return 算出したCSSプロパティ
  ###
  calc: () =>
    return { opacity: '0' } if @cur > 49 + @adjust
    top: util.sum @css.top, (@drop * @step)
    opacity: '1'

###*
* 怒マークパーツ
*
* @class Angry
###
class Angry extends FaceParts
  ### エレメントのクラス名に入れるパーツ名 ###
  name: 'angry'

  ###*
  * 初期処理(親クラスのコンストラクタから呼ばれる)
  ###
  init: () ->
    @css =
      opacity: '0'

  ###*
  * 状態位置に対するCSSプロパティの算出
  *
  * @return 算出したCSSプロパティ
  ###
  calc: () =>
    return {} if @cur < 150 + @adjust
    opacity: "#{util.sum util.styleNumValue(@css.opacity), (0.02 * @step)}"

###*
* 顔パーツ(本体)
*
* @class FaceEmotion
###
class FaceEmotion
  ###*
  * コンストラクタ
  *
  * @param id パーツを設置するエレメントのID
  * @param options オプション
  ###
  constructor: (id, options = {}) ->
    ### 設置先エレメント取得 ###
    @el = document.getElementById id
    throw new Error "no such element id: #{id}" unless @el

    ### オプションデフォルト値 ###
    options.size ?= 200

    ### 怒マークや涙などのエフェクトスタイル(短縮表記) ###
    effectNum =
      tear:
        size: options.size / 200 * 12
        min: options.size / 200
      angry:
        size: options.size / 20
        border: options.size / 200 * 3
        radius: 3
    effects =
      tear:
        '':
          position: 'absolute'
          opacity: '0'
          MsFilter: '"alpha(opacity=0)"'
          zIndex: '5'
          height: effectNum.tear.size
          left: effectNum.tear.min * 60
        ':b,:a':
          content: "''"
          position: 'absolute'
        ':b':
          top: effectNum.tear.min * -4
          left: effectNum.tear.min * 1.8
          borderStyle: 'solid'
          borderColor: 'transparent'
          borderBottomColor: '#7ef'
          borderWidth: "0px #{effectNum.tear.min * 4}px #{effectNum.tear.min * 8}px"
        ':a':
          height: effectNum.tear.size
          width: effectNum.tear.size
          top: 2
          left: 0
          background: '#7ef'
          borderRadius: '50%'
      angry:
        '':
          height: effectNum.angry.size
          position: 'absolute'
          opacity: '0'
          MsFilter: '"alpha(opacity=0)"'
          zIndex: '5'
          top: effectNum.angry.size * 6
          right: effectNum.angry.size * 4
        'top,bottom':
          position: 'relative'
        'top:b,top:a,bottom:b,bottom:a':
          content: "''"
          position: 'absolute'
          width: effectNum.angry.size / 10 * 4
          height: effectNum.angry.size / 10 * 4
          borderStyle: 'solid'
          borderColor: '#f44'
          borderWidth: 0
        'top:b,top:a':
          top: 0
          borderBottomWidth: effectNum.angry.border
        'bottom:b,bottom:a':
          top: effectNum.angry.size
          borderTopWidth: effectNum.angry.border
        'top:b,bottom:b':
          left: 0
          borderRightWidth: effectNum.angry.border
        'top:a,bottom:a':
          left: effectNum.angry.size
          borderLeftWidth: effectNum.angry.border
        'top:b':
          borderBottomRightRadius: effectNum.angry.radius
        'top:a':
          borderBottomLeftRadius: effectNum.angry.radius
        'bottom:b':
          borderTopRightRadius: effectNum.angry.radius
        'bottom:a':
          borderTopLeftRadius: effectNum.angry.radius

    ### 擬似属性を含むスタイルはJavaScriptでセットできないようなのでDOMにstyleタグを追加してCSSとして書き込み ###
    util.addEffectStyle effects

    ### 輪郭エレメント作成 ###
    @outline = document.createElement 'div'
    @outline.className = "#{commonPrefix}outline"
    styles =
      background: '#fff'
      border: 'solid 4px #000'
      width: options.size
      height: options.size
      borderRadius: '50%'
      position: 'relative'
    for cc, prop of styles
      prop += 'px' if typeof(prop) is 'number'
      @outline.style[cc] = prop

    ### 各パーツ作成 ###
    @parts =
      eyeBrowLeft:
        key: 'eyebrow'
        obj: new EyeBrow options, 'left'
      eyeBrowRight:
        key: 'eyebrow'
        obj: new EyeBrow options, 'right'
      eyeLeft:
        key: 'eye'
        obj: new Eye options, 'left'
      eyeRight:
        key: 'eye'
        obj: new Eye options, 'right'
      mouth:
        key: 'mouth'
        obj: new Mouth options

    ### 顔パーツ設置 ###
    @outline.appendChild p.obj.el for n, p of @parts

    ### 涙 ###
    if options.effect?.tear
      @parts.tear =
        obj: new Tear options, 'effect'
      @outline.appendChild @parts.tear.obj.el
      ### 左目に連動させる ###
      @parts.eyeLeft.obj.effect = @parts.tear.obj

    ### 怒マーク ###
    if options.effect?.angry
      @parts.angry =
        obj: new Angry options, 'effect'
      for c in [ 'top', 'bottom' ]
        e = document.createElement 'div'
        e.className = "#{commonPrefix}effect #{commonPrefix}angry-#{c}"
        @parts.angry.obj.el.appendChild e
      @outline.appendChild @parts.angry.obj.el
      ### 右眉に連動させる ###
      @parts.eyeBrowRight.obj.effect = @parts.angry.obj

    ### 呼び出し時に指定されたエレメントに顔パーツ追加 ###
    @el.appendChild @outline

    ### 状態変更中カウント ###
    @moving = 0

  ###*
  * 現在の各パーツの状態位置取得
  *
  * @return { パーツ名: 状態位置 }の連想配列
  ###
  state: () =>
    eyebrow: @parts.eyeBrowLeft.obj.cur - 100
    eye: @parts.eyeLeft.obj.cur - 100
    mouth: @parts.mouth.obj.cur - 100

  ###*
  * 指定したパーツの状態位置変更
  *
  * @param name パーツ名もしくは{ パーツ名: 状態位置 }の連想配列
  * @param value nameにパーツ名を指定した場合は状態位置、nameに連想配列を指定した場合はオプションがずれて入る
  * @param options オプション
  ###
  set: (name, value, options = {}) =>
    ### 現在状態変更中なら中止する ###
    if @moving > 0
      p.obj.abort() for n, p of @parts

    ### 状態変更設定とオプション取得(引数に渡されたパターンにより変化) ###
    parts = {}
    if typeof(name) is 'string'
      parts[name] = value
    else
      options = value ? {}
      parts = name

    ### オプションデフォルト値 ###
    options.speed ?= 10
    options.speed = Number options.speed
    options.animate ?= true

    ### 変更させるパーツを判別して実行用配列にセット ###
    funcs = []
    for name, value of parts
      for n, p of @parts when p.key?
        if p.key is name
          funcs.push { parts: n, value: value }

    ### 状態変更実行 ###
    @moving = funcs.length
    cb = () => options.complete?() if --@moving is 0
    @parts[f.parts].obj.set f.value, options, cb for f in funcs

@FaceEmotion = FaceEmotion
