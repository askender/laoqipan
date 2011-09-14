class Board

  constructor: (@board_size, @first_color, @game_id) ->
    @stone_radius     = 12
    @board_edge       = 40.5
    @board_square     = @stone_radius*2 + 1
    @board_image_size = @board_edge*2 + (@board_size - 1) * @board_square
    @star_radius      = 3
    @color_in_turn    = @first_color

    @status           = 0
    # color of stone to be captured
    @captured_color   = "e"
    # name of dot who is in ko status
    @ko_dot           = null
    @last_move        = null
    @draw_last_move   = true
    @dots_of_star     = ["dd", "dj", "dp","jd", "jj", "jp", "pd", "pj", "pp"]
    @show_step        = false
    @step_count       = 0
    @dots             = []
    @dots_checked     = []
    @to_be_captured   = []
    
    @dead_black_count = 0
    @dead_white_count = 0
    
    @draw_game()
    
  draw_game: ->
    if @status == 0
      @init_dots()
    else if @status == 1
      @draw_dots()
      
  draw_black_stone: (name) ->
    target = @game_id + '-' + name
    $('#'+target).attr('class', 'b')
    
  draw_white_stone: (name) ->
    target = @game_id + '-' + name
    $('#'+target).attr('class', 'w')
    
  draw_last_mark: (dot) ->
    if not @draw_last_move then return

    if @show_step
      dot.show_dot_step '#f00'
    else
      target = @game_id + '-' + dot.name
      if dot.owner is "b"
        $('#'+target).attr('class', 'b last')
      else
        $('#'+target).attr('class', 'w last')

    @last_move = dot
    
  block_last_mark: -> @draw_last_move = false
  
  dredge_last_mark: -> @draw_last_move = true
  
  pass: -> @color_in_turn = if @color_in_turn is "b" then "w" else "b"
      
  init_dots: ->
    alphabet = "abcdefghijklmnopqrs".split ""
    for i in [0...alphabet.length]
      for j in [0...alphabet.length]
        dot = new BoardDot alphabet[i]+alphabet[j], @board_edge + @board_square*i, @board_edge + @board_square*j, @
          
        @dots[@dots.length] = dot
        
    @status = 1
    
  draw_dots: ->
    for dot in @dots
      if dot.owner == "b"
        @draw_black_stone dot.name
      else if dot.owner == "w"
        @draw_white_stone dot.name
      if @show_step and dot.owner isnt 'e'
        dot.show_dot_step()
    return
    
  draw_fake_stone: (dot) ->
    @refresh()
    if @last_move? then @draw_last_mark @last_move
    
    target = @game_id + '-' + dot.name
    $('#'+target).attr('class', @color_in_turn + " fake")
    
  on_dot_click: (dot) ->
    if dot?
      if @ko_dot?
        if dot.name is @ko_dot
          return false
        else
          @ko_dot = null
      # add stone, then check liberties
      if dot.occupy @color_in_turn
        @dots_checked = []
        if @is_alive dot
          dot.check_nearby_dots true
        else
          dot.check_nearby_dots false
          if @captured_color is dot.owner or @captured_color is 'e'
            @to_be_captured[@to_be_captured.length] = dot
            
        @capture_stones()
        @captured_color = 'e'
        
        if dot.step != -1
          @step_count++
          dot.step = @step_count
        if window.refresh
          @refresh()
          
        @draw_last_mark dot

      return true
    
    return false
  
  find_stone_by_name: (name) ->
    for dot in @dots
      if name is dot.name
        return dot
    return null
    
  find_stone_by_coordinates: (co) ->
    if co.length > 3 or co.length < 2
      throw "invalid coordinates"
      
    name_set = "abcdefghijklmnopqrs"
    x = "ABCDEFGHJKLMNOPQRST".indexOf co[0].toUpperCase()
    y = @board_size - parseInt co[1]+co[2], 10
    
    @find_stone_by_name name_set[x] + name_set[y]
    
  add_examined: (name) ->
    for e in @dots_checked
      if e is name
        return false
        
    @dots_checked[@dots_checked.length] = name
    return true
  
  # add stone to the capture list
  # return true on success, false if dot is already in the list
  add_captured: (dot) ->
    rc = true
    if @captured_color isnt "e"
      if @captured_color isnt dot.owner
        @captured_color = "e"
        @to_be_captured = []
    else
      for dead in @to_be_captured
        if dead.name is dot.name
          rc = false 
          break
    
    if rc
      @to_be_captured[@to_be_captured.length] = dot
      @captured_color = dot.owner
      
    return rc
  
  capture_stones: ->
    for dot in @to_be_captured
      if dot.owner is 'b'
        @dead_black_count++
      else if dot.owner is 'w'
        @dead_white_count++
      dot.owner = "e"
      dot.step = 0
    
    # update stone capture status
    $('#black_captured').text(@dead_black_count)
    $('#white_captured').text(@dead_white_count)
    @to_be_captured = []
    
  # @flag: true => same color survive, false => same color has no liberties, too
  check_with_capture: (examinee, examiner, flag) ->
    @add_examined examiner.name
    
    if typeof examinee isnt "undefined"
      if examinee.owner is "e" then return
      
      if flag
        if examinee.owner isnt examiner.owner and examinee.owner isnt "e"
          if not @is_alive examinee
            @add_captured examinee
      else
        # check opponent stone without liberties
        if examinee.owner isnt examiner.owner
          if not @is_alive examinee
            @add_captured examinee
        # if stones to be captured has same color of examiner
        if examinee.owner is examiner.owner
          # if we have same color stone in capture list
          if @captured_color is examinee.owner
            @add_captured examinee

    if flag
      if @captured_color isnt examiner.owner
        @capture_stones()
    else
      if examinee.owner isnt examiner.owner
        @capture_stones()
    
  is_alive: (dot) ->
    rc = false
    if dot.owner is "e" then return false
    @add_examined dot.name
    dots_nearby = dot.get_nearby_dots()
    
    for e in dots_nearby
      if e.owner is "e"
        # at least one liberty
        if e.name not in @dots_checked
          rc = true
          break
    
    # dot has no liberties, check nearby stones
    if rc isnt true
      for e in dots_nearby
        if e.owner is dot.owner
          if e.name not in @dots_checked
            # found an ally, recursive check this ally
            rc = @is_alive e
            if rc is true
              @to_be_captured = []
              break
            else
              # ally has no liberty too, time to die...
              @add_captured e
              
    if rc is true
      @dots_checked = []
    return rc
    
  refresh : ->
    board = @game_id.split('-')[0]
    if board is 'board'
      $('#board .board_fallback_area div').attr('class', 'e')
    else if board is 'board_review'
      $('#board_review .board_fallback_area div').attr('class', 'e')
    
    for dot in @dots
      dot.refresh()
      
    @draw_game()
    
  reset : ->
    @step_count = 0
    for dot in @dots
      dot.reset()
    @color_in_turn = @first_color
    @dead_black_count = 0
    @dead_white_count = 0
    @refresh()
    
  click_via_coordinates: (coordinates, color) ->
    if color?
      @color_in_turn = color
    if coordinates.length > 3 or coordinates.length < 2
      throw 'invalid coordinates'
    
    dot = @find_stone_by_coordinates coordinates
    @on_dot_click dot
    
  click_via_name: (name, color) ->
    if color?
      @color_in_turn = color
      
    if name.length != 2
      if name.length != 0
        throw 'invalid sgf move name'
        
    if name is ''
      if @color_in_turn is "b"
        @color_in_turn = 'w'
      else if @color_in_turn is 'w'
        @color_in_turn = 'b'
    else
      dot = @find_stone_by_name name.toLowerCase()
      @on_dot_click dot
      
  set_text : (dot_name, text) ->
    if dot_name.length != 2 then throw 'invalid sgf move name'
    dot = @find_stone_by_name dot_name.toLowerCase()
    dot.set_text text
    
  click : (click_fn) ->
    target = @game_id.split('-')[0]
    if target is 'board'
      $('#board .e').bind('click', click_fn)
    else
      $('#board_review .e').bind('click', click_fn)
    
  remove_click_fn : (click_fn) ->
    target = @game_id.split('-')[0]
    if target is 'board'
      $('#board .e').unbind('click', click_fn)
    else
      $('#board_review .e').unbind('click', click_fn)
      
