"""Audit saved PCM against the playback catalog, without changing assets."""
from pathlib import Path
import hashlib
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'


def main():
    catalog = json.loads((ROOT / 'catalog.json').read_text())
    rows = {}
    failures = []
    for name, entry in catalog['clips'].items():
        path = ROOT / entry['file']
        with wave.open(str(path), 'rb') as source:
            rate, channels, width, frames = (source.getframerate(), source.getnchannels(),
                                           source.getsampwidth(), source.getnframes())
            pcm = np.frombuffer(source.readframes(frames), dtype='<i2').reshape(-1, channels)
        signal = pcm.astype(float) / 32767
        peak = float(np.max(np.abs(signal)))
        rms = float(np.sqrt(np.mean(signal * signal)))
        checks = {
            'format': rate == entry['rate'] == 32000 and width == 2 and channels == entry['channels'],
            'frames': frames == entry['frames'],
            'hash': hashlib.sha256(path.read_bytes()).hexdigest() == entry['sha256'],
            'unclipped': peak < .981,
            'peak_matches': abs(peak - entry['peak']) < .00006,
            'rms_matches': abs(rms - entry['rms']) < .00006,
            'non_silent_channels': bool(np.all(np.mean(signal * signal, axis=0) > 1e-7)),
            'silent_endpoints': bool(np.all(pcm[0] == 0) and np.all(pcm[-1] == 0)),
        }
        failures.extend(f'{name}: {key}' for key, passed in checks.items() if not passed)
        rows[name] = {'seconds': round(frames / rate, 4), 'peak': round(peak, 5),
                      'rms': round(rms, 5), 'checks': checks}
    report = {'clips': len(rows), 'playback_clips': len(rows) - 1,
              'total_bytes': sum((ROOT / e['file']).stat().st_size for e in catalog['clips'].values()),
              'failures': failures, 'assets': rows}
    (ROOT / 'qa_report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f'Audio asset audit: {len(rows)} clips, {len(failures)} failures')
    if failures:
        raise SystemExit('\n'.join(failures))


if __name__ == '__main__':
    main()
