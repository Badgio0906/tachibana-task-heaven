"""Rebuild original SVG art, chart data (first run), and deterministic WAV music."""
from pathlib import Path
import json, math, wave, random
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
for d in ['data','assets/audio','assets/characters','assets/fonts','tools','tests/artifacts','docs','web']:
    (ROOT/d).mkdir(parents=True, exist_ok=True)

def write(path, text):
    (ROOT/path).write_text(text, encoding='utf-8')

def chart(name, bpm, theme, rows):
    target = ROOT/'data'/f'{name}.json'
    if target.exists(): return
    rounds=[]
    for row in rows:
        values, step, length = row[:3]
        rounds.append(dict(length=length, final=len(row)>3, rests=[i*step for i,v in enumerate(values) if not v],
            beats=[dict(beat=i*step, channel=v) for i,v in enumerate(values) if v]))
    target.write_text(json.dumps(dict(bpm=bpm,theme=theme,rounds=rounds),ensure_ascii=False,indent=2),encoding='utf-8')

chart('tutorial',90,'まずは練習',[([1,2,3,4],1,4)])
chart('stage_01',90,'今日もお仕事',[
    ([1,1,2,1],1,4),([2,1,2,2],1,4),([1,2,3,1],1,4),
    ([2,2,1,3],1,4),([1,2,3,3,1],1,5),([3,1,2,3,2],1,5)])
chart('stage_02',110,'タスク増えてきた',[
    ([1,2,3,4,1],1,5),([1,0,2,3,3,4],1,6),([2,3,2,4,4,1],1,6),
    ([1,1,3,0,4,2],1,6),([4,2,0,3,1,4,2],1,7),([1,2,3,4,3,2,4],1,7)])
chart('stage_03',136,'タスク地獄',[
    ([1,2,1,3,4,3,2,4],1,8),([1,1,2,3,3,4,2,1],1,8),
    ([4,3,2,1,4,4,3,2],1,8),([3,2,1,4,2,3,4,1],1,8),([1,2,3,4,1,2,3,4,2,4],.5,5),
    ([1,1,2,0,3,3,4,0,1,2,3,4,1,0,4],.5,8,True)])

SR=22050
rng=np.random.default_rng(240922)
def sound(kind,duration=.6):
    t=np.arange(int(SR*duration))/SR
    noise=rng.uniform(-1,1,len(t))
    if kind==1: y=(noise*.45+np.sin(2*np.pi*2800*t)*.15)*np.exp(-t*18)
    elif kind==2: y=(np.sin(2*np.pi*2350*t)+.4*np.sin(2*np.pi*3713*t))*np.exp(-t*6)*.4
    elif kind==3: y=(noise*.6+.15*np.sin(2*np.pi*6100*t))*np.exp(-t*8)
    elif kind==4: y=np.sin(2*np.pi*(48*t+4*(1-np.exp(-t*25))))*np.exp(-t*13)*.9
    elif kind==5: y=(np.sin(2*np.pi*(220*t-90*t*t))*.6)*np.exp(-t*10)
    elif kind==6: y=noise*np.exp(-t*25)*.32
    elif kind==7: y=np.sin(2*np.pi*1200*t)*np.exp(-t*65)*.22
    else: y=noise*.10*(.6+.4*np.sin(t*6))
    return y
def save_wav(path,y):
    y=np.clip(y,-.97,.97)
    with wave.open(str(ROOT/path),'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes((y*32767).astype('<i2').tobytes())
for k,n in enumerate(['tambourine','triangle','cymbal','kick','error','omit','tick','wind'],1):
    save_wav(f'assets/audio/{n}.wav',sound(k,2 if k==8 else .6))

def put(buf, at, note, amp=1):
    p=int(at*SR)
    end=min(len(buf),p+len(note))
    if p>=0 and p<end: buf[p:end]+=note[:end-p]*amp

durations={}
for name in ['tutorial','stage_01','stage_02','stage_03']:
    data=json.loads((ROOT/'data'/f'{name}.json').read_text(encoding='utf8'))
    spb=60/data['bpm']; cursor=4; demos=[]
    for row in data['rounds']:
        if row['final']: cursor+=4
        for note in row['beats']: demos.append(((cursor+note['beat'])*spb,note['channel']))
        cursor+=row['length']*2+3.5
    duration=cursor*spb+.6
    durations[name]=round(duration,3)
    buf=np.zeros(int((duration+1)*SR))
    for beat in range(math.ceil(cursor)):
        put(buf,beat*spb,sound(4 if beat%4==0 else 7),.25 if beat%4==0 else .6)
        if beat%2==1: put(buf,beat*spb,sound(1),.14)
        # Original major-seventh office groove: C / Am / F / G.
        roots=[130.813,110,87.307,97.999]
        root=roots[(beat//8)%4]
        tt=np.arange(int(spb*.7*SR))/SR
        bass=np.sin(2*np.pi*root*tt)*np.exp(-tt*9)*.13
        put(buf,beat*spb,bass)
        freq=root*[4,5,6,5][beat%4]
        tt=np.arange(int(.22*SR))/SR
        pluck=(np.sin(2*np.pi*freq*tt)+.2*np.sin(2*np.pi*freq*2*tt))*np.exp(-tt*18)*.09
        put(buf,(beat+.5)*spb,pluck)
    for at,ch in demos: put(buf,at,sound(ch),.85)
    save_wav(f'assets/audio/{name}.wav',buf)
for win in [True,False]:
    buf=np.zeros(SR*3)
    for i,freq in enumerate([523.25,659.25,783.99,1046.5] if win else [392,349,293.66,196]):
        tt=np.arange(SR*.7)/SR
        put(buf,i*.22,np.sin(2*np.pi*freq*tt)*np.exp(-tt*5)*.3)
    save_wav('assets/audio/'+('clear' if win else 'fail')+'.wav',buf)

NAVY='#263448'; SKIN='#f4c89e'
def svg(body,w=320,h=360):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><g stroke="{NAVY}" stroke-width="6" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>'

from pixel_characters import build as build_characters
build_characters()

write('assets/icon.svg',svg('<rect x="18" y="18" width="220" height="220" rx="48" fill="#eea969"/><rect x="47" y="55" width="164" height="113" rx="12" fill="#fffdf3"/><path d="M82 111 L116 141 L175 84 M130 170 L130 199 M94 202 L169 202" fill="none" stroke-width="13"/>',256,256))
print(json.dumps({'stage_duration_seconds':durations},ensure_ascii=False))