class BoardDot

  constructor: (@name, @x, @y, @parent) ->
    @step = 0
    @is_star = false
    for v in @parent.dots_of_star
      if v == @name
        @is_star = true
        break
    @owner = "e"
  
  occupy: (color) ->
    if @owner isnt "e" 
      return false
      
    if @parent.color_in_turn is "b"
      @parent.draw_black_stone @name
      @parent.color_in_turn = "w"
    else if @parent.color_in_turn is "w"
      @parent.draw_white_stone @name
      @parent.color_in_turn = "b"
      
    @owner = color
    return true
  
  reset: ->
    @owner = "e"
    @step = 0
    
  refresh: ->
    target = @parent.game_id + '-' + @name
    $('#'+target).text('')
    $('#'+target).removeAttr('style')
    
  set_text: (text) ->
    target = @parent.game_id + '-' + @name
    $('#'+target).text(text)
    $('#'+target).css({"background-color":'#FFCC66';})
    
  show_dot_step: (color) ->
    return if @step is -1
    if @step is 0
      @step = @parent.step_count + 1
      
    target = @parent.game_id + '-' + @name
    $('#'+target).text(@step)
    
    if color?
      font_color = color
    else
      if @owner is "b"
        font_color = '#fff'
      else
        font_color = '#000'
    
    $('#'+target).css({color:font_color})
    
  get_dot_from: (pos) ->
    alphabet = 'abcdefghijklmnopqrs'
    my_x_index = alphabet.indexOf @name[0]
    my_y_index = alphabet.indexOf @name[1]
    if pos is "left"
      if my_x_index > 0
        x = my_x_index - 1
        y = my_y_index
    else if pos is "right"
      if my_x_index < 18
        x = my_x_index + 1
        y = my_y_index
    else if pos is "top"
      if my_y_index > 0
        x = my_x_index
        y = my_y_index - 1
    else if pos is "bottom"
      if my_y_index < 18
        x = my_x_index
        y = my_y_index + 1
        
    if typeof x isnt 'undefined' and typeof y isnt 'undefined'
      return @parent.find_stone_by_name(alphabet[x] + alphabet[y])
    else
      return null
  
  get_nearby_dots: ->
    dots = []
    for w in ["left", "right", "top", "bottom"]
      dot = @get_dot_from w
      if dot?
        dots[dots.length] = dot
      else
        continue
        
    return dots
     
  # @flag: true => sibling dots of same color live
  #        false => sibling dots of same color die
  check_nearby_dots: (flag) ->
    dots = @get_nearby_dots()
    
    if not flag
      # this dot has no liberties, check ko status first
      if not @has_ally()
        # and it has no allies
        for dot in dots
          if not dot.has_ally()
            if @parent.ko_dot?
              # there are more than one stones nearby surrounded by opponents
              # so it's not in ko status
              @parent.ko_dot = null
              break
            else
              @parent.ko_dot = dot.name
              
    for dot in dots
      @parent.check_with_capture dot, @, flag
    @parent.capture_stones()
          
  has_ally: ->
    dots = @get_nearby_dots()
    
    for dot in dots
      if dot.owner is @owner or dot.owner is 'e'
        return true
    
    return false
    
