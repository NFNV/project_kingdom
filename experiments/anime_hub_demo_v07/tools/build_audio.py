"""Master the original score and create deterministic original ambience/foley.

NumPy + standard library only. No synthesis or file decoding runs during play.
"""
from pathlib import Path
import hashlib,json,wave
import numpy as np

ROOT=Path(__file__).resolve().parents[1]/'assets'/'audio'
SR=32000
RNG=np.random.default_rng(48270)
CATALOG={}

def noise(seconds, low=80, high=8000):
    count=round(seconds*SR)
    spectrum=np.fft.rfft(RNG.normal(0,1,count))
    hz=np.fft.rfftfreq(count,1/SR)
    response=(1-np.exp(-(hz/max(low,1))**4))*np.exp(-(hz/high)**4)
    signal=np.fft.irfft(spectrum*response,count)
    return signal/max(np.std(signal),1e-9)

def save(name, signal, loop=False, rms=.15):
    signal=np.asarray(signal,dtype=np.float64)
    signal-=np.mean(signal,axis=0)
    signal*=min(rms/max(np.sqrt(np.mean(signal*signal)),1e-9),.78/max(np.max(np.abs(signal)),1e-9))
    # Very short endpoint tapers avoid clicks without audible musical pumping.
    fade=min(int(.004*SR),len(signal)//8)
    shape=np.linspace(0,1,fade)
    if signal.ndim==2: shape=shape[:,None]
    signal[:fade]*=shape
    signal[-fade:]*=shape[::-1]
    pcm=np.round(np.clip(signal,-.98,.98)*32767).astype('<i2')
    path=ROOT/(name+'.wav')
    with wave.open(str(path),'wb') as file:
        file.setnchannels(2 if pcm.ndim==2 else 1);file.setsampwidth(2);file.setframerate(SR);file.writeframes(pcm.tobytes())
    CATALOG[name]={'file':path.name,'frames':len(signal),'rate':SR,'channels':2 if pcm.ndim==2 else 1,'loop':loop,'seconds':round(len(signal)/SR,4),'peak':round(float(np.max(np.abs(signal))),5),'rms':round(float(np.sqrt(np.mean(signal*signal))),5),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

def tone(midi, duration, decay=3):
    t=np.arange(round(duration*SR))/SR
    hz=440*2**((midi-69)/12)
    signal=np.sin(2*np.pi*hz*t)+.25*np.sin(2*np.pi*hz*2.006*t)+.11*np.sin(2*np.pi*hz*2.76*t)
    return signal*np.minimum(1,t/.008)*np.exp(-t*decay)

def chime(name, notes, interval=.12):
    signal=np.zeros(round((len(notes)*interval+1.1)*SR))
    for i,note in enumerate(notes):
        part=tone(note,1.1,5)
        at=round(i*interval*SR);signal[at:at+len(part)]+=part
    save(name,signal,rms=.12)

def main():
    ROOT.mkdir(parents=True,exist_ok=True)
    music=[]
    for name in ['town','woodland','night','battle']:
        with wave.open(str(ROOT/(name+'_raw.wav')),'rb') as file:
            raw=np.frombuffer(file.readframes(file.getnframes()),dtype='<i2').reshape(-1,2).astype(float)/32768
        score=json.loads((ROOT/(name+'_score.json')).read_text())
        frames=round(score['duration']*SR)
        assert len(raw)==frames*2 and np.max(np.abs(raw))<.999,'Raw score must be complete and unclipped'
        signal=raw[frames:frames*2].copy()
        save('music_'+name,signal,True,rms=.14)
        music.append(signal[:8*SR])
    for surface in ['stone','wood','grass','earth']:
        for index in range(4):
            duration=.22;t=np.arange(round(duration*SR))/SR
            grit=noise(duration,250,6500 if surface in ['stone','grass'] else 4000)
            body=np.sin(2*np.pi*(105+index*9+(120 if surface=='wood' else 0))*t)*np.exp(-t*50)
            envelope=np.minimum(1,t/.0015)*np.exp(-t*(34 if surface=='stone' else 23))
            sound=grit*envelope*(.25 if surface=='wood' else .5)+body*.75
            if surface=='grass': sound+=noise(duration,1800,10000)*envelope*.28
            save('step_'+surface+'_'+str(index),sound,rms=.12)
    for index in range(3):
        t=np.arange(round(.30*SR))/SR
        shape=np.sin(np.pi*np.clip(t/.30,0,1))**2*np.exp(-t*5)
        save('sword_'+str(index),noise(.30,600+index*110,10500)*shape,rms=.14)
        t=np.arange(round(.24*SR))/SR
        hit=noise(.24,200,8000)*np.exp(-t*40)+.4*np.sin(2*np.pi*(145+index*11)*t)*np.exp(-t*24)
        hit+=.09*(np.sin(2*np.pi*1300*t)+np.sin(2*np.pi*2150*t))*np.exp(-t*50)
        save('hit_'+str(index),hit,rms=.16)
    t=np.arange(round(.45*SR))/SR
    save('club',noise(.45,80,3300)*np.sin(np.pi*t/.45)**2*np.exp(-t*4),rms=.15)
    t=np.arange(round(.28*SR))/SR
    save('wind_charge',(noise(.28,500,7000)*.3+np.sin(2*np.pi*(340*t+700*t*t))*.18)*np.sin(np.pi*t/.56)**2,rms=.13)
    t=np.arange(round(.65*SR))/SR
    save('wind_release',noise(.65,350,12000)*np.minimum(1,t/.012)*np.exp(-t*7)+.1*np.sin(2*np.pi*(650*t-260*t*t))*np.exp(-t*8),rms=.18)
    t=np.arange(round(.30*SR))/SR
    save('hurt_player',noise(.30,90,1800)*np.exp(-t*20)+np.sin(2*np.pi*(180*t-100*t*t))*.6*np.exp(-t*13),rms=.16)
    save('defeat',noise(.45,130,5000)*np.sin(np.pi*np.arange(round(.45*SR))/(.45*SR))*np.exp(-np.arange(round(.45*SR))/SR*7),rms=.12)
    chime('coin',[86,93],.065);chime('victory',[74,78,81,86],.13)
    chime('ui_open',[74,81],.065);chime('ui_confirm',[78,86],.075);chime('ui_error',[57,55],.09)
    chime('bandit_alert',[55,62],.075)
    t=np.arange(round(.7*SR))/SR
    save('door',noise(.7,80,2200)*np.exp(-t*11)*.4+np.sin(2*np.pi*(280*t+17*np.sin(t*10)))*np.exp(-t*7)*.12,rms=.13)
    duration=12;t=np.arange(duration*SR)/SR
    breeze=noise(duration,55,1700)*(.11+.035*np.sin(2*np.pi*t/duration))
    birds=np.zeros_like(breeze)
    for at in [.8,2.7,5.1,7.9,10.2]:
        length=.36;local=np.arange(round(length*SR))/SR
        chirp=np.sin(2*np.pi*(2200*local+500*local*local+13*np.sin(local*18)))*np.sin(np.pi*local/length)**2*.15
        start=round(at*SR);birds[start:start+len(chirp)]+=chirp
    save('birds_breeze',np.stack([breeze+birds,np.roll(breeze,2701)+np.roll(birds,5000)],axis=1),True,rms=.10)
    crickets=noise(duration,60,1000)*.055
    for at in np.arange(.3,duration-.2,.47):
        local=np.arange(round(.16*SR))/SR
        chirp=np.sin(2*np.pi*3800*local)*np.sin(np.pi*local/.16)**2*(.5+.5*np.sin(local*2*np.pi*48))*.08
        start=round(at*SR);crickets[start:start+len(chirp)]+=chirp
    save('night_air',np.stack([crickets,np.roll(crickets,7200)],axis=1),True,rms=.075)
    for name,high in [('fountain',6000),('river',3600)]:
        water=noise(duration,90,high)*(.65+.08*np.sin(t*2*np.pi/duration*3))
        water+=np.sin(2*np.pi*(310*t+4*np.sin(t*9)))*.035
        save(name,np.stack([water,np.roll(water,3197)],axis=1),True,rms=.13)
    oven=noise(duration,70,1400)*.09
    for at in RNG.uniform(.1,duration-.2,35):
        length=.06;local=np.arange(round(length*SR))/SR
        pop=noise(length,100,5000)*np.exp(-local*80)*RNG.uniform(.05,.12)
        start=round(at*SR);oven[start:start+len(pop)]+=pop
    save('oven',oven,True,rms=.09)
    preview=music[0].copy()
    overlap=round(.35*SR)
    blend=np.linspace(0,1,overlap)[:,None]
    for part in music[1:]:
        preview[-overlap:]=preview[-overlap:]*(1-blend)+part[:overlap]*blend
        preview=np.concatenate([preview,part[overlap:]],axis=0)
    save('soundtrack_preview',preview,rms=.14)
    manifest={'sample_rate':SR,'provenance':'Original compositions and sound design authored for Project Kingdom. Musical performances rendered offline with the local Core Audio GM sampler; no downloaded songs or instrument bank files are distributed. Ambience/foley are deterministic NumPy synthesis. All playback assets are finished PCM audio; synthesis never runs during gameplay.','clips':CATALOG}
    (ROOT/'catalog.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(f'Mastered {len(CATALOG)} original audio clips.')

if __name__=='__main__': main()
