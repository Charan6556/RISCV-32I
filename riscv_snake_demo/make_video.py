#!/usr/bin/env python3
# makes a GIF and MP4 from the console output of tb_soc
# each frame comes from the characters the core printed:
# '#' wall, 'o' body, '@' head, '*' food
# usage: python3 make_video.py build_out.txt out_name
import re, subprocess, sys, os
from PIL import Image, ImageDraw, ImageFont

log = open(sys.argv[1], encoding="latin-1").read()
out = sys.argv[2] if len(sys.argv) > 2 else "snake_rv32i"

frames = [f for f in log.split("\x1b[H")[1:] if "RV32I SNAKE" in f]
stats = dict(re.findall(r"\[tb\] (.+?)\s*: (\S+)", log))
ending = "TARGET REACHED" if "TARGET REACHED" in log else "GAME OVER"

CELL, PAD = 20, 24
COLS, ROWS = 32, 16
W = COLS * CELL + 2 * PAD
TOP, BOT = 78, 70
H = TOP + ROWS * CELL + BOT

BG, WALL, EMPTY = (13, 17, 23), (48, 54, 61), (22, 27, 34)
BODY, HEAD, FOOD = (46, 160, 67), (126, 231, 135), (248, 81, 73)
TXT, DIM, ACC = (230, 237, 243), (139, 148, 158), (88, 166, 255)

mono = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
bold = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
f_title, f_sub, f_stat = ImageFont.truetype(bold, 20), ImageFont.truetype(mono, 13), ImageFont.truetype(mono, 15)

ANSI = re.compile(r"\x1b\[[0-9;]*m")

def parse(frame):
    frame = ANSI.sub("", frame)   # remove the color codes
    lines = frame.split("\n")
    grid = [line[0::2][:COLS] for line in lines[:ROWS]]
    status = re.search(r"score (\d+)\s+length (\d+)\s+step (\d+)", frame)
    return grid, status.groups()

def render(grid, status, banner=None):
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    d.text((PAD, 14), "Snake running on my 5-stage RV32I CPU", font=f_title, fill=TXT)
    d.text((PAD, 44), "C code compiled with clang, running on my SystemVerilog RTL in Verilator",
           font=f_sub, fill=DIM)
    for y in range(ROWS):
        row = grid[y].ljust(COLS)
        for x in range(COLS):
            c = row[x]
            x0, y0 = PAD + x * CELL, TOP + y * CELL
            box = (x0 + 1, y0 + 1, x0 + CELL - 2, y0 + CELL - 2)
            if c == "#":
                d.rectangle((x0, y0, x0 + CELL - 1, y0 + CELL - 1), fill=WALL)
            elif c in "o@":
                d.rounded_rectangle(box, radius=5, fill=HEAD if c == "@" else BODY)
            elif c == "*":
                d.ellipse((x0 + 3, y0 + 3, x0 + CELL - 4, y0 + CELL - 4), fill=FOOD)
            else:
                d.rectangle(box, fill=EMPTY)
    score, length, step = status
    yb = TOP + ROWS * CELL + 14
    d.text((PAD, yb), f"score {score:>2}   length {length:>2}   step {step:>3}", font=f_stat, fill=TXT)
    d.text((PAD, yb + 24), "BFS to food + flood fill check, RV32I only (no mul/div)",
           font=f_sub, fill=DIM)
    if banner:
        bw, bh = 470, 150
        bx, by = (W - bw) // 2, TOP + (ROWS * CELL - bh) // 2
        d.rounded_rectangle((bx, by, bx + bw, by + bh), radius=12, fill=(13, 17, 23), outline=ACC, width=2)
        for i, (t, f, col) in enumerate(banner):
            d.text((bx + 22, by + 16 + i * 25), t, font=f, fill=col)
    return im

parsed = [parse(f) for f in frames]
imgs = [render(g, s) for g, s in parsed]

summary = [
    ("TARGET REACHED" if ending == "TARGET REACHED" else "GAME OVER", f_title, HEAD),
    (f"{int(stats['retired']):,} instructions retired", f_stat, TXT),
    (f"{int(stats['cycles']):,} cycles   CPI {stats['CPI']}", f_stat, TXT),
    (f"{int(stats['load-use stalls']):,} load-use stalls", f_stat, DIM),
    (f"{int(stats['taken redirects']):,} taken branches/jumps", f_stat, DIM),
]
final = render(*parsed[-1], banner=summary)

# GIF: every 2nd frame, then hold the summary at the end
gif_frames = imgs[::2] + [final]
durations = [50] * (len(gif_frames) - 1) + [4000]
gif_frames[0].save(f"{out}.gif", save_all=True, append_images=gif_frames[1:],
                   duration=durations, loop=0, optimize=True)

# MP4: 30 fps, one game step per frame
tmp = "build/vidframes"
os.makedirs(tmp, exist_ok=True)
seq = imgs + [imgs[-1]] * 15 + [final] * 120
for i, im in enumerate(seq):
    im.save(f"{tmp}/f{i:05d}.png")
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "30", "-i", f"{tmp}/f%05d.png",
                "-vf", "scale=iw*2:ih*2:flags=neighbor,pad=ceil(iw/2)*2:ceil(ih/2)*2",
                "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18", f"{out}.mp4"], check=True)
final.save(f"{out}_final.png")
print(f"{len(frames)} frames, wrote {out}.gif, {out}.mp4, {out}_final.png")
