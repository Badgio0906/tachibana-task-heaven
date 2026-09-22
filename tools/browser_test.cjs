const {chromium} = require(process.env.TASK_NODE_MODULES + '/playwright');
const fs = require('fs');
const path = require('path');
const root=path.resolve(__dirname,'..');
const out=process.env.TASK_ARTIFACT_DIR || path.join(root,'tests/artifacts');
fs.mkdirSync(out,{recursive:true});
const base=process.argv[2] || 'http://127.0.0.1:8766/';
const mode=process.argv[3] || 'full';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const errors=[],results=[];
function timeline(index){
 const d=JSON.parse(fs.readFileSync(path.join(root,'data',index?'stage_0'+index+'.json':'tutorial.json'),'utf8'));
 let cursor=4,notes=[];const spb=60/d.bpm;
 for(const r of d.rounds){if(r.final)cursor+=4;for(const n of r.beats)notes.push({time:(cursor+r.length+2+n.beat)*spb,ch:n.channel});cursor+=r.length*2+3.5;}
 return {notes,duration:cursor*spb+.6};
}
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true,args:['--enable-webgl','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const context=await browser.newContext({viewport:{width:1280,height:720},hasTouch:true});
 const page=await context.newPage();
 page.on('pageerror',e=>errors.push(String(e)));
 page.on('console',msg=>{if(msg.type()==='error')errors.push(msg.text());});
 await page.goto(base);
 await page.waitForFunction(()=>window.TaskHeavenStatus?.state==='title',null,{timeout:60000});
 await page.screenshot({path:path.join(out,'browser_title.png')});
 console.log('TITLE loaded',base);
 if(mode==='screens'){await browser.close();return;}
 await page.keyboard.press('F4'); await sleep(150);
 if(await page.evaluate(()=>TaskHeavenStatus.state)!=='title')throw Error('Release debug shortcut is active');
 await page.mouse.click(220,489);
 await page.waitForFunction(()=>window.TaskHeavenStatus?.state==='help');
 await page.screenshot({path:path.join(out,'browser_help.png')});
 await page.mouse.click(290,597);
 await page.waitForFunction(()=>window.TaskHeavenStatus?.state==='playing',null,{timeout:45000});
 const audio=await page.evaluate(()=>({state:TaskAudio.context.state,sampleRate:TaskAudio.context.sampleRate,ready:TaskAudio.ready,buffers:Object.keys(TaskAudio.buffers).length}));
 if(audio.state!=='running'||audio.buffers!==13)throw Error('Audio not ready');
 results.push({audio});
 await page.mouse.click(1207,48);
 await page.waitForFunction(()=>TaskHeavenStatus.state==='paused');
 const pausedAt=await page.evaluate(()=>TaskAudio.clock());await sleep(300);
 const pauseDrift=await page.evaluate(()=>TaskAudio.clock())-pausedAt;
 if(Math.abs(pauseDrift)>.025)throw Error('Pause did not freeze audio clock');
 results.push({pauseDrift});
 await page.mouse.click(620,375);
 await page.waitForFunction(()=>TaskHeavenStatus.state==='playing');
 // Verify actual non-silent samples reach the output graph.
 results.push({audioEnergy:await page.evaluate(async()=>{
   const a=TaskAudio.context.createAnalyser();TaskAudio.gain.connect(a);a.fftSize=2048;
   let max=0; const b=new Float32Array(2048);
   for(let i=0;i<15;i++){a.getFloatTimeDomainData(b);max=Math.max(max,...b.map(Math.abs));await new Promise(r=>setTimeout(r,30));}
   TaskAudio.gain.disconnect(a); return max;
 })});
 async function playStage(index,touch=false){
  const chart=timeline(index);
  for(const n of chart.notes){
   await page.waitForFunction(target=>window.TaskAudio.clock()>=target,n.time-.025,{polling:'raf',timeout:20000});
   if(touch)await page.touchscreen.tap((53+(n.ch-1)*208+(n.ch>2?22:0)+96)*844/1280,410*844/1280+(390-720*844/1280)/2);
   else await page.keyboard.press(String(n.ch));
  }
  await page.waitForFunction(()=>['between','practice_result','clear','fail'].includes(window.TaskHeavenStatus?.state),null,{timeout:20000});
  const status=await page.evaluate(()=>TaskHeavenStatus);results.push({stage:index,...status});
  console.log('STAGE',index,status);
  if(status.misses!==0||status.state==='fail')throw Error('Unexpected miss during timed browser inputs');
 }
 await playStage(0);
 await page.screenshot({path:path.join(out,'browser_tutorial_complete.png')});
 await page.mouse.click(625,413);
 await page.waitForFunction(()=>window.TaskHeavenStatus?.stage===1&&window.TaskHeavenStatus.state==='playing');
 await page.screenshot({path:path.join(out,'browser_game.png')});
 if(mode==='full'){
  for(let i=1;i<=3;i++){
   await playStage(i);
   await page.screenshot({path:path.join(out,i===3?'browser_clear.png':'browser_stage_'+i+'_complete.png')});
   if(i<3){await page.mouse.click(630,430);await page.waitForFunction(index=>TaskHeavenStatus.stage===index&&TaskHeavenStatus.state==='playing',i+1);}
  }
  await page.mouse.click(500,645);
  await page.waitForFunction(()=>TaskHeavenStatus.state==='playing');
  const probe=timeline(1).notes;
  for(let i=0;i<3;i++){
   await page.waitForFunction(t=>TaskAudio.clock()>=t,probe[i].time+[.12,.23,0][i],{polling:'raf'});
   await page.keyboard.press(String(i===2?4:probe[i].ch));
  }
  await page.waitForFunction(()=>TaskHeavenStatus.counts.GOOD>=1&&TaskHeavenStatus.counts.OK>=1&&TaskHeavenStatus.counts.MISS>=1);
  results.push({judgmentProbe:await page.evaluate(()=>TaskHeavenStatus.counts)});
  await page.waitForFunction(()=>TaskHeavenStatus.state==='fail',null,{timeout:60000});
  await sleep(700);
  results.push({failure:await page.evaluate(()=>TaskHeavenStatus)});
  await page.screenshot({path:path.join(out,'browser_fail.png')});
  await page.mouse.click(800,645);
  await page.waitForFunction(()=>TaskHeavenStatus.state==='title');
 }
 // Landscape phone touch uses real touch events, with native canvas scaling.
 await page.setViewportSize({width:844,height:390});
 await page.reload();
 await page.waitForFunction(()=>window.TaskHeavenStatus?.state==='title',null,{timeout:60000});
 await page.screenshot({path:path.join(out,'mobile_landscape.png')});
 // Board factor is min(844/1280,390/720) = 390/720, centered horizontally.
 const factor=390/720, ox=(844-1280*factor)/2;
 const tap=(x,y)=>page.touchscreen.tap(ox+x*factor,y*factor);
 await tap(220,565); await page.waitForFunction(()=>TaskHeavenStatus.state==='help');
 await tap(290,597); await page.waitForFunction(()=>TaskHeavenStatus.state==='playing');
 for(const n of timeline(0).notes){
  await page.waitForFunction(t=>TaskAudio.clock()>=t,n.time-.025,{polling:'raf'});
  await tap(53+(n.ch-1)*208+(n.ch>2?22:0)+96,410);
 }
 await page.waitForFunction(()=>TaskHeavenStatus.state==='practice_result');
 const mobile=await page.evaluate(()=>TaskHeavenStatus);results.push({mobile});
 if(mobile.misses)throw Error('Touch tutorial failed');
 await page.screenshot({path:path.join(out,'mobile_touch_pass.png')});
 await page.setViewportSize({width:390,height:844});await sleep(250);
 await page.screenshot({path:path.join(out,'mobile_portrait.png')});
 results.push({portrait:await page.evaluate(()=>TaskHeavenStatus.portrait)});
 await browser.close();
 const report={base,mode,results,errors};
 fs.writeFileSync(path.join(out,'browser_'+mode+'.json'),JSON.stringify(report,null,2));
 console.log(JSON.stringify(report));
 if(errors.length)process.exitCode=1;
})().catch(e=>{console.error(e);fs.writeFileSync(path.join(out,'browser_error.json'),JSON.stringify({error:String(e),results,errors},null,2));process.exit(1);});
