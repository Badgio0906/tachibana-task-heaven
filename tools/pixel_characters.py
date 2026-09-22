"""Original 96x128 pixel characters. Integer pixels, authored shapes, no resampling.

The source is a palette and deliberately placed shapes. SVG stores horizontal
pixel runs, so Godot imports the exact small canvas and draws it with NEAREST.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INK = '#293444'
SKIN = '#f2c397'
LIGHT = '#ffe0b0'
SHADE = '#d89778'
CHEEK = '#e6a08a'
WHITE = '#fff9ed'
SHIRT = '#e5e9df'
SHADOW = '#b4c4c5'
HAIR = '#3b424e'
HAIRLIGHT = '#5f6978'
PANTS = '#414d65'
PANTSLIGHT = '#596880'
TEAL = '#528e86'
TEALLIGHT = '#80b4a0'
TEALDARK = '#38666d'
CORAL = '#d77563'
BROWN = '#665061'
BHIGHLIGHT = '#94707a'

class Sprite:
    def __init__(self):
        self.pixels = [[None] * 96 for _ in range(128)]

    def dot(self, x, y, color):
        if 0 <= x < 96 and 0 <= y < 128:
            self.pixels[y][x] = color

    def rect(self, x, y, w, h, color):
        for yy in range(y, y+h):
            for xx in range(x, x+w): self.dot(xx, yy, color)

    def line(self, a, b, color):
        x0,y0=a; x1,y1=b
        dx=abs(x1-x0); sx=1 if x0<x1 else -1
        dy=-abs(y1-y0); sy=1 if y0<y1 else -1
        error=dx+dy
        while True:
            self.dot(x0,y0,color)
            if x0==x1 and y0==y1: break
            e=2*error
            if e>=dy: error+=dy; x0+=sx
            if e<=dx: error+=dx; y0+=sy

    def poly(self, points, color, outline=None):
        for y in range(min(p[1] for p in points),max(p[1] for p in points)+1):
            intersections=[]
            for i,(x0,y0) in enumerate(points):
                x1,y1=points[(i+1)%len(points)]
                if (y0<=y<y1) or (y1<=y<y0):
                    intersections.append(x0+(y-y0)*(x1-x0)/(y1-y0))
            intersections.sort()
            for i in range(0,len(intersections)-1,2):
                for x in range(round(intersections[i]),round(intersections[i+1])+1):self.dot(x,y,color)
        if outline:
            for i,p in enumerate(points):self.line(p,points[(i+1)%len(points)],outline)

    def ellipse(self,x,y,w,h,color):
        for yy in range(y,y+h):
            for xx in range(x,x+w):
                if ((xx+.5-x-w/2)/(w/2))**2+((yy+.5-y-h/2)/(h/2))**2<=1:self.dot(xx,yy,color)

    def save(self,name):
        runs=[]
        for y,row in enumerate(self.pixels):
            x=0
            while x<96:
                color=row[x]; end=x+1
                while end<96 and row[end]==color:end+=1
                if color:runs.append(f'<path fill="{color}" d="M{x} {y}h{end-x}v1H{x}z"/>')
                x=end
        svg='<svg xmlns="http://www.w3.org/2000/svg" width="96" height="128" viewBox="0 0 96 128" shape-rendering="crispEdges">'+''.join(runs)+'</svg>'
        (ROOT/'assets/characters'/f'{name}.svg').write_text(svg,encoding='utf8')

def legs(s, female=False):
    s.poly([(32,83),(65,83),(65,110),(61,117),(52,117),(49,96),(46,117),(33,117),(31,111)],PANTS,INK)
    s.rect(35,91,6,22,PANTSLIGHT);s.rect(55,93,5,20,PANTSLIGHT)
    s.line((49,89),(49,99),INK)
    s.poly([(32,114),(45,114),(45,121),(27,121),(27,118)],INK,INK)
    s.poly([(53,114),(63,114),(70,118),(70,121),(53,121)],INK,INK)
    s.rect(31,116,10,2,'#6e6b70');s.rect(56,116,7,2,'#6e6b70')
    s.rect(27,122,19,1,'#b4b8ac');s.rect(53,122,18,1,'#b4b8ac')

def hand(s,x,y,raised=False):
    s.poly([(x+2,y),(x+7,y),(x+9,y+3),(x+9,y+7),(x+6,y+10),(x+1,y+9),(x,y+4)],SKIN,INK)
    s.rect(x+2,y+2,4,3,LIGHT)
    s.line((x+3,y+7),(x+7,y+7),SHADE)
    if raised:s.line((x+2,y+3),(x+6,y+3),SHADE)

def badge(s,x,y):
    s.line((x-3,y-15),(x+4,y),INK);s.line((x+13,y-15),(x+6,y),INK)
    s.rect(x,y,12,10,INK);s.rect(x+1,y+1,10,8,WHITE)
    s.rect(x+2,y+3,3,4,TEAL);s.rect(x+7,y+3,3,1,SHADOW);s.rect(x+7,y+5,2,1,SHADOW)

def face(s,state):
    # Small ears, broad soft jaw, quiet eyes and mouth.
    s.ellipse(25,29,9,13,INK);s.ellipse(26,30,7,11,SKIN)
    s.ellipse(61,29,9,13,INK);s.ellipse(62,30,7,11,SKIN)
    s.poly([(33,17),(42,13),(54,14),(63,20),(65,30),(64,42),(59,50),(52,54),(42,53),(33,48),(29,39),(29,28)],SKIN,INK)
    s.poly([(32,24),(36,20),(57,19),(61,26),(60,39),(55,46),(43,46),(34,40)],LIGHT)
    s.line((34,46),(41,50),SHADE);s.rect(61,34,2,8,SHADE)
    s.poly([(28,32),(27,21),(31,13),(39,8),(49,7),(59,10),(65,15),(68,23),(65,34),(61,31),(61,22),(55,18),(45,18),(41,23),(34,24),(32,34)],HAIR,INK)
    s.poly([(31,19),(35,14),(44,11),(54,12),(60,16),(49,14),(40,17)],HAIRLIGHT)
    s.rect(30,27,2,8,'#949a9b');s.rect(63,26,2,9,'#949a9b')
    if state=='fail':
        s.line((36,30),(41,28),INK);s.line((53,28),(59,30),INK)
        s.rect(38,34,2,3,INK);s.rect(55,34,2,3,INK)
        s.poly([(42,45),(45,43),(50,43),(53,45)],None,INK)
        s.rect(38,38,2,7,'#71b7cf');s.rect(55,38,2,7,'#71b7cf')
        s.rect(38,40,1,3,'#c9f0e8')
    else:
        s.rect(36,29,6,1,HAIR);s.rect(53,29,6,1,HAIR)
        if state=='clear':
            s.line((36,36),(38,34),INK);s.line((38,34),(41,36),INK)
            s.line((53,36),(55,34),INK);s.line((55,34),(58,36),INK)
        else:
            s.rect(38,34,2,3,INK);s.rect(55,34,2,3,INK)
        s.line((42,44),(44,46),INK);s.line((44,46),(51,46),INK);s.line((51,46),(53,44),INK)
        s.rect(34,40,5,2,CHEEK);s.rect(57,40,4,2,CHEEK)
    s.line((47,37),(46,40),SHADE);s.rect(47,40,2,1,SHADE)

def worker(state):
    s=Sprite()
    back=state in ['idle','success','miss']
    legs(s)
    if state=='clear':
        s.poly([(62,59),(75,55),(77,41),(69,33),(72,27),(78,29),(84,40),(84,58),(76,73),(65,72)],SHIRT,INK)
        s.poly([(76,41),(76,48),(79,48),(81,40),(77,34)],SHADOW)
        hand(s,66,24)
    s.poly([(31,55),(41,51),(55,51),(66,55),(73,64),(68,87),(28,87),(23,64)],SHIRT,INK)
    s.poly([(26,65),(31,68),(33,83),(64,83),(68,76),(67,87),(29,87)],SHADOW)
    s.poly([(34,57),(40,55),(55,55),(63,60),(63,79),(35,79)],WHITE)
    if back:
        s.poly([(26,59),(21,63),(16,77),(21,85),(28,82),(31,69)],SHIRT,INK)
        if state=='success':
            s.poly([(65,59),(71,55),(73,44),(81,44),(82,61),(76,73),(67,74)],SHIRT,INK)
            hand(s,73,35,True)
        else:
            s.poly([(66,59),(73,64),(81,77),(77,85),(69,83),(64,69)],SHIRT,INK)
            hand(s,76,74)
        hand(s,12,74)
        s.rect(41,46,15,9,SKIN)
        s.ellipse(25,30,9,13,INK);s.ellipse(26,31,7,11,SKIN)
        s.ellipse(61,30,9,13,INK);s.ellipse(62,31,7,11,SKIN)
        s.poly([(31,15),(38,10),(48,8),(59,11),(65,17),(68,29),(64,43),(57,50),(38,49),(30,42),(27,29)],HAIR,INK)
        s.poly([(31,23),(34,16),(42,13),(52,13),(60,17),(64,25),(57,21),(47,18),(37,21)],HAIRLIGHT)
        s.rect(29,33,3,9,'#899294');s.rect(63,33,3,9,'#899294')
        s.line((39,43),(46,46),HAIRLIGHT);s.line((46,46),(56,43),HAIRLIGHT)
        s.poly([(30,82),(35,78),(60,78),(67,83),(67,106),(61,113),(34,113),(28,107),(28,89)],'#50799b',INK)
        s.poly([(32,84),(36,81),(59,81),(63,84),(63,89),(32,89)],'#81acbe')
        s.poly([(29,99),(34,107),(62,107),(66,99),(65,110),(59,115),(35,115),(29,111)],'#3d5d7d',INK)
        s.rect(45,111,6,10,INK);s.rect(27,120,42,3,INK)
        s.rect(25,121,6,4,INK);s.rect(66,121,6,4,INK)
        if state=='miss':
            s.poly([(73,18),(71,23),(72,26),(76,26),(78,23)],'#78b7c9',INK)
            s.rect(72,22,2,2,'#c7e5e2')
        if state=='success':
            s.rect(14,27,2,11,CORAL);s.rect(15,27,5,2,CORAL);s.ellipse(10,35,6,4,CORAL)
    else:
        s.rect(42,48,13,9,SKIN)
        s.poly([(38,53),(47,60),(41,66),(33,56)],WHITE,SHADOW)
        s.poly([(57,53),(49,60),(54,66),(63,56)],WHITE,SHADOW)
        s.poly([(46,60),(50,60),(52,65),(49,69),(53,80),(49,85),(44,81),(46,68),(44,65)],CORAL,INK)
        s.rect(47,65,2,11,'#e7a078')
        s.poly([(25,59),(20,66),(21,86),(24,92),(31,91),(31,81),(29,64)],SHIRT,INK)
        s.rect(22,71,3,14,SHADOW);s.rect(23,87,8,4,WHITE)
        hand(s,23,91)
        if state!='clear':
            s.poly([(66,59),(72,66),(72,86),(69,91),(62,90),(63,78),(63,64)],SHIRT,INK)
            s.rect(68,71,3,14,SHADOW);s.rect(63,86,8,4,WHITE)
            hand(s,62,90)
        face(s,state)
        if state=='fail':
            s.poly([(31,56),(38,53),(57,53),(67,57),(74,69),(70,94),(27,94),(23,69)],TEAL,INK)
            s.poly([(29,61),(35,58),(61,58),(67,63),(65,88),(31,88)],TEALLIGHT)
            s.rect(46,62,2,28,TEALDARK)
            for y in [72,82,90]:s.line((29,y),(67,y),TEALDARK)
            s.poly([(32,52),(41,55),(55,55),(63,52),(65,60),(53,66),(35,64),(29,59)],'#d7b582',INK)
            s.poly([(52,61),(62,59),(60,83),(53,81)],'#d7b582',INK)
            s.rect(54,65,2,14,'#edcc96')
            s.poly([(24,69),(32,69),(42,81),(57,74),(65,75),(64,83),(43,89),(33,84),(26,80)],TEAL,INK)
            badge(s,42,76)
        else:badge(s,55,74)
    s.save('tachibana_'+state)

def boss(state):
    s=Sprite();legs(s,True)
    # Hair is a rounded bob behind the jaw, with no pointed wedge nose.
    s.poly([(29,16),(36,11),(47,10),(59,14),(66,23),(68,44),(64,56),(51,58),(28,53),(24,42),(25,27)],BROWN,INK)
    s.poly([(31,18),(39,14),(51,14),(59,18),(63,26),(57,21),(42,18)],BHIGHLIGHT)
    s.poly([(31,57),(39,52),(55,53),(64,58),(70,69),(65,90),(28,90),(24,69)],TEAL,INK)
    s.poly([(30,62),(36,58),(58,59),(63,64),(62,84),(31,84)],TEALLIGHT)
    s.poly([(40,54),(45,56),(52,54),(53,61),(48,78),(42,65)],WHITE,INK)
    s.poly([(37,56),(42,69),(40,73),(46,79),(42,88),(32,88),(33,68)],TEAL,TEALDARK)
    s.poly([(55,56),(53,66),(56,70),(49,79),(52,88),(62,88),(62,66)],TEAL,TEALDARK)
    s.rect(48,81,2,2,'#e6cda0');s.rect(48,86,2,2,'#e6cda0')
    s.rect(39,46,12,11,SKIN)
    s.poly([(31,24),(40,19),(51,21),(58,27),(58,39),(54,47),(47,52),(37,51),(31,46),(28,40),(25,37),(28,33)],SKIN,INK)
    s.poly([(33,26),(39,22),(48,23),(54,28),(53,39),(49,46),(38,47),(31,41),(28,37),(31,33)],LIGHT)
    s.ellipse(54,31,7,10,INK);s.ellipse(55,32,5,8,SKIN)
    s.poly([(28,30),(27,22),(32,16),(39,13),(53,16),(60,23),(61,34),(57,37),(54,28),(44,24),(39,20),(35,26)],BROWN,INK)
    s.line((33,19),(38,17),BHIGHLIGHT);s.line((44,17),(55,21),BHIGHLIGHT)
    s.rect(56,38,2,2,'#efd18d')
    if state=='angry':
        s.line((30,31),(35,33),INK);s.line((43,33),(49,31),INK)
        s.rect(32,35,2,3,INK);s.rect(45,35,2,3,INK)
        s.line((34,44),(39,43),INK)
    elif state in ['happy','clap','clap2']:
        s.line((30,35),(32,33),INK);s.line((32,33),(35,35),INK)
        s.line((43,35),(45,33),INK);s.line((45,33),(48,35),INK)
        s.line((34,43),(36,45),INK);s.line((36,45),(41,44),INK)
        s.rect(29,40,5,2,CHEEK);s.rect(47,40,4,2,CHEEK)
    else:
        s.rect(30,30,5,1,BROWN);s.rect(43,30,6,1,BROWN)
        s.rect(32,34,2,3,INK);s.rect(45,34,2,3,INK)
        if state=='talk':
            s.ellipse(34,41,6,6,INK);s.rect(35,44,4,2,CORAL)
        else:s.line((34,44),(39,44),INK)
    s.dot(31,39,SHADE)
    if state.startswith('clap'):
        gap=3 if state=='clap2' else 0
        s.poly([(28,60),(24,65),(24,76),(33,79),(43-gap,70),(39-gap,64),(33,69),(32,62)],TEAL,INK)
        s.poly([(64,61),(69,67),(67,76),(59,78),(43+gap,68),(48+gap,63),(58,69)],TEAL,INK)
        hand(s,34-gap,59);hand(s,43+gap,58)
    else:
        # Clipboard side arm.
        s.poly([(63,59),(69,65),(70,81),(64,88),(55,83),(59,75),(60,64)],TEAL,INK)
        s.poly([(40,75),(57,72),(63,93),(44,97)],INK,INK)
        s.poly([(42,76),(55,74),(60,92),(46,94)],'#e8cc93',INK)
        s.line((46,81),(54,79),'#c49b75');s.line((47,85),(55,83),'#c49b75')
        hand(s,55,77)
        if state=='talk':
            s.poly([(27,59),(20,66),(13,65),(10,70),(22,76),(31,69)],TEAL,INK)
            s.poly([(4,61),(4,56),(6,56),(6,54),(8,54),(8,55),(10,55),(10,57),(12,57),(12,62),(15,61),(16,63),(13,69),(8,70),(4,66)],SKIN,INK)
            s.line((6,58),(6,62),SHADE);s.line((9,58),(9,62),SHADE)
        elif state=='angry':
            s.poly([(27,60),(18,68),(20,79),(29,83),(33,78),(25,74),(29,67)],TEAL,INK)
            hand(s,26,76)
        elif state=='happy':
            s.poly([(27,60),(21,65),(16,70),(21,77),(30,71)],TEAL,INK)
            s.poly([(11,64),(10,60),(10,55),(13,55),(14,61),(20,61),(22,64),(21,70),(15,72),(11,69)],SKIN,INK)
            s.rect(11,56,2,4,LIGHT);s.line((16,65),(20,65),SHADE);s.line((16,68),(20,68),SHADE)
        else:
            s.poly([(27,60),(22,64),(22,84),(27,92),(33,88),(30,79),(31,65)],TEAL,INK)
            hand(s,25,89)
    s.save('boss_'+state)

def build():
    for state in ['idle','success','miss','clear','fail','title']:worker(state)
    for state in ['idle','talk','happy','angry','clap','clap2']:boss(state)

if __name__=='__main__':
    build()
    print('12 original pixel sprites written (96x128).')
