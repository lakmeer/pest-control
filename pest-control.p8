pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- pest control
-- by mat, josh and jordan

-- todo
-- - what happens in a draw???
-- - why is swarm's acc so high?
-- - why is swarm's speed so low?
-- - ram damage proportional
--   to combined velocity

-- global state

t=0
p1={con=0,num=1,sel=1,sel_y=0,ship=nil,x=-56,y=-56,col=8, pulse={ 8, 8,2}}
p2={con=1,num=2,sel=2,sel_y=0,ship=nil,x= 56,y= 56,col=12,pulse={12,12,1}}
players={p1,p2}
winner=nil

ents={}
ships={}
stars={}
timers={}
particles={}

cam={x=0,y=0,tx=0,ty=0,z=1,tz=1}
zoom=1
shake=0
flash=0


-- debugging flags

debug={}

_debug_skip_title=false
_debug_show_perf=false
_debug_start_round=false
_debug_show_winner=false
_debug_particle_test=false
_debug_ship_builder=false
_debug_show_ship_helpers=false


-- reference data

__taunt="suck it, peasants!|can't delay the inevitable|cheeeehooo!|press x to eat a dick|and tell your mum to◆stop texting me|disgraceful|what an absolute punisher|what a complete wounder|a shameful display|step `n get rekt|back 2 school, son"
__ships={
  "fighter,cannon,chaff,8.2.0,8,80,0.2,3,1,50◆8|8|40:70,50:30,60:70,0:70,z/0|9|45:50,50:90,55:50/2|7|0:40,20:10,80:10,z",
  "sadist,rocket,homing,9.4.0,14,80,0.35,2,0.8,20◆9|9|10:30,25:30,20:50,10:80,28:80,39:78,41:50,59:50,61:78,72:80,90:80,80:50,75:30,90:30,z/0|10|41:56,50:68,59:56/4|7|10:20,32:20,68:20,90:20,z",
  "winch,flak,tractor,10.4.0,10,80,0.3,2,0.7,2◆5|10|20:60,25:74,28:76,30:75,45:30,50:50,55:30,70:75,72:76,75:74,80:60,z/0|10|40:33,50:70,60:33/10|7|22:56,25:66,28:68,50:20,72:68,75:66,78:56,z",
  "viper,rapid,stunner,11.3.0,12,70,0.15,2,0.6,70◆6|11|45:60,55:60,65:65,65:45,55:40,50:15,45:40,35:45,35:65,z/3|11|46:60,47:70,53:70,54:60/3|11|45:60,55:60,65:65,90:90,93:82,65:45,55:40,50:15,45:40,35:45,7:82,10:90,35:65,z",
  "surgeon,railgun,sapper,12.1.0,12,100,0.2,3,0.5,1◆6|12|58:75,65:70,95:80,56:60,44:60,5:80,35:70,42:75,z/0|9|57:77,53:90,50:70,47:90,43:77/12|7|94:70,97:80,54:50,46:50,3:80,6:70",
  "hammer,shockwave,ram,13.1.0,16,120,0.15,2,0.6,70◆13|13|75:80,85:80,95:80,5:80,15:80,25:80,z/13|12|63:25,50:85,37:25/10|7|74:70,72:70,28:70,26:70",
  "swarm,spread,microships,14.2.0,11,50,0.5,5,2,0.5,70◆14|14|8:60,17:55,33:55,42:60,92:60,83:55,67:55,58:60,z/2|6|0:0,55:80,45:80,z/2|7|0:0,95:80,5:80,z",
  "wasp,laser,autoaim,6.5.0,8,50,0.35,4,0.9,70◆6|7|25:15,15:30,25:45,35:30,z/6|6|75:15,65:30,75:45,85:30,z/6|7|98:50,2:50,48:50,52:50,z",
}


-- main gamestate
--
-- we change the operation of
-- game by swapping in new draw
-- and update functions to be
-- called during the main loop.
-- we might also define some
-- functions to manage the
-- transition from one mode to
-- another, so we can control
-- animations & timers & stuff.

curr_update=nil
curr_draw=nil


-- core hooks

function _init ()
 t=0
 stars=make_starfield(200)

 -- hydrate compiled data
 __taunt=split(__taunt,"|");
 __ships=xmap(__ships,define_ship);

 show_title()

 -- mostly debug init modes
 if _debug_skip_title then
  show_choose()
 end

 if _debug_particle_test then
  curr_update=particle_test
  curr_draw=particle_test_draw
  return
 end

 if _debug_ship_builder then
  music(-1)
  curr_update=ship_builder
  curr_draw=draw_ship_builder
  return
 end

 if _debug_start_round then
  p1.ship=make_ship(8,p1)
  p2.ship=make_ship(flr(rnd(8))+1,p2)

  if _debug_show_winner then
   winner=p2
   winner.ship.dx=2
   winner.ship.dy=-2
   winner.ship.tgt_ornt=-0.35
   other_player(winner).ship.alive=false
   show_gover()
  else
   show_ready()
   p2.ship.tgt_ornt=0
   p2.ship.ornt=0
  end
 end
end

function _update ()
 -- add one to frame counter
 t+=1

 -- always update timers and
 -- particles regardless of the
 -- current update function
 foreach(timers,update_timer)
 particles=filter(particles,sim_particle)

 -- perform whatever the current
 -- update function describes
 curr_update()
end

