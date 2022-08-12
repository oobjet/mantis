-- mantis - infinite euclidian rythm
--
-- K2 : grab sound & generate euclidian sequence
-- K3 : generate euclidian sequence
-- E1 : pattern length
-- E2 : pattern density
-- E3 : pattern offset

lattice = require("lattice")
er = require("er")

-- TODO:
-- screen
-- read sequence from disk file

function init()
  softcut_init()
  active = 1
  p_length = {12, 12, 12, 12, 10, 10}
  p_density = {2, 3, 4, 5, 6, 7}
  p_offset = {1, 2, 3, 4, 5, 6}
  p_length_min = {8, 8, 8, 4, 4, 4}
  p_length_max = {16, 12, 16, 16, 16, 16}
  p_density_min = {1,1,2,2,4,4}
  p_density_max = {4,8,12,12,16,16}
  p_offset_min = {0,0,0,0,0,0}
  p_offset_max = {15,15,15,15,15,15}
  er_table = {{f},{f},{f},{f},{f},{f}}
  step = {1, 1, 1, 1, 1, 1}
  -- speeds = {1, 2, 0.5}
  speeds = {1}
  speed_table = {{1},{1},{1},{1},{1},{1}}
  clock.run(play)
  -- clock.run(autograb)
  busy = false
  redraw()
end

function softcut_init()
for i = 1,6 do
    softcut.enable(i,1)
    softcut.buffer(i,1)
    softcut.level(i,1.0)
    softcut.loop(i,1)
    softcut.loop_start(i,(i-1)*10)
    -- softcut.loop_end(i,i*10)
    softcut.loop_end(i,(i-1)*10+clock.get_beat_sec()/2)
    softcut.position(i,(i-1)*10)
    softcut.play(i,1)
    softcut.rec(i,1)
--    softcut.fade_time(i,0.01)
    softcut.level_slew_time(i,0.01)
    softcut.recpre_slew_time(i,0.01)
    softcut.rate(i,1)
    -- softcut.rec_level(i,1.0)
    -- softcut.pre_level(i,0.0)
    softcut.level_input_cut(1,i,1.0)
    softcut.level_input_cut(2,i,0.0)
--    softcut.pan (i,math.random(-10,10)/10)
    -- overdub ?
    --softcut.rec(i,1)
    --softcut.play(i,1)
    --softcut.pre_level(i,0.5)
  end
  audio.level_adc_cut(1)
  softcut.buffer_clear()
end

function grab(a)
  softcut.position(active, (active-1)*10)
  softcut.rate(active, 1)
  softcut.rec(active,1)
end

function grabsync(a)
  clock.sync(1/2)
  -- softcut.position(active, (active-1)*10)
  -- softcut.rate(active, 1)
  softcut.rec_level(active,1.0)
  softcut.pre_level(active,0)
  -- softcut.rec(active,1)
  clock.sync(1/2)
  softcut.rec_level(active,0)
  softcut.pre_level(active,1.0)
  apply()
end

function autograb()
  while true do
    clock.sync(8)
    active = math.random(6)
    grabsync()
  end
end

function generate(a)
  -- generate random preset
  print("generate"..active)
  softcut.rec(active, 0)
  softcut.position(active, (active-1)*10)
  p_length[active]=math.random(p_length_min[active],p_length_max[active])
  p_density[active]=math.random(p_density_min[active],p_density_max[active])
  p_offset[active]=math.random(p_offset_min[active],p_offset_max[active])
  er_table[active] = er.gen(p_density[active], p_length[active],p_offset[active])
  active = active + 1
  redraw()
end

function apply(a)
  -- apply user preset
  -- softcut.rec(active, 0)
 -- softcut.position(active, (active-1)*10)
  er_table[active] = er.gen(p_density[active], p_length[active],p_offset[active])
  -- speed_gen()
  redraw()
end

function speed_gen()
    for i = 1, p_length[active] do
      speed_table[active][i] = speeds[math.random(1, #speeds)]
    end
end


function play()
  while true do
    clock.sync(1/2)
    for i = 1,6 do
      if er_table[i][step[i]] then
        -- if not busy then busy = true end
        -- softcut.position(i, (i-1)*10)
        -- softcut.play(i, 1)
        softcut.level(i, 1)
       -- softcut.rate(i, speed_table[i][step[i]])
      else
        -- softcut.play(i, 0)
        softcut.level(i, 0)
        -- busy = false
      end
      step[i] = util.wrap(step[i] + 1, 1, p_length[i])
    end
  end
end

function enc(e, d)
  if e == 3 then 
    p_length[active] = util.clamp(p_length[active] + d, p_density[active], 16)
  end
  if e == 2 then 
    p_density[active] = util.clamp(p_density[active] + d, 0, p_length[active])
  end
  if e == 1 then 
    p_offset[active] = util.clamp(p_offset[active] + d, 0, p_length[active])
  end
  apply(active)
  redraw()
end

function key(k, z)
  -- key 1 = reset
  if k==1 and z==1 then
    init()
  end
  -- key 2 = change active track
  if k==2 and z==1 then
    active = (active + 1) % 6
    redraw()
  end
  -- key 3 = grab & generate
  if k==3 and z==1 then
    clock.run(grabsync)
  end
  -- if k==3 and z==0 then
    -- apply(active)
  -- end
end

function redraw()
  -- screen redraw
  screen.clear()
  screen.level(15)
  screen.move(10,10)
  screen.text("offset")
  screen.move(40,10)
  screen.text("density")
  screen.move(80,10)
  screen.text("length")
  for i=1, 6 do
    screen.level(3)
    if i == active then screen.level(15) end
    screen.move(10,(i+1)*10)
    screen.text(p_offset[i])
    screen.move(40,(i+1)*10)
    screen.text(p_density[i])
    screen.move(80,(i+1)*10)
    screen.text(p_length[i])
  end
  screen.update()
end
