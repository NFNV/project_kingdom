from pathlib import Path
out=Path(__file__).resolve().parent
vests={
'n':'M112 107 121 111 119 156 107 160 105 130Z M138 110 145 107 153 133 148 160 137 156Z',
'ne':'M119 107 128 111 126 156 114 160 112 130Z M145 110 152 107 160 133 155 160 144 156Z',
'e':'M121 109 129 111 134 154 118 157 112 131Z M139 111 145 116 149 140 140 158 136 154Z',
'se':'M119 107 126 114 126 154 115 160 111 132Z M144 113 150 108 159 133 153 161 142 155Z',
's':'M113 107 120 114 120 154 109 160 105 132Z M138 113 144 108 153 133 147 161 136 155Z'
}
for view,path in vests.items():
 body=f'<path d="{path}" fill="#76543b" stroke="#513d2c" stroke-width="2" stroke-linejoin="round"/><path d="M112 156Q128 164 145 156" fill="none" stroke="#b5935f" stroke-width="2"/>'
 (out/(view+'_hero_vest.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">'+body+'</svg>\n')
# The protagonist has a pale cream tail tip.
p=out/'cat_tail.svg';p.write_text(p.read_text().replace('#f0ca80','#f6e5bd'))
print('Five matching brown vest layers and cream tail tip created.')