function _draw ()
 -- start by clearing the screen
 -- instead of clearing to black
 -- we use the flash function to
 -- set an appropriate color
 cls(update_flash())

 -- perform the current draw
 curr_draw()

 -- debug shit
 if _debug_show_perf then
  print(flr(stat(0)).."kb",1, 91, 8)
  print(stat(1),      1, 97, 9)
  print(stat(2),      1,103,10)
  print(#ents,        1,109,11)
  print(#particles,   1,115,12)
 end
 for i,n in pairs(debug) do print(n,1,2+i*6,15) end
 debug={}
end


-->8
-- entities & timers

-- entity system

function new_ent (props)
 local e={
  x=0,
  y=0,
  age=0,
  life=100,
  alive=true,
  owner=nil,
  update=age_ent,
  draw=draw_generic_ent
 }
 mixin(e,props)
 add(ents,e)
 return e
end

function update_entity (e)
 e:update()
 return e.alive
end

function age_ent (e)
 e.age+=1
 if (e.age>=e.life) e.alive=false
end

function sim_ent (e)
 e.x+=e.dx
 e.y+=e.dy
end

function draw_entity (e)
 e:draw()
end

function draw_generic_ent (e)
 local r=4
 if (e.r!=nil) r=e.r
 _circfill(e.x,e.y,r,7)
 _circ(e.x,e.y,r,14)

 if e.ornt!=nil then
  _line(e.x,e.y,
       e.x+sin(e.ornt)*r*2,
       e.y+cos(e.ornt)*r*2,
       14)
 end
end


-- timers

function new_timer (length)
 local t={
  t=0,
  p=0,
  d=length,
  on=false,
  elf=false,
  done=false,
  reset=reset_timer,
 }
 add(timers,t)
 return t
end

function update_timer (t)

 -- always keep these up to date
 t.p=t.t/t.d
 if (t.t >= t.d) t.done=true
 t.elf=false

 -- only if currently running
 if t.on then
  t.t+=1

  if t.done then
	  t.elf=true
	  t.on=false
  end
 end
end

function reset_timer (t,d)
 t.p=0
 t.t=0
 t.done=false
 t.elf=false
 t.on=true
 if (d!=nil) t.d=d
end

function dump_timer (t,name)
 if (name==nil) name=""
 local str=""
 for i=0,9 do
  if t.p>i/10 then
   str=str.."█"
  else
   str=str.."░"
  end
 end
 str=str.." "..name
 return str
end
-->8
-- weapons & abilities

function no_gun (s)
 add(debug,"p"..(1+s.p.con).." special")
end

-- fat bullets

function shoot_bullet (s)
 s.refire_t=4
 sfx(1)
 return new_ent({
  ship=s,
  col=10,
  r=2,
  x=s.x,
  y=s.y,
  life=40,
  dx=s.dx+8*sin(s.ornt),
  dy=s.dy+8*cos(s.ornt),
  dmg=10,
  update=update_bullet,
  draw=draw_bullet
 })
end

function update_bullet (b)
 age_ent(b)
 b.x+=b.dx
 b.y+=b.dy

 local tgt=other_ship(b.ship)
 if collides(b,tgt) then
  sfx(3)
  damage_ship(tgt,b.dmg)
  spawn_sparks(b.x,b.y)
  b.alive=false
 end
end

function draw_bullet (b)
 _circfill(b.x,b.y,b.r,b.col)
end


-- lasers

function shoot_laser (s)
 s.refire_t=45
 sfx(16)
 new_ent({
  sweep_dmg=true,
  ship=s,
  life=30,
  dmg=1,
  col={7,7,7,6,5,1},
  a={
   x=s.x+s.r*sin(s.ornt),
   y=s.y+s.r*cos(s.ornt),
  },
  b={
   x=s.x+128*sin(s.ornt),
   y=s.y+128*cos(s.ornt),
  },
  len=128,
  update=update_laser,
  draw=draw_laser
 })
end

function update_laser (l)
 age_ent(l)
 local s=l.ship
 local other=other_ship(s)

 l.a.x=s.x-s.r*sin(s.ornt)
 l.a.y=s.y-s.r*cos(s.ornt)
 l.b.x=s.x+(s.r+l.len)*sin(s.ornt)
 l.b.y=s.y+(s.r+l.len)*cos(s.ornt)

 for i=1,10 do
  local r=rnd()
  local x=lerp(l.a.x,l.b.x,r)
  local y=lerp(l.a.y,l.b.y,r)
  spawn_particle({
   x=x,
   y=y,
   col=l.col,
   dx=rndr(-5,5),
   dy=rndr(-5,5),
   life=3,
   r=1
  })
 end

 if l.sweep_dmg then
  local coll=collide_beam(l,other)
  if coll!=false then
   damage_ship(other,l.dmg)
   spawn_sparks(coll.x,coll.y)
   sfx(12)
  end
 end
end

function draw_laser (l)
 local p=l.age/l.life
 local c=l.col[flr(p*#l.col)]
 _line(l.a.x,l.a.y,l.b.x,l.b.y,c)
end

function shoot_rail (s)
 s.refire_t=60
 sfx(14)
 local beam=new_ent({
  ship=s,
  life=10,
  dmg=80,
  col=split("7,12,12,12,12,1"),
  a={
   x=s.x-s.r*sin(s.ornt),
   y=s.y-s.r*cos(s.ornt),
  },
  b={
   x=s.x+512*sin(s.ornt),
   y=s.y+512*cos(s.ornt),
  },
  len=512,
  update=update_laser,
  draw=draw_rail
 })

 for i=1,512,5 do
  local x=lerp(beam.a.x,beam.b.x,i/512)
  local y=lerp(beam.a.y,beam.b.y,i/512)
  spawn_particle({
   x=x,y=y,
   col=split("7,12,12,1"),
   dx=rndr(-2,2),
   dy=rndr(-2,2),
   life=rndr(10,20),
   r=1
  })
 end

 local other=other_ship(s)
 local coll=collide_beam(beam,other)
 if coll!=false then
  damage_ship(other,beam.dmg)
  spawn_xpld(coll.x,coll.y)
  sfx(15)
 end
end

function draw_rail (l)
 local p=l.age/l.life
 local c=l.col[flr(p*#l.col)]

 for i=-1,1 do
 	for j=-1,1 do
   _line(l.a.x+i,l.a.y+j,l.b.x+i,l.b.y+j,c)
  end
 end

 _line(l.a.x,l.a.y,l.b.x,l.b.y,7)
end


-- missiles

function shoot_missile (s)
 local speed=3
 s.refire_t=10

 new_ent({
  x=s.x,
  y=s.y,
  dx=s.dx+speed*sin(s.ornt),
  dy=s.dy+speed*cos(s.ornt),
  r=2,
  dmg=20,
  life=120,
  ornt=s.ornt,
  spd=0.5,
  maxs=speed,
  tgt=other_ship(s),
  update=update_missile,
 })
end

function update_missile (m)
 age_ent(m)

 local turn=shortest_arc(
  m.ornt,
  atan2(m.tgt.y-m.y,m.tgt.x-m.x)
 )

 m.ornt+=turn*0.6
 m.ornt=m.ornt%1
 m.dx+=m.spd*sin(m.ornt)
 m.dy+=m.spd*cos(m.ornt)
 m.dx=mid(-m.maxs,m.dx,m.maxs)
 m.dy=mid(-m.maxs,m.dy,m.maxs)
 m.x+=m.dx
 m.y+=m.dy

 if collides(m,m.tgt) then
  sfx(5)
  m.tgt.hp-=m.dmg
  m.alive=false
  spawn_xpld(m.x,m.y,10,5)
 end
end

-- rockets

function shoot_rocket (s)
 if (s.rkt==nil) then
  s.refire_t=5
  s.rkt=new_ent({
   ship=s,
   life=150,
   r=3,
   x=s.x,
   y=s.y,
   dmg=50,
   range=12,
   dx=s.dx+6*sin(s.ornt),
   dy=s.dy+6*cos(s.ornt),
   update=update_rocket
  })
 else
  s.refire_t=10
  s.rkt.alive=false
 end
end

function update_rocket (r)
 age_ent(r)
 update_bullet(r)
 if not r.alive then
  local s=r.ship
  sfx(2)
  r.ship.rkt=nil
  spawn_xpld(r.x,r.y,9,r.range)
  local splash={x=r.x,y=r.y,r=r.range}
  local other=other_ship(s)
  if collides(other,splash) then
   local dist=hyp(splash.x,splash.y,other.x,other.y)
   other.hp-=r.dmg*dist/r.range
  end
 end
end


-- spread shot

function shoot_spread (s)
 for i=-2,2 do
  local my_ornt=(s.ornt+i*rnd(0.06)+1)%1
  s.refire_t=5

  new_ent({
   ship=s,
   r=1,
   dmg=10,
   x=s.x,
   y=s.y,
   dx=s.dx+6*sin(my_ornt),
   dy=s.dy+6*cos(my_ornt),
   life=30,
   update=update_bullet
  })
 end
end

-- flak cannon

function shoot_flak (s)
 sfx(3)
 local bullet=shoot_bullet(s,true)
 bullet.dmg=0 -- only damage using smaller bullets
 bullet.r=2
 bullet.col=10
 bullet.update=update_flak
 bullet.life=20
end

function update_flak (f)
 update_bullet(f)

 if not f.alive then
  sfx(1)
  for i=0,7 do
   new_ent({
    ship=f.ship,
    r=1,
    x=f.x,
    y=f.y,
    dx=5*sin(i/8),
    dy=5*cos(i/8),
    col=f.col,
    life=6,
    dmg=5,
    update=update_bullet,
    draw=draw_bullet
   })
  end
 end
end

-- machineguns

function shoot_rapid (s)
 if (s.rapid_osc==nil) s.rapid_osc=0.25
 s.rapid_osc=-1*s.rapid_osc
 s.refire=2
 sfx(1)

 new_ent({
  ship=s,
  x=s.x+s.r*sin(s.ornt+s.rapid_osc),
  y=s.y+s.r*cos(s.ornt+s.rapid_osc),
  dx=s.dx+8*sin(s.ornt),
  dy=s.dy+8*cos(s.ornt),
  dmg=3,
  life=40,
  col=11,
  r=1,
  update=update_bullet,
  draw=draw_bullet
 })
end

-- wavefront gun

function shoot_wave (s)


end


--
-- special abilities
--

-- chaff

function shoot_chaff (s)
 s.special_t=20
 for i=1,20 do
  local r_ornt=rndr(-0.1,0.1)
  new_ent({
   chaff=true,
   x=s.x,
   y=s.y,
   r=7,
   age=flr(2),
   life=rnd(90,110),
   dx=s.dx+rnd(4)*sin(s.ornt+0.5+r_ornt),
   dy=s.dy+rnd(4)*cos(s.ornt+0.5+r_ornt),
   update=update_chaff,
   draw=draw_chaff
  })
 end
end

function update_chaff (cp)
 cp.dx*=0.9
 cp.dy*=0.9
 age_ent(cp)
 sim_ent(cp)
 cp.p=cp.age/cp.life

 for e in all(ents) do
  if not e.chaff
     and collides(cp,e) then
   e.alive=false
   cp.alive=false
  end
 end
end

function draw_chaff (cp)
 local c=6
 if ((cp.p*7+t/2)%8<4) c=5
 _circfill(cp.x,cp.y,cp.r,c)
end

-- tractor

function shoot_tractor (s)
 local other=other_ship(s)
 local dx=other.x-s.x
 local dy=other.y-s.y
 other.dx-=dx*0.001
 other.dy-=dy*0.001
 other.being_tractored=true

 if not s.tractor_engaged then
  sfx(17,3)
 end

 s.tractor_engaged=true
end

-- stunner

function shoot_stun (s)
 s.special_t=30*5
 local other=other_ship(s)
 other.stun_t=60
 flash=8
end

-- sapper

function shoot_sap (s)
 local other=other_ship(s)
 other.en=max(0,other.en-1)
end

-- autoaimer

function shoot_autoaim (s)
 s.special_t=30
end

function update_autoaim (s)
 if s.special_t>0 then
  local other=other_ship(s)
  local dx=other.x-s.x
  local dy=other.y-s.y
  local o=atan2(dy,dx)
  s.tgt_ornt=o
 end
end

-- microships

function shoot_micro (s)
 add(debug,"micro")
end

-- rammer

function shoot_ram (s)
 add(debug,"ram")
end


-- weapons library
--
-- we organise all the weapon
-- functions like this so that
-- we can access them with
-- strings from the ship
-- definitions

weapons={
 noop=no_gun,
 cannon=shoot_bullet,
 rocket=shoot_rocket,
 homing=shoot_missile,
 flak=shoot_flak,
 rapid=shoot_rapid,
 railgun=shoot_rail,
 shockwave=shoot_wave,
 spread=shoot_spread,
 laser=shoot_laser,
 chaff=shoot_chaff,
 tractor=shoot_tractor,
 stunner=shoot_stun,
 sapper=shoot_sap,
 ram=shoot_ram,
 microships=shoot_micro,
 autoaim=shoot_autoaim
}


-->8
-- ships

-- ship definition helpers

function ship_vectors (str)
 local d={col={}}
 local keys=split("main,thrust,fire")
 local lines=split(str,"/")
 for l_ix,l in pairs(lines) do
  local parts=split(l,"|")
  local coords={}
  d.col[keys[l_ix].."_off"]=parts[1]
  d.col[keys[l_ix].."_on"] =parts[2]
  local pts=split(parts[3])
  for pt in all(pts) do
   if pt=="z" then
    add(coords,"z")
   else
    add(coords,split(pt,":"))
   end
  end
  d[keys[l_ix]]=coords
 end
 return d
end

function define_ship (def)
 local defs,keys=split(def,"◆"),split("name,shoot_name,special_name,plt,r,hp,spd,maxs,turn_spd,s_cost")
 local props,s=split(defs[1]),{ design=ship_vectors(defs[2]), }
 for i,k in pairs(keys) do
  local v=props[i]
  if (tonum(v)!=nil) v=tonum(v)
  s[k]=v
 end
 s.plt=split(s.plt,".")
 s.shoot=weapons[s.shoot_name]
 s.special=weapons[s.special_name]
 return s
end

-- ship definitions
--
-- takes two compiled arguments,
-- which are strings, but are
-- processed at init time into
-- real data.
--
-- the first is a set of basic
-- config params which are:
--
-- - name
-- - primary shoot function
-- - special shoot function
-- - color palette
-- - collision radius
-- - starting health
-- - acceleration factor
-- - maximum speed
-- - turning speed
-- - special cost (in energy pts)
--
-- the second is the vector
-- shape which gets drawn.
-- it is made of three chunks
-- seperated by a '/'. each has
-- a pair of colors, and then a
-- vector sequence.
-- the 3 chunks are:
--
-- 1. the main hull shape
-- 2. the thrust shape
-- 3. the firing shape
--
-- the main hull is drawn always
--
-- the thrust shape flashes its
-- 2 colors when when U is held
--
-- the firing shape is one color
-- when the ship is not firing,
-- and the other when it is
--
-- the hull shape doesn't change
-- color but the second color in
-- it's chunk is used to draw
-- text and health bars are so
-- on relating to this ship type.
--
-- vector sequences are defined
-- as a sequence of points in
-- the form "a:m", or the letter
-- "z", seperated by commas.
--
-- a, the angle, 0 -> 100
-- goes clockwise. zero is north.
--
-- m, the magnitude, 0 -> 100
-- 0 is the center, 100 the edge.
--
-- "z" is special and means
-- 'close the shape'. it joins
-- the last point to the first.
--
-- shape chunks are in the form:
--
-- p|s|a:m,a:m,a:m...,z
--
-- where p is the primary color,
-- s is the secondary color, and
-- a:m are points in a vector
-- sequence which may include z,
-- but doesn't need to.


-- ship-related functions

function make_ship (typ,pl)
 local proto=__ships[typ]
 local ship={
  p=pl,
  typ=typ,
  col=proto.design.col.main_on,
  hp=10,
  en=140,
  dx=0,
  dy=0,
  x=pl.x,
  y=pl.y,
  stun_t=0,
  refire_t=0,
  special_t=0,
  thrust=false,
  shield=false,
  firing=false,
  stunned=false,
  ornt=0.5,
  tgt_ornt=0.5,
  alive=true,
 }

 -- remove any ships here that
 -- already belong to me
 ships=filter(ships,function (s) return s.p!=pl end)

 -- add new ship
 mixin(ship,proto)
 add(ships,ship)
 return ship
end

function update_ship (s)
 s.hp=max(0,s.hp)
 if (not s.alive) return

 if (s.refire_t >0) s.refire_t -=1
 if (s.special_t>0) s.special_t-=1
 if (s.stun_t>0) s.stun_t-=1
 s.stunned=s.stun_t>0

 if s.thrust then
  s.dx+=s.spd*sin(s.ornt)
  s.dy+=s.spd*cos(s.ornt)
  thrust_particles(s.x,s.y,s.r,s.design.col.thrust_on,s.ornt)
 end

 s.en=min(s.en+0.25,150)
 if (s.shield) s.en-=1
 if (s.en<=0)  s.shield=false

 if not s.being_tractored then
  if (s.dx<-s.maxs) s.dx=-s.maxs
  if (s.dy<-s.maxs) s.dy=-s.maxs
  if (s.dx> s.maxs) s.dx= s.maxs
  if (s.dy> s.maxs) s.dy= s.maxs
 end

 s.x+=s.dx
 s.y+=s.dy

 -- smash into iother player?
 local other=other_ship(s)

 if collides(s,other) and
    other.alive then
  -- because other ship will
  -- confirm the same collision
  -- just take care of this ship
  sfx(13)
  damage_ship(other,40)
  s.dx*=-1
  s.dy*=-1
 end

 -- die if run out of health
 if (s.hp<=0) then
  s.alive=false
  sfx(2)
  sfx(-1,3)
  spawn_xpld(s.x,s.y,9,15)
 end

 return s.alive
end

function damage_ship (s,dmg)
 if s.shield then
  sfx(4)
 else
  s.hp-=dmg
 end
end

function draw_ship (s)
 if (not s.alive) return

 if _debug_show_ship_helpers then
  _circ(s.x,s.y,s.r+1,6)
  _line(s.x,s.y,
       s.x+sin(s.tgt_ornt)*s.r*2,
       s.y+cos(s.tgt_ornt)*s.r*2,
       7)
  _line(s.x,s.y,
       s.x+sin(s.ornt)*s.r*2,
       s.y+cos(s.ornt)*s.r*2,
       6)
 end

 draw_ship_vectors(s,s.design,s.x,s.y,20)
end

function draw_ship_vectors (s,d,x,y,r)
 if (r<=1) return
 local c
 local stun_c=8+t%7
 local stunned=s.stunned

 c=d.col.thrust_off
 if (s.thrust and t%2==0) c=d.col.thrust_on
 if (d.col.thrust_off!=0 and s.shield) c=7

 draw_vector(d.thrust,x,y,r,s.ornt,c)

 if (d.fire!=nil) then
  c=d.col.fire_off
  if (s.firing) c=d.col.fire_on
  if (s.shield) c=7
  if (s.stunned) c=stun_c
  draw_vector(d.fire,x,y,r,s.ornt,c)
 end

 c=d.col.main_off
 if (s.shield) c=7
 if (s.stunned) c=stun_c
 draw_vector(d.main,x,y,r,s.ornt,c)
end

function draw_vector (pts,x,y,r,ornt,c)
 local a={x=0,y=0}
 local b={x=0,y=0}

 for i,pt in pairs(pts) do
  if (pt=="z") pt=pts[1]
  b.x=x+r*pt[2]/100*sin(ornt+pt[1]/100)
  b.y=y+r*pt[2]/100*cos(ornt+pt[1]/100)
  if i>1 then
   _line(
    flr(a.x+0.5),
    flr(a.y+0.5),
    flr(b.x+0.5),
    flr(b.y+0.5),
    c)
  end
  a.x=b.x a.y=b.y
 end
end

-->8
-- main game loop

function update_game ()
 update_inputs(p1)
 update_inputs(p2)

 ents=filter(ents,update_entity)
 ships=filter(ships,update_ship)
 cam_seek(midpoint(ships))
 update_cam()

 -- check for winner
 if #ships==1 then
  winner=ships[1].p
  show_gover()
 end
end

function draw_game ()

 -- draw hud
 draw_hud(p1,0)
 draw_hud(p2,120)

 -- draw game world
 clip(0,7,127,113)
 draw_starfield(stars,cam)
 camera(cam.x*zoom-64,cam.y*zoom-64)
 foreach(ents,draw_entity)
 foreach(ships,draw_ship)
 foreach(particles,draw_particle)
 clip()
 camera()
end

function new_round ()
 ents={}
 ships={}
 particles={}
 p1.ship=make_ship(p1.ship.typ,p1)
 p2.ship=make_ship(p2.ship.typ,p2)
end

function draw_hud (p,y)
 local s=p.ship
 rectfill(0,y,127,y+6,6)
 rectfill(1,y+1,5,y+5,s.design.col.main_on)
 print(s.name,8,y+1,5)

 rectfill(51,y+1,126,y+5,5)
 rectfill(51,y+1,126,y+1,0)

 if (s.hp<=0) return
 rectfill(51,y+1,51+s.hp/2,y+4,s.design.col.main_on)

 if (s.en<=0) return
 rectfill(51,y+5,51+s.en/2,y+5,7)
end


-- player controls

function update_inputs (p)
 local s,n=p.ship,p.con

 -- movement
 if not s.shield and not (s.stun_t>0) then
  if (btn(⬅️,n)) s.tgt_ornt-=1/32*s.turn_spd
  if (btn(➡️,n)) s.tgt_ornt+=1/32*s.turn_spd
  s.thrust=btn(⬆️,n)
 end

 local turn=
  shortest_arc(s.ornt,s.tgt_ornt)
 --s.tgt_ornt=(s.tgt_ornt+1)%1
 s.ornt+=turn*0.35

 -- actions
 local can_anything=
   not (s.stun_t>0) and
   not s.shield and
   winner==nil

 local can_fire=
   can_anything and
   s.refire_t<=0 and
   btn(🅾️,n)

 local can_special=
   can_anything and
   s.special_t<=0 and
   s.en>=s.s_cost and
   btn(❎,n)

 if (can_fire) s:shoot()

 if (can_special) then
  s.en-=s.s_cost
  s:special()
 end

 -- shield on when btn held
 if s.en>=0 then
  s.shield=btn(⬇️,n)
 end

 -- special handling
 if s.tractor_engaged and
    not btn(❎,n) then
  sfx(-1,3)
  other_ship(s).being_tractored=false
  s.tractor_engaged=false
 end
end

-->8
-- minor game loops

-- generic timer for misc use
t_wait=new_timer(60)

--
-- title screen ----------------
--

t_title_in=new_timer(90)
t_title_out=new_timer(60)

function show_title ()
 music(0)
 curr_update=update_title
 curr_draw=draw_title
 t_title_in:reset()
end

function update_title ()
 if t_title_out.elf then
  show_choose()
 else
  if btnp(❎,0) or btnp(🅾️,0) or
     btnp(❎,1) or btnp(🅾️,1) then
   sfx(9)
   music(-1,1500)
   t_title_out:reset()
  end
 end
end

function draw_title ()
 if (t_title_in.elf) flash=8
 local top=ease_out(-100,32,t_title_in.p)
          +ease_in(0,-132,t_title_out.p)
 local btm=ease_out(200,64,t_title_in.p)
          +ease_in(0,136,t_title_out.p)
 draw_starfield(stars,{x=0,y=t*5})

 if (not t_title_in.done) for i=1,15 do pal(i,5) end
 draw_logo(64,top,t/200)

 local tt=t/20
 if (t_title_out.p>0) tt=t/3
 cprint("by mat, josh and jordan",btm+5,6)
 cprint("(mal didn't help)",      btm+12,5)
 cprint("press    or    to start",btm+30,pulse(split("7, 7,6,5"),tt),0)
 cprint("      🅾️               ",btm+30,pulse(split("7,11,3,1"),tt),-2)
 cprint("            ❎         ",btm+30,pulse(split("7,14,8,2"),tt),-2)
 pal()
end

function draw_logo (x,y,t)
 local w2,h2=37,18
 sspr(80,105,32,23,x-16,y-h2)
 sspr(0,114,75,14,x-w2,y)
 chrome(x-w2,y,w2*2,14,t)
end


--
-- ship selection --------------
--

t_select={new_timer(15),new_timer(15)}

function show_choose ()
 music(10)
 p1.ship=nil
 p2.ship=nil
 t_select[1]:reset()
 t_select[2]:reset()
 curr_update=update_choose
 curr_draw=draw_choose
end

function update_choose ()
 choose_inputs(p1)
 choose_inputs(p2)
 if p1.ship!=nil and p2.ship!=nil then
  if (t_wait.elf) show_ready()
  if (not t_wait.on) t_wait:reset(10)
 end
end

function set_sel (pl,n)
 sfx(8)
 pl.sel=n
 if (pl.sel>8) pl.sel-=8
 if (pl.sel<1) pl.sel+=8
 t_select[pl.num]:reset()
end

function choose_inputs (pl)
 local n,p=pl.sel,pl.con

 if pl.ship==nil then
  if (btnp(⬅️,p)) set_sel(pl,n-1)
  if (btnp(➡️,p)) set_sel(pl,n+1)
  if (btnp(⬆️,p)) set_sel(pl,n-4)
  if (btnp(⬇️,p)) set_sel(pl,n+4)
  if btnp(🅾️,p) then
   sfx(9)
   pl.ship=make_ship(n,pl)
   t_select[pl.num]:reset()
  end
 else
  if btnp(❎,p) then
   sfx(7)
   pl.ship=nil
   t_select[pl.num]:reset()
  end
 end
end

function draw_choose ()
 draw_starfield(stars,{x=0,y=t*3})

 for pl in all(players) do
  local x,y,z=flr((pl.sel-1)%4)*32,flr((pl.sel-1)/4)*32,30
  local c=pl.pulse[3]
  if pl.ship==nil then
   if (p1.sel==p2.sel and pl.con==1) x+=1 y+=1 z-=2
   c=pulse(pl.pulse,t/12)
  end
  rect(x+1,y+1,x+z,y+z,c)
  draw_ship_stats(__ships[pl.sel],pl.con*64,64,pl)
 end

 for i,ship in pairs(__ships) do
  local ornt,x,y=0.5,flr((i-1)%4)*32+16,flr((i-1)/4)*32+16
  local seld=p1.sel==i or p2.sel==i
  if (seld) ornt+=0.02*sin(t/40)
  draw_ship_vectors(
   {ornt=ornt,thrust=seld,stun_t=0},
   ship.design,x,y,14)
 end
end

function draw_spec_line (lab,v,x,y,c)
 print(lab,x,y,5)
 if type(v)=="string" or v==nil then
  print(v,x+15,y,c)
 else
  _rf(x+15,y,40,  5,5)
  _rf(x+15,y,40,  1,0)
  _rf(x+15,y,40*v,5,c)
 end
end

function draw_ship_stats (ship,x,y,pl)
 local tx,bl,br,c=x+4,x+18,x+59,ship.design.col.main_on

 if pl.ship==nil then
  rectfill(x,y,x+63,y+63,6)
  wave_print("the "..ship.name,x+32,y+5,ship.plt,t/50,0)
  draw_spec_line("pri",ship.shoot_name,  tx,y+16,c)
  draw_spec_line("sec",ship.special_name,tx,y+23,c)
  draw_spec_line("hp", ship.hp/150,      tx,y+33,c)
  draw_spec_line("spd",ship.maxs/5,      tx,y+40,c)
  draw_spec_line("acc",ship.spd/0.5,     tx,y+47,c)
  draw_spec_line("trn",ship.turn_spd/2,  tx,y+54,c)
  line(x,y,x+62,y,7)
  line(x,y,x,y+62,7)
  line(x+63,y+1,x+63,y+63,5)
  line(x+1,y+63,x+63,y+63,5)
 else
  wave_print("the "..ship.name,x+32,ease_out(y+5,y+28,t_select[pl.num].p),ship.plt,t/30,1.8)
 end

end


--
-- ready to start --------------
--

ready_step=1
ready_time=30
if (_debug_start_round) ready_time=1
t_ready=new_timer(ready_time)

function show_ready ()
 silence_all()
 new_round()
 cam_seek(midpoint(ships))
 curr_update=update_ready
 curr_draw=draw_ready
 t_ready:reset()
 ready_step=1
 winner=nil

 if _debug_start_round then
  ready_step=3
 else
  sfx(10)
 end
end

function update_ready ()
 if t_ready.elf then
  ready_step+=1
  if ready_step==4 then
   sfx(11)
   curr_update=update_game
   curr_draw=draw_game
  else
   sfx(10)
  end
  t_ready:reset()
 end

 update_cam()
end

function draw_ready ()
 draw_game()

 print(ready_step,64,64,15)
 local c=11
 if (ready_step==3) c=11
 if (ready_step==2) c=9
 if (ready_step==1) c=8
 circfill(64,64,ease_out(25,12,t_ready.p),c)
end


--
-- round over ------------------
--

t_gover=new_timer(20)
gover_taunt=""

function show_gover ()
 t_gover:reset()
 gover_taunt=rnd_from(__taunt)
 curr_update=update_gover
 curr_draw=draw_gover
 music(9)
end

function update_gover ()
 update_inputs(winner)

 ents=filter(ents,update_entity)
 ships=filter(ships,update_ship)
 cam_seek(midpoint(ships))
 cam.ty+=32 -- make room for txt
 update_cam()

 if t_gover.done then
  if btnp(❎,winner.con) then
   show_choose()
  end

  if btnp(🅾️,winner.con) then
   new_round()
   show_ready()
  end
 end
end

function draw_gover ()
 draw_game()

 local w2,h2,x,y=27,64,64,ease_out(182,54,t_gover.p)

 sspr(0,114-16,65,14,x-w2,y)
 chrome(x-w2,y,61,13,t/100)

 wave_print(gover_taunt,68,22+y,winner.ship.plt,t/25,2)
 chrome(x-w2,y+14,61,20,t/100)

 local btm,tt=y+46,t/20
 print("rematch",    50,btm+0,pulse(split("7,7,6"),tt),0)
 print("choose ship",50,btm+7,pulse(split("7,7,6"),tt),0)
 print("🅾️",40,btm+0,pulse(split("7,11,3,1"),tt),-2)
 print("❎",40,btm+7,pulse(split("7,14,8,2"),tt),-2)
end

-->8
-- particles & fx

function spawn_particle (pt)
 local p={
  x=0,y=0,r=1,
  dx=0,dy=0,dr=0,
  ddx=0,ddy=0,
  p=0,f=1,age=0,life=100,
  col=split("7,7,14,8,2,1")
 }
 p.c=p.col[1]
 mixin(p,pt)
 add(particles,p)
end

function sim_particle (p)
 p.age+=1
 p.p=p.age/p.life
 p.dx+=p.ddx
 p.dy+=p.ddy
 p.dx*=p.f
 p.dy*=p.f
 p.x+=p.dx
 p.y+=p.dy
 p.r+=p.dr
 p.c=p.col[1+flr(#p.col*p.p)]
 return p.age<p.life
end

function draw_particle (p)
 _circfill(p.x,p.y,p.r,p.c)
end


-- explosions

function spawn_xpld (x,y,s)
 if (s==nil) s=2
 shake+=s*s/8
 flash=3

 for n=1,20 do
  local ornt=rnd(1)

  spawn_particle({
   x=x,
   y=y,
   dx=rnd(15)*sin(ornt),
   dy=rnd(15)*cos(ornt),
   r=rndr(s,s*2),
   dr=-0.3,
   f=rndr(0.8,0.9),
   life=10+rnd(5),
   age=flr(rnd(5)),
   col=split("7,1,10,9,10,9,6,6,6,5,5,5")
  })
 end

 spawn_particle({
  x=x+100,
  y=y+100,
  r=s*4,
  dr=-0.5,
  life=0,
  col=split("7,1,7")
 })
end

function spawn_sparks (x,y)
 for i=1,2 do
  spawn_particle({
   x=x,y=y,
   r=2,
   dr=-0.5,
   col=split("7,0,7,0,6,0,5,0,1"),
   life=8,
   dx=4*sin(rnd()),
   dy=4*cos(rnd()),
   f=0.8,
  })
 end
end


-- starfield

function make_starfield (n)
 local ss={}
 for i=1,n do
  add(ss,{
   x=rndr(-256,256),
   y=rndr(-256,256),
   z=rnd(128)
  })
 end
 return ss
end

function draw_starfield (ss,cam)
 for s in all(ss) do
  local c=1
  if (s.z<64) c=5
  if (s.z<32) c=6
  local x=s.x-(1-s.z/128)*cam.x*0.7
  local y=s.y-(1-s.z/128)*cam.y*0.7
  pset((64+x*zoom)%512,
       (64+y*zoom)%512,c)
 end
end


-- camera fx

function cam_seek (tgt)
 cam.tx=tgt.x
 cam.ty=tgt.y
end

function update_cam ()
 cam.x=lerp(cam.x,cam.tx,0.4)
 cam.y=lerp(cam.y,cam.ty,0.4)
 cam.x+=min(3,shake*sin(rnd()))
 cam.y+=min(3,shake*cos(rnd()))
 shake=(shake*0.8)
 if (shake<=1) shake=0
end


-- color fx

function pulse (plt,t)
 return plt[1+flr(#plt*(0.5+0.49*sin(t)))]
end

function shine (x,y,w,h,tgt,t,plt)
 for px=x,x+w do
  for py=y,y+h do
   if pget(px,py)==tgt then
    local c=0.5+0.49*sin(px/32+py/64+t)
    pset(px,py,plt[1+flr(#plt*c)])
   end
  end
 end
end

function chrome (x,y,w,h,t)
 shine(x,y,w,h,15,t,
  split("6,7,15,6,5,13,6"))
 shine(x,y,w,h,7,t*0.8,
  split("7,6,6,6,7"))
end

function update_flash ()
 if (flash<=0) return 0
 flash-=1
 if (flash==3) return 6
 if (flash==2) return 5
 if (flash==1) return 1
 if (t%2>=1) return 0
 return 7
end


-- text fx

function cprint (str,y,c,bump)
 if (bump==nil) bump=0
 local w=#str*4
 print(str,64-w/2+bump,y,c)
end

function oprint (str,x,y,c,c2)
 for dy=-1,1 do
  for dx=-1,1 do
   print(str,x+dx,y+dy,c2)
  end
 end
 print(str,x,y,c)
end

function wave_print (txt,cent,top,plt,t,z)
 local lines=split(txt,"◆")

 for n,str in pairs(lines) do
  local w=#str*4

  for i=1,#str do
   local x=cent-w/2+i*4-4
   oprint(
    sub(str,i,i),
    x,
    top+z*sin(t-x/32)+(n-1)*9,
    pulse(plt,i/16+t*2.2),
    7)
  end
 end
end


-- misc shapes

function draw_rings (x,y,r,plt)
 for i=0,#plt-1 do
  circfill(x,y,r-i,plt[i+1])
 end
end

function thrust_particles (x,y,r,c,ornt)
 spawn_particle({
  x=x+r*sin(ornt+0.5),
  y=y+r*cos(ornt+0.5),
  dx=rnd(10)*sin(ornt+0.5+rnd(0.05)),
  dy=rnd(10)*cos(ornt+0.5+rnd(0.05)),
  col={c},
  life=5,
  r=1,
  dr=-0.2,
 })
end
-->8
-- testing

-- ship builder

b={
 tgt_ornt=0.5,
 ornt=0.5,
 firing=false,
 thrust=false,
 shield=false,
 special=false,
 stun_t=0
}

function ship_builder ()
 if (btn(⬅️)) b.tgt_ornt-=0.02
 if (btn(➡️)) b.tgt_ornt+=0.02
 b.thrust =btn(⬆️)
 b.shield =btn(⬇️)
 b.firing =btn(🅾️)
 b.special=btn(❎)

 if (btnp(❎)) b.rotate=not b.rotate
 b.ornt=lerp(b.ornt,b.tgt_ornt,0.4)
end

function draw_ship_builder ()
 for i,s in pairs(__ships) do
  local x=21+42*flr((i-1)%3)
  local y=21+42*flr((i-1)/3)
  circ(x,y,s.r,5)
  line(x,y,x+s.r*sin(b.ornt),y+s.r*cos(b.ornt),5)
  draw_ship_vectors(b,s.design,x,y,21)
 end
end


-- particle tests

t_test=new_timer(20)
t_test:reset()

function particle_test ()

 local r={7,14,8,2,1}
 local b={7,12,12,13,1}
 local g={7,11,11,3,1}

 for i=1,10 do
  local x=rnd(128)
  local col=b
  if (x>=42) col=g
  if (x>=84) col=r

  spawn_particle({
   x=x,
   y=128,
   ddy=rndr(-0.15,-0.1),
   dx=rndr(-1,1),
   r=4,
   dr=-0.1,
   life=rndr(20,30),
   col=col,
  })
 end

 if t_test.elf then
  t_test:reset()
  local x,y=rndr(0,128),rndr(0,128)

  spawn_xpld(64,64,4)
 end
end

function particle_test_draw ()
 color(13)
 print("particle test: "..#particles)
 foreach(particles,draw_particle)
end


-- helpers


-- tables

--[[
function dump (t,d)
 if (d==nil) d=0
 local str=""
 for k,v in pairs(t) do
  for i=1,d do str=str.." " end
  str=str..k.."="
  if type(v)=="table" then
   str=str.."\n"..dump(v,d+1).."\n"
  elseif type(v)=="string" then
   str=str.."`"..v.."'\n"
  elseif type(v)=="function" then
   str=str.."<func>\n"
  elseif v==true then
   str=str.."#t\n"
  elseif v==false then
   str=str.."#f\n"
  else
   str=str..v.."\n"
  end
 end
 return str
end
]]--

function mixin (a,b)
 for k,v in pairs(b) do
  a[k]=v
 end
end

function xmap (table,fn)
 local t={}
 for x in all(table) do
  add(t,fn(x))
 end
 return t
end

function filter (table,fn)
 local t={}
 for x in all(table) do
  if (fn(x)) add(t,x)
 end
 return t
end

function rnd_from (t)
 return t[flr(1+rnd(#t))]
end


-- maths

function rndr (a,b)
 return a+rnd(b-a)
end

function hyp (x1,y1,x2,y2)
 local dx=(x2-x1)/1000
 local dy=(y2-y1)/1000
 return sqrt(dx*dx+dy*dy)*1000
end

function collides (a,b)
 local rr=a.r+b.r
 if (abs(a.x-b.x)>=rr) return false
 if (abs(a.y-b.y)>=rr) return false
 local d=hyp(a.x,a.y,b.x,b.y)
 return d<=a.r+b.r
end

function collide_beam (beam,tgt)
 for i=1,512,10 do
  local x=lerp(beam.a.x,beam.b.x,i/512)
  local y=lerp(beam.a.y,beam.b.y,i/512)
  local c={x=x,y=y,r=2}
  if (collides(c,tgt)) return c
 end
 return false
end

--[[
function wrap_torus (z)
 if (z.x<0)   z.x=127+z.x
 if (z.y<0)   z.y=127+z.y
 if (z.x>127) z.x-=127
 if (z.y>127) z.y-=127
end
]]--

function midpoint (things)
 local mp={x=0,y=0}
 for t in all(things) do
  mp.x+=t.x/#things
  mp.y+=t.y/#things
 end

 for t in all(things) do
  zoom=max(zoom,hyp(mp.x,mp.y,t.x,t.y))
 end

 zoom=mid(0.25,48/zoom,1)
 return mp
end

function shortest_arc (a,b)
 local arc1,arc2=b-a,0

 if arc1<0 then
  arc2=arc1+1
 else
  arc2=arc1-1
 end

 if (abs(arc1)<abs(arc2)) return arc1
 return arc2
end


-- easing

function lerp (a,b,t)
 return a+t*(b-a)
end

function ease_in (a,b,t)
 return lerp(a,b,t*t*t)
end

function ease_out (a,b,t)
 t=1-t
 return lerp(a,b,1-t*t)
end


-- game-specific

function other_player (p)
 if (p==p1) return p2
 return p1
end

function other_ship (s)
 return other_player(s.p).ship
end

function ornt_to_seg (ornt)
 return 1+flr(0.5+(0.5+ornt)*16)%16
end

function seg_to_spr_xform (s,n)
 local xf=__spr_xform[s]
 return {
  off  =xf[1],
  vflip=xf[2]==1,
  hflip=xf[3]==1
 }
end

function ornt_to_spr_xform (ornt)
 return seg_to_spr_xform(
         ornt_to_seg(ornt))
end

function silence_all ()
 for i=0,3 do sfx(-1,i) end
 music(-1,1500)
end


-- strings

function split (str,char)
 if (char==nil) char=","
 local words,word={},""

 for i=1,#str do
  local c=sub(str,i,i)
  if c==char then
   add(words,word)
   word=""
  else
   word=word..c
  end
 end

 add(words,word)
 return words
end


-- zoom-adjusted versions
-- of drawing functions

function _line (x1,y1,x2,y2,c)
 line(x1*zoom,y1*zoom,
      x2*zoom,y2*zoom,c)
end

function _circ (x,y,r,c)
 r=max(1,r)
 circ(x*zoom,y*zoom,r*zoom,c)
end

function _circfill (x,y,r,c)
 r=max(1,r)
 circfill(x*zoom,y*zoom,r*zoom,c)
end

function _spr (s,x,y,w,h,fh,fv)
 if (w==nil) w=1
 if (h==nil) h=1
 local ox,oy=1-4*w,1-4*h
 spr(s,x*zoom+ox,y*zoom+oy,w,h,fh,fv)
end

function _rf (x,y,w,h,c)
 rectfill(x,y,x+w-1,y+h-1,c)
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777000777777770000007777700777700000777707777777000000000000000000000000000000000000000000000000000000000000000000000000000
7fffffff7707fffffff770007fffff707ff7000007ff70fffffff700000000000000000000000000000000000000000000000000000000000000000000000000
7fffffffff07fffffffff707fffffff07ff7000007ff70ffffffff70000000000000000000000000000000000000000000000000000000000000000000000000
7ff77777ff07ff77777fff70ff777ff07ff7000007ff7077777fff70000000000000000000000000000000000000000000000000000000000000000000000000
7ff700007f07ff700007ff70f70007f07ff7007007ff70000007ff70000000000000000000000000000000000000000000000000000000000000000000000000
7ff700007f07ff700007ff70f70007f07ff707f707ff7007777fff70000000000000000000000000000000000000000000000000000000000000000000000000
7ff700007f07ff70007fff70f70007f07ff77fff77ff7007ffffff70000000000000000000000000000000000000000000000000000000000000000000000000
7ff700007f07ff7777fff70ff77777f07fffffffffff7007fffff700000000000000000000000000000000000000000000000000000000000000000000000000
7ff700007f07ffffffff707ffffffff07fffffffffff700777777000000000000000000000000000000000000000000000000000000000000000000000000000
7ff700007f07ffffffff707ffffffff07fffffffffff700000000000000000000000000000000000000000000000000000000000000000000000000000000000
7ff77777ff07ff777ffff70ff77777f07fffff7fffff700777700000000000000000000000000000000000000000000000000000000000000000000000000000
7fffffffff07ff7007ffff70f70007f07ffff707ffff7007ff700000000000000000000000000000000000000000000000000000000000000000000000000000
7fffffff7707ff70007fff70f70007f07fff70007fff7007ff700000000000000000000000000000000000000000000000000000000000000000000000000000
77777777000777700007777077000770777700000777700777700000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77770000077077777777077000077077770000777707777770777777770000000000000000000000000000000000000000000000000000000000000000000000
7ff7000007f07ffffff70ff70007f07fff70007ff70ffffff07fffffff7700000000000000000000000000000000000000000000000000000000000000000000
7ff7000007f07ffffff70fff7007f07ffff7007ff70ffffff07fffffffff70000000000000000000000000000000000000000000000000000000000000000000
7ff7000007f0777ff7770ffff707f07fffff707ff70f7777707ff77777fff7000000000000000000000000000000000000000000000000000000000000000000
7ff7007007ff007ff700ffffff77f07ffffff77ff70f7000007ff700007ff7000000000000000000000000000000000000000000000000000000000000000000
7ff707f707ff707ff707fffffffff07ffffffffff70f7777007ff700007ff7000000000000000000000000000000000000000000000000000000000000000000
7ff77fff77ff707ff707fffffffff07ffffffffff70ffff7007ff70007fff7000000000000000000000000000000000000000000000000000000000000000000
7fffffffffff707ff707fffffffff07ffffffffff70ffff7007ff7777fff70000000000000000000000000000000000000000000000002800000000000000000
7fffffffffff707ff707fffffffff07ffffffffff70f7777007ffffffff700000000000000000000000000000000000000000000000008800000000000000000
7fffffffffff007ff700ff77fffff07ff77ffffff70f7000007ffffffff700000000000000000000000000028888200000000000000028800000000000000000
7fffff7ffff0777ff7770f707ffff07ff707fffff70f7777707ff777ffff70000000000000000000000000088002820000000000000088200000000000000000
7ffff707fff07ffffff70f7007fff07ff7007ffff70ffffff07ff7007ffff7000000000000000000000000288000880000000000000288000000000000000000
7fff70007ff07ffffff70f70007ff07ff70007fff70ffffff07ff70007fff7000000000000000000000000882000880288888888888888880000000000000000
77770000077077777777077000077077770000777707777770777700007777000000000000000000000002880002880000000000000880000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000008820008820888200888800880000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000028800028808828808802802820000000000000000000
00000777777770077770000777700007707777777777077777700000007777000077770000000000000088200088288008888208008800000000000000000000
00077ffffff7077ffff77007fff70007f07ffffffff70ffffff7700077ffff77007ff70000000000000088000882880088288000008800000000000000000000
007fffffff707ffffffff707ffff7007f07ffffffff70ffffffff707ffffffff707ff70000000000000288028822882882028888028200000000000000000000
07ffff777707fff7777fff70fffff707f07777ff77770f77777ff07fff7777fff70ff70000000000000888888008888820000088088000000000000000000000
07fff7000007ff700007ff70ffffff77ff0007ff7000ff700007f07ff700007ff70ff70000000000000880000008800000080288088000000000000000000000
7fff7000007ff70000007ff70fffffffff7007ff7007ff70000707ff70000007ff70f70000000000002820000008800280820880282008000000000000000000
7fff7000007ff70000007ff70fffffffff7007ff7007ff70007f07ff70000007ff70f70000000000008820000008828820288800882082000000000000000000
7fff7000007ff70000007ff70fffffffff7007ff7007ff7777ff07ff70000007ff70f70000000000008800000002888200000000888820000000000000000000
7fff7000007ff70000007ff70fffffffff7007ff7007fffffff707ff70000007ff70f70000000000028200000000000000000000288200000000000000000000
07fff7000007ff700007ff70ff77ffffff7007ff7007ffffffff707ff700007ff70ff70000000000080000000000000000000000000000000000000000000000
07ffff777707fff7777fff70ff707fffff7007ff7007ff777ffff07fff7777fff70ff77777700000080000000000000000000000000000000000000000000000
007fffffff707ffffffff707ff7007ffff7007ff7007ff7007ffff07ffffffff707fffffff700000080000000000000000000000000000000000000000000000
00077ffffff7077ffff77007ff70007fff7007ff7007ff70007ffff077ffff77007fffffff700000000000000000000000000000000000000000000000000000
00000777777770077770000777700007777007777007777000077777007777000077777777700000000000000000000000000000000000000000000000000000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
888888888888888888888888888888888888888888888888888888888888888888888888888888888882282288882288228882228228888888ff888888228888
888882888888888ff8ff8ff88888888888888888888888888888888888888888888888888888888888228882288822222288822282288888ff8f888888222888
88888288828888888888888888888888888888888888888888888888888888888888888888888888882288822888282282888222888888ff888f888888288888
888882888282888ff8ff8ff888888888888888888888888888888888888888888888888888888888882288822888222222888888222888ff888f888822288888
8888828282828888888888888888888888888888888888888888888888888888888888888888888888228882288882222888822822288888ff8f888222288888
888882828282888ff8ff8ff8888888888888888888888888888888888888888888888888888888888882282288888288288882282228888888ff888222888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555500000000000055555555555555555555555555555555555555500000000000055000000000000555
555555e555566656655555e555555555555665666566555506600660000055555555555555555555565555665566566655506660666000055066606660000555
55555ee555555655655555ee55555555556555656565655500600060000055555555555555555555565556565656565655506060606000055060606060000555
5555eee555556655655555eee5555555556665666565655500600060000055555555555555555555565556565656566655506060606000055060606060000555
55555ee555555655655555ee55555555555565655565655500600060000055555555555555555555565556565656565555506060606000055060606060000555
555555e555566656665555e555555555556655655566655506660666000055555555555555555555566656655665565555506660666000055066606660000555
55555555555555555555555555555555555555555555555500000000000055555555555555555555555555555555555555500000000000055000000000000555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555566666566666577777566666555555588888888566666666566666666566666666566666666566666666566666666566666666555555555
55555665566566655565566565556575557565656555555588877888566666766566666677566777776566667776566766666566766676566677666555dd5555
5555656565555655556656656665657775756565655555558878878856667767656666776756676667656666767656767666657676767656677776655d55d555
5555656565555655556656656555657755756555655555558788887856776667656677666756676667656666767657666767657777777756776677655d55d555
55556565655556555566566565666577757566656555555578888887576666667577666667577766677577777677576667767567676767577666677555dd5555
55556655566556555565556565556575557566656555555588888888566666666566666666566666666566666666566666666567666667566666666555555555
55555555555555555566666566666577777566666555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555555555555555555005005005005005dd500566555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
555565655665655555005005005005005dd5665665555555777777775dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd555555555
555565656565655555005005005005005775665665555555777777775d55ddddd5dd5dd5dd5ddd55ddd5ddddd5dd5dd5ddddd5dddddddd5dddddddd555555555
555565656565655555005005005005665775665665555555777777775d555dddd5d55d55dd5dddddddd5dddd55dd5dd55dddd55d5d5d5d5d55dd55d555555555
555566656565655555005005005665665775665665555555777557775dddd555d5dd55d55d5d5d55d5d5ddd555dd5dd555ddd55d5d5d5d5d55dd55d555555555
555556556655666555005005665665665775665665555555777777775ddddd55d5dd5dd5dd5d5d55d5d5dd5555dd5dd5555dd5dddddddd5dddddddd555555555
555555555555555555005665665665665775665665555555777777775dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd5dddddddd555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000066600eee00ccc00000005500770000066600eee00ccc00ddd005507770000066600eee00ccc00dd0005507770000066600eee00ccc00ddd00555
5550707000000060000e0000c0000000550700000000060000e0000c0000d00550700000000060000e0000c000d000550700000000060000e0000c0000d00555
55507770000006600eee0000c00000005507000000006600eee0000c00ddd005507700000006600eee0000c000d0005507700000006600eee0000c00ddd00555
55507070000000600e000000c00000005507070000000600e000000c00d00005507000000000600e000000c000d0005507000000000600e000000c00d0000555
55507070000066600eee0000c000d0005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd00555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000066600eee00ccc00ddd005500770000066600eee00ccc00ddd005507770000066600eee00ccc00ddd005507770000066600eee00ccc00ddd00555
5550707000000060000e0000c0000d00550700000000060000e0000c0000d00550700000000060000e0000c0000d00550700000000060000e0000c0000d00555
55507770000006600eee0000c00ddd005507000000006600eee0000c00ddd005507700000006600eee0000c00ddd005507700000006600eee0000c00ddd00555
55507070000000600e000000c00d00005507070000000600e000000c00d00005507000000000600e000000c00d00005507000000000600e000000c00d0000555
55507070000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd00555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000066600eee00ccc00ddd005500770000066600eee00ccc00ddd005507770000066600eee00ccc00ddd005507770000066600eee00ccc00ddd00555
5550707000000060000e0000c0000d00550700000000060000e0000c0000d00550700000000060000e0000c0000d00550700000000060000e0000c0000d00555
55507770000006600eee0000c00ddd005507000000006600eee0000c00ddd005507700000006600eee0000c00ddd005507700000006600eee0000c00ddd00555
55507070000000600e000000c00d00005507070000000600e000000c00d00005507000000000600e000000c00d00005507000000000600e000000c00d0000555
55507070000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd00555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000066600eee00ccc00ddd005500770000066600eee00ccc00ddd005507770000066600eee00ccc00ddd005507770000066600eee00ccc00ddd00555
5550707000000060000e0000c0000d00550700000000060000e0000c00d0000550700000000060000e0000c0000d00550700000000060000e0000c00d0000555
55507770000006600eee0000c00ddd005507000000006600eee0000c00ddd005507700000006600eee0000c00ddd005507700000006600eee0000c00ddd00555
55507070000000600e000000c00d00005507070000000600e000000c0000d005507000000000600e000000c00d00005507000000000600e000000c0000d00555
55507070000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd00555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005501111111111111111111111aaaaa0555
55507770000066600eee00ccc00ddd005507700000066600eee00ccc00dd0005507770000066600eee00ccc00ddd005507771111166611eee11ccc1aaaaa0555
5550707000000060000e0000c0000d00550707000000060000e0000c000d000550700000000060000e0000c0000d00550711111111161111e1111c1aaaaa0555
55507770000006600eee0000c00ddd005507070000006600eee0000c000d0005507700000006600eee0000c00ddd005507711111116611eee1111c1aaaaa0555
55507070000000600e000000c00d00005507070000000600e000000c000d0005507000000000600e000000c00d00005507111111111611e111111c1aaaaa0555
55507070000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd005507771111166611eee1111c1aadaa0555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005501111111111111111111111aaaaa0555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55507770000066600eee00ccc00ddd005507700000066600eee00ccc00ddd005507770000066600eee00ccc00ddd005507770000066600eee00ccc00ddd00555
5550707000000060000e0000c00d0000550707000000060000e0000c0000d00550700000000060000e0000c00d0000550700000000060000e0000c0000d00555
55507770000006600eee0000c00ddd005507070000006600eee0000c00ddd005507700000006600eee0000c00ddd005507700000006600eee0000c00ddd00555
55507070000000600e000000c0000d005507070000000600e000000c00d00005507000000000600e000000c0000d005507010000000600e000000c00d0000555
55507070000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd005507171000066600eee0000c00ddd00555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500177100000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500177710000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500177771000000000000000000000555
55500770000066600eee00ccc00000005507700000066600eee00ccc00ddd005507770000066600eee00ccc00ddd005507177110066600eee00ccc00ddd00555
5550700000000060000e0000c0000000550707000000060000e0000c0000d00550700000000060000e0000c0000d00550701171000060000e0000c0000d00555
55507000000006600eee0000c00000005507070000006600eee0000c00ddd005507700000006600eee0000c00ddd005507700000006600eee0000c00ddd00555
55507070000000600e000000c00000005507070000000600e000000c00d00005507000000000600e000000c00d00005507000000000600e000000c00d0000555
55507770000066600eee0000c000d0005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd00555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500770000066600eee00ccc00ddd005507700000066600eee00ccc00ddd005507770000066600eee00ccc00ddd005507770000066600eee00ccc00ddd00555
5550700000000060000e0000c0000d00550707000000060000e0000c00d0000550700000000060000e0000c0000d00550700000000060000e0000c00d0000555
55507000000006600eee0000c00ddd005507070000006600eee0000c00ddd005507700000006600eee0000c00ddd005507700000006600eee0000c00ddd00555
55507070000000600e000000c00d00005507070000000600e000000c0000d005507000000000600e000000c00d00005507000000000600e000000c0000d00555
55507770000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd005507770000066600eee0000c00ddd00555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55500000000000000000000000000000550000000000000000000000000000055000000000000000000000000000005500000000000000000000000000000555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__sfx__
00140000183000f3001130013300113000f3000c3000f300113001330015302173021730217302003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
00020000357202c711237111e7111b712197121771216712007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701
00030000356702e6702e2702a670137701f6601b2500c6601466012660112701757011670135600e6500c350116500945007640106300333003420036200b3300342003020020200102001020010200101001010
0002000026650136401c6300e6201364009630056200a640036300060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000100002d4522d4422d4322d4222d412004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
0002000020670156701a6701b670136700a6600565005630166100966011650096400e63005620076100c610116000960007600106000360003600036000b6000360003600026000160001600016000160001600
010200060c2700c3700c4700c5700c4700c3700c2000c3000c4000c5000c4000c3000c2000c3000c4000c5000c4000c3000c2000c3000c4000c5000c4000c3000c2000c3000c4000c5000c4000c3000c2000c700
0003000014552145520a5521355209540125300852011510005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000300000c5500a550135501555000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000300000c5500a550155502255022552225422253222522225220050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000800001644416450164501645016450164501645500400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
00090000224542245022450224502245022450224502245022440224402243022430224202242022410224152e4002e4002e4002e4002e4002e4002e4002e4002e4002e4002e4002e4002e4002e4002e40022400
0001000036350066500000039000000000000000000370000170036000087000d7000f70012700167001b70000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000116500945007640106300333003450036200b330034500302002050010200106001020010100105000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000026240212501d2501a260182601826018260172601526014260112600e2600d2600a26006250031500114001140011400113001130011200212002110041100611008110091100b1100c1100e11001100
000200001b2733b2731e273382731f273362732127334273232733127323273302732327330263232633026323263302632325330253232533024323233302332322330223232133021323213302130c0000c000
00040000294501d4511d4521d4521d4521d4521d4521d4521d4511d4521d4521d4521d4521d4521d4521d4511d4521d4521d4521d4521d4521d4521d452114511145300400004000040000400004000040000400
011800000005100041000310002100031000410005100041000310002100031000410005100041000310002100031000410005100041000310002100031000410000100001000010000100001000010000100001
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b00001f2301f2351c2301c2351c2301c2351e2301e2351c2301c2351c2301c2351e2301e2351c2301c2351f2301f2351c2301c2351c2301c2351e2301e2351c2301c2351c2301c2351e2301e2351c2301c235
010b00001f2301f2351c2301c2351c2301c2351e2301e2351c2301c2351c2301c2351e2301e2351c2301c23521230212351c2301c2351c2301c2351f2301f2351c2301c2351c2301c23522231222322223222235
010b000010773000003b615000003b615000003b615000003c673000003b615000003b61500000107730000010773000003b6153b6153b615000003b615000003c673000003b615000003c673000051077300000
010b00000725007250072500725500200002001225012255062500625500200002001225012255062500625507250072500725007255002000020012250122550625006255002000020012250122550625006255
010b00000725007250072500725500200002001225012255062500625500200002001225012255062500625507250072500725007255002000020015250152550925009255002000020016250162501625500000
010b00002d2702f2712f2702f2702f2702f2722f2522f23500200002000020000200002000020000200002002b2702d2712d2702d2722d2722d2722d2522d2350020700200002000020000200002000020000200
010b00002d2702d2722d2722d2722d2722d2752b2702b2722b2722b2722b2722b275282702827228272282752627026272262722627226272262752827028272282722827228272282752b2702b2722b2722b275
010b00002d2702d2722d2722d2722d2722d2752b2702b2722b2722b2722b2722b2752627026272262722627228271282702827028272282622825228232282150000000000000000000000000000000000000000
010900000000000000000000000021140211402214022140231402314026140261422614226142231402314026140261422614226142281402814228142281322814228132281222811228132281322812228112
01090000000000000000000000000917009160091500914015141151400c1400c1400c1400c14018141181400e1400e1401a1411a14010140101401c1401c14010120101201c1201c12010110101101c1101c110
010b00000775007750077500775500700007001275012755067500675500700007001275012755067500675507750077500775007755007000070012750127550675006755007000070012750127550675006755
010b00000775007750077500775500700007001275012755067500675500700007001275012755067500675507750077500775007755007000070015750157550975009755007000070016750167501675500700
010b00000577505775047700477500700007000477004775047700477500700007000477004775047750477505775057750477004775007000070004770047750577004775047750477507770047750477504775
010b00000577505775047700477500700007000477004775047700477500700007000477004775047750477505775057750477004775007000070004770047750477004775057710577506775067750777107775
__music__
00 1a585b44
01 1a181b1d
00 1a191c1e
00 1a181b1d
00 1a191c1f
00 1a181b5d
00 1a191c5e
00 1a181b5d
02 1a191c5e
04 20214344
01 22424344
00 23424344
00 22424344
00 23424344
00 24654344
00 25654344
00 24654344
02 25654344