window.bind_review = ->
  on_review_click

window.on_review_click = (e) ->
  move = {}
  name = e.target.id.split('-')[2]
  dot = review.board.find_stone_by_name name
  if dot?
    if dot.owner isnt 'e' then return
    if review.board.on_dot_click(dot) is true
      key = dot.owner.toUpperCase()
      value = dot.name
      
      branch = review.branch_start_with(key, value)
      if !review.master.property[review.step+1] 
        # at the end of master node
        if branch? 
          # and clicked dot included in branches
          # track node path
          if review.track[review.track.length-1] isnt branch
            review.track.push(branch)
          # assign branch property to @master
          review.master = branch
          review.step   = 1
        else if review.master.branches.length > 0
          # clicked dot not included in current branches
          # so, create a new branch
          data = {}
          data[key] = value
          new_branch = create_branch(data)
          review.fork_branches(new_branch)
          if review.track[review.track.length-1] isnt branch
            review.track.push(new_branch)
          review.master = new_branch
          review.step   = 1
        else
          # at the end of master node, have no branches
          data = {}
          data[key] = value
          review.master.property.push(data)
          review.step++
      else
        # not at the end of master branch
        next_node = review.master.property[review.step+1]
        if next_node[key] is value
          # click node is the next node
          return
        else
          data = {}
          data[key] = value
          new_branch = create_branch(data)
          review.fork_branches(new_branch)
          if review.track[review.track.length-1] isnt branch
            review.track.push(new_branch)
          review.master = new_branch
          review.step   = 1
        
      review.sgf_json = review.track[0]
      $('#game_review').attr('sgf', to_sgf(review.sgf_json))

window.bind_click = ->
  on_player_click
window.on_player_click = (e) ->
  move           = {}
  game_mode      = $('#game').attr('mode')
  game_status    = $('#game').attr('status')
  black_player   = $('#game').attr('black_player')
  white_player   = $('#game').attr('white_player')
  current_player = $('#game').attr('current_player')
  current_user   = $('#game').attr('current_user')
  if game_mode isnt 0
    if current_player isnt current_user or game_status is '1'
      return

  name = e.target.id.split('-')[2]
  dot = player.board.find_stone_by_name name
  player.board.draw_fake_stone dot
  if clock_status is 0
    rattle_clock()
  window.pendding_move = ->
    if player.board.on_dot_click(dot) is true
      move[dot.owner.toUpperCase()] = dot.name
      player.parser.update_game move
      if black_player is current_player
        $('#game').attr('current_player', white_player)
      else
        $('#game').attr('current_player', black_player)
      # for better user experience
      $('#pass').hide()
      $('#score').hide()
      $('#resign').hide()
      $('#clock').hide()
      if window.board_game_id?
        $.post('http://' + window.location.host + '/games/' + window.board_game_id  + '/moves', {"sgf":$("#game").attr("sgf"), "player_id":$("#game").attr("current_user")})

window.post_comments = ->
  (e) ->
    if e.keyCode is 13
      if e.ctrlKey
        $('#post_button').trigger('click')
        
window.bind_key_fn = ->
  (e) ->
    charCode = e.which
    charStr = String.fromCharCode charCode
    switch charStr
      when "n" then $("#next").trigger("click")
      when "p" then $("#prev").trigger("click")
      when "a" then $("#start").trigger("click")
      when "e" then $("#end").trigger("click")
      when "s" then $("#show_steps").trigger("click")

window.Board = Board
window.BoardDot = BoardDot
window.refresh = true
window.sound_enabled = true
window.loaded_sounds = new Array()
window.pendding_move = null
    

    