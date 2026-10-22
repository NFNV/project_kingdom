from pathlib import Path
import math
root=Path('experiments/anime_hub_demo_v07/assets/motion/guides');root.mkdir(exist_ok=True);(root/'.gdignore').write_text('')
dirs={'e':0,'se':math.pi/4,'s':math.pi/2,'sw':3*math.pi/4,'w':math.pi,'nw':-3*math.pi/4,'n':-math.pi/2,'ne':-math.pi/4}
for direction,angle in dirs.items():
 out=['<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="2000" viewBox="0 0 1600 2000"><rect width="1600" height="2000" fill="#fff9ed"/>']
 d=(math.cos(angle),math.sin(angle));side=(-d[1],d[0])
 def project(x,y,z,cx,cy): return (cx+x,cy+y*.5-z)
 def line(a,b,col,width=12): out.append(f'<path d="M{a[0]:.2f} {a[1]:.2f}L{b[0]:.2f} {b[1]:.2f}" fill="none" stroke="{col}" stroke-width="{width}" stroke-linecap="round"/>')
 for i in range(20):
  row,col=divmod(i,4);cx=col*400+200;cy=row*400+345;f=i%8 if i<16 else 2;run=8<=i<16
  stride=0 if i>=16 else (56 if run else 37)
  contacts=[1,.5,0,-.5,-1,-.5,0,.5];liftL=[0,0,0,0,0,16,32,20];liftR=[0,16,32,20,0,0,0,0]
  lean=16 if run else 0;body=4*math.sin(f*math.pi/2);hipz=78+body;shoulderz=147+body
  p=lambda x,y,z:project(x,y,z,cx,cy)
  for leg_sign,color,lifts in [(-1,'#dc493c',liftR),(1,'#276fce',liftL)]:
   forward=contacts[f]*stride*leg_sign;lift=0 if i>=16 else lifts[f]*(1.4 if run else 1)
   hip=(side[0]*leg_sign*13+d[0]*lean,side[1]*leg_sign*13+d[1]*lean,hipz)
   foot=(side[0]*leg_sign*13+d[0]*forward,side[1]*leg_sign*13+d[1]*forward,lift)
   knee=((hip[0]+foot[0])*.5+d[0]*(15+lift*.25),(hip[1]+foot[1])*.5+d[1]*(15+lift*.25),(hip[2]+lift)*.5)
   line(p(*hip),p(*knee),color,14);line(p(*knee),p(*foot),color,12)
   line(p(foot[0]-d[0]*6,foot[1]-d[1]*6,lift),p(foot[0]+d[0]*16,foot[1]+d[1]*16,lift),color,13)
   shoulder=(side[0]*leg_sign*22+d[0]*lean,side[1]*leg_sign*22+d[1]*lean,shoulderz)
   elbow=(shoulder[0]-d[0]*forward*.35,shoulder[1]-d[1]*forward*.35,shoulderz-28)
   hand=(shoulder[0]-d[0]*forward*.7,shoulder[1]-d[1]*forward*.7,shoulderz-45+(15 if run else 0))
   line(p(*shoulder),p(*elbow),color,12);line(p(*elbow),p(*hand),color,11)
  line(p(d[0]*lean,d[1]*lean,hipz),p(d[0]*lean,d[1]*lean,shoulderz),'#71846c',35)
  hx,hy=p(d[0]*(lean+3),d[1]*(lean+3),193+body)
  out.append(f'<circle cx="{hx:.2f}" cy="{hy:.2f}" r="43" fill="#f0d9a0" stroke="#635d4c" stroke-width="3"/>')
  for e in [-1,1]:out.append(f'<path d="M{hx+e*33} {hy-22}L{hx+e*32} {hy-57}L{hx+e*9} {hy-36}Z" fill="#f0d9a0" stroke="#635d4c" stroke-width="3"/>')
  line((hx,hy),(hx+d[0]*38,hy+d[1]*12),'#635d4c',4)
  out.append(f'<text x="{col*400+20}" y="{row*400+35}" font-size="20" fill="#383e37">{"RUN" if run else "WALK"} {f+1}: '+['LEFT contact','LEFT support / RIGHT lifting','RIGHT passing','RIGHT forward','RIGHT contact','RIGHT support / LEFT lifting','LEFT passing','LEFT forward'][f]+'</text>')
  out.append(f'<path d="M{cx-90} {cy+20}h180" stroke="#c5ba9f" fill="none"/>')
 out.append('</svg>');(root/(direction+'.svg')).write_text(''.join(out))
