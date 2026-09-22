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

for state in ['idle','success','miss','clear','fail','title']:
    front=state in ['clear','fail','title']
    body='<ellipse cx="161" cy="343" rx="112" ry="12" fill="#263448" opacity=".12" stroke="none"/>'
    body+='<path d="M100 295 L94 333 L143 333 L155 290 M180 288 L185 333 L231 333 L219 287" fill="#263448"/>'
    shirt='#81b5c4' if state=='fail' else '#fffdf3'
    body+=f'<path d="M102 187 Q156 168 216 187 L248 277 Q170 315 72 275Z" fill="{shirt}"/>'
    if front: body+='<path d="M134 186 L160 210 L183 186 M157 211 L147 261 L163 276 L176 259 L166 211" fill="#e78061"/>'
    body+=f'<path d="M131 171 L131 193 Q158 212 182 189 L182 165" fill="{SKIN}"/>'
    body+=f'<ellipse cx="154" cy="117" rx="65" ry="74" fill="{SKIN}"/>'
    body+=f'<ellipse cx="90" cy="133" rx="13" ry="20" fill="{SKIN}"/><ellipse cx="220" cy="133" rx="13" ry="20" fill="{SKIN}"/>'
    if front:
        body+='<path d="M90 110 Q75 49 121 39 Q137 20 169 40 Q229 30 220 110 L207 91 L193 78 Q166 96 136 68 L111 89Z" fill="#514443"/>'
        if state=='fail':
            body+='<path d="M118 117 L140 126 M174 126 L195 116 M138 163 Q159 145 179 165" fill="none"/>'
            body+='<path d="M127 136 Q108 166 128 171 Q143 160 127 136 M187 136 Q171 165 190 170 Q203 160 187 136" fill="#87c9ed" stroke="none"/>'
        else:
            body+='<path d="M117 126 Q128 114 140 126 M173 126 Q186 114 198 126 M139 157 Q160 178 180 156" fill="none"/>'
            body+='<ellipse cx="116" cy="147" rx="14" ry="8" fill="#eea295" stroke="none"/><ellipse cx="199" cy="147" rx="14" ry="8" fill="#eea295" stroke="none"/>'
        if state=='clear': body+=f'<path d="M211 203 Q279 187 252 117 L222 100 L208 112 L231 137 L224 179" fill="{SKIN}"/>'
        else: body+=f'<path d="M95 200 L65 242 L79 255 L120 221 M215 200 L249 240 L234 254 L198 219" fill="{SKIN}"/>'
        body+='<path d="M183 219 L180 267 L211 268 L211 235" fill="none" stroke-width="3"/><rect x="178" y="254" width="38" height="26" rx="3" fill="#fffdf3"/><circle cx="188" cy="265" r="4" fill="#66b5a5" stroke="none"/>'
    else:
        body+='<path d="M92 148 Q78 90 95 62 Q105 29 137 37 Q164 20 192 45 Q230 47 219 146 Q206 174 184 174 L180 153 Q153 171 130 153 L124 172 Q99 168 92 148Z" fill="#514443"/>'
        body+=f'<path d="M104 214 L49 197 L23 211 L95 250 M209 212 L268 194 L297 213 L224 247" fill="{SKIN}"/>'
        body+='<rect x="95" y="246" width="127" height="84" rx="24" fill="#779dba"/><path d="M159 329 L159 347 M112 350 L207 350" fill="none"/>'
        if state=='miss': body+='<path d="M254 76 L265 101 L242 106 L254 131" fill="none" stroke="#e57460" stroke-width="9"/>'
        if state=='success': body+='<path d="M260 79 L260 120 Q236 112 239 129 Q259 143 272 122 L272 72Z" fill="#ecb945" stroke="none"/>'
    write(f'assets/characters/tachibana_{state}.svg',svg(body))

for state in ['idle','talk','happy','angry','clap','clap2']:
    body='<ellipse cx="154" cy="340" rx="85" ry="12" fill="#263448" opacity=".12" stroke="none"/>'
    body+='<path d="M113 253 L110 325 L144 325 L153 264 L168 326 L202 326 L195 249" fill="#263448"/>'
    body+='<path d="M119 167 Q157 152 191 172 L217 267 L96 267Z" fill="#87bdb0"/>'
    body+='<path d="M140 175 L155 207 L174 174 L163 236Z" fill="#fffdf3"/>'
    body+='<path d="M106 140 Q75 24 157 25 Q235 29 215 158Z" fill="#55424b"/>'
    body+=f'<path d="M138 136 L138 174 Q155 192 177 169 L175 135" fill="{SKIN}"/>'
    body+=f'<path d="M112 67 Q144 37 193 65 L194 104 L211 119 L196 129 Q191 164 161 167 Q115 161 111 111Z" fill="{SKIN}"/>'
    body+='<path d="M104 107 L114 65 Q159 104 194 64 L196 45 Q131 9 104 58Z" fill="#55424b"/>'
    body+='<circle cx="178" cy="109" r="4" fill="#263448"/>'
    if state=='talk': body+='<ellipse cx="186" cy="143" rx="9" ry="11" fill="#bb656b"/>'
    elif state in ['happy','clap','clap2']: body+='<path d="M171 140 Q182 154 193 139 M166 103 L180 100" fill="none"/>'
    elif state=='angry': body+='<path d="M164 96 L183 103 M173 145 L189 141" fill="none"/>'
    else: body+='<path d="M175 141 L188 141" fill="none"/>'
    if state.startswith('clap'):
        gap=12 if state=='clap2' else 0
        body+=f'<path d="M112 194 L83 228 L129 219 L{152-gap} 190 L{141-gap} 178 L117 204Z" fill="{SKIN}"/>'
        body+=f'<path d="M194 194 L211 228 L164 216 L{148+gap} 186 L{161+gap} 177 L181 204Z" fill="{SKIN}"/>'
    else:
        body+=f'<path d="M117 192 L72 169 L62 145 L44 153 L56 182 L108 222" fill="{SKIN}"/>'
        body+='<path d="M43 147 L86 107" fill="none" stroke-width="5"/>'
        body+='<path d="M189 196 L227 223 L213 245 L180 221" fill="#87bdb0"/><path d="M205 223 L211 207 L169 186 L158 217Z" fill="#fff2bf"/>'
    write(f'assets/characters/boss_{state}.svg',svg(body))
write('assets/icon.svg',svg('<rect x="18" y="18" width="220" height="220" rx="48" fill="#eea969"/><rect x="47" y="55" width="164" height="113" rx="12" fill="#fffdf3"/><path d="M82 111 L116 141 L175 84 M130 170 L130 199 M94 202 L169 202" fill="none" stroke-width="13"/>',256,256))
print(json.dumps({'stage_duration_seconds':durations},ensure_ascii=False))
