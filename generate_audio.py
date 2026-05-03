import wave
import math
import struct
import os
import random

os.makedirs('assets/audio', exist_ok=True)

def generate_wav(filename, duration, freq1, freq2=None, volume=0.5, wave_type='sine', decay=0.0):
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            
            # frequency sweep if freq2 is provided
            current_freq = freq1
            if freq2 is not None:
                current_freq = freq1 + (freq2 - freq1) * (t / duration)
                
            if wave_type == 'sine':
                value = math.sin(2.0 * math.pi * current_freq * t)
            elif wave_type == 'square':
                value = 1.0 if math.sin(2.0 * math.pi * current_freq * t) > 0 else -1.0
            elif wave_type == 'noise':
                value = random.uniform(-1.0, 1.0)
            
            # Decay envelope
            envelope = 1.0
            if decay > 0:
                envelope = math.exp(-t * decay)
            value *= envelope * volume
            
            # Convert to 16-bit PCM
            data = struct.pack('<h', int(value * 32767.0))
            wav_file.writeframesraw(data)

# 1. Spin tick (short click) — PRESERVED: using manually sourced spin.wav, do not overwrite
# generate_wav('assets/audio/spin.wav', 0.1, 800, 1200, 0.2, 'square', decay=20)

# 2. Reel Stop (deep thud, frequency sweep down)
generate_wav('assets/audio/stop.wav', 0.3, 150, 40, 0.8, 'sine', decay=15)

# 3. Win Fanfare (bright happy sweep up)
generate_wav('assets/audio/win.wav', 1.5, 400, 1200, 0.5, 'sine', decay=2)

# 4. Coin Chime (short high pitched sine, 1200Hz, steep decay)
generate_wav('assets/audio/coin_chime.wav', 0.05, 1200, None, 0.4, 'sine', decay=30)

print("Audio files generated in assets/audio/")
