-- bounciiing balls
-- colliiisions
-- v.0.1
-- =========================
-- TO DO
-- - midi clock in
-- - midi cc implementation

tempo = 100 --bpm
div = 6 --subdivide tempo e.g. 4 is 16th notes
tempo = 60/(tempo*div) --bpm to time

-- =========================
-- BALLS
-- =========================
balls = {
  {
    x = nil, y = nil,
    dx = 1, dy = 1,
    start_x = nil, start_y = nil,
    prev_x = 0, prev_y = 0,
    origin_timer = 0,
    origin_active = false,
    running = false
  },
  {
    x = nil, y = nil,
    dx = -1, dy = 1,
    start_x = nil, start_y = nil,
    prev_x = 0, prev_y = 0,
    origin_timer = 0,
    origin_active = false,
    running = false
  }
}
current_ball = 1

-- =========================
-- STATE
-- =========================
collision = false
collision_active = false
collision_timer = 0
collision_x = nil
collision_y = nil

origin_collision = false
origin_collision_x = nil
origin_collision_y = nil
origin_timer = 0
origin_active = false
origin_note = {48,55,45,43}
current_ori_note = 1

-- LEFT HEMISPHERE
left_b = nil
left_note = {60,62,64,67,69,66,71,74}

-- RIGHT HEMISPHERE
right_b = nil
right_note = {60,72,60,72,62,60,64,62}

-- TOP HEMISPHERE
top_b = nil
top_note = {69,71,74,69,67,76,62,69,67,79,67,74,62,69,67,69}

-- BOTTOM HEMISPHERE
bot_b = nil
bot_note = {69,64,62,69,67,69,62,74,67,69,67,71,62,64,67,69}

-- MIDI CC
cc_numbers = {1,2}

for i, b in ipairs(balls) do
  b.slew_id = slew.new(
  function(v)
    midi_cc(cc_numbers[i],v,2)
  end,
  0, -- start value
  0, -- end value
  0.05 -- duration in seconds
  )
end

-- // -- // -- // --
-- // -- // -- // --
-- =========================
-- INPUT
-- =========================
function event_grid(x,y,z)

  if z == 1 then
    -- STOP
    if x == 16 and y == 8 then
      for _, b in ipairs(balls) do
        b.running = false
        b.x, b.y = nil, nil
        b.start_x, b.start_y = nil, nil
      end
      left_b, right_b = nil, nil
      top_b, bot_b = nil, nil
      origin_collision_x, origin_collision_y = nil, nil
      collision_x, collision_y = nil, nil
      return
    end

    -- START BALL
    if x >= 2 and y >= 2 and x <= 15 and y <= 7 then
      local b = balls[current_ball]

      b.x, b.y = x,y
      b.start_x, b.start_y = x,y

      b.dx = (math.random(0,1) == 0) and -1 or 1
      b.dy = (math.random(0,1) == 0) and -1 or 1

      b.running = true

      current_ball = (current_ball % 2) + 1
    end
  end
end

