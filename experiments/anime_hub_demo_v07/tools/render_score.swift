// Offline Core Audio rendering. The system instrument bank is never copied.
import Foundation
import AVFoundation
import AudioToolbox

struct Note: Decodable { let track:Int; let pitch:Int; let start:Double; let duration:Double; let velocity:Int }
struct Score: Decodable { let name:String; let duration:Double; let programs:[Int]; let pan:[Int]; let events:[Note] }
struct Event { let frame:AVAudioFramePosition; let track:Int; let pitch:UInt8; let velocity:UInt8 }
let directory=URL(fileURLWithPath:CommandLine.arguments[1])
let bank=URL(fileURLWithPath:"/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
let rate=32000.0
for name in ["town","woodland","night","battle"] {
 let score=try JSONDecoder().decode(Score.self,from:Data(contentsOf:directory.appendingPathComponent(name+"_score.json")))
 let engine=AVAudioEngine()
 engine.mainMixerNode.outputVolume = 0.50
 let format=AVAudioFormat(standardFormatWithSampleRate:rate,channels:2)!
 var samplers:[AVAudioUnitSampler]=[]
 for (index,program) in score.programs.enumerated() {
  let sampler=AVAudioUnitSampler()
  engine.attach(sampler)
  try sampler.loadSoundBankInstrument(at:bank,program:UInt8(program),bankMSB:UInt8(kAUSampler_DefaultMelodicBankMSB),bankLSB:0)
  sampler.sendController(10,withValue:UInt8(score.pan[index]),onChannel:0)
  engine.connect(sampler,to:engine.mainMixerNode,format:format)
  samplers.append(sampler)
 }
 let reverb=AVAudioUnitReverb()
 engine.attach(reverb)
 reverb.loadFactoryPreset(.mediumHall)
 reverb.wetDryMix = name=="night" ? 19 : 12
 engine.connect(engine.mainMixerNode,to:reverb,format:format)
 engine.connect(reverb,to:engine.outputNode,format:format)
 try engine.enableManualRenderingMode(.offline,format:format,maximumFrameCount:512)
 let buffer=AVAudioPCMBuffer(pcmFormat:engine.manualRenderingFormat,frameCapacity:512)!
 let file=try AVAudioFile(forWriting:directory.appendingPathComponent(name+"_raw.wav"),settings:[AVFormatIDKey:kAudioFormatLinearPCM,AVSampleRateKey:rate,AVNumberOfChannelsKey:2,AVLinearPCMBitDepthKey:16,AVLinearPCMIsFloatKey:false,AVLinearPCMIsBigEndianKey:false],commonFormat:.pcmFormatFloat32,interleaved:false)
 var events:[Event]=[]
 let cycle=AVAudioFramePosition((score.duration*rate).rounded())
 for repeatIndex in 0..<2 {
  for note in score.events {
   let begin=AVAudioFramePosition((note.start*rate).rounded())+AVAudioFramePosition(repeatIndex)*cycle
   let end=begin+AVAudioFramePosition((note.duration*rate).rounded())
   events.append(Event(frame:begin,track:note.track,pitch:UInt8(note.pitch),velocity:UInt8(note.velocity)))
   events.append(Event(frame:end,track:note.track,pitch:UInt8(note.pitch),velocity:0))
  }
 }
 events.sort { $0.frame==$1.frame ? $0.velocity<$1.velocity : $0.frame<$1.frame }
 try engine.start()
 var cursor:AVAudioFramePosition=0
 var eventIndex=0
 while cursor<cycle*2 {
  while eventIndex<events.count && events[eventIndex].frame<=cursor {
   let event=events[eventIndex]
   if event.velocity==0 { samplers[event.track].stopNote(event.pitch,onChannel:0) }
   else { samplers[event.track].startNote(event.pitch,withVelocity:event.velocity,onChannel:0) }
   eventIndex+=1
  }
  let next=eventIndex<events.count ? events[eventIndex].frame : cycle*2
  let length=AVAudioFrameCount(min(512,min(cycle*2-cursor,max(1,next-cursor))))
  let status=try engine.renderOffline(length,to:buffer)
  if status == .success {
   try file.write(from:buffer)
   cursor+=AVAudioFramePosition(buffer.frameLength)
  } else if status == .error { fatalError("Offline render failed") }
 }
 engine.stop()
 print("Rendered \(name), two cycles, \(score.duration) seconds each")
}
