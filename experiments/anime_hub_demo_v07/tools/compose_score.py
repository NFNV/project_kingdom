"""Original demo score. MIDI events are rendered offline by render_score.swift.

No downloaded songs, recorded loops or sound bank files are bundled.
"""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'

def compose(name, bpm, meter, chords, melody, repeats, programs, velocities):
    beat = 60 / bpm
    events = []
    def note(track, pitch, start, duration, velocity):
        events.append({'track':track,'pitch':pitch,'start':round(start*beat,6),'duration':round(duration*beat,6),'velocity':velocity})
    for repeat in range(repeats):
        for bar, chord in enumerate(chords):
            t = (repeat*len(chords)+bar)*meter
            # Finger-picked accompaniment and a low, unhurried harmonic bed.
            pattern = [0,2,1,2,0,1] if meter==3 else [0,2,1,2,0,2,1,2]
            for index, degree in enumerate(pattern):
                note(1,chord[degree],t+index*.5,.42,velocities[1]+(4 if index%3==0 else -3))
            note(2,chord[0]-12,t,meter-.18,velocities[2])
            for pitch in chord[1:]:
                note(2,pitch,t+.04,meter-.22,velocities[2]-7)
            for index, (pitch, length) in enumerate(melody[bar%len(melody)]):
                start = sum(item[1] for item in melody[bar%len(melody)][:index])
                if pitch:
                    note(0,pitch+(12 if name=='night' and repeat%2 else 0),t+start,length*.87,velocities[0]+((bar+index)%3-1)*4)
            # A few bell/harp answers leave space around the main tune.
            if bar%2==1:
                note(3,chord[2]+12,t+meter-1,.8,velocities[3])
                note(3,chord[1]+12,t+meter-.5,.45,velocities[3]-5)
            if name=='battle':
                for index in range(meter):
                    note(4,chord[0]-12,t+index,.32,68 if index%2==0 else 48)
    score = {'name':name,'bpm':bpm,'meter':meter,'duration':round(len(chords)*repeats*meter*beat,6),'programs':programs,'pan':[70,42,64,92,58],'events':events,'authorship':'Original note sequences and arrangement authored for Project Kingdom. Rendered with the local Core Audio GM sampler; the system sound bank is not redistributed.'}
    (ROOT/(name+'_score.json')).write_text(json.dumps(score,indent=2)+'\n')

def main():
    ROOT.mkdir(exist_ok=True,parents=True)
    # D major: an original little market-square waltz.
    chords=[[62,66,69],[59,62,66],[55,59,62],[57,61,64],[62,66,69],[55,59,62],[64,67,71],[57,61,64]]
    melody=[[(78,.75),(81,.25),(78,1),(76,1)],[(74,1.5),(73,.5),(71,1)],[(74,1),(78,.5),(79,.5),(78,1)],[(76,2),(0,1)],[(78,.5),(81,.5),(83,1),(81,1)],[(79,1),(78,1),(74,1)],[(76,1),(79,1),(78,1)],[(76,1.5),(73,.5),(69,1)]]
    compose('town',90,3,chords,melody,3,[73,24,48,46],[64,46,28,39])
    # G/D suspended colors, broad phrases and small pauses for the woodland.
    chords=[[55,62,69],[59,62,66],[60,64,67],[57,62,67],[55,59,62],[64,67,71],[60,64,69],[57,61,64]]
    melody=[[(79,1.5),(78,.5),(74,1),(0,1)],[(78,2),(76,1),(74,1)],[(76,1),(79,1),(83,1.5),(0,.5)],[(81,1.5),(79,.5),(78,1),(0,1)],[(74,1),(71,1),(74,1),(79,1)],[(78,1.5),(76,.5),(74,1),(0,1)],[(76,2),(72,1),(74,1)],[(73,1),(76,1),(74,1),(0,1)]]
    compose('woodland',72,4,chords,melody,2,[73,46,48,8],[54,39,26,30])
    chords=[[59,62,66],[55,59,62],[62,66,69],[57,61,64],[64,67,71],[55,59,62],[60,64,67],[57,61,64]]
    melody=[[(78,1),(74,1),(0,1)],[(79,1.5),(78,.5),(74,1)],[(81,2),(0,1)],[(76,1),(73,1),(0,1)],[(79,1),(83,1),(78,1)],[(74,1.5),(71,.5),(0,1)],[(76,1),(79,1),(74,1)],[(73,2),(0,1)]]
    compose('night',55,3,chords,melody,2,[8,46,48,10],[45,32,23,30])
    chords=[[59,62,66],[55,59,62],[62,66,69],[57,61,64],[59,62,66],[64,67,71],[55,59,62],[57,61,64]]
    melody=[[(78,.5),(78,.5),(81,1),(78,.5),(76,.5),(74,1)],[(79,1),(78,.5),(74,.5),(71,1),(74,1)],[(81,.5),(78,.5),(81,1),(85,1),(83,1)],[(81,1),(76,1),(73,.5),(76,.5),(78,1)],[(83,1),(81,.5),(78,.5),(74,1),(78,1)],[(79,.5),(78,.5),(76,1),(79,1),(83,1)],[(81,1),(79,1),(78,.5),(74,.5),(71,1)],[(73,1),(76,1),(78,1),(0,1)]]
    compose('battle',120,4,chords,melody,3,[48,24,48,46,12],[68,58,39,41,60])
    print('Composed four original scores.')

if __name__=='__main__': main()