-- =========================
-- DRAW LOOP
-- =========================
function draw()
  grid_led_all(0)
  -- DRAW START BOUNCE

  -- TOP-BOT background
  for i=1,16 do
    grid_led(i,1,2)
    grid_led(i,8,2)
  end
  -- LEFT_RIGHT background
  for i=1,8 do
    grid_led(1,i,2)
    grid_led(16,i,2)
  end

  -- INSIDE LOOP --//--//--//--//--
  for _, b in ipairs(balls) do
    if b.running and b.x and b.y then

        b.prev_x = b.x
        b.prev_y = b.y

        b.x = b.x + b.dx
        b.y = b.y + b.dy

        -- MIDI CC here ???

        --LEFT-RIGHT BOUNCE
        if b.x >= 16 or b.x <= 1 then
          b.dx = -b.dx

          if b.x <= 1 then
            left_b = b.y
            midi_note_on(left_note[b.y],127,1)
            midi_note_off(left_note[b.y],0,1)
          end
          if b.x >= 16 then
            right_b = b.y
            midi_note_on(right_note[b.y],127,1)
            midi_note_off(right_note[b.y],0,1)
          end
        end

      --TOP-BOTTOM BOUNCE
        if b.y >= 8 or b.y <= 1 then
          b.dy = -b.dy

          if b.y <= 1 then
            top_b = b.x
            midi_note_on(top_note[b.x],127,1)
            midi_note_off(top_note[b.x],0,1)
          end

          if b.y >= 8 then
            bot_b = b.x
            midi_note_on(bot_note[b.x],127,1)
            midi_note_off(bot_note[b.x],0,1)
          end
        end

        -- ORIGIN HIT
        if b.start_x and b.start_y then
          if b.x == b.start_x and b.y == b.start_y then
            if b.prev_x ~= b.start_x or b.prev_y ~= b.start_y then
              midi_note_on(origin_note[current_ori_note],127,1)
              midi_note_off(origin_note[current_ori_note],0,1)

              current_ori_note = (current_ori_note % 4) + 1
            end
          end
        end
    end
  end
  -- OUTSIDE LOOP --//--//--//--//--

  --------------------------------------------------
  -- 3. COLLISION DETECTION
  --------------------------------------------------
  local b1 = balls[1]
  local b2 = balls[2]

  -- MIDI CC here ???
  -- midi_cc(1,(b1.x-1)*8 + (8-b1.y),1)
  -- cc_value = (b1.x-1)*8 + (8-b1.y)
  -- print(cc_value)

  local is_collision = false

  if b1.x and b2.x then
    if (b1.x == b2.x and b1.y == b2.y) or
        (b1.x == b2.prev_x and b1.y == b2.prev_y and
          b2.x == b1.prev_x and b2.y == b1.prev_y) then

      is_collision = true
    end
  end

  -- MIDI COLLISION Trigger
  if is_collision and not collision_active then
    midi_note_on(96,127,1)
    midi_note_off(96,0,1)
  end

  collision_active = is_collision
  collision = is_collision

  -- TIMER + STORE POSITION
  if is_collision then
    collision_timer = 2
    collision_x = b1.x
    collision_y = b1.y
  elseif collision_timer > 0 then
    collision_timer = collision_timer - 1
  end

  --------------------------------------------------
  -- 4. ORIGIN COLLISION DETECTION
  --------------------------------------------------
  origin_collision = false


  for _, b in ipairs(balls) do
    local hit_origin = false

    if b.start_x and b.start_y then
      if b.x == b.start_x and b.y == b.start_y then
        if b.prev_x ~= b.start_x or b.prev_y ~= b.start_y then

          hit_origin = true
        end
      end
    end

    if hit_origin and not b.origin_active then
      b.origin_timer = 4
    end

    b.origin_active = hit_origin

    if b.origin_timer > 0 then
      b.origin_timer = b.origin_timer - 1
    end
  end

  --------------------------------------------------
  -- 5. DRAW BALLS / COLLISION FLASH / MIDI CC
  --------------------------------------------------

  if collision_timer > 0 and collision_x then
    grid_led(collision_x, collision_y,15)
  else
    for i,b in ipairs(balls) do
      if b.x then
        grid_led(b.x,b.y,7)

        local cc_value = (b.x-1)*8 + (8-b.y)
        -- local cc_num = cc_numbers[i]

        if b.x ~= b.prev_x or b.y ~= b.prev_y then
          -- STEPPY CC Version--
          -- midi_cc(cc_num, cc_value, 1)

          -- SMOOTHING CC VERSION--
          -- slew.to(b.slew_id, cc_value, 0.05)

          -- OPTION: each ball different smoothing
          slew.to(b.slew_id, cc_value, i == 1 and 0.03 or 0.08)
        end
      end
    end
  end

--------------------------------------------------
  -- 6. DRAW ORIGINS
--------------------------------------------------
  for _,b in ipairs(balls) do
    if b.start_x and b.start_y then
      local brightness = 6

      if b.x == b.start_x and b.y == b.start_y then
        brightness = 8
      end

      if b.origin_timer > 0 then
        brightness = 15
      end

      grid_led(b.start_x,b.start_y, brightness)
    end
  end


  -- LEFT-RIGHT Radio Button
  if left_b then
    grid_led(1, left_b,12)
  end

  if right_b then
    grid_led(16, right_b,12)
  end

  -- TOP-BOT Radio Button
  if top_b then
    grid_led(top_b,1,12)
  end

  if bot_b then
    grid_led(bot_b,8,12)
  end

  --------------------------------------------------
  -- 7. TRANSPORT LED
  --------------------------------------------------
  -- local any_running = false
  -- for _,b in ipairs(balls) do
  --   if b.running then
  --     any_running = true
  --   end
  -- end
  --
  -- grid_led(16,8,any_running and 2 or 4)

  grid_refresh()
end

function setTempo(i)
  tempo = i
  tempo = 60/(tempo*div)
  m.time = tempo
end

m = metro.init(draw,tempo)
m:start()
